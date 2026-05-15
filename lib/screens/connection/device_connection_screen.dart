import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/models/device_info.dart';
import 'package:serial_lab/providers/serial_provider.dart';

/// 기기 연결 화면
class DeviceConnectionScreen extends StatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  ConnectionType _selectedType = ConnectionType.usb;
  final _wifiNameController = TextEditingController();
  final _wifiAddressController = TextEditingController();
  int _selectedBaudRate = 9600;
  final List<int> _baudRates = [9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600];

  @override
  void dispose() {
    _wifiNameController.dispose();
    _wifiAddressController.dispose();
    super.dispose();
  }

  void _scanDevices() {
    final provider = context.read<SerialProvider>();
    provider.scanDevices(_selectedType);
  }

  void _showWifiDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.wifiDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _wifiNameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.wifiDialogNameLabel,
                hintText: l10n.connectionDeviceNameHint,
                prefixIcon: const Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _wifiAddressController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.wifiDialogAddressLabel,
                hintText: l10n.wifiDialogAddressHint,
                prefixIcon: const Icon(Icons.wifi),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = context.read<SerialProvider>();
              provider.addWifiDevice(
                _wifiNameController.text,
                _wifiAddressController.text,
              );
              _wifiNameController.clear();
              _wifiAddressController.clear();
              Navigator.pop(context);
            },
            child: Text(l10n.commonAdd),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SerialProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Connection Type Selector
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.connectionTypeLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<ConnectionType>(
                      segments: const [
                        ButtonSegment(
                          value: ConnectionType.usb,
                          label: Text('USB'),
                          icon: Icon(Icons.usb),
                        ),
                        ButtonSegment(
                          value: ConnectionType.bluetooth,
                          label: Text('Bluetooth'),
                          icon: Icon(Icons.bluetooth),
                        ),
                        ButtonSegment(
                          value: ConnectionType.wifi,
                          label: Text('WiFi'),
                          icon: Icon(Icons.wifi),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (Set<ConnectionType> selection) {
                        setState(() {
                          _selectedType = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 연결 타입별 유의사항
                    _buildWarningForType(_selectedType, context),
                    
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: provider.isScanning ? null : _scanDevices,
                            icon: provider.isScanning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.search),
                            label: Text(
                              provider.isScanning ? l10n.connectionScanning : l10n.connectionScan,
                            ),
                          ),
                        ),
                        if (_selectedType == ConnectionType.wifi) ...[
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: _showWifiDialog,
                            icon: const Icon(Icons.add),
                            label: Text(l10n.commonAdd),
                          ),
                        ],
                      ],
                    ),
                    if (_selectedType != ConnectionType.wifi) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Baud Rate',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          DropdownButton<int>(
                            value: _selectedBaudRate,
                            items: _baudRates.map((rate) {
                              return DropdownMenuItem(
                                value: rate,
                                child: Text('$rate'),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              if (value != null) {
                                setState(() {
                                  _selectedBaudRate = value;
                                });
                                
                                // 연결 중이면 재연결
                                if (provider.isConnected && provider.currentDevice != null) {
                                  final device = provider.currentDevice!;
                                  final messenger = ScaffoldMessenger.of(context);
                                  final l10n = AppLocalizations.of(context)!;
                                  final scheme = Theme.of(context).colorScheme;

                                  // 스낵바로 재연결 알림
                                  if (mounted) {
                                    messenger.hideCurrentSnackBar();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.baudrateChanging(value)),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                  
                                  // 기존 연결 해제
                                  await provider.disconnect();
                                  
                                  // 새 보드레이트 설정
                                  provider.setBaudRate(value);
                                  
                                  // 재연결 시도
                                  final success = await provider.connect(device);
                                  
                                  if (mounted) {
                                    messenger.hideCurrentSnackBar();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                            ? l10n.baudrateChanged(value)
                                            : l10n.reconnectFailed,
                                        ),
                                        backgroundColor: success ? scheme.primary : scheme.error,
                                      ),
                                    );
                                  }
                                } else {
                                  // 연결 안 됐으면 그냥 설정만 변경
                                  provider.setBaudRate(value);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Device List
            Expanded(
              child: provider.availableDevices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.devices_other,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.connectionNoDevices,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.connectionNoDevicesHint,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.availableDevices.length,
                      itemBuilder: (context, index) {
                        final device = provider.availableDevices[index];
                        return _DeviceListItem(device: device);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWarningForType(ConnectionType type, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    String title;
    String message;
    IconData icon;

    switch (type) {
      case ConnectionType.usb:
        title = l10n.connectionWarnUsbTitle;
        message = l10n.connectionWarnUsbBody;
        icon = Icons.usb;
        break;
      case ConnectionType.bluetooth:
        title = l10n.connectionWarnBluetoothTitle;
        message = l10n.connectionWarnBluetoothBody;
        icon = Icons.bluetooth;
        break;
      case ConnectionType.wifi:
        title = l10n.connectionWarnWifiTitle;
        message = l10n.connectionWarnWifiBody;
        icon = Icons.wifi;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.tertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceListItem extends StatelessWidget {
  final DeviceInfo device;

  const _DeviceListItem({required this.device});

  IconData _getIcon() {
    switch (device.connectionType) {
      case ConnectionType.usb:
        return Icons.usb;
      case ConnectionType.bluetooth:
        return Icons.bluetooth;
      case ConnectionType.wifi:
        return Icons.wifi;
    }
  }

  Color _getIconColor(BuildContext context) {
    switch (device.connectionType) {
      case ConnectionType.usb:
        return Colors.orange;
      case ConnectionType.bluetooth:
        return Colors.blue;
      case ConnectionType.wifi:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Consumer<SerialProvider>(
      builder: (context, provider, child) {
        final isConnected = provider.currentDevice?.id == device.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getIconColor(context).withValues(alpha: 0.1),
              child: Icon(_getIcon(), color: _getIconColor(context)),
            ),
            title: Text(
              () {
                if (device.connectionType == ConnectionType.usb) {
                  final board = SerialProvider.boardDisplayNameFromAddress(device.address);
                  return board.isNotEmpty ? board : device.name;
                }
                return device.name;
              }(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(device.connectionType == ConnectionType.usb
                ? device.name  // USB는 subtitle에 원래 장치명
                : device.address),
            trailing: isConnected
                ? Chip(
                    label: Text(l10n.connectionConnectedChip),
                    avatar: const Icon(Icons.check_circle, size: 16),
                    backgroundColor: scheme.primaryContainer,
                  )
                : FilledButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      bool success = false;

                      // 블루투스 기기인 경우 프로토콜 선택 다이얼로그 표시
                      if (device.connectionType == ConnectionType.bluetooth) {
                        final selectedProtocol = await showDialog<String>(
                          context: context,
                          builder: (BuildContext context) {
                            final dl10n = AppLocalizations.of(context)!;
                            final dscheme = Theme.of(context).colorScheme;
                            return AlertDialog(
                              title: Text(dl10n.btProtocolTitle),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(dl10n.btProtocolChoose(device.name)),
                                  const SizedBox(height: 16),
                                  ListTile(
                                    leading: Icon(Icons.bluetooth, color: dscheme.primary),
                                    title: Text(dl10n.btProtocolClassic),
                                    subtitle: Text(dl10n.btProtocolClassicDesc),
                                    onTap: () => Navigator.of(context).pop('Classic'),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.bluetooth_connected, color: dscheme.secondary),
                                    title: Text(dl10n.btProtocolBle),
                                    subtitle: Text(dl10n.btProtocolBleDesc),
                                    onTap: () => Navigator.of(context).pop('BLE'),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                                ),
                              ],
                            );
                          },
                        );

                        if (selectedProtocol != null) {
                          success = await provider.connectWithProtocol(device, selectedProtocol);
                        } else {
                          return;
                        }
                      } else {
                        success = await provider.connect(device);
                      }

                      if (context.mounted) {
                        messenger.hideCurrentSnackBar();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? l10n.connectionConnectedTo(device.name)
                                  : l10n.connectionFailed,
                            ),
                            backgroundColor: success ? scheme.primary : scheme.error,
                          ),
                        );
                      }
                    },
                    child: Text(l10n.connectionConnect),
                  ),
          ),
        );
      },
    );
  }
}
