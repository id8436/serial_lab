import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add WiFi Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _wifiNameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                hintText: 'Arduino WiFi',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _wifiAddressController,
              decoration: const InputDecoration(
                labelText: 'WebSocket Address',
                hintText: 'ws://192.168.1.100:8080',
                prefixIcon: Icon(Icons.wifi),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      'Connection Type',
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
                              provider.isScanning ? 'Scanning...' : 'Scan Devices',
                            ),
                          ),
                        ),
                        if (_selectedType == ConnectionType.wifi) ...[
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: _showWifiDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
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
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedBaudRate = value;
                                });
                                provider.setBaudRate(value);
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No devices found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click "Scan Devices" to search',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
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
    String title;
    String message;
    IconData icon;

    switch (type) {
      case ConnectionType.usb:
        title = 'USB 연결';
        message = '• Android에서만 지원됩니다\n• 보드레이트를 아두이노 코드와 동일하게 설정하세요.';
        icon = Icons.usb;
        break;
      case ConnectionType.bluetooth:
        title = '블루투스 연결';
        message = '• 먼저 시스템 설정에서 페어링을 완료하세요\n• 보드레이트를 아두이노 코드와 동일하게 설정하세요.';
        icon = Icons.bluetooth;
        break;
      case ConnectionType.wifi:
        title = 'WiFi 연결';
        message = '• WebSocket 주소 형식: ws://IP:PORT\n• 아두이노에서 WebSocket 서버를 실행해야 합니다';
        icon = Icons.wifi;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange, size: 20),
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
                    color: Colors.grey[700],
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
    return Consumer<SerialProvider>(
      builder: (context, provider, child) {
        final isConnected = provider.currentDevice?.id == device.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getIconColor(context).withOpacity(0.1),
              child: Icon(_getIcon(), color: _getIconColor(context)),
            ),
            title: Text(
              device.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(device.address),
            trailing: isConnected
                ? const Chip(
                    label: Text('Connected'),
                    avatar: Icon(Icons.check_circle, size: 16),
                    backgroundColor: Colors.green,
                  )
                : FilledButton(
                    onPressed: () async {
                      bool success = false;
                      
                      // 블루투스 기기인 경우 프로토콜 선택 다이얼로그 표시
                      if (device.connectionType == ConnectionType.bluetooth) {
                        final selectedProtocol = await showDialog<String>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Select Bluetooth Protocol'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Choose the protocol for ${device.name}:'),
                                  const SizedBox(height: 16),
                                  ListTile(
                                    leading: Icon(Icons.bluetooth, color: Colors.blue),
                                    title: Text('Classic Bluetooth'),
                                    subtitle: Text('For HC-05, HC-06, etc.'),
                                    onTap: () => Navigator.of(context).pop('Classic'),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.bluetooth_connected, color: Colors.indigo),
                                    title: Text('Bluetooth Low Energy (BLE)'),
                                    subtitle: Text('For modern BLE modules'),
                                    onTap: () => Navigator.of(context).pop('BLE'),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('Cancel'),
                                ),
                              ],
                            );
                          },
                        );
                        
                        if (selectedProtocol != null) {
                          success = await provider.connectWithProtocol(device, selectedProtocol);
                        }
                      } else {
                        success = await provider.connect(device);
                      }
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Connected to ${device.name}'
                                  : 'Failed to connect',
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Connect'),
                  ),
          ),
        );
      },
    );
  }
}
