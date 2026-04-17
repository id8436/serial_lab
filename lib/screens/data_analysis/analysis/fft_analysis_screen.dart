import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  static const _windowOptions = [64, 128, 256, 512];

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisDataProvider>(
      builder: (context, analysisData, _) {
        final chartData = analysisData.chartData;
        if (chartData.isEmpty) {
          return const Center(child: Text('No data. Start receiving numeric JSON first.'));
        }

        if (_selectedSeries == null || !chartData.containsKey(_selectedSeries)) {
          _selectedSeries = chartData.keys.first;
        }

        final result = FftService.analyze(
          chartData[_selectedSeries!]!,
          windowSize: _windowSize,
        );

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  const Text('Series'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedSeries,
                      isExpanded: true,
                      items: chartData.keys
                          .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedSeries = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Window'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _windowSize,
                    items: _windowOptions
                        .map((v) => DropdownMenuItem<int>(value: v, child: Text('$v')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _windowSize = v);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: result == null || result.bins.isEmpty
                  ? const Center(child: Text('Not enough samples for FFT.'))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text('Sample count: ${result.sampleCount}'),
                              const SizedBox(width: 16),
                              Text('Sample rate: ${result.sampleRateHz.toStringAsFixed(2)} Hz'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(child: _buildChart(result)),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChart(FftResult result) {
    final spots = result.bins
        .map((b) => FlSpot(b.frequencyHz, b.magnitude))
        .toList(growable: false);
    final maxX = spots.isEmpty ? 1.0 : spots.last.x;
    var maxY = 0.0;
    for (final spot in spots) {
      if (spot.y > maxY) {
        maxY = spot.y;
      }
    }
    if (maxY <= 0) {
      maxY = 1;
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY * 1.1,
        gridData: FlGridData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            dotData: const FlDotData(show: false),
            barWidth: 2,
            color: Colors.deepPurple,
          ),
        ],
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}
