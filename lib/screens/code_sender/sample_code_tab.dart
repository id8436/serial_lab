import 'package:flutter/material.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/models/sample_code.dart';
import 'package:serial_lab/models/sample_code_catalog.dart';
import 'package:serial_lab/screens/code_sender/config/code_editor_config.dart';

class SampleCodeTab extends StatelessWidget {
  final void Function(SampleCode sample)? onLoadSample;

  const SampleCodeTab({super.key, this.onLoadSample});

  // 카테고리별로 그룹화 (category 필드가 비어있으면 일반 샘플로 분류)
  Map<String, List<SampleCode>> _grouped(AppLocalizations l10n) {
    final result = <String, List<SampleCode>>{};
    for (final sample in sampleCodes) {
      final cat = sample.category.isEmpty ? l10n.sampleGeneralCategory : l10n.sampleDiagCategory;
      result.putIfAbsent(cat, () => []).add(sample);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groups = _grouped(l10n);
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
          return _buildCategoryHeader(context, item.category, l10n);
        }
        final sample = (item as _SampleItem).sample;
        final title = _resolveKey(l10n, sample.titleKey);
        final desc = _resolveKey(l10n, sample.descKey);
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

  Widget _buildCategoryHeader(BuildContext context, String category, AppLocalizations l10n) {
    final isDiag = category == l10n.sampleDiagCategory;
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

  /// ARB 키를 l10n에서 조회. 없으면 키 그대로 반환.
  String _resolveKey(AppLocalizations l10n, String key) {
    switch (key) {
      case 'sampleDiagBlink': return l10n.sampleDiagBlink;
      case 'sampleDiagBlinkDesc': return l10n.sampleDiagBlinkDesc;
      case 'sampleDiagJsonRandom': return l10n.sampleDiagJsonRandom;
      case 'sampleDiagJsonRandomDesc': return l10n.sampleDiagJsonRandomDesc;
      case 'sampleBlink': return l10n.sampleBlink;
      case 'sampleBlinkDesc': return l10n.sampleBlinkDesc;
      case 'sampleBlinkMillis': return l10n.sampleBlinkMillis;
      case 'sampleBlinkMillisDesc': return l10n.sampleBlinkMillisDesc;
      case 'sampleSerialHello': return l10n.sampleSerialHello;
      case 'sampleSerialHelloDesc': return l10n.sampleSerialHelloDesc;
      case 'sampleAnalogRead': return l10n.sampleAnalogRead;
      case 'sampleAnalogReadDesc': return l10n.sampleAnalogReadDesc;
      case 'samplePwmFade': return l10n.samplePwmFade;
      case 'samplePwmFadeDesc': return l10n.samplePwmFadeDesc;
      case 'sampleServoSweep': return l10n.sampleServoSweep;
      case 'sampleServoSweepDesc': return l10n.sampleServoSweepDesc;
      case 'sampleTempDht': return l10n.sampleTempDht;
      case 'sampleTempDhtDesc': return l10n.sampleTempDhtDesc;
      case 'sampleButtonDebounce': return l10n.sampleButtonDebounce;
      case 'sampleButtonDebounceDesc': return l10n.sampleButtonDebounceDesc;
      case 'sampleLedControl': return l10n.sampleLedControl;
      case 'sampleLedControlDesc': return l10n.sampleLedControlDesc;
      case 'sampleUltrasonic': return l10n.sampleUltrasonic;
      case 'sampleUltrasonicDesc': return l10n.sampleUltrasonicDesc;
      default: return key;
    }
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
