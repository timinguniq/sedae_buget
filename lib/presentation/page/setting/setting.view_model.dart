import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 설치된 앱의 버전. 읽지 못하면 null(설정 화면은 '...'으로 둔다).
final appVersionProvider = FutureProvider<String?>((_) => readAppVersion(PackageInfo.fromPlatform));

/// [load]로 읽은 앱 버전. 비었거나 읽지 못하면 null.
/// 오류를 던지지 않는다 — provider가 실패하면 Riverpod가 자동으로 다시 시도한다.
Future<String?> readAppVersion(Future<PackageInfo> Function() load) async {
  try {
    final version = (await load()).version;
    return version.isEmpty ? null : version;
  } catch (_) {
    return null;
  }
}
