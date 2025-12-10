import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';

/// 블루투스 시리얼 전용 화면
class BluetoothSerialScreen extends StatefulWidget {
  const BluetoothSerialScreen({super.key});

  @override
  State<BluetoothSerialScreen> createState() => _BluetoothSerialScreenState();
}

class _BluetoothSerialScreenState extends State<BluetoothSerialScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendData() {
    final provider = context.read<SerialProvider>();
    if (_textController.text.isNotEmpty && provider.isConnected) {
      // 줄바꿈 추가해서 전송 (아두이노 버퍼링에 맞춤)
      provider.sendString('${_textController.text}\n');
      _textController.clear();
    }
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SerialProvider>(
      builder: (context, provider, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 데이터 표시 영역
                Expanded(
                  child: Card(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: provider.rawTextData.length,
                      itemBuilder: (context, index) {
                        final textData = provider.rawTextData[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: SelectableText(
                            textData,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // 키보드 높이만큼 패딩 추가
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 0),
                
                // 데이터 입력 영역
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: provider.currentDevice != null 
                                ? '${provider.currentDevice!.name}로 전송할 데이터...'
                                : '기기 연결 후 데이터 입력...',
                              border: const OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _sendData(),
                            enabled: provider.isConnected,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: provider.isConnected ? _sendData : null,
                          icon: const Icon(Icons.send),
                          label: const Text('전송'),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 키보드가 올라올 때 추가 패딩
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        );
      },
    );
  }
}