import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/providers/analysis_data_provider.dart';
import 'package:serial_lab/services/analysis/fft_service.dart';

class FftAnalysisScreen extends StatefulWidget {
  const FftAnalysisScreen({super.key});

  @override
  State<FftAnalysisScreen> createState() => _FftAnalysisScreenState();
}

class _FftAnalysisScreenState extends State<FftAnalysisScreen> {
  String? _selectedSeries;
  int _windowSize = 128;
  FftWindow _windowFn = FftWindow.hann;

  static const _windowOptions = [64, 128, 256, 512];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Consumer<AnalysisDataProvider>(
      builder: (context, analysisData, _) {
        final chartData = analysisData.chartData;
        if (chartData.isEmpty) {
          return Center(child: Text(l10n.fftEmpty));
        }

        if (_selectedSeries == null || !chartData.containsKey(_selectedSeries)) {
          _selectedSeries = chartData.keys.first;
        }

        final result = FftService.analyze(
          chartData[_selectedSeries!]!,
          windowSize: _windowSize,
          window: _windowFn,
        );

        return Column(
          children: [
            _ControlBar(
              l10n: l10n,
              scheme: scheme,
              seriesKeys: chartData.keys.toList(growable: false),
              selectedSeries: _selectedSeries,
              windowSize: _windowSize,
              windowFn: _windowFn,
              windowOptions: _windowOptions,
              onSeriesChanged: (v) => setState(() => _selectedSeries = v),
              onWindowSizeChanged: (v) {
                if (v != null) setState(() => _windowSize = v);
              },
              onWindowFnChanged: (v) {
                if (v != null) setState(() => _windowFn = v);
              },
            ),
            Expanded(
              child: result == null || result.bins.isEmpty
                  ? Center(child: Text(l10n.fftNotEnough))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ResultStats(l10n: l10n, scheme: scheme, result: result),
                          const SizedBox(height: 12),
                          Expanded(child: _buildChart(result, scheme, l10n)),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChart(FftResult result, ColorScheme scheme, AppLocalizations l10n) {
    final spots = result.bins
        .map((b) => FlSpot(b.frequencyHz, b.magnitude))
        .toList(growable: false);
    final maxX = spots.isEmpty ? 1.0 : spots.last.x;
    var maxY = 0.0;
    for (final spot in spots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    if (maxY <= 0) maxY = 1;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY * 1.1,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: scheme.outlineVariant),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            dotData: const FlDotData(show: false),
            barWidth: 2,
            color: scheme.primary,
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            axisNameWidget: Text(
              l10n.fftAxisFrequency,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            sideTitles: const SideTitles(showTitles: true, reservedSize: 28),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              l10n.fftAxisMagnitude,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            sideTitles: const SideTitles(showTitles: true, reservedSize: 44),
          ),
        ),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.l10n,
    required this.scheme,
    required this.seriesKeys,
    required this.selectedSeries,
    required this.windowSize,
    required this.windowFn,
    required this.windowOptions,
    required this.onSeriesChanged,
    required this.onWindowSizeChanged,
    required this.onWindowFnChanged,
  });

  final AppLocalizations l10n;
  final ColorScheme scheme;
  final List<String> seriesKeys;
  final String? selectedSeries;
  final int windowSize;
  final FftWindow windowFn;
  final List<int> windowOptions;
  final ValueChanged<String?> onSeriesChanged;
  final ValueChanged<int?> onWindowSizeChanged;
  final ValueChanged<FftWindow?> onWindowFnChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: scheme.surfaceContainerHighest,
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _LabeledDropdown<String>(
            label: l10n.fftSeries,
            value: selectedSeries,
            items: seriesKeys
                .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                .toList(),
            onChanged: onSeriesChanged,
          ),
          _LabeledDropdown<int>(
            label: l10n.fftWindowSize,
            value: windowSize,
            items: windowOptions
                .map((v) => DropdownMenuItem<int>(value: v, child: Text('$v')))
                .toList(),
            onChanged: onWindowSizeChanged,
          ),
          _LabeledDropdown<FftWindow>(
            label: l10n.fftWindowFunction,
            value: windowFn,
            items: [
              DropdownMenuItem(
                value: FftWindow.hann,
                child: Text(l10n.fftWindowHann),
              ),
              DropdownMenuItem(
                value: FftWindow.rectangular,
                child: Text(l10n.fftWindowRectangular),
              ),
            ],
            onChanged: onWindowFnChanged,
          ),
        ],
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: 8),
        DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ResultStats extends StatelessWidget {
  const _ResultStats({
    required this.l10n,
    required this.scheme,
    required this.result,
  });

  final AppLocalizations l10n;
  final ColorScheme scheme;
  final FftResult result;

  @override
  Widget build(BuildContext context) {
    final peak = result.peak;
    final jitterPct = result.jitterRatio * 100;
    final jitterUnstable = result.jitterRatio > 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            Text(l10n.fftSampleCount(result.sampleCount)),
            Text(l10n.fftSampleRate(result.sampleRateHz.toStringAsFixed(2))),
            Text(
              l10n.fftNyquist(result.nyquistHz.toStringAsFixed(2)),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            if (peak != null)
              Text(
                l10n.fftPeak(
                  peak.frequencyHz.toStringAsFixed(2),
                  peak.magnitude.toStringAsFixed(3),
                ),
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        if (jitterUnstable) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: scheme.tertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.fftJitterWarning(jitterPct.toStringAsFixed(1)),
                  style: TextStyle(color: scheme.tertiary, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
