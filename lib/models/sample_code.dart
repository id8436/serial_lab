/// 아두이노 샘플 코드 항목
class SampleCode {
  final String id;
  final String titleKey; // l10n key
  final String descKey; // l10n key
  final String icon;
  final String code;
  final String category;

  const SampleCode({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.icon,
    required this.code,
    this.category = '',
  });
}
