import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/models/device_info.dart';
import 'package:serial_lab/services/board_label_service.dart';
import 'package:serial_lab/widgets/board_search_dialog.dart';
import 'package:serial_lab/widgets/confirm_dialog.dart';
import 'package:serial_lab/widgets/info_row.dart';
import 'package:serial_lab/widgets/stat_card.dart';

/// 연결된 기기 정보 화면
class DeviceInfoScreen extends StatelessWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Consumer<SerialProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 연결 상태 카드
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                provider.isConnected ? Icons.check_circle : Icons.cancel,
                                color: provider.isConnected ? scheme.primary : scheme.error,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                provider.isConnected ? l10n.statusConnected : l10n.statusDisconnected,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: provider.isConnected ? scheme.primary : scheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (provider.isConnected && provider.currentDevice != null) ...[
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                          
                          // 기기 정보
                          InfoRow(
                            icon: Icons.device_hub,
                            label: l10n.deviceInfoDeviceName,
                            value: provider.currentDevice!.name,
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.location_pin,
                            label: l10n.deviceInfoAddress,
                            value: provider.currentDevice!.address,
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.category,
                            label: l10n.deviceInfoConnType,
                            value: _getConnectionTypeText(provider.currentDevice!.connectionType),
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.speed,
                            label: l10n.deviceInfoBaudRate,
                            value: '${provider.baudRate} bps',
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.memory,
                            label: l10n.deviceInfoSelectedBoard,
                            value: BoardLabelService.getLabel(provider.selectedBoard),
                          ),
                          
                          // HC-06 전용 정보 (기기별 특화)
                          if (provider.currentDevice!.name.toLowerCase().contains('hc-')) ...[
                            const SizedBox(height: 12),
                            InfoRow(
                              icon: Icons.bluetooth,
                              label: l10n.deviceInfoProtocol,
                              value: 'Classic Bluetooth SPP',
                            ),
                            const SizedBox(height: 12),
                            InfoRow(
                              icon: Icons.memory,
                              label: l10n.deviceInfoBuffering,
                              value: l10n.deviceInfoBufferingValue,
                            ),
                            const SizedBox(height: 12),
                            InfoRow(
                              icon: Icons.settings_input_antenna,
                              label: l10n.deviceInfoDataFormat,
                              value: l10n.deviceInfoDataFormatValue,
                            ),
                          ],
                          
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          // 통계 정보 (차이점 명시)
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  icon: Icons.data_object,
                                  label: l10n.deviceInfoJsonData,
                                  subtitle: l10n.deviceInfoJsonSub,
                                  value: '${provider.receivedData.length}',
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCard(
                                  icon: Icons.text_fields,
                                  label: l10n.deviceInfoTextData,
                                  subtitle: l10n.deviceInfoTextSub,
                                  value: '${provider.rawTextData.length}',
                                  color: scheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // 연결 해제 버튼
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final l10n = AppLocalizations.of(context)!;
                                if (provider.isReceiving) {
                                  final ok = await showConfirmDialog(
                                    context: context,
                                    title: l10n.confirmDisconnectTitle,
                                    message: l10n.confirmDisconnectMessage,
                                    confirmLabel: l10n.tooltipDisconnect,
                                    icon: Icons.link_off,
                                  );
                                  if (!ok) return;
                                }
                                await provider.disconnect();
                              },
                              icon: const Icon(Icons.close),
                              label: Text(AppLocalizations.of(context)!.tooltipDisconnect),
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                                foregroundColor: Theme.of(context).colorScheme.onError,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          ] else ...[
                          const SizedBox(height: 20),
                          Text(
                            l10n.deviceInfoConnectFromTab,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        ]
                      ),
                    ),
                  ),

                  // 장치 설정 카드 (보드 선택 + 보드레이트)
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.settings,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.deviceInfoDeviceSettings,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          // 보드 선택
                          Consumer<SerialProvider>(
                            builder: (context, provider, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.developer_board, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        l10n.deviceInfoArduinoBoard,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      // 자동 감지 버튼 (항상 표시, 연결 안 되면 비활성)
                                      FilledButton.tonalIcon(
                                        onPressed: provider.isConnected ? () {
                                          final detected = provider.detectBoardFromDevice();
                                          provider.setBoard(detected);
                                          final messenger = ScaffoldMessenger.of(context);
                                          messenger.hideCurrentSnackBar();
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(l10n.deviceInfoDetected(BoardLabelService.getLabel(detected))),
                                              backgroundColor: scheme.primary,
                                            ),
                                          );
                                        } : null,
                                        icon: const Icon(Icons.auto_fix_high, size: 16),
                                        label: Text(l10n.deviceInfoAutoDetect),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () async {
                                      final result = await showDialog<String>(
                                        context: context,
                                        builder: (_) => BoardSearchDialog(
                                          currentFqbn: provider.selectedBoard,
                                          recentBoards: provider.recentBoards,
                                        ),
                                      );
                                      if (result != null) provider.setBoard(result);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  BoardLabelService.getLabel(
                                                      provider.selectedBoard),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge,
                                                ),
                                                Text(
                                                  provider.selectedBoard,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                          color: scheme.onSurfaceVariant),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.search, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // 최근 사용 보드
                                  if (provider.recentBoards.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.deviceInfoRecentUsed,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: provider.recentBoards.map((board) {
                                        final isSelected = board == provider.selectedBoard;
                                        return FilterChip(
                                          label: Text(BoardLabelService.getLabel(board)),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            if (selected) {
                                              provider.setBoard(board);
                                            }
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                        const SizedBox(height: 24),
                        
                        // 보드레이트 표시 (읽기 전용)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.speed,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.deviceInfoBaudRate,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${provider.baudRate} bps',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Tooltip(
                                message: l10n.deviceInfoBaudRateTooltip,
                                child: Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _getConnectionTypeText(ConnectionType type) {
    return switch (type) {
      ConnectionType.bluetooth => 'Bluetooth',
      ConnectionType.usb => 'USB Serial',
      ConnectionType.wifi => 'WiFi',
    };
  }
}
