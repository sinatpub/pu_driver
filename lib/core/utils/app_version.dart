import 'package:package_info_plus/package_info_plus.dart';
import 'package:pu_taxi_driver/core/utils/pretty_logger.dart';

/// Audit D-11 — the installed app's version, read from the build once at
/// startup.
///
/// It was `HomeLogic.currentVersionIos` / `currentVersionAndroid`, both
/// "1.1.9" by hand: every release had to remember to change them, the update
/// check compared the server's version against that constant rather than
/// against what was installed, and Contact Us showed it.
class AppVersion {
  AppVersion._();

  /// `pubspec.yaml`'s version name ("1.1.9"). Empty until [load] has run,
  /// which is the case in tests.
  static String current = '';

  static Future<void> load({Future<String> Function()? read}) async {
    try {
      current = await (read ?? _fromPlatform)();
    } catch (e) {
      tlog('Could not read the app version: $e');
    }
  }

  static Future<String> _fromPlatform() async =>
      (await PackageInfo.fromPlatform()).version;
}

/// Whether [server] is a newer version than [installed]: "1.2.0" over
/// "1.1.9", "1.10.0" over "1.9.9". A build number ("+1191") is ignored. When
/// either one is missing or is not a dotted number, no.
///
/// The update check used to prompt whenever the two differed, so a build
/// newer than the server's (a tester's) was told to "update" to an older one.
bool isNewerVersion(String? server, {required String installed}) {
  final List<int>? s = _versionParts(server);
  final List<int>? i = _versionParts(installed);
  if (s == null || i == null) return false;
  final int length = s.length > i.length ? s.length : i.length;
  for (int k = 0; k < length; k++) {
    final int a = k < s.length ? s[k] : 0;
    final int b = k < i.length ? i[k] : 0;
    if (a != b) return a > b;
  }
  return false;
}

List<int>? _versionParts(String? version) {
  final String core = (version ?? '').trim().split('+').first;
  if (core.isEmpty) return null;
  final List<int> parts = <int>[];
  for (final String part in core.split('.')) {
    final int? n = int.tryParse(part);
    if (n == null) return null;
    parts.add(n);
  }
  return parts;
}
