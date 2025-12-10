import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:serial_lab/providers/serial_provider.dart';

/// 터미널 화면 - 데이터 송수신
class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _dateFormat = DateFormat('HH:mm:ss');
  bool _autoScroll = true;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendData() {
    final provider = context.read<SerialProvider>();
    if (_textController.text.isNotEmpty) {
      provider.sendString(_textController.text);
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

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Text(
                    'Received: ${provider.receivedData.length} messages',
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
                  const Text('Auto-scroll'),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: () {
                      provider.clearChartData();
                    },
                    tooltip: 'Clear',
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.receivedData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No data received yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: provider.receivedData.length,
                      itemBuilder: (context, index) {
                        final data = provider.receivedData[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ExpansionTile(
                            leading: const Icon(Icons.data_object),
                            title: Text(
                              _dateFormat.format(data.timestamp),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              data.data.keys.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: data.data.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${entry.key}: ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              entry.value.toString(),
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                      decoration: const InputDecoration(
                        hintText: 'Enter data to send...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
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
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
