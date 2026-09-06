import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/auth_provider.dart';

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  UserProfileRepository get _repo => locator<UserProfileRepository>();

  /// 프로필은 서버 세션에 묶여 있다. 미로그인이면 요청 없이 null이고,
  /// 로그인·로그아웃으로 세션이 바뀌면 다시 읽는다.
  @override
  Future<UserProfile?> build() async {
    final user = await ref.watch(authProvider.future);
    if (user == null) return null;
    return _repo.current();
  }

  Future<void> save(UserProfile profile) async {
    await _repo.save(profile);
    state = AsyncData(profile);
  }

  Future<void> clear() async {
    await _repo.clear();
    state = const AsyncData(null);
  }
}

/// 스플래시·전역 가드가 기다리는 provider라 실패를 즉시 드러낸다(Riverpod 기본 자동 재시도 끔).
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
  retry: (_, _) => null,
);
