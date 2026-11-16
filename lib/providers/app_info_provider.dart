import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Versión instalada, p. ej. "1.0.0 (9)": versionName y versionCode de
/// pubspec.yaml (`version: 1.0.0+9`).
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return formatAppVersion(info.version, info.buildNumber);
});

String formatAppVersion(String version, String buildNumber) =>
    buildNumber.isEmpty ? version : '$version ($buildNumber)';
