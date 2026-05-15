import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/providers/analysis_data_provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/screens/data_analysis/analysis/realtime_table_analysis_screen.dart';
import 'package:serial_lab/services/analysis/session_io_service.dart';

class AnalysisDataScreen extends StatefulWidget {
  const AnalysisDataScreen({super.key});

  @override
  State<AnalysisDataScreen> createState() => _AnalysisDataScreenState();
}

class _AnalysisDataScreenState extends State<AnalysisDataScreen> {
  Future<void> _saveData(AnalysisDataProvider analysisProvider, _DataSaveFormat format) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final path = switch (format) {
        _DataSaveFormat.json => await SessionIoService.saveJsonFile(analysisProvider.chartData),
        _DataSaveFormat.csv => await SessionIoService.saveCsvFile(analysisProvider.chartData),
      };

      if (!mounted || path == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            format == _DataSaveFormat.json
                ? l10n.chartSavedJson(path)
                : l10n.chartExportedCsv(path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chartLoadFailed(e.toString()))),
      );
    }
  }

  Future<void> _loadData(AnalysisDataProvider analysisProvider) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final loaded = await SessionIoService.loadDataFile();
      if (!mounted || loaded == null) {
        return;
      }

      analysisProvider.loadData(loaded, []);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chartLoadedSeries(loaded.length))),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chartLoadFailed(error.message))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chartLoadFailed(error.toString()))),
      );
    }
  }

  Future<void> _confirmAndClear(AnalysisDataProvider analysisProvider) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<_ClearAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.analysisClearConfirmTitle),
        content: Text(l10n.analysisClearConfirmMessage),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(ctx).pop(_ClearAction.cancel),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_ClearAction.deleteOnly),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.analysisClearDeleteOnly),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(_ClearAction.saveAndDelete),
            child: Text(l10n.analysisClearSaveAndDelete),
          ),
        ],
      ),
    );

    if (!mounted) return;

    switch (result) {
      case _ClearAction.saveAndDelete:
        await _saveData(analysisProvider, _DataSaveFormat.json);
        if (!mounted) return;
        analysisProvider.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.drawerDataCleared)),
        );
      case _ClearAction.deleteOnly:
        analysisProvider.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.drawerDataCleared)),
        );
      case null:
      case _ClearAction.cancel:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AnalysisDataProvider>(
      builder: (context, analysisProvider, child) {
        final seriesCount = analysisProvider.chartData.length;
        final pointCount = analysisProvider.chartData.values.fold<int>(
          0,
          (sum, series) => sum + series.dataPoints.length,
        );

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  // 왼쪽: 시리즈/포인트 수
                  Text(l10n.analysisDataSeriesCount(seriesCount)),
                  const SizedBox(width: 12),
                  Text(l10n.analysisDataPointsCount(pointCount)),
                  const Spacer(),
                  // 오른쪽: 아이콘 버튼들
                  PopupMenuButton<_DataSaveFormat>(
                    enabled: analysisProvider.chartData.isNotEmpty,
                    tooltip: l10n.chartSaveData,
                    icon: const Icon(Icons.save_alt),
                    onSelected: (format) => _saveData(analysisProvider, format),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _DataSaveFormat.json,
                        child: Text(l10n.chartSaveAsJson),
                      ),
                      PopupMenuItem(
                        value: _DataSaveFormat.csv,
                        child: Text(l10n.chartSaveAsCsv),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () => _loadData(analysisProvider),
                    tooltip: l10n.chartLoadData,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: analysisProvider.hasData
                        ? () => _confirmAndClear(analysisProvider)
                        : null,
                    tooltip: l10n.chartClearData,
                  ),
                  const SizedBox(width: 4),
                  // 실시간 데이터 불러오기
                  Consumer<SerialProvider>(
                    builder: (context, serialProvider, _) {
                      final hasRealtime = serialProvider.chartData.isNotEmpty ||
                          serialProvider.receivedData.isNotEmpty;
                      return FilledButton.icon(
                        onPressed: hasRealtime
                            ? () {
                                analysisProvider.loadFromProvider(serialProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.analysisLoadedPoints(
                                        analysisProvider.chartData.length)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.download, size: 18),
                        label: Text(l10n.analysisLoadRealtime),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Expanded(
              child: RealtimeTableAnalysisScreen(
                source: RealtimeTableSource.analysis,
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _DataSaveFormat {
  json,
  csv,
}

enum _ClearAction {
  cancel,
  saveAndDelete,
  deleteOnly,
}
