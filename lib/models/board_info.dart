/// 보드 카탈로그 단일 항목
class BoardInfo {
  final String fqbn;
  final String name;
  final String description;
  final String category;

  const BoardInfo({
    required this.fqbn,
    required this.name,
    required this.description,
    required this.category,
  });
}
