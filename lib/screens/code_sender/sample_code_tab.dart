import 'package:flutter/material.dart';
import 'package:serial_lab/screens/code_sender/funcs/sample_codes.dart';
import 'package:serial_lab/screens/code_sender/funcs/code_editor_config.dart';

class SampleCodeTab extends StatelessWidget {
  final void Function(SampleCode sample)? onLoadSample;

  const SampleCodeTab({super.key, this.onLoadSample});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sampleCodes.length,
      itemBuilder: (context, index) {
        final sample = sampleCodes[index];
        final title = _sampleTitle(sample.titleKey);
        final desc = _sampleTitle(sample.descKey);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: Text(sample.icon, style: const TextStyle(fontSize: 24)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => onLoadSample!(sample),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Load into editor'),
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

  String _sampleTitle(String key) {
    const map = <String, String>{
      'sampleBlink': 'Blink LED',
      'sampleBlinkDesc': 'Blink the built-in LED every second.',
      'sampleSerialHello': 'Serial Hello',
      'sampleSerialHelloDesc': 'Send greeting text periodically over serial.',
      'sampleSerialJson': 'Serial JSON',
      'sampleSerialJsonDesc': 'Send temperature and humidity as JSON.',
      'sampleAnalogRead': 'Analog Read',
      'sampleAnalogReadDesc': 'Read analog input and print the value.',
      'sampleServoSweep': 'Servo Sweep',
      'sampleServoSweepDesc': 'Move a servo back and forth smoothly.',
      'sampleTempDht': 'DHT Temperature',
      'sampleTempDhtDesc': 'Read DHT sensor values and print them.',
      'sampleLedControl': 'LED Control',
      'sampleLedControlDesc': 'Turn LED on/off by serial command.',
      'sampleUltrasonic': 'Ultrasonic Distance',
      'sampleUltrasonicDesc': 'Measure distance with an HC-SR04 sensor.',
    };
    return map[key] ?? key;
  }
}
