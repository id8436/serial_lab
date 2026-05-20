import 'dart:async';

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
  bool _isBusy = false;
  String? _busyLabel;

  Future<void> _runWithLoading(
    String label,
    Future<void> Function() action,
  ) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _busyLabel = label;
    });

    // 로딩 오버레이가 먼저 그려질 수 있도록 한 프레임 양보
    await Future<void>.delayed(Duration.zero);

    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _busyLabel = null;
        });
      }
    }
  }

  Future<void> _saveData(AnalysisDataProvider analysisProvider, _DataSaveFormat format) async {
    final l10n = AppLocalizations.of(context)!;
    await _runWithLoading(
      l10n.chartSaveData,
      () async {
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
      },
    );
  }

  Future<void> _loadData(AnalysisDataProvider analysisProvider) async {
    final l10n = AppLocalizations.of(context)!;

    final pickedFile = await SessionIoService.pickDataFile(
      onLargeFileWarning: (fileName, fileSizeBytes) {
        return _confirmLargeFileLoad(
          fileName: fileName,
          fileSizeBytes: fileSizeBytes,
        );
      },
    );
    if (!mounted || pickedFile == null) {
      debugPrint('[_loadData] pickDataFile returned null (cancelled or empty)');
      return;
    }

    await _runWithLoading(
      l10n.chartLoadData,
      () async {
        try {
          final loaded = await SessionIoService.parsePickedDataFile(pickedFile)
              .timeout(const Duration(seconds: 90));
          debugPrint('[_loadData] parsePickedDataFile returned ${loaded.length} series: '
              '${loaded.keys.take(4).join(", ")}');
          if (!mounted) {
            debugPrint('[_loadData] early return: mounted=$mounted');
            return;
          }

          analysisProvider.loadDataWithPreview(loaded);
          debugPrint('[_loadData] loadDataWithPreview called with ${loaded.length} series');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.chartLoadedSeries(loaded.length))),
          );
        } on FormatException catch (error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.chartLoadFailed(error.message))),
          );
        } on TimeoutException {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.chartLoadFailed('Loading timed out. Try a smaller file.'))),
          );
        } catch (error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.chartLoadFailed(error.toString()))),
          );
        }
      },
    );
  }

  Future<bool> _confirmLargeFileLoad({
    required String fileName,
    required int fileSizeBytes,
  }) async {
    if (!mounted) return false;

    final sizeText = _formatFileSize(fileSizeBytes);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Large file warning'),
          content: Text(
            'Selected file is $sizeText ($fileName).\\n\\n'
            'Parsing may take time and can temporarily reduce responsiveness. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'unknown size';
    const kb = 1024.0;
    const mb = kb * 1024.0;
    const gb = mb * 1024.0;
    final b = bytes.toDouble();
    if (b >= gb) return '${(b / gb).toStringAsFixed(2)} GB';
    if (b >= mb) return '${(b / mb).toStringAsFixed(2)} MB';
    if (b >= kb) return '${(b / kb).toStringAsFixed(2)} KB';
    return '$bytes B';
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
        final seriesCount = analysisProvider.seriesCount;
        final pointCount = analysisProvider.pointCount;

        return Stack(
          children: [
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Column(
                    children: [
                      if (analysisProvider.isHydratingImportedData) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Analyzing imported data... '
                                '${analysisProvider.hydratedSeriesCount}/${analysisProvider.totalSeriesCount} series',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text('${(analysisProvider.hydrationProgress * 100).round()}%'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: analysisProvider.hydrationProgress),
                        const SizedBox(height: 8),
                      ],
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isSmallScreen = constraints.maxWidth < 600;
                          if (isSmallScreen) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            Text(l10n.analysisDataSeriesCount(seriesCount)),
                                            const SizedBox(width: 12),
                                            Text(l10n.analysisDataPointsCount(pointCount)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
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
                                      Consumer<SerialProvider>(
                                        builder: (context, serialProvider, _) {
                                          final hasRealtime = serialProvider.hasRealtimeAnalysisSource;
                                          return FilledButton.icon(
                                            onPressed: hasRealtime
                                                ? () => _runWithLoading(
                                                      l10n.analysisLoadRealtime,
                                                      () async {
                                                        analysisProvider.loadFromProvider(serialProvider);
                                                        if (!mounted) return;
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text(l10n.analysisLoadedPoints(
                                                                analysisProvider.seriesCount)),
                                                            duration: const Duration(seconds: 2),
                                                          ),
                                                        );
                                                      },
                                                    )
                                                : null,
                                            icon: const Icon(Icons.download, size: 18),
                                            label: Text(l10n.analysisLoadRealtime),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Row(
                              children: [
                                Text(l10n.analysisDataSeriesCount(seriesCount)),
                                const SizedBox(width: 12),
                                Text(l10n.analysisDataPointsCount(pointCount)),
                                const Spacer(),
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
                                Consumer<SerialProvider>(
                                  builder: (context, serialProvider, _) {
                                    final hasRealtime = serialProvider.hasRealtimeAnalysisSource;
                                    return FilledButton.icon(
                                      onPressed: hasRealtime
                                          ? () => _runWithLoading(
                                                l10n.analysisLoadRealtime,
                                                () async {
                                                  analysisProvider.loadFromProvider(serialProvider);
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(l10n.analysisLoadedPoints(
                                                          analysisProvider.seriesCount)),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                },
                                              )
                                          : null,
                                      icon: const Icon(Icons.download, size: 18),
                                      label: Text(l10n.analysisLoadRealtime),
                                    );
                                  },
                                ),
                              ],
                            );
                          }
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
            ),
            if (_isBusy) ...[
              Positioned.fill(
                child: AbsorbPointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                          const SizedBox(height: 10),
                          Text(_busyLabel ?? l10n.chartLoadData),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
