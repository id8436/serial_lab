import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';

/// 코드 전송 화면 - 미리 정의된 코드 스니펫을 쉽게 전송
class CodeSenderScreen extends StatefulWidget {
  const CodeSenderScreen({super.key});

  @override
  State<CodeSenderScreen> createState() => _CodeSenderScreenState();
}

class _CodeSenderScreenState extends State<CodeSenderScreen> {
  final _customCodeController = TextEditingController();
  
  // 미리 정의된 명령어들
  final List<CodeSnippet> _predefinedCommands = [
    CodeSnippet(
      name: 'LED ON',
      description: 'Turn LED on',
      code: 'led_on',
      icon: Icons.lightbulb,
      color: Colors.amber,
    ),
    CodeSnippet(
      name: 'LED OFF',
      description: 'Turn LED off',
      code: 'led_off',
      icon: Icons.lightbulb_outline,
      color: Colors.grey,
    ),
    CodeSnippet(
      name: 'Reset Counter',
      description: 'Reset counter to 0',
      code: '{"command":"reset"}',
      icon: Icons.refresh,
      color: Colors.blue,
    ),
    CodeSnippet(
      name: 'Start Monitoring',
      description: 'Start data monitoring',
      code: '{"command":"start"}',
      icon: Icons.play_arrow,
      color: Colors.green,
    ),
    CodeSnippet(
      name: 'Stop Monitoring',
      description: 'Stop data monitoring',
      code: '{"command":"stop"}',
      icon: Icons.stop,
      color: Colors.red,
    ),
    CodeSnippet(
      name: 'Get Status',
      description: 'Request device status',
      code: '{"command":"status"}',
      icon: Icons.info,
      color: Colors.purple,
    ),
  ];

  @override
  void dispose() {
    _customCodeController.dispose();
    super.dispose();
  }

  void _sendCode(String code) {
    final provider = context.read<SerialProvider>();
    if (provider.isConnected) {
      provider.sendString(code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent: $code'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect to a device first'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddCommandDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Command'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Command Name',
                  hintText: 'e.g., Blink LED',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Blink LED 5 times',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  hintText: 'e.g., {"command":"blink","times":5}',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.isNotEmpty) {
                setState(() {
                  _predefinedCommands.add(
                    CodeSnippet(
                      name: nameController.text.isEmpty ? 'Custom' : nameController.text,
                      description: descController.text.isEmpty ? 'Custom command' : descController.text,
                      code: codeController.text,
                      icon: Icons.code,
                      color: Colors.teal,
                    ),
                  );
                });
                Navigator.pop(context);
              }
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
            // Connection Status Banner
            if (!provider.isConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No Device Connected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please connect to a device from the Device Connection menu',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Send Section
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flash_on,
                          color: provider.isConnected ? null : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Send',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: provider.isConnected ? null : Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        if (provider.isConnected)
                          const Chip(
                            label: Text('Ready', style: TextStyle(fontSize: 11)),
                            avatar: Icon(Icons.check_circle, size: 14),
                            backgroundColor: Colors.green,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customCodeController,
                      decoration: InputDecoration(
                        labelText: 'Custom Code',
                        hintText: provider.isConnected 
                            ? 'Enter code or JSON...' 
                            : 'Connect device first',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.code),
                      ),
                      maxLines: 3,
                      enabled: provider.isConnected,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: provider.isConnected
                          ? () {
                              if (_customCodeController.text.isNotEmpty) {
                                _sendCode(_customCodeController.text);
                                _customCodeController.clear();
                              }
                            }
                          : null,
                      icon: const Icon(Icons.send),
                      label: Text(
                        provider.isConnected ? 'Send Code' : 'Device Not Connected',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Predefined Commands Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Predefined Commands',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: provider.isConnected ? null : Colors.grey,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _showAddCommandDialog,
                    tooltip: 'Add custom command',
                  ),
                ],
              ),
            ),

            Expanded(
              child: Stack(
                children: [
                  GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _predefinedCommands.length,
                    itemBuilder: (context, index) {
                      final command = _predefinedCommands[index];
                      return CommandCard(
                        command: command,
                        onTap: () => _sendCode(command.code),
                        enabled: provider.isConnected,
                      );
                    },
                  ),
                  if (!provider.isConnected)
                    Container(
                      color: Colors.black12,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Connect a device to use commands',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
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

class CodeSnippet {
  final String name;
  final String description;
  final String code;
  final IconData icon;
  final Color color;

  CodeSnippet({
    required this.name,
    required this.description,
    required this.code,
    required this.icon,
    required this.color,
  });
}

class CommandCard extends StatelessWidget {
  final CodeSnippet command;
  final VoidCallback onTap;
  final bool enabled;

  const CommandCard({
    super.key,
    required this.command,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? [
                      command.color.withOpacity(0.1),
                      command.color.withOpacity(0.05),
                    ]
                  : [
                      Colors.grey.withOpacity(0.1),
                      Colors.grey.withOpacity(0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  command.icon,
                  size: 40,
                  color: enabled ? command.color : Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  command.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: enabled ? null : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  command.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: enabled ? Colors.grey[600] : Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
