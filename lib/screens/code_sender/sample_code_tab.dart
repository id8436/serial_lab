import 'package:flutter/material.dart';
import 'package:serial_lab/models/sample_code.dart';
import 'package:serial_lab/models/sample_code_catalog.dart';
import 'package:serial_lab/screens/code_sender/config/code_editor_config.dart';

class SampleCodeTab extends StatelessWidget {
  final void Function(SampleCode sample)? onLoadSample;

  const SampleCodeTab({super.key, this.onLoadSample});

  // 카테고리별로 그룹화
  Map<String, List<SampleCode>> get _grouped {
    final result = <String, List<SampleCode>>{};
    for (final sample in sampleCodes) {
      final cat = sample.category.isEmpty ? '샘플 코드' : sample.category;
      result.putIfAbsent(cat, () => []).add(sample);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    final categories = groups.keys.toList();

    // 카테고리 헤더 + 항목을 하나의 flat 리스트로 변환
    final items = <_ListItem>[];
    for (final cat in categories) {
      items.add(_HeaderItem(cat));
      for (final sample in groups[cat]!) {
        items.add(_SampleItem(sample));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is _HeaderItem) {
          return _buildCategoryHeader(context, item.category);
        }
        final sample = (item as _SampleItem).sample;
        final title = _sampleTitle(sample.titleKey);
        final desc = _sampleTitle(sample.descKey);
        final isDiag = sample.category == '점검용';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          shape: isDiag
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                )
              : null,
          child: ExpansionTile(
            leading: Text(sample.icon, style: const TextStyle(fontSize: 24)),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).hintColor)),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF5F5F5),
                child: SelectableText(
                  sample.code,
                  style: TextStyle(
                    fontFamily: CodeEditorConfig.fontFamily,
                    fontSize: 12,
                  ),
                ),
              ),
              if (onLoadSample != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => onLoadSample!(sample),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('에디터로 불러오기'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String category) {
    final isDiag = category == '점검용';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Row(
        children: [
          if (isDiag)
            Icon(Icons.bug_report_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary),
          if (isDiag) const SizedBox(width: 6),
          Text(
            category,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  String _sampleTitle(String key) {
    const map = <String, String>{
      'sampleDiagBlink': '[점검용] LED Blink',
      'sampleDiagBlinkDesc': '배선 없이 보드 업로드 & 동작 확인. 내장 LED를 1초 간격으로 점멸합니다.',
      'sampleDiagJsonRandom': '[점검용] 랜덤 JSON 전송',
      'sampleDiagJsonRandomDesc': '1초마다 temperature / humidity / pressure 랜덤값을 JSON으로 전송. 시리얼 수신·그래프 확인용.',
      'sampleBlink': 'Board LED Check (Blink)',
      'sampleBlinkDesc': 'No wiring needed. Blink the built-in LED to verify board upload.',
      'sampleBlinkMillis': 'Non-blocking Blink (millis)',
      'sampleBlinkMillisDesc': 'Blink built-in LED without delay() to keep loop responsive.',
      'sampleSerialHello': 'Serial Hello',
      'sampleSerialHelloDesc': 'Send greeting text periodically over serial.',
      'sampleSerialJson': 'Serial JSON',
      'sampleSerialJsonDesc': 'Send temperature and humidity as JSON.',
      'sampleAnalogRead': 'Analog Read',
      'sampleAnalogReadDesc': 'Read analog input and print the value.',
      'samplePwmFade': 'PWM LED Fade',
      'samplePwmFadeDesc': 'Fade an LED on PWM pin 9 from dark to bright and back.',
      'sampleServoSweep': 'Servo Sweep',
      'sampleServoSweepDesc': 'Move a servo back and forth smoothly.',
      'sampleTempDht': 'DHT Temperature',
      'sampleTempDhtDesc': 'Read DHT sensor values and print them.',
      'sampleButtonDebounce': 'Button Debounce Toggle',
      'sampleButtonDebounceDesc': 'Toggle built-in LED with debounced button input (INPUT_PULLUP).',
      'sampleLedControl': 'LED Control',
      'sampleLedControlDesc': 'Turn LED on/off by serial command.',
      'sampleUltrasonic': 'Ultrasonic Distance',
      'sampleUltrasonicDesc': 'Measure distance with an HC-SR04 sensor.',
    };
    return map[key] ?? key;
  }
}

// ── 리스트 아이템 타입 ─────────────────────────────────────────
abstract class _ListItem {}

class _HeaderItem extends _ListItem {
  final String category;
  _HeaderItem(this.category);
}

class _SampleItem extends _ListItem {
  final SampleCode sample;
  _SampleItem(this.sample);
}
