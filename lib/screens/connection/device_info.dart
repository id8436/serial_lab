import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/models/device_info.dart';
import 'funcs/board_helpers.dart';
import 'funcs/device_widgets.dart';

/// 연결된 기기 정보 화면
class DeviceInfoScreen extends StatelessWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                          InfoRow(
                            icon: Icons.device_hub,
                            label: '기기 이름',
                            value: provider.currentDevice!.name,
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.location_pin,
                            label: '주소',
                            value: provider.currentDevice!.address,
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.category,
                            label: '연결 타입',
                            value: _getConnectionTypeText(provider.currentDevice!.connectionType),
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.speed,
                            label: '보드레이트',
                            value: '${provider.baudRate} bps',
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.memory,
                            label: '선택된 보드',
                            value: BoardHelpers.getBoardName(provider.selectedBoard),
                          ),
                          
                          // HC-06 전용 정보 (기기별 특화)
                          if (provider.currentDevice!.name.toLowerCase().contains('hc-')) ...[
                            const SizedBox(height: 12),
                            InfoRow(
                              icon: Icons.bluetooth,
                              label: '프로토콜',
                              value: 'Classic Bluetooth SPP',
                            ),
                            const SizedBox(height: 12),
                            InfoRow(
                              icon: Icons.memory,
                              label: '버퍼링',
                              value: '50ms timeout (Arduino 호환)',
                            ),
                            const SizedBox(height: 12),
                            InfoRow(
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
                                child: StatCard(
                                  icon: Icons.data_object,
                                  label: 'JSON 데이터',
                                  subtitle: '구조화된 데이터',
                                  value: '${provider.receivedData.length}',
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCard(
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
                                '장치 설정',
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
                                        'Arduino 보드',
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
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('감지된 보드: ${BoardHelpers.getBoardName(detected)}'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } : null,
                                        icon: const Icon(Icons.auto_fix_high, size: 16),
                                        label: const Text('자동 감지'),
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
                                  DropdownButtonFormField<String>(
                                    initialValue: provider.selectedBoard,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    ),
                                    items: BoardHelpers.buildBoardMenuItems(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        provider.setBoard(value);
                                      }
                                    },
                                  ),
                                  
                                  // 최근 사용 보드
                                  if (provider.recentBoards.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      '최근 사용',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: provider.recentBoards.map((board) {
                                        final isSelected = board == provider.selectedBoard;
                                        return FilterChip(
                                          label: Text(BoardHelpers.getBoardName(board)),
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
                                    '보드레이트',
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
                                message: '기기 연결 탭에서 변경 가능',
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
