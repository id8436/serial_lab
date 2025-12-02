import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/models/chart_data.dart';

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
    return Consumer<SerialProvider>(
      builder: (context, provider, child) {
        final chartData = provider.chartData;

        if (chartData.isEmpty) {
          return Center(
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
                  'No chart data available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send numeric JSON data to see charts',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // 선택된 시리즈가 없으면 첫 번째 선택
        if (_selectedSeries == null || !chartData.containsKey(_selectedSeries)) {
          _selectedSeries = chartData.keys.first;
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  const Text('Data Series: '),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedSeries,
                      isExpanded: true,
                      items: chartData.keys.map((key) {
                        return DropdownMenuItem(
                          value: key,
                          child: Text(key),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSeries = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: () {
                      provider.clearChartData();
                    },
                    tooltip: 'Clear Data',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: RealtimeChart(
                  series: chartData[_selectedSeries]!,
                ),
              ),
            ),
            if (chartData[_selectedSeries]!.dataPoints.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Current',
                      chartData[_selectedSeries]!.dataPoints.last.value,
                      Icons.fiber_manual_record,
                    ),
                    _buildStatCard(
                      'Min',
                      chartData[_selectedSeries]!.minValue ?? 0,
                      Icons.arrow_downward,
                    ),
                    _buildStatCard(
                      'Max',
                      chartData[_selectedSeries]!.maxValue ?? 0,
                      Icons.arrow_upward,
                    ),
                    _buildStatCard(
                      'Points',
                      chartData[_selectedSeries]!.dataPoints.length.toDouble(),
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

  const RealtimeChart({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.dataPoints.isEmpty) {
      return const Center(child: Text('No data points'));
    }

    final spots = series.dataPoints
        .map((point) => FlSpot(
              point.x,
              point.y,
            ))
        .toList();

    final minX = series.dataPoints.first.x;
    final maxX = series.dataPoints.last.x;
    final minY = series.minValue ?? 0;
    final maxY = series.maxValue ?? 100;
    final margin = (maxY - minY) * 0.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
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
                  axisSide: meta.axisSide,
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
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
              color: Colors.blue.withOpacity(0.1),
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
