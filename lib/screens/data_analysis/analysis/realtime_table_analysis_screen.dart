import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/models/chart_data.dart';
import 'package:serial_lab/models/serial_data.dart';
import 'package:serial_lab/providers/analysis_data_provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/widgets/page_visibility.dart';

/// 테이블 표시 데이터 소스
enum RealtimeTableSource { realtime, analysis }

/// 실시간/분석 테이블 화면.
///
/// - [RealtimeTableSource.realtime] 이면 `SerialProvider.dataTick` 에 맞춰
///   `receivedData`를 주기적으로 읽어 DataTable을 다시 만든다.
///   `PageVisibility`가 `false` 일 때는 rebuild를 건너뛴다.
/// - [RealtimeTableSource.analysis] 이면 `AnalysisDataProvider`의 스냅샷을 사용.
class RealtimeTableAnalysisScreen extends StatelessWidget {
  final RealtimeTableSource source;

  const RealtimeTableAnalysisScreen({
    super.key,
    this.source = RealtimeTableSource.realtime,
  });

  /// 한 번에 화면에 그리는 최대 행 수
  static const int _maxVisibleRows = 120;
  /// 한 번에 화면에 그리는 최대 열 수
  static const int _maxVisibleColumns = 16;

  @override
  Widget build(BuildContext context) {
    if (source == RealtimeTableSource.analysis) {
      return _AnalysisTable();
    }
    return _RealtimeTable(maxVisibleRows: _maxVisibleRows);
  }
}

// ─────────────────────── Realtime (live) ───────────────────────

class _RealtimeTable extends StatelessWidget {
  const _RealtimeTable({required this.maxVisibleRows});
  final int maxVisibleRows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<SerialProvider>();
    return ActiveListenableBuilder(
      listenable: provider.dataTick,
      builder: (context) {
        final data = provider.receivedData;
        if (data.isEmpty) return _TableEmpty(l10n: l10n);
        return _TableBody(
          data: data,
          maxVisibleRows: maxVisibleRows,
          maxVisibleColumns: RealtimeTableAnalysisScreen._maxVisibleColumns,
          l10n: l10n,
        );
      },
    );
  }
}

// ─────────────────────── Analysis (snapshot) ───────────────────────

class _AnalysisTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final analysisProvider = context.watch<AnalysisDataProvider>();

    final List<SerialData> data = analysisProvider.receivedData.isNotEmpty
        ? analysisProvider.receivedData
        : _buildFromChartDataLimited(
            analysisProvider.chartData,
            maxRowsPerSeries: RealtimeTableAnalysisScreen._maxVisibleRows,
          );

    if (data.isEmpty) return _TableEmpty(l10n: l10n);
    return _TableBody(
      data: data,
      maxVisibleRows: RealtimeTableAnalysisScreen._maxVisibleRows,
      maxVisibleColumns: RealtimeTableAnalysisScreen._maxVisibleColumns,
      l10n: l10n,
    );
  }
}

// ─────────────────────── Shared table body ───────────────────────

class _TableBody extends StatelessWidget {
  static const double _kTimeCellWidth = 96;
  static const double _kValueCellWidth = 92;

  const _TableBody({
    required this.data,
    required this.maxVisibleRows,
    required this.maxVisibleColumns,
    required this.l10n,
  });

  final List<SerialData> data;
  final int maxVisibleRows;
  final int maxVisibleColumns;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final rows = data.reversed.take(maxVisibleRows).toList(growable: false);
    final allColumns = _collectColumns(rows);
    final columns = allColumns.take(maxVisibleColumns).toList(growable: false);
    final hiddenColumnCount = allColumns.length - columns.length;
    final tableWidth = _kTimeCellWidth + (columns.length * _kValueCellWidth);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(l10n.analysisTableRows(data.length)),
              if (data.length > rows.length)
                Text(
                  l10n.analysisTableShowingRecent(rows.length, data.length),
                ),
              if (hiddenColumnCount > 0)
                Text('Showing ${columns.length}/${allColumns.length} columns'),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        border: Border(
                          bottom: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          _HeaderCell(
                            width: _kTimeCellWidth,
                            text: l10n.analysisTableTime,
                          ),
                          for (final key in columns)
                            _HeaderCell(
                              width: _kValueCellWidth,
                              text: key,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final entry = rows[index];
                          final striped = index.isEven;
                          return Container(
                            color: striped
                                ? scheme.surface
                                : scheme.surfaceContainerLowest,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                _ValueCell(
                                  width: _kTimeCellWidth,
                                  text: DateFormat('HH:mm:ss')
                                      .format(entry.timestamp),
                                ),
                                for (final key in columns)
                                  _ValueCell(
                                    width: _kValueCellWidth,
                                    text: _formatValue(entry.data[key]),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.width, required this.text});

  final double width;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({required this.width, required this.text});

  final double width;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _TableEmpty extends StatelessWidget {
  const _TableEmpty({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.analysisTableNoData,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.analysisTableNoDataHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Utils ───────────────────────

/// chartData에서 SerialData 행 목록을 재구성 (시간 기준 정렬)
List<SerialData> _buildFromChartDataLimited(
  Map<String, ChartSeries> chartData, {
  required int maxRowsPerSeries,
}) {
  if (chartData.isEmpty) return const [];

  final Map<int, Map<String, dynamic>> rowMap = {};
  final Map<int, DateTime> timeMap = {};

  for (final entry in chartData.entries) {
    final points = entry.value.dataPoints;
    final start = points.length > maxRowsPerSeries
        ? points.length - maxRowsPerSeries
        : 0;
    for (var i = start; i < points.length; i++) {
      final p = points[i];
      final ms = p.time.millisecondsSinceEpoch;
      rowMap.putIfAbsent(ms, () => {});
      rowMap[ms]![entry.key] = p.value;
      timeMap.putIfAbsent(ms, () => p.time);
    }
  }

  final sortedKeys = rowMap.keys.toList()..sort();
  return sortedKeys
      .map((ms) => SerialData(
            id: ms.toString(),
            timestamp: timeMap[ms]!,
            data: rowMap[ms]!,
          ))
      .toList();
}

List<String> _collectColumns(List<SerialData> rows) {
  final keys = <String>{};
  for (final row in rows) {
    keys.addAll(row.data.keys);
  }
  final list = keys.toList()..sort();
  return list;
}

String _formatValue(dynamic value) {
  if (value == null) return '-';
  if (value is num) {
    final asDouble = value.toDouble();
    if (asDouble == asDouble.roundToDouble()) {
      return asDouble.toInt().toString();
    }
    return asDouble.toStringAsFixed(3);
  }
  return value.toString();
}
