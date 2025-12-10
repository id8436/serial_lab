import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/models/device_info.dart';

/// 연결된 기기 정보 화면
class DeviceInfoScreen extends StatelessWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SerialProvider>(
      builder: (context, provider, child) {
        return SafeArea(
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
                              color: provider.isConnected ? Colors.green : Colors.red,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              provider.isConnected ? '연결됨' : '연결 안됨',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: provider.isConnected ? Colors.green : Colors.red,
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
                          _InfoRow(
                            icon: Icons.device_hub,
                            label: '기기 이름',
                            value: provider.currentDevice!.name,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.location_pin,
                            label: '주소',
                            value: provider.currentDevice!.address ?? 'Unknown',
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.category,
                            label: '연결 타입',
                            value: _getConnectionTypeText(provider.currentDevice!.connectionType),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.speed,
                            label: '보드레이트',
                            value: '${provider.baudRate} bps',
                          ),
                          
                          // HC-06 전용 정보 (기기별 특화)
                          if (provider.currentDevice!.name.toLowerCase().contains('hc-')) ...[
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.bluetooth,
                              label: '프로토콜',
                              value: 'Classic Bluetooth SPP',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.memory,
                              label: '버퍼링',
                              value: '50ms timeout (Arduino 호환)',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.settings_input_antenna,
                              label: '데이터 형식',
                              value: 'Arduino BTSerial 텍스트',
                            ),
                          ],
                          
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          // 통계 정보 (차이점 명시)
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.data_object,
                                  label: 'JSON 데이터',
                                  subtitle: '구조화된 데이터',
                                  value: '${provider.receivedData.length}',
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.text_fields,
                                  label: '텍스트 데이터',
                                  subtitle: '원본 데이터',
                                  value: '${provider.rawTextData.length}',
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // 연결 해제 버튼
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => provider.disconnect(),
                              icon: const Icon(Icons.close),
                              label: const Text('연결 해제'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 20),
                          Text(
                            '기기 연결 탭에서 기기를 연결해주세요.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _getConnectionTypeText(ConnectionType type) {
    switch (type) {
      case ConnectionType.bluetooth:
        return 'Bluetooth';
      case ConnectionType.usb:
        return 'USB Serial';
      case ConnectionType.wifi:
        return 'WiFi';
      default:
        return 'Unknown';
    }
  }
}

/// 정보 행 위젯
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// 통계 카드 위젯 (subtitle 추가)
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
