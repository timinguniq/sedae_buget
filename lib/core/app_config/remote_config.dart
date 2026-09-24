import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sedae_budget/core/util/logger/custom_logger.dart';
import 'package:sedae_budget/entity/entity.dart';

final _logger = CustomLogger.create(tag: 'RemoteConfig');

/// 앱 이용 가능 여부(점검·업데이트)를 판정할 재료: 원격 시작 정보와 설치된 빌드 번호.
/// 판정([AppStatus.of])과 안내 화면은 이 파일 밖에 있다.
abstract class AppStatusSource {
  /// 원격 시작 정보. 원격 설정을 쓸 수 없거나(Firebase 미초기화 등) 값이 없으면 null.
  Future<AppInitialInfo?> fetchInitialInfo();

  /// 앱을 쓰는 중에 원격 시작 정보가 바뀌면 알린다.
  Stream<AppInitialInfo> get initialInfoUpdates;

  /// 설치된 앱의 빌드 번호. 읽을 수 없으면 null.
  Future<int?> currentBuild();
}

/// Firebase Remote Config의 `initialInfo`(JSON) 값을 읽는다.
class FirebaseAppStatusSource implements AppStatusSource {
  static const _key = 'initialInfo';

  @override
  Future<AppInitialInfo?> fetchInitialInfo() async {
    try {
      final config = FirebaseRemoteConfig.instance;
      await config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 2),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await config.fetchAndActivate();
      return _parse(config.getString(_key));
    } catch (e, s) {
      _logger.w('fetchInitialInfo() : 원격 설정을 쓸 수 없음 — 판정하지 않는다. $e', stackTrace: s);
      return null;
    }
  }

  @override
  Stream<AppInitialInfo> get initialInfoUpdates {
    final FirebaseRemoteConfig config;
    try {
      config = FirebaseRemoteConfig.instance;
    } catch (e) {
      _logger.w('initialInfoUpdates : 원격 설정을 쓸 수 없음 — 갱신을 듣지 않는다. $e');
      return const Stream.empty();
    }
    return config.onConfigUpdated.asyncExpand((_) async* {
      await config.activate();
      final info = _parse(config.getString(_key));
      if (info != null) yield info;
    });
  }

  @override
  Future<int?> currentBuild() async {
    try {
      return int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
    } catch (e) {
      _logger.w('currentBuild() : 빌드 번호를 읽지 못함. $e');
      return null;
    }
  }

  AppInitialInfo? _parse(String raw) {
    if (raw.isEmpty) return null;
    try {
      return AppInitialInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, s) {
      _logger.e('_parse() : initialInfo 형식이 잘못됨: $raw', error: e, stackTrace: s);
      return null;
    }
  }
}
