import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/analysis_data_provider.dart';
import 'package:serial_lab/services/analysis/stats_service.dart';

class StatsAnalysisScreen extends StatefulWidget {
  const StatsAnalysisScreen({super.key});

  @override
  State<StatsAnalysisScreen> createState() => _StatsAnalysisScreenState();
}

class _StatsAnalysisScreenState extends State<StatsAnalysisScreen> {
  String? _selectedSeries;

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

        final series = chartData[_selectedSeries]!;
        final result = StatsService.analyze(series);

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
                ],
              ),
            ),
            Expanded(
              child: result == null
                  ? const Center(child: Text('Not enough valid points for analysis.'))
                  : GridView.count(
                      padding: const EdgeInsets.all(16),
                      crossAxisCount: 2,
                      childAspectRatio: 1.7,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _card('Count', '${result.count}'),
                        _card('Mean', result.mean.toStringAsFixed(4)),
                        _card('Median', result.median.toStringAsFixed(4)),
                        _card('Std Dev', result.standardDeviation.toStringAsFixed(4)),
                        _card('Min', result.min.toStringAsFixed(4)),
                        _card('Max', result.max.toStringAsFixed(4)),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _card(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
