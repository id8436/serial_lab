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
  static const int _maxVisibleRows = 300;

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
        : _buildFromChartData(analysisProvider.chartData);

    if (data.isEmpty) return _TableEmpty(l10n: l10n);
    return _TableBody(
      data: data,
      maxVisibleRows: RealtimeTableAnalysisScreen._maxVisibleRows,
      l10n: l10n,
    );
  }
}

// ─────────────────────── Shared table body ───────────────────────

class _TableBody extends StatelessWidget {
  const _TableBody({
    required this.data,
    required this.maxVisibleRows,
    required this.l10n,
  });

  final List<SerialData> data;
  final int maxVisibleRows;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final rows = data.reversed.take(maxVisibleRows).toList(growable: false);
    final columns = _collectColumns(rows);

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
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.analysisTableTime)),
                    ...columns.map((key) => DataColumn(label: Text(key))),
                  ],
                  rows: rows.map((entry) {
                    return DataRow(
                      cells: [
                        DataCell(Text(
                            DateFormat('HH:mm:ss').format(entry.timestamp))),
                        ...columns.map((key) {
                          final value = entry.data[key];
                          return DataCell(Text(_formatValue(value)));
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
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
List<SerialData> _buildFromChartData(Map<String, ChartSeries> chartData) {
  if (chartData.isEmpty) return const [];

  final Map<int, Map<String, dynamic>> rowMap = {};
  final Map<int, DateTime> timeMap = {};

  for (final entry in chartData.entries) {
    for (final p in entry.value.dataPoints) {
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
