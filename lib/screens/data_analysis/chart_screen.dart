import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/models/chart_data.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/widgets/page_visibility.dart';

/// 실시간 차트 화면.
///
/// 성능 모델:
/// - 시리즈 키 집합은 [Selector]로 추적 (키 변화 시에만 rebuild)
/// - 포인트 추가에는 `SerialProvider.dataTick`을 [ActiveListenableBuilder]로
///   listen → 이 페이지가 실제로 보일 때만 LineChart 를 다시 그림.
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
    return Selector<SerialProvider, List<String>>(
      selector: (_, p) => p.chartData.keys.toList(growable: false),
      shouldRebuild: (prev, next) {
        if (prev.length != next.length) return true;
        for (var i = 0; i < prev.length; i++) {
          if (prev[i] != next[i]) return true;
        }
        return false;
      },
      builder: (context, keys, _) {
        // 선택된 시리즈가 사라졌거나 초기값이 없는 경우 보정
        if (keys.isNotEmpty &&
            (_selectedSeries == null || !keys.contains(_selectedSeries))) {
          _selectedSeries = keys.first;
        } else if (keys.isEmpty) {
          _selectedSeries = null;
        }

        return Column(
          children: [
            _SeriesSelector(
              keys: keys,
              selected: _selectedSeries,
              onChanged: (v) => setState(() => _selectedSeries = v),
              l10n: l10n,
            ),
            Expanded(
              child: _selectedSeries == null
                  ? _EmptyChart(l10n: l10n)
                  : _LiveChartPanel(seriesKey: _selectedSeries!, l10n: l10n),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────── 내부 위젯 ───────────────────────

class _SeriesSelector extends StatelessWidget {
  const _SeriesSelector({
    required this.keys,
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  final List<String> keys;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Text(l10n.chartDataSeries),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              hint: Text(l10n.chartNoDataPoints),
              items: keys
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: keys.isEmpty ? null : onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.chartNoData,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.chartNoDataHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}

/// 실제 LineChart + 통계 카드를 dataTick 에 맞춰 갱신하는 패널.
///
/// 페이지가 off-stage 인 동안에는 [ActiveListenableBuilder]가 tick 을 무시한다.
class _LiveChartPanel extends StatelessWidget {
  const _LiveChartPanel({required this.seriesKey, required this.l10n});
  final String seriesKey;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SerialProvider>();
    return ActiveListenableBuilder(
      listenable: provider.dataTick,
      builder: (context) {
        final series = provider.chartData[seriesKey];
        if (series == null || series.dataPoints.isEmpty) {
          return Center(child: Text(l10n.chartNoDataPoints));
        }
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: RealtimeChart(series: series),
              ),
            ),
            _StatsBar(series: series, l10n: l10n),
          ],
        );
      },
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.series, required this.l10n});
  final ChartSeries series;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCard(
            label: l10n.chartCurrent,
            value: series.dataPoints.last.value,
            icon: Icons.fiber_manual_record,
          ),
          _StatCard(
            label: l10n.chartMin,
            value: series.minValue ?? 0,
            icon: Icons.arrow_downward,
          ),
          _StatCard(
            label: l10n.chartMax,
            value: series.maxValue ?? 0,
            icon: Icons.arrow_upward,
          ),
          _StatCard(
            label: l10n.chartPoints,
            value: series.dataPoints.length.toDouble(),
            icon: Icons.data_array,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// 실시간 라인 차트 위젯. Stateless — 입력만으로 결정된다.
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

    final allPoints = series.dataPoints;
    final startIndex = allPoints.length > _maxVisiblePoints
        ? allPoints.length - _maxVisiblePoints
        : 0;
    final visiblePoints = allPoints.sublist(startIndex);

    final spots = visiblePoints
        .map((p) => FlSpot(p.x, p.y))
        .toList(growable: false);

    final minX = visiblePoints.first.x;
    final maxX = visiblePoints.last.x;
    final yValues = visiblePoints.map((p) => p.value);
    final minY = yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.reduce((a, b) => a > b ? a : b);
    final margin = (maxY - minY) * 0.1;

    return InteractiveViewer(
      panEnabled: true,
      scaleEnabled: true,
      minScale: 1.0,
      maxScale: 4.0,
      boundaryMargin: const EdgeInsets.all(80),
      clipBehavior: Clip.none,
      child: LineChart(
        LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
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
                final time =
                    DateTime.fromMillisecondsSinceEpoch(value.toInt());
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
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10),
              ),
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
            dotData: FlDotData(show: spots.length < 20),
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
                final time =
                    DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                return LineTooltipItem(
                  '${DateFormat('HH:mm:ss').format(time)}\n'
                  '${spot.y.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        ),
      ),
    );
  }
}
