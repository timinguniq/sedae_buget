import 'dart:async';

import 'package:sedae_budget/core/core.dart';
import 'package:package_info_plus/package_info_plus.dart';

final _logger = CustomLogger.create(tag: (CPackageInfo).toString());

class CPackageInfo {
  CPackageInfo._();

  static late PackageInfo _packageInfo;

  static int buildNumber = int.parse(_packageInfo.buildNumber);

  static String version = _packageInfo.version;

  static Future<Map<String, dynamic>> initialize() async {
    _logger.i('initialize() : start');
    _packageInfo = await PackageInfo.fromPlatform();

    return {
      'app_version': _packageInfo.version,
      'build_number': _packageInfo.buildNumber,
    };
  }
}
