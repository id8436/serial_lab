import 'package:flutter/material.dart';
import 'package:serial_lab/screens/code_sender/funcs/sample_codes.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/screens/code_sender/funcs/code_editor_config.dart';

class SampleCodeTab extends StatelessWidget {
  final void Function(SampleCode sample)? onLoadSample;

  const SampleCodeTab({super.key, this.onLoadSample});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sampleCodes.length,
      itemBuilder: (context, index) {
        final sample = sampleCodes[index];
        final title = _sampleTitle(l10n, sample.titleKey);
        final desc = _sampleTitle(l10n, sample.descKey);
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
                        label: Text(l10n.sampleEditButton),
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

  String _sampleTitle(AppLocalizations l10n, String key) {
    final map = <String, String Function(AppLocalizations)>{
      'sampleBlink': (l) => l.sampleBlink,
      'sampleBlinkDesc': (l) => l.sampleBlinkDesc,
      'sampleSerialHello': (l) => l.sampleSerialHello,
      'sampleSerialHelloDesc': (l) => l.sampleSerialHelloDesc,
      'sampleSerialJson': (l) => l.sampleSerialJson,
      'sampleSerialJsonDesc': (l) => l.sampleSerialJsonDesc,
      'sampleAnalogRead': (l) => l.sampleAnalogRead,
      'sampleAnalogReadDesc': (l) => l.sampleAnalogReadDesc,
      'sampleServoSweep': (l) => l.sampleServoSweep,
      'sampleServoSweepDesc': (l) => l.sampleServoSweepDesc,
      'sampleTempDht': (l) => l.sampleTempDht,
      'sampleTempDhtDesc': (l) => l.sampleTempDhtDesc,
      'sampleLedControl': (l) => l.sampleLedControl,
      'sampleLedControlDesc': (l) => l.sampleLedControlDesc,
      'sampleUltrasonic': (l) => l.sampleUltrasonic,
      'sampleUltrasonicDesc': (l) => l.sampleUltrasonicDesc,
    };
    return map[key]?.call(l10n) ?? key;
  }
}
