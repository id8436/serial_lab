import 'package:flutter/widgets.dart';

/// `IndexedStack` 같은 구조에서 특정 자식이 현재 보이는 페이지인지 자손 위젯에
/// 전달하기 위한 InheritedWidget.
///
/// 사용 예 (HomeScreen):
/// ```dart
/// IndexedStack(
///   index: _selectedIndex,
///   children: [
///     for (var i = 0; i < pages.length; i++)
///       PageVisibility(active: i == _selectedIndex, child: pages[i]),
///   ],
/// )
/// ```
///
/// 자손 위젯은 [PageVisibility.of] 로 현재 활성 여부를 확인하고
/// 무거운 build 를 생략할 수 있다. [ActiveListenableBuilder] 는 이 정보를
/// 이용해 off-stage 일 때 tick rebuild 를 전부 억제한다.
class PageVisibility extends InheritedWidget {
  final bool active;

  const PageVisibility({
    super.key,
    required this.active,
    required super.child,
  });

  /// 조상 중 가장 가까운 [PageVisibility] 의 active 값. 없으면 `true`.
  static bool of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<PageVisibility>();
    return w?.active ?? true;
  }

  /// 의존성을 등록하지 않고 현재 값만 읽는다. (listener 내부 등)
  static bool readOf(BuildContext context) {
    final w = context
        .getElementForInheritedWidgetOfExactType<PageVisibility>()
        ?.widget as PageVisibility?;
    return w?.active ?? true;
  }

  @override
  bool updateShouldNotify(PageVisibility oldWidget) =>
      active != oldWidget.active;
}

/// [Listenable]이 tick 할 때마다 rebuild하되, 조상 [PageVisibility.active]가
/// `false` 이면 rebuild를 건너뛰고 pending 상태로 둔다. 페이지가 다시 활성화되면
/// (InheritedWidget 변화로) 한 번 rebuild 된다.
///
/// 실시간 차트/테이블처럼 "보일 때만 다시 그리면 충분한" 위젯에 사용한다.
class ActiveListenableBuilder extends StatefulWidget {
  final Listenable listenable;
  final WidgetBuilder builder;

  const ActiveListenableBuilder({
    super.key,
    required this.listenable,
    required this.builder,
  });

  @override
  State<ActiveListenableBuilder> createState() =>
      _ActiveListenableBuilderState();
}

class _ActiveListenableBuilderState extends State<ActiveListenableBuilder> {
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_onTick);
  }

  @override
  void didUpdateWidget(ActiveListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_onTick);
      widget.listenable.addListener(_onTick);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    if (PageVisibility.readOf(context)) {
      setState(() {});
    } else {
      _pending = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 페이지가 비활성 → 활성으로 전환될 때 보류된 tick 을 한 번 반영한다.
    // (InheritedWidget 변화로 인해 이 메서드가 호출되면서 자연스럽게 build 된다.)
    if (_pending && PageVisibility.of(context)) {
      _pending = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
