import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/models/serial_data.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/widgets/confirm_dialog.dart';
import 'package:serial_lab/widgets/page_visibility.dart';

/// 터미널 화면 - 데이터 송수신.
///
/// 메시지 리스트는 `SerialProvider.dataTick` 에 맞춰 주기적으로 갱신되며,
/// [PageVisibility]가 false 일 때는 rebuild 를 건너뛴다.
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
    final provider = context.read<SerialProvider>();
    return SafeArea(
      child: Column(
        children: [
          _TopBar(
            autoScroll: _autoScroll,
            onAutoScrollChanged: (v) => setState(() => _autoScroll = v),
          ),
          Expanded(
            child: ActiveListenableBuilder(
              listenable: provider.dataTick,
              builder: (context) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                final data = provider.receivedData;
                if (data.isEmpty) return const _EmptyInbox();
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: data.length,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemBuilder: (context, index) => _MessageCard(
                    data: data[index],
                    dateFormat: _dateFormat,
                  ),
                );
              },
            ),
          ),
          _SendBar(
            controller: _textController,
            onSend: _sendData,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── 내부 위젯 ───────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.autoScroll,
    required this.onAutoScrollChanged,
  });

  final bool autoScroll;
  final ValueChanged<bool> onAutoScrollChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          // 수신 카운트만 ActiveListenableBuilder로 tick 반영 (상단바 통째로 rebuild 회피)
          _ReceivedCountLabel(),
          const Spacer(),
          Switch(value: autoScroll, onChanged: onAutoScrollChanged),
          Text(l10n.terminalAutoScroll),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _confirmClear(context),
            tooltip: l10n.tooltipClear,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<SerialProvider>();
    final ok = await showConfirmDialog(
      context: context,
      title: l10n.confirmClearTitle,
      message: l10n.confirmClearMessage,
      confirmLabel: l10n.tooltipClear,
      icon: Icons.delete_sweep,
    );
    if (!ok) return;
    provider.clearChartData();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.drawerDataCleared)),
    );
  }
}

class _ReceivedCountLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<SerialProvider>();
    return ActiveListenableBuilder(
      listenable: provider.dataTick,
      builder: (context) {
        return Text(
          l10n.terminalReceivedCount(provider.receivedData.length),
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            l10n.terminalNoData,
            style: TextStyle(fontSize: 16, color: onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.data, required this.dateFormat});
  final SerialData data;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.data_object),
        title: Text(
          dateFormat.format(data.timestamp),
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(fontFamily: 'monospace'),
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
  }
}

class _SendBar extends StatelessWidget {
  const _SendBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Selector<SerialProvider, bool>(
      selector: (_, p) => p.isConnected,
      builder: (context, isConnected, _) {
        return Container(
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
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: l10n.terminalSendHint,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  enabled: isConnected,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isConnected ? onSend : null,
                icon: const Icon(Icons.send),
                label: Text(l10n.terminalSend),
              ),
            ],
          ),
        );
      },
    );
  }
}
