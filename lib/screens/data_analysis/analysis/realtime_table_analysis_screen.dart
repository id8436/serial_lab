import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/models/chart_data.dart';
import 'package:serial_lab/models/serial_data.dart';
import 'package:serial_lab/providers/analysis_data_provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';

/// 테이블 표시 데이터 소스
enum RealtimeTableSource { realtime, analysis }

class RealtimeTableAnalysisScreen extends StatelessWidget {
  /// [source]가 [RealtimeTableSource.realtime]이면 SerialProvider에서 직접 읽고,
  /// [RealtimeTableSource.analysis]이면 AnalysisDataProvider 스냅샷을 읽습니다.
  final RealtimeTableSource source;

  const RealtimeTableAnalysisScreen({
    super.key,
    this.source = RealtimeTableSource.realtime,
  });

  static const int _maxVisibleRows = 300;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<SerialData> data;
    if (source == RealtimeTableSource.analysis) {
      final analysisProvider = context.watch<AnalysisDataProvider>();
      if (analysisProvider.receivedData.isNotEmpty) {
        data = analysisProvider.receivedData;
      } else {
        // 파일에서 로드한 경우 receivedData가 비어있으므로 chartData에서 재구성
        data = _buildFromChartData(analysisProvider.chartData);
      }
    } else {
      data = context.watch<SerialProvider>().receivedData;
    }

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.analysisTableNoData,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    l10n.analysisTableNoDataHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final rows = data.reversed.take(_maxVisibleRows).toList(growable: false);
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
                    Text(l10n.analysisTableShowingRecent(rows.length, data.length)),
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
                            DataCell(Text(DateFormat('HH:mm:ss').format(entry.timestamp))),
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

  /// chartData에서 SerialData 행 목록을 재구성 (시간 기준 정렬)
  static List<SerialData> _buildFromChartData(Map<String, ChartSeries> chartData) {
    if (chartData.isEmpty) return const [];

    // 시간 → {key: value} 맵으로 병합
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
    return sortedKeys.map((ms) {
      return SerialData(
        id: ms.toString(),
        timestamp: timeMap[ms]!,
        data: rowMap[ms]!,
      );
    }).toList();
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
    if (value == null) {
      return '-';
    }

    if (value is num) {
      final asDouble = value.toDouble();
      if (asDouble == asDouble.roundToDouble()) {
        return asDouble.toInt().toString();
      }
      return asDouble.toStringAsFixed(3);
    }

    return value.toString();
  }
}
