import 'package:flutter/material.dart';
import 'package:serial_lab/l10n/app_localizations.dart';

/// 홈 대시보드 화면
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.developer_board,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.dashboardWelcome,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.dashboardSubtitle,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Guide
          Text(
            l10n.dashboardGettingStarted,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildGuideStep(
            context,
            '1',
            l10n.dashboardStep1Title,
            l10n.dashboardStep1Desc,
            Icons.devices,
            Colors.blue,
          ),
          _buildGuideStep(
            context,
            '2',
            l10n.dashboardStep2Title,
            l10n.dashboardStep2Desc,
            Icons.cloud_download,
            Colors.green,
          ),
          _buildGuideStep(
            context,
            '3',
            l10n.dashboardStep3Title,
            l10n.dashboardStep3Desc,
            Icons.analytics,
            Colors.purple,
          ),
          const SizedBox(height: 24),

          // 앱 소개
          Text(
            l10n.dashboardIntro,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.dashboardIntroText,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 주요 기능
          Text(
            l10n.dashboardMainFeatures,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem(Icons.usb, l10n.dashboardUsbSerial),
                  _buildFeatureItem(Icons.bluetooth, l10n.dashboardBluetooth),
                  _buildFeatureItem(Icons.wifi, l10n.dashboardWifi),
                  _buildFeatureItem(Icons.show_chart, l10n.dashboardRealtimeViz),
                  _buildFeatureItem(Icons.terminal, l10n.dashboardSerialMonitor),
                  _buildFeatureItem(Icons.analytics, l10n.dashboardDataAnalysis),
                  _buildFeatureItem(Icons.code, l10n.dashboardCodeSnippet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildGuideStep(
    BuildContext context,
    String step,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  step,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: color),
          ],
        ),
      ),
    );
  }
}
