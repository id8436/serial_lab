import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:serial_lab/l10n/app_localizations.dart';

/// 오픈소스 라이선스 화면
class OpenLicenseScreen extends StatefulWidget {
  const OpenLicenseScreen({super.key});

  @override
  State<OpenLicenseScreen> createState() => _OpenLicenseScreenState();
}

class _OpenLicenseScreenState extends State<OpenLicenseScreen> {
  late final Future<(List<LicenseEntry>, PackageInfo)> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.wait([
      LicenseRegistry.licenses.toList(),
      PackageInfo.fromPlatform(),
    ]).then((r) => (r[0] as List<LicenseEntry>, r[1] as PackageInfo));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<(List<LicenseEntry>, PackageInfo)>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(l10n.licenseLoadError(snapshot.error.toString())));
        }

        final (allLicenses, packageInfo) = snapshot.data!;

        // 패키지명으로 그룹화하여 중복 제거
        final Map<String, LicenseEntry> uniqueLicenses = {};
        for (var license in allLicenses) {
          final key = license.packages.join(', ');
          if (!uniqueLicenses.containsKey(key)) {
            uniqueLicenses[key] = license;
          }
        }

        final licenses = uniqueLicenses.values.toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.appTitle,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(l10n.appVersion(packageInfo.version)),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                          color: Theme.of(context).colorScheme.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          l10n.licenseTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.licensePackageCountDesc(licenses.length),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...licenses.map((license) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(
                    license.packages.join(', '),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  children: [
                    Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        license.paragraphs.map((p) => p.text).join('\n\n'),
                        style: const TextStyle(fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
