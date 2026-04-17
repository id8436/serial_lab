import 'package:flutter/material.dart';
import 'package:serial_lab/models/board_info.dart';
import 'package:serial_lab/models/board_catalog.dart';
import 'package:serial_lab/services/board_label_service.dart';

/// 보드 검색 다이얼로그
class BoardSearchDialog extends StatefulWidget {
  final String currentFqbn;
  final List<String> recentBoards;

  const BoardSearchDialog({
    super.key,
    required this.currentFqbn,
    required this.recentBoards,
  });

  @override
  State<BoardSearchDialog> createState() => _BoardSearchDialogState();
}

class _BoardSearchDialogState extends State<BoardSearchDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BoardInfo> get _filtered {
    if (_query.isEmpty) return boardCatalog;
    final q = _query.toLowerCase();
    return boardCatalog.where((b) {
      return b.name.toLowerCase().contains(q) ||
          b.fqbn.toLowerCase().contains(q) ||
          b.description.toLowerCase().contains(q) ||
          b.category.toLowerCase().contains(q);
    }).toList();
  }

  Map<String, List<BoardInfo>> get _grouped {
    final result = <String, List<BoardInfo>>{};
    for (final board in _filtered) {
      result.putIfAbsent(board.category, () => []).add(board);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    final categories = groups.keys.toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.developer_board),
                const SizedBox(width: 12),
                Text(
                  '보드 선택',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // 검색창
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '보드 이름 또는 FQBN 검색...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          // 최근 사용 (검색 중에는 숨김)
          if (widget.recentBoards.isNotEmpty && _query.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최근 사용',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.recentBoards.map((fqbn) {
                      return ActionChip(
                        label: Text(BoardLabelService.getLabel(fqbn)),
                        onPressed: () => Navigator.pop(context, fqbn),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 16),
                ],
              ),
            ),
          // 보드 목록
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"$_query" 검색 결과 없음',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: categories.length,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, gi) {
                      final category = categories[gi];
                      final boards = groups[category]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              category,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          ...boards.map((board) {
                            final isSelected = board.fqbn == widget.currentFqbn;
                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              selectedColor: Theme.of(context).colorScheme.primary,
                              leading: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.developer_board_outlined,
                                size: 20,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              title: Text(board.name),
                              subtitle: Text(
                                board.description,
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: isSelected
                                  ? null
                                  : const Icon(Icons.chevron_right, size: 16),
                              onTap: () => Navigator.pop(context, board.fqbn),
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
