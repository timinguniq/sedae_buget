import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/initial/app_status_dialog.dart';
import 'package:sedae_budget/presentation/service/dependency_provider.dart';

// 앱 이용 가능 여부(점검·업데이트). 판정 규칙은 AppStatus.of, 재료는 appStatusSourceProvider.
// 원격 값이나 빌드 번호를 못 읽으면 쓸 수 있는 것으로 본다(환경과 무관하게 항상 판정한다).

bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

/// 점검·강제 업데이트 안내 뒤 앱을 끝내는 방법. 테스트는 실제로 끝내지 않는 것으로 바꾼다.
final appExitProvider = Provider<void Function()>((_) => exitAppSoon);

/// 앱을 켤 때의 판정.
final appStatusProvider = FutureProvider<AppStatus>((ref) async {
  final source = ref.watch(appStatusSourceProvider);
  return AppStatus.of(
    await source.fetchInitialInfo(),
    build: await source.currentBuild(),
    isIOS: _isIOS,
  );
});

/// 앱을 쓰는 중에 원격 설정이 바뀌어 다시 한 판정.
final appStatusUpdatesProvider = StreamProvider<AppStatus>((ref) async* {
  final source = ref.watch(appStatusSourceProvider);
  final build = await source.currentBuild();
  await for (final info in source.initialInfoUpdates) {
    yield AppStatus.of(info, build: build, isIOS: _isIOS);
  }
});
