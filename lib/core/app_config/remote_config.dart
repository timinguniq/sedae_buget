
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = CustomLogger.create(tag: (RemoteConfig).toString());

abstract class RemoteConfig {
  RemoteConfig._();

  static final _instance = FirebaseRemoteConfig.instance;

  static AppInitialInfo _initialInfo = AppInitialInfo.empty();

  static Future<void> initialize() async {
    _logger.i('initialize() : start.');
    await _instance.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 2),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    /// Set event listener
    _instance.onConfigUpdated.listen((event) async {
      _logger.i('onConfigUpdated.listen($event) : start.');
      await _instance.activate();
      await checkServiceAvailable();
    });

    await _instance.fetch();
    final isActive = await _instance.activate();
    _logger.d('initialize() : isActive=$isActive');

    await _retryFetchUntilSuccess(3, 500);

    await _loadAppInitialInfo();
  }

  static Future<bool?> checkServiceAvailable() async {
    _logger.d('checkServiceAvailable() : start.');
    if (const String.fromEnvironment('env').isNotEmpty) {
      return true;
    }

    if (!_initialInfo.serviceStatus.available) {
      await _serviceUnavailableDialog();
      return false;
    }

    final appVersion = Platform.isIOS ? _initialInfo.ios : _initialInfo.android;
    if (CPackageInfo.buildNumber < appVersion.releaseVersion) {
      await _appUpdateDialog(appVersion);
    }

    return true;
  }

  static AppEnvironment getAppEnvironment() {
    final appVersion = Platform.isIOS ? _initialInfo.ios : _initialInfo.android;
    return CPackageInfo.buildNumber > appVersion.releaseVersion ? AppEnvironment.staging : AppEnvironment.prod;
  }

  static Future<void> _retryFetchUntilSuccess(int maxAttempts, int milliseconds) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (_instance.lastFetchStatus == RemoteConfigFetchStatus.success) {
        _logger.d('Fetching remote config Success.');
        return;
      }

      await Future.delayed(Duration(milliseconds: milliseconds));
    }
    _logger.w('Fetching remote config failed. lastFetchStatus=${_instance.lastFetchStatus}');
  }

  static Future<void> _loadAppInitialInfo() async {
    try {
      _initialInfo = AppInitialInfo.fromJson(jsonDecode(_instance.getString('initialInfo')));
      _logger.d('Successfully loaded initialInfo=$_initialInfo');
    } catch (e, st) {
      _logger.e('Failed to load initialInfo=${_instance.getString('initialInfo')}', error: e, stackTrace: st);
    }
  }

  static Future<void> _appUpdateDialog(AppVersion appVersion) async {
    _logger.i('_appUpdateDialog($appVersion) : current=${CPackageInfo.version}(${CPackageInfo.buildNumber})');
    final isAvailableVersion = CPackageInfo.buildNumber >= appVersion.minimumAvailableVersion;
    final isUpdate = await showDialog<bool>(
      context: rootNavigatorKey.currentContext!,
      barrierColor: Palette.materialScrim13,
      barrierDismissible: false,
      builder: (context) {
        return CDialog(
          title: 'App update required',
          description: 'Get the latest app update for an even better experience!',
          buttons: [
            if (isAvailableVersion)
              CDialogButton(label: 'Close', result: false, color: Palette.fillGrey, labelColor: Palette.labelNeutral),
            CDialogButton(label: 'Update', result: true),
          ],
        );
      },
    );
    if (isAvailableVersion && isUpdate != true) {
      CRoute.pop();
      return;
    }

    unawaited(_moveToUpdate(appVersion.link));
    Future.delayed(const Duration(seconds: 1), () => exit(0));
  }

  static Future<void> _serviceUnavailableDialog() async {
    _logger.i('_serviceUnavailableDialog(): current=${CPackageInfo.version}(${CPackageInfo.buildNumber})');
    await showDialog<bool>(
      context: rootNavigatorKey.currentContext!,
      barrierColor: Palette.materialScrim13,
      barrierDismissible: false,
      builder: (context) => CDialog(
        title: _initialInfo.serviceStatus.noticeTitle,
        description: _initialInfo.serviceStatus.noticeContent,
        buttons: [
          CDialogButton(
            label: 'Check Back Soon',
            result: true,
            color: Palette.primaryStrong,
            labelColor: Palette.labelWhite,
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 1), () => exit(0));
  }

  static Future<bool> _moveToUpdate(String url) async {
    if (!await canLaunchUrl(
      Uri.parse(url),
    )) {
      _logger.e('Failed to launch url: $url');
      return false;
    }
    return launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }
}
