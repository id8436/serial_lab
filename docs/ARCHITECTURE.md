# Serial Lab — Architecture Reference

> AI 및 신규 기여자가 **전체 트리를 매번 순회하지 않고도** 구조와 규칙을 빠르게 파악하기 위한 문서.
> 수정 시 이 파일을 먼저 갱신할 것.

---

## 1. 폴더 지도 (`lib/`)

| 경로 | 책임 |
|---|---|
| `l10n/` | 자동 생성된 `AppLocalizations` (flutter gen-l10n) |
| `main.dart` | 앱 엔트리, `MultiProvider` + `MaterialApp` 설정 |
| `models/` | 순수 데이터 모델 — `serial_data.dart`, `chart_data.dart`, `device_info.dart`, … |
| `providers/` | `ChangeNotifier` 상태 허브 — **`serial_provider.dart` (핵심)**, `analysis_data_provider.dart`, `settings_provider.dart`, `locale_provider.dart`, `theme_provider.dart` |
| `services/` | 부수효과 캡슐화 — `communication/` (USB/BT/WiFi 전송계층), `analysis/` (세션 I/O), `board_label_service.dart`, Hive 저장 서비스 등 |
| `screens/` | 페이지 단위 UI — `home_screen.dart`(Drawer 루트), `connection/`, `serial_monitor/`, `realtime_data/`, `data_analysis/`, `code_sender/`, `settings/`, `dashboard_screen.dart` |
| `widgets/` | 재사용 위젯 — **`page_visibility.dart`** (성능 핵심), `realtime_chart.dart`, 공통 카드/칩 |
| `utils/` | 소형 헬퍼 |

---

## 2. 데이터 흐름

```
[Arduino / HC-06 / ESP WebSocket]
        │  bytes
        ▼
CommunicationService  (services/communication/*)
        │  SerialData / String
        ▼
SerialProvider  (providers/serial_provider.dart)  ◀── 단일 상태 허브
        │
        ├── receivedData : List<SerialData>   (최대 1000개, FIFO)
        ├── chartData    : Map<String, ChartSeries>  (시리즈당 최대 2000 포인트)
        ├── rawTextData  : List<String>       (최대 1000개, FIFO)
        ├── isConnected / selectedBoard / currentDevice / …
        │
        ├── notifyListeners()    ← 저주파: 연결/설정/새 시리즈 key 추가 시에만
        └── dataTick (ValueListenable<int>) ← 고주파: 데이터 도착마다, 100ms 스로틀
                │
                ▼
           UI 위젯들
```

---

## 3. Provider 계약 (★ 꼭 준수)

`SerialProvider` 는 **2-rate 알림 모델**을 사용한다.

| 알림 채널 | 트리거 | 구독 방법 | 용도 |
|---|---|---|---|
| `notifyListeners()` | connect/disconnect, 보드/포트 변경, 수신 토글, **새로운 차트 시리즈 key 추가**, clear, `isReceiving` 변경 | `Selector<SerialProvider, X>`, `context.watch`, `Consumer` | AppBar 상태, 드로어, 컨트롤 바 등 **저빈도** UI |
| `dataTick` (`ValueListenable<int>`) | 모든 수신 데이터. 내부적으로 100ms 스로틀 | `ActiveListenableBuilder(listenable: provider.dataTick, …)` | 실시간 차트, 실시간 테이블, 수신 카운트 등 **고빈도** UI |

### 규칙
1. **heavy/live 위젯은 `context.watch<SerialProvider>()` 금지.** 항상 `Selector` (저빈도 필드) 또는 `ActiveListenableBuilder(listenable: provider.dataTick)` 사용.
2. `Selector` 의 selector 는 primitive/record/Immutable 만 반환. `List`/`Map` 반환 시 `shouldRebuild` 커스터마이즈.
3. 새로운 "자주 바뀌는 값"을 추가해야 한다면 **새 `ValueListenable` 을 SerialProvider 에 노출**하라. `notifyListeners()` 로 흘려보내지 말 것.

---

## 4. 성능 규칙

### 4.1 데이터 캡 (무한 증가 방지)
| 위치 | 상수 | 값 |
|---|---|---|
| `SerialProvider._kMaxReceivedEntries` | 수신 SerialData FIFO | 1000 |
| `SerialProvider._kMaxRawTextEntries` | raw 텍스트 FIFO | 1000 |
| `ChartData.defaultMaxPoints` | 시리즈별 포인트 | 2000 (evict 시 min/max 재계산 lazy) |

포인트 재계산은 `_statsDirty` 플래그로 **지연 평가** — getter 호출 시에만 수행.

### 4.2 IndexedStack + PageVisibility (★ 필수)
모든 `IndexedStack` 은 자식을 **`PageVisibility(active: i == selectedIndex, child: ...)`** 로 감싼다.
이 없이 자식을 넣으면 off-stage 페이지가 tick 마다 rebuild 되어 탭 복귀 시 프리즈를 유발한다.

자식 트리 내부에서 live 구독자는 반드시 `ActiveListenableBuilder` 를 사용한다. 해당 빌더는 `PageVisibility.readOf(context)` 로 현재 보이는지 확인하고, 보이지 않으면 tick 을 **pending** 으로 보류한 뒤 재활성화 시 한 번만 rebuild 한다.

### 4.3 차트
`_LiveChartPanel` 은 최근 200 포인트만 렌더링. 시리즈 수가 늘어도 `fl_chart` 가 O(n) 이므로 필요 시 downsample.

---

## 5. 레시피: 새 화면 추가

1. `screens/<feature>/<feature>_home.dart` 생성. 가능하면 `const` 생성자 사용.
2. 부모 `IndexedStack` 에 추가할 때 반드시 `PageVisibility(active: …, child: <MyPage>())` 로 감쌀 것.
3. 내부 위젯 분리:
   - **연결/설정 등 저빈도 필드** → `Selector<SerialProvider, T>` + record.
   - **실시간 데이터 표시** → `ActiveListenableBuilder(listenable: provider.dataTick, builder: (ctx,_) { ... })`. `provider` 는 `context.read<SerialProvider>()` 로 한 번만 잡아 두기.
4. `context.watch<SerialProvider>()` 를 쓰고 싶어지면 **멈추고** 2-rate 계약을 다시 보라.
5. 새로운 localization 키는 `l10n/app_en.arb` 등에 먼저 추가 후 `flutter gen-l10n` (자세한 흐름은 §9).
6. 색상은 직접 `Colors.*` 쓰지 말고 `Theme.of(context).colorScheme` 토큰을 사용 (자세한 규칙 §11).
7. 파괴적 액션 (disconnect/clear/overwrite) 은 `widgets/confirm_dialog.dart` 의 `showConfirmDialog` 를 쓸 것 (§10).
8. 사용자에게 노출할 에러는 `serialProvider._emitError(...)` 로 흘리고, UI 측에서 다시 SnackBar 를 띄우지 말 것 (§12 — 글로벌 핸들러가 처리).
9. 수정 후 `flutter analyze` (또는 VS Code task `shell: analyze`) 로 0 issues 확인.

---

## 6. 파일 포인터 (참조 예시)

| 파일 | 역할 | 참고 |
|---|---|---|
| `lib/providers/serial_provider.dart` | 상태 허브, 2-rate 알림의 **정답 구현체** | `_scheduleDataTick`, `_handleReceivedData` 주목 |
| `lib/widgets/page_visibility.dart` | `PageVisibility` InheritedWidget + `ActiveListenableBuilder` | off-stage tick 억제 로직 |
| `lib/models/chart_data.dart` | 링버퍼 시리즈 + lazy stats | `defaultMaxPoints`, `_statsDirty` |
| `lib/screens/home_screen.dart` | Drawer 루트, IndexedStack + PageVisibility 기준 예시 | `_AppBarConnectionStatus`, `_DrawerHeader`, `_DrawerFooter` 는 `Selector` 예시 |
| `lib/screens/realtime_data/realtime_data_home.dart` | BottomNavigationBar + IndexedStack + `Selector` 기반 컨트롤 바 | `_ControlBar` |
| `lib/screens/data_analysis/chart_screen.dart` | `ActiveListenableBuilder` 로 그려지는 실시간 차트 | `_LiveChartPanel` |
| `lib/screens/data_analysis/analysis/realtime_table_analysis_screen.dart` | 실시간 테이블 (ActiveListenableBuilder) + 분석 스냅샷 (watch) 혼합 | `_RealtimeTable` vs `_AnalysisTable` |
| `lib/screens/serial_monitor/terminal_screen.dart` | 수신 카운트만 dataTick 구독, 나머지는 Selector | `_ReceivedCountLabel` |
| `lib/screens/serial_monitor/terminal_home.dart` | IndexedStack + PageVisibility 추가 예시 |  |

---

## 7. 자주 틀리는 지점

- ❌ `context.watch<SerialProvider>()` in a chart/table body
  → ✅ `ActiveListenableBuilder(listenable: provider.dataTick, builder: ...)`
- ❌ `IndexedStack` 에 페이지를 그대로 넣기
  → ✅ `PageVisibility(active: ..., child: page)` 로 감싸기
- ❌ 새 고빈도 값을 `notifyListeners()` 로 흘려보내기
  → ✅ 별도 `ValueListenable` 추가
- ❌ `ChartSeries` 에 무제한으로 addDataPoint
  → ✅ `maxPoints` 를 존중 (기본 2000)
- ❌ `PageVisibility.of(ctx)` 를 listener 콜백에서 호출 (dependency 재등록)
  → ✅ 콜백 안에서는 `PageVisibility.readOf(ctx)` 사용
- ❌ `Colors.red` / `Colors.grey[600]` 같은 직접 색상
  → ✅ `Theme.of(context).colorScheme.error` / `.onSurfaceVariant`
- ❌ catch 블록에서 조용히 무시하거나 자체 SnackBar 띄우기
  → ✅ `_emitError(...)` 로 흘려보내고 글로벌 핸들러가 처리하도록 (§12)
- ❌ disconnect/clear/overwrite 에 `AlertDialog` 직접 작성
  → ✅ `showConfirmDialog(...)` 사용 (§10.1)
- ❌ ARB 한 로케일만 수정하고 커밋
  → ✅ en/ko/ja 동시 수정 + `flutter gen-l10n` (§9)

---

## 8. 체크리스트 (PR/커밋 전)

- [ ] `flutter analyze` → `No issues found!`
- [ ] 새로운 `IndexedStack` 자식이 `PageVisibility` 로 감싸져 있는가?
- [ ] 새로운 live 위젯이 `ActiveListenableBuilder(dataTick)` 을 쓰는가?
- [ ] 새로운 무한 목록/버퍼에 상한이 있는가?
- [ ] l10n 키가 모든 로케일에 추가되었는가? (en / ko / ja — §9)
- [ ] 색상 하드코딩 (`Colors.red`, `Colors.grey[600]`) 이 없는가? `colorScheme` 사용 (§11)
- [ ] 파괴적 액션에 `showConfirmDialog` 가 적용되었는가? (§10)
- [ ] 사용자 노출 에러는 `_emitError` 한 곳에서만 발생하는가? UI 에서 catch 후 SnackBar 직접 띄우지 않았는가? (§12)

---

## 9. l10n 파이프라인

`l10n.yaml` 가 루트에 있어 `flutter gen-l10n` 만 호출하면 다음 흐름이 동작한다.

```
lib/l10n/app_en.arb   ──┐
lib/l10n/app_ko.arb   ──┼─►  flutter gen-l10n  ─►  lib/l10n/app_localizations*.dart  (자동 생성)
lib/l10n/app_ja.arb   ──┘
```

### 규칙
1. **3개 ARB 파일을 함께 수정**한다. `app_en.arb` 에만 키를 추가하고 ko/ja 를 빼먹는 PR 금지.
2. 매개변수가 있는 키는 `app_en.arb` 에 `@키이름.placeholders` 메타도 함께 정의:
   ```json
   "deviceInfoDetected": "Detected board: {board}",
   "@deviceInfoDetected": {
     "placeholders": { "board": { "type": "String" } }
   }
   ```
   ko/ja 는 본문만 추가.
3. 추가 후 반드시 `flutter gen-l10n` 실행. (생성 파일은 `.gitignore` 에 들어있지 않으므로 커밋한다.)
4. 사용처에서는 `final l10n = AppLocalizations.of(context)!;` 후 `l10n.<키>` 로 접근.
5. **사용자에게 보이는 모든 문자열은 ARB 경유**가 원칙. 단 다음 예외만 하드코딩 허용:
   - 디버그 로그 (`logger.d(...)`)
   - 외부 식별자 (`'Classic Bluetooth SPP'`, `'arduino:avr:uno'` 같은 기술 식별자)
6. 반복적으로 쓰이는 OK/Cancel 은 `MaterialLocalizations.of(context).cancelButtonLabel` 등 플랫폼 표준을 우선 활용.

---

## 10. 다이얼로그 / SnackBar 패턴

### 10.1 확인 다이얼로그 — `widgets/confirm_dialog.dart`
파괴적 / 비가역 액션 (disconnect, clear, overwrite, delete) 은 반드시 `showConfirmDialog` 를 사용한다.

```dart
final ok = await showConfirmDialog(
  context: context,
  title: l10n.confirmDisconnectTitle,
  message: l10n.confirmDisconnectMessage,
  confirmLabel: l10n.tooltipDisconnect,
  icon: Icons.link_off,
);
if (!ok) return;
```

| 옵션 | 기본값 | 비고 |
|---|---|---|
| `isDestructive` | `true` | confirm 버튼이 `colorScheme.error/onError` 로 렌더 |
| `cancelLabel` | `MaterialLocalizations.cancelButtonLabel` | Cancel 버튼은 `autofocus: true` (실수 방지) |
| `icon` | 없음 | 헤더 아이콘 |

**금지**: 화면 안에 `AlertDialog` 를 직접 띄워 같은 패턴을 다시 만들지 말 것. 새로운 옵션이 필요하면 헬퍼 자체를 확장한다.

### 10.2 SnackBar
- 항상 `messenger.hideCurrentSnackBar()` 후 `showSnackBar` — 스택 방지.
- 성공: `colorScheme.primary`, 실패: `colorScheme.error`, 정보: 기본.
- 글로벌 에러는 §12 의 `_emitError` 경로로 가고, 화면-로컬 정보성 메시지만 직접 띄운다.

---

## 11. 테마 / 색상

다크 모드 안전을 위해 **`Colors.*` 직접 사용 금지** (단 외부 위젯이 요구하는 const literal 한정 예외).

| 의도 | 사용할 토큰 |
|---|---|
| 기본 텍스트 | `colorScheme.onSurface` |
| 보조 텍스트 / 아이콘 | `colorScheme.onSurfaceVariant` |
| 카드 / 헤더 배경 | `colorScheme.surfaceContainerHighest` 등 surfaceContainer* 톤 |
| 주요 액센트 (성공/연결/긍정) | `colorScheme.primary` |
| 부정 / 실패 / 파괴적 액션 | `colorScheme.error` |
| 정보 / 경고 강조 | `colorScheme.tertiary` |
| 보조 강조 | `colorScheme.secondary` |
| 그라데이션 위 텍스트/아이콘 | `colorScheme.onPrimary` (primary 그라데이션일 때) |
| 구분선 | `colorScheme.outlineVariant` |

`Colors.green/red` 같은 신호색은 `primary/error` 토큰이 시스템에 따라 자동으로 의미 있는 색을 잡아주므로 그쪽을 쓴다. BottomNavigationBar 의 `unselectedItemColor` 는 `onSurfaceVariant` 로 통일.

---

## 12. 에러 서페이싱

`SerialProvider` 는 사용자에게 노출할 가치가 있는 에러를 단일 채널로 모은다.

```dart
final ValueNotifier<String?> _lastError = ValueNotifier(null);
ValueListenable<String?> get lastError => _lastError;

void _emitError(String message) { ... }   // 동일 메시지도 재방출
void clearLastError() { ... }
```

### Provider 측
- catch 블록 중 **사용자가 알아야 할 것**만 `_emitError(...)` 호출.
- 다음 블록은 침묵 유지 (스팸 방지):
  - JSON 라인 파싱 실패 (의도된 fallback)
  - 스트림 listener 셋업 실패 (상위 connect 에러로 이미 노출)
  - per-line raw 텍스트 처리 에러
- 현재 적용 지점: `scanDevices`, `connect`, `dataStream.onError`, `connectionStream.onError`, `_tryAutoSaveSession`.

### UI 측
- `_HomeScreenState.didChangeDependencies` 에서 `provider.lastError` 를 한 번 구독한다.
- 메시지가 들어오면 글로벌 floating SnackBar (`colorScheme.error`) 로 노출 후 즉시 `clearLastError()`.
- **다른 화면에서 같은 catch → SnackBar 패턴을 또 만들지 말 것.** 글로벌 핸들러가 이미 처리한다.
- 화면-로컬한 비-에러 안내 (예: "Copied", "Reconnect waiting") 는 §10.2 패턴으로 직접 띄운다.

### 메시지 정책
현재 `_emitError` 는 영문 하드코딩. 구조화된 에러 코드 enum 도입 시 `lastError` 시그니처를 바꾸고 UI 측 ARB 매핑으로 옮길 것 (현재는 의도적으로 미적용).
