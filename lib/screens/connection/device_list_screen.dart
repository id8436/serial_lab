import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/models/device_info.dart';
import 'package:serial_lab/providers/serial_provider.dart';

/// 기기 목록 및 연결 화면
class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  ConnectionType _selectedType = ConnectionType.usb;
  final _wifiNameController = TextEditingController();
  final _wifiAddressController = TextEditingController();

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
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _wifiAddressController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.wifiDialogAddressLabel,
                hintText: l10n.wifiDialogAddressHint,
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<ConnectionType>(
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
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
                        ElevatedButton.icon(
                          onPressed: _showWifiDialog,
                          icon: const Icon(Icons.add),
                          label: Text(l10n.commonAdd),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: provider.availableDevices.isEmpty
                  ? Center(
                      child: Text(
                        l10n.deviceListEmpty,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.availableDevices.length,
                      itemBuilder: (context, index) {
                        final device = provider.availableDevices[index];
                        return DeviceListTile(device: device);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class DeviceListTile extends StatelessWidget {
  final DeviceInfo device;

  const DeviceListTile({super.key, required this.device});

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Consumer<SerialProvider>(
      builder: (context, provider, child) {
        final isConnected = provider.currentDevice?.id == device.id;

        return ListTile(
          leading: Icon(_getIcon()),
          title: Text(device.name),
          subtitle: Text(device.address),
          trailing: isConnected
              ? Chip(
                  label: Text(l10n.connectionConnectedChip),
                  backgroundColor: scheme.primaryContainer,
                )
              : ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await provider.connect(device);
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
        );
      },
    );
  }
}
