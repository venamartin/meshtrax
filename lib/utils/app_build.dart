import 'package:package_info_plus/package_info_plus.dart';

import 'platform_info.dart';

/// The number after the + in this app's version; 0 when the platform
/// doesn't say.
Future<int> appBuild() async {
  try {
    final code = int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
    if (code == null) return 0;
    // A split APK's versionCode is the build plus 1000 times its ABI
    // (Flutter's --split-per-abi): arm64's 2252 is build 252.
    return PlatformInfo.isAndroid ? code % 1000 : code;
  } on Object catch (_) {
    return 0;
  }
}
