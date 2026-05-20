import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:serial_lab/l10n/app_localizations.dart';

/// 홈 대시보드 화면
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Future<_DeviceSpecsSnapshot> _specsFuture;

  @override
  void initState() {
    super.initState();
    _specsFuture = _loadDeviceSpecs();
  }

  Future<_DeviceSpecsSnapshot> _loadDeviceSpecs() async {
    final plugin = DeviceInfoPlugin();
    final baseInfo = await plugin.deviceInfo;
    final data = baseInfo.data;
    final profile = _RecommendedSpecProfile.forCurrentPlatform();

    final cpuCores = kIsWeb
        ? (_readNestedInt(data, ['hardwareConcurrency']) ?? 4)
        : Platform.numberOfProcessors;
    var memoryMb = _extractMemoryMb(baseInfo, data);
    memoryMb ??= await _readSystemMemoryMbFallback();
    final osCheck = _evaluateOsCheck(profile, data);
    final platformLabel = kIsWeb
        ? (_asString(data['browserName']) ?? 'web')
        : Platform.operatingSystem;
    final osLabel = kIsWeb
        ? (_asString(data['appVersion']) ?? _asString(data['userAgent']) ?? 'Web runtime')
        : Platform.operatingSystemVersion;

    return _DeviceSpecsSnapshot(
      deviceLabel: _extractDeviceLabel(data),
      platformLabel: platformLabel,
      osLabel: osLabel,
      cpuCores: cpuCores,
      memoryMb: memoryMb,
      profile: profile,
      osCheck: osCheck,
    );
  }

  String _extractDeviceLabel(Map<String, dynamic> data) {
    final manufacturer = _asString(data['manufacturer']);
    final model = _asString(data['model']) ?? _asString(data['name']) ?? _asString(data['computerName']);
    if (manufacturer != null && model != null) {
      return '$manufacturer $model';
    }
    return model ?? _asString(data['hostName']) ?? _asString(data['machineId']) ?? 'Unknown device';
  }

  int? _extractMemoryMb(BaseDeviceInfo baseInfo, Map<String, dynamic> data) {
    if (kIsWeb) {
      final deviceMemoryGb = _asNum(data['deviceMemory']);
      if (deviceMemoryGb != null && deviceMemoryGb > 0) {
        return (deviceMemoryGb * 1024).round();
      }
    }

    if (baseInfo is AndroidDeviceInfo) {
      if (baseInfo.physicalRamSize > 0) {
        return baseInfo.physicalRamSize;
      }
    }

    const candidateKeys = [
      'systemMemoryInMegabytes',
      'physicalRamSize',
      'totalRamSize',
      'totalMem',
      'totalMemKb',
      'totalMemMb',
      'memorySize',
      'physicalMemory',
      'totalPhysicalMemory',
      'totalMemory',
      'ramSize',
      'availableRamSize',
    ];

    for (final key in candidateKeys) {
      final parsed = _asNum(data[key]);
      if (parsed != null) return _normalizeMemoryToMb(parsed);
    }

    final versionMap = data['version'];
    if (versionMap is Map) {
      for (final key in candidateKeys) {
        final parsed = _asNum(versionMap[key]);
        if (parsed != null) return _normalizeMemoryToMb(parsed);
      }
    }

    return null;
  }

  int _normalizeMemoryToMb(num value) {
    if (value <= 0) return 0;

    // bytes (e.g., 8589934592)
    if (value >= 1024 * 1024 * 1024) {
      return (value / (1024 * 1024)).round();
    }
    // kB (e.g., 8388608)
    if (value >= 1024 * 64) {
      return (value / 1024).round();
    }
    // MB (e.g., 4096)
    if (value >= 1024) {
      return value.round();
    }
    // GB-like small values (e.g., 4, 6, 8)
    return (value * 1024).round();
  }

  Future<int?> _readSystemMemoryMbFallback() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      return null;
    }

    try {
      if (Platform.isLinux) {
        final memInfo = await File('/proc/meminfo').readAsString();
        final match = RegExp(r'^MemTotal:\s+(\d+)\s+kB', multiLine: true)
            .firstMatch(memInfo);
        if (match != null) {
          final kb = int.tryParse(match.group(1)!);
          if (kb != null && kb > 0) return (kb / 1024).round();
        }
      }

      if (Platform.isMacOS) {
        final out = await _runCommandStdout('sysctl', ['-n', 'hw.memsize']);
        final bytes = num.tryParse(out ?? '');
        if (bytes != null && bytes > 0) return _normalizeMemoryToMb(bytes);
      }

      if (Platform.isWindows) {
        final out = await _runCommandStdout(
          'powershell',
          ['-NoProfile', '-Command', '(Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize'],
        );
        final kb = num.tryParse((out ?? '').trim());
        if (kb != null && kb > 0) return _normalizeMemoryToMb(kb);
      }
    } catch (_) {
      // Ignore fallback failures and keep unknown state.
    }

    return null;
  }

  Future<String?> _runCommandStdout(String executable, List<String> args) async {
    final result = await Process.run(executable, args).timeout(const Duration(seconds: 2));
    if (result.exitCode != 0) return null;
    final value = result.stdout?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  _OsCheck _evaluateOsCheck(_RecommendedSpecProfile profile, Map<String, dynamic> data) {
    if (kIsWeb) {
      final browser = _asString(data['browserName']);
      return _OsCheck(
        recommended: profile.osRequirement,
        current: browser == null ? null : 'Browser: $browser',
        status: _SpecCheckStatus.good,
      );
    }

    if (Platform.isAndroid) {
      final sdk = _readNestedInt(data, ['version', 'sdkInt']) ?? _readNestedInt(data, ['sdkInt']);
      final release = _readNestedString(data, ['version', 'release']) ?? _asString(data['version.release']);
      final status = sdk == null
          ? _SpecCheckStatus.unknown
          : (sdk >= profile.minAndroidSdk ? _SpecCheckStatus.good : _SpecCheckStatus.warning);
      return _OsCheck(
        recommended: profile.osRequirement,
        current: sdk == null
            ? (release == null ? null : 'Android $release')
            : (release == null ? 'Android SDK $sdk' : 'Android $release (SDK $sdk)'),
        status: status,
      );
    }

    if (Platform.isWindows) {
      final major = _readNestedInt(data, ['majorVersion']);
      final status = major == null
          ? _SpecCheckStatus.unknown
          : (major >= profile.minOsMajor ? _SpecCheckStatus.good : _SpecCheckStatus.warning);
      return _OsCheck(
        recommended: profile.osRequirement,
        current: major == null ? null : 'Windows $major',
        status: status,
      );
    }

    if (Platform.isMacOS) {
      final osRelease = _asString(data['osRelease']);
      final major = _firstVersionMajor(osRelease ?? Platform.operatingSystemVersion);
      final status = major == null
          ? _SpecCheckStatus.unknown
          : (major >= profile.minOsMajor ? _SpecCheckStatus.good : _SpecCheckStatus.warning);
      return _OsCheck(
        recommended: profile.osRequirement,
        current: osRelease,
        status: status,
      );
    }

    if (Platform.isLinux) {
      final prettyName = _asString(data['prettyName']) ?? _asString(data['name']);
      final version = _asString(data['versionId']) ?? _asString(data['version']);
      final major = _firstVersionMajor(version ?? prettyName ?? Platform.operatingSystemVersion);
      final status = major == null
          ? _SpecCheckStatus.unknown
          : (major >= profile.minOsMajor ? _SpecCheckStatus.good : _SpecCheckStatus.warning);
      return _OsCheck(
        recommended: profile.osRequirement,
        current: prettyName == null
            ? version
            : (version == null ? prettyName : '$prettyName $version'),
        status: status,
      );
    }

    if (Platform.isIOS) {
      final systemVersion = _asString(data['systemVersion']);
      final major = _firstVersionMajor(systemVersion);
      final status = major == null
          ? _SpecCheckStatus.unknown
          : (major >= profile.minOsMajor ? _SpecCheckStatus.good : _SpecCheckStatus.warning);
      return _OsCheck(
        recommended: profile.osRequirement,
        current: systemVersion,
        status: status,
      );
    }

    return _OsCheck(
      recommended: profile.osRequirement,
      current: null,
      status: _SpecCheckStatus.unknown,
    );
  }

  int? _readNestedInt(Map<String, dynamic> data, List<String> path) {
    final value = _readNestedValue(data, path);
    return _asNum(value)?.toInt();
  }

  String? _readNestedString(Map<String, dynamic> data, List<String> path) {
    final value = _readNestedValue(data, path);
    return _asString(value);
  }

  dynamic _readNestedValue(Map<String, dynamic> data, List<String> path) {
    dynamic cursor = data;
    for (final key in path) {
      if (cursor is! Map) return null;
      final map = cursor;
      cursor = map[key];
      if (cursor == null) {
        // 일부 런타임에서는 키 타입이 String이 아닐 수 있으므로 문자열 비교 fallback
        for (final entry in map.entries) {
          if (entry.key.toString() == key) {
            cursor = entry.value;
            break;
          }
        }
      }
    }
    return cursor;
  }

  int? _firstVersionMajor(String? value) {
    if (value == null) return null;
    final match = RegExp(r'(\d+)').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  String? _asString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  num? _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      final normalized = value.trim().replaceAll(',', '');
      if (normalized.isEmpty) return null;
      return num.tryParse(normalized);
    }
    return null;
  }

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
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

          // iOS 안내 카드 (iOS에서만 표시)
          if (!kIsWeb && Platform.isIOS) ...[
            _buildIosNoticeCard(context, l10n),
            const SizedBox(height: 24),
          ],

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
            Theme.of(context).colorScheme.primary,
          ),
          _buildGuideStep(
            context,
            '2',
            l10n.dashboardStep2Title,
            l10n.dashboardStep2Desc,
            Icons.cloud_download,
            Theme.of(context).colorScheme.tertiary,
          ),
          _buildGuideStep(
            context,
            '3',
            l10n.dashboardStep3Title,
            l10n.dashboardStep3Desc,
            Icons.analytics,
            Theme.of(context).colorScheme.secondary,
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
          const SizedBox(height: 24),

          // 권장 사양 비교
          Text(
            l10n.dashboardSpecComparisonTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.dashboardSpecComparisonSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<_DeviceSpecsSnapshot>(
            future: _specsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n.dashboardSpecLoading),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      l10n.dashboardSpecFailed,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                );
              }

              return _buildSpecComparisonCard(context, l10n, snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecComparisonCard(
    BuildContext context,
    AppLocalizations l10n,
    _DeviceSpecsSnapshot specs,
  ) {
    final rows = <_SpecRowData>[
      _SpecRowData(
        title: l10n.dashboardSpecItemOs,
        recommended: specs.osCheck.recommended,
        current: specs.osCheck.current ?? l10n.dashboardSpecUnknownValue,
        reason: l10n.dashboardSpecReasonOs,
        status: specs.osCheck.status,
      ),
      _SpecRowData(
        title: l10n.dashboardSpecItemCpu,
        recommended: '${specs.profile.minCpuCores}+ cores',
        current: '${specs.cpuCores} cores',
        reason: l10n.dashboardSpecReasonCpu,
        status: specs.cpuCores >= specs.profile.minCpuCores
            ? _SpecCheckStatus.good
            : _SpecCheckStatus.warning,
      ),
      _SpecRowData(
        title: l10n.dashboardSpecItemMemory,
        recommended: '${specs.profile.minRamGb} GB+',
        current: specs.memoryMb == null
            ? l10n.dashboardSpecUnknownValue
            : '${(specs.memoryMb! / 1024).toStringAsFixed(1)} GB',
        reason: l10n.dashboardSpecReasonMemory,
        status: specs.memoryMb == null
            ? _SpecCheckStatus.unknown
            : (specs.memoryMb! >= specs.profile.minRamGb * 1024
                ? _SpecCheckStatus.good
                : _SpecCheckStatus.warning),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.dashboardSpecCurrentDevice,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('${specs.deviceLabel} · ${specs.platformLabel}'),
            const SizedBox(height: 2),
            Text(
              specs.osLabel,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.dashboardSpecRecommended,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            for (final row in rows) ...[
              _buildSpecRow(context, l10n, row),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.usb,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.dashboardSpecReasonConnection}\n${l10n.dashboardSpecConnectionTip}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(BuildContext context, AppLocalizations l10n, _SpecRowData row) {
    final scheme = Theme.of(context).colorScheme;
    Color badgeColor;
    String badgeText;

    switch (row.status) {
      case _SpecCheckStatus.good:
        badgeColor = scheme.primary;
        badgeText = l10n.dashboardSpecStatusGood;
        break;
      case _SpecCheckStatus.warning:
        badgeColor = scheme.tertiary;
        badgeText = l10n.dashboardSpecStatusNeedAttention;
        break;
      case _SpecCheckStatus.unknown:
        badgeColor = scheme.onSurfaceVariant;
        badgeText = l10n.dashboardSpecStatusUnknown;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${l10n.dashboardSpecRecommended}: ${row.recommended}'),
          Text('${l10n.dashboardSpecCurrentDevice}: ${row.current}'),
          const SizedBox(height: 4),
          Text(
            row.reason,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(text),
          ],
        ),
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildIosNoticeCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_iphone, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.dashboardIosNoticeTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.check_circle, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(l10n.dashboardSupported, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        l10n.dashboardIosAvailable,
                        style: const TextStyle(fontSize: 12, height: 1.7),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.cancel, size: 14, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 4),
                        Text(l10n.dashboardUnsupported, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        l10n.dashboardIosUnavailable,
                        style: const TextStyle(fontSize: 12, height: 1.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceSpecsSnapshot {
  final String deviceLabel;
  final String platformLabel;
  final String osLabel;
  final int cpuCores;
  final int? memoryMb;
  final _RecommendedSpecProfile profile;
  final _OsCheck osCheck;

  const _DeviceSpecsSnapshot({
    required this.deviceLabel,
    required this.platformLabel,
    required this.osLabel,
    required this.cpuCores,
    required this.memoryMb,
    required this.profile,
    required this.osCheck,
  });
}

class _RecommendedSpecProfile {
  final int minRamGb;
  final int minCpuCores;
  final int minOsMajor;
  final int minAndroidSdk;
  final String osRequirement;

  const _RecommendedSpecProfile({
    required this.minRamGb,
    required this.minCpuCores,
    required this.minOsMajor,
    required this.minAndroidSdk,
    required this.osRequirement,
  });

  factory _RecommendedSpecProfile.forCurrentPlatform() {
    if (kIsWeb) {
      return const _RecommendedSpecProfile(
        minRamGb: 4,
        minCpuCores: 2,
        minOsMajor: 0,
        minAndroidSdk: 30,
        osRequirement: 'Latest Chrome / Edge / Safari',
      );
    }

    if (Platform.isAndroid) {
      return const _RecommendedSpecProfile(
        minRamGb: 6,
        minCpuCores: 4,
        minOsMajor: 11,
        minAndroidSdk: 30,
        osRequirement: 'Android 11+',
      );
    }
    if (Platform.isWindows) {
      return const _RecommendedSpecProfile(
        minRamGb: 8,
        minCpuCores: 4,
        minOsMajor: 10,
        minAndroidSdk: 30,
        osRequirement: 'Windows 10+',
      );
    }
    if (Platform.isMacOS) {
      return const _RecommendedSpecProfile(
        minRamGb: 8,
        minCpuCores: 4,
        minOsMajor: 12,
        minAndroidSdk: 30,
        osRequirement: 'macOS 12+',
      );
    }
    if (Platform.isIOS) {
      return const _RecommendedSpecProfile(
        minRamGb: 4,
        minCpuCores: 4,
        minOsMajor: 15,
        minAndroidSdk: 30,
        osRequirement: 'iOS 15+',
      );
    }
    if (Platform.isLinux) {
      return const _RecommendedSpecProfile(
        minRamGb: 8,
        minCpuCores: 4,
        minOsMajor: 22,
        minAndroidSdk: 30,
        osRequirement: 'Linux (Ubuntu 22.04+ equivalent)',
      );
    }
    return const _RecommendedSpecProfile(
      minRamGb: 8,
      minCpuCores: 4,
      minOsMajor: 0,
      minAndroidSdk: 30,
      osRequirement: 'Recent LTS release',
    );
  }
}

class _SpecRowData {
  final String title;
  final String recommended;
  final String current;
  final String reason;
  final _SpecCheckStatus status;

  const _SpecRowData({
    required this.title,
    required this.recommended,
    required this.current,
    required this.reason,
    required this.status,
  });
}

class _OsCheck {
  final String recommended;
  final String? current;
  final _SpecCheckStatus status;

  const _OsCheck({
    required this.recommended,
    required this.current,
    required this.status,
  });
}

enum _SpecCheckStatus {
  good,
  warning,
  unknown,
}
