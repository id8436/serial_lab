import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/models/chart_data.dart';
import 'package:serial_lab/l10n/app_localizations.dart';

/// 실시간 차트 화면
class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  String? _selectedSeries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // chartData의 키 목록 + 선택된 시리즈의 데이터 길이가 바뀔 때만 rebuild
    return Selector<SerialProvider, ({List<String> keys, int length})>(
      selector: (_, p) {
        final keys = p.chartData.keys.toList();
        final len = _selectedSeries != null
            ? (p.chartData[_selectedSeries]?.dataPoints.length ?? 0)
            : 0;
        return (keys: keys, length: len);
      },
      shouldRebuild: (prev, next) =>
          prev.length != next.length ||
          prev.keys.length != next.keys.length,
      builder: (context, sel, child) {
        final chartData = context.read<SerialProvider>().chartData;

        if (chartData.isNotEmpty &&
            (_selectedSeries == null || !chartData.containsKey(_selectedSeries))) {
          _selectedSeries = chartData.keys.first;
        }

        final selectedSeries =
            _selectedSeries != null ? chartData[_selectedSeries] : null;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Text(l10n.chartDataSeries),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedSeries != null ? _selectedSeries : null,
                      isExpanded: true,
                      hint: Text(l10n.chartNoDataPoints),
                      items: chartData.keys.map((key) {
                        return DropdownMenuItem(
                          value: key,
                          child: Text(key),
                        );
                      }).toList(),
                      onChanged: chartData.isEmpty
                          ? null
                          : (value) {
                              setState(() {
                                _selectedSeries = value;
                              });
                            },
                    ),
                  ),

                ],
              ),
            ),
            Expanded(
              child: selectedSeries == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.chartNoData,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              l10n.chartNoDataHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: RealtimeChart(
                        series: selectedSeries,
                      ),
                    ),
            ),
            if (selectedSeries != null && selectedSeries.dataPoints.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      l10n.chartCurrent,
                      selectedSeries.dataPoints.last.value,
                      Icons.fiber_manual_record,
                    ),
                    _buildStatCard(
                      l10n.chartMin,
                      selectedSeries.minValue ?? 0,
                      Icons.arrow_downward,
                    ),
                    _buildStatCard(
                      l10n.chartMax,
                      selectedSeries.maxValue ?? 0,
                      Icons.arrow_upward,
                    ),
                    _buildStatCard(
                      l10n.chartPoints,
                      selectedSeries.dataPoints.length.toDouble(),
                      Icons.data_array,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, double value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 실시간 라인 차트 위젯
class RealtimeChart extends StatelessWidget {
  final ChartSeries series;
  /// 차트에 표시할 최대 데이터 포인트 수
  static const int _maxVisiblePoints = 200;

  const RealtimeChart({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.dataPoints.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.chartNoDataPoints));
    }

    // 최근 _maxVisiblePoints개만 표시
    final allPoints = series.dataPoints;
    final startIndex = allPoints.length > _maxVisiblePoints
        ? allPoints.length - _maxVisiblePoints
        : 0;
    final visiblePoints = allPoints.sublist(startIndex);

    final spots = visiblePoints
        .map((point) => FlSpot(
              point.x,
              point.y,
            ))
        .toList();

    final minX = visiblePoints.first.x;
    final maxX = visiblePoints.last.x;
    final yValues = visiblePoints.map((p) => p.value);
    final minY = yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.reduce((a, b) => a > b ? a : b);
    final margin = (maxY - minY) * 0.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (maxX - minX) / 5,
              getTitlesWidget: (value, meta) {
                final time = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    DateFormat('HH:mm:ss').format(time),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        minX: minX,
        maxX: maxX,
        minY: minY - margin,
        maxY: maxY + margin,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length < 20,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final time = DateTime.fromMillisecondsSinceEpoch(
                  spot.x.toInt(),
                );
                return LineTooltipItem(
                  '${DateFormat('HH:mm:ss').format(time)}\n${spot.y.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
