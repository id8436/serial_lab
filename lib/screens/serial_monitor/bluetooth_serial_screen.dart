import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Consumer<SerialProvider>(
      builder: (context, provider, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return SafeArea(
          child: Column(
            children: [
              // 상단 정보 바
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Text(
                      l10n.terminalReceivedCount(provider.rawTextData.length),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Switch(
                      value: _autoScroll,
                      onChanged: (value) {
                        setState(() {
                          _autoScroll = value;
                        });
                      },
                    ),
                    Text(l10n.terminalAutoScroll),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      onPressed: () {
                        provider.clearChartData();
                      },
                      tooltip: l10n.tooltipClear,
                    ),
                  ],
                ),
              ),
              
              // 데이터 표시 영역
              Expanded(
                child: provider.rawTextData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.terminalNoData,
                              style: TextStyle(
                                fontSize: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: provider.rawTextData.length,
                        itemBuilder: (context, index) {
                          final textData = provider.rawTextData[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SelectableText(
                                textData,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              
              // 데이터 입력 영역
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: l10n.terminalSendHint,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        enabled: provider.isConnected,
                        onSubmitted: (_) => _sendData(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: provider.isConnected ? _sendData : null,
                      icon: const Icon(Icons.send),
                      label: Text(l10n.terminalSend),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}