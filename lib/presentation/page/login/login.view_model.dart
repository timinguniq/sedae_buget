import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/service/dependency_provider.dart';

/// 로그인 세션. 값이 null이면 로그아웃 상태이고, 오류는 "세션을 확인하지 못함"(서버에 닿지 못함 등)만 뜻한다.
class AuthNotifier extends AsyncNotifier<AuthUser?> {
  AuthUsecase get _usecase => ref.read(authUsecaseProvider);

  @override
  Future<AuthUser?> build() async {
    final expired = _usecase.sessionExpired.listen((_) => _expire());
    ref.onDispose(expired.cancel);
    return (await _usecase.currentUser()).unwrap();
  }

  /// 소셜 로그인 → 서버 세션. 실패하면 로그아웃 상태로 두고 실패를 돌려준다(화면이 문구를 띄운다).
  Future<Result<AuthUser>> signIn(AuthProvider provider) async {
    state = const AsyncLoading();
    final res = await _usecase.signIn(provider);
    if (res is Success<AuthUser>) ref.read(sessionExpiredProvider.notifier).clear();
    state = AsyncData(res is Success<AuthUser> ? res.data : null);
    return res;
  }

  /// 서버 응답과 무관하게 로컬 세션은 끝난다(로그아웃은 되돌리지 않는다).
  Future<void> signOut() async {
    await _usecase.signOut();
    ref.read(sessionExpiredProvider.notifier).clear();
    state = const AsyncData(null);
  }

  /// 세션을 확인하지 못했을 때 다시 확인한다.
  void retry() => ref.invalidateSelf();

  /// 쓰는 중에 서버가 세션을 끝냈다. 로그아웃 상태로 두고 로그인 화면이 알리게 한다.
  void _expire() {
    ref.read(sessionExpiredProvider.notifier).mark();
    state = const AsyncData(null);
  }
}

/// 전역 가드가 기다리는 provider라 실패를 즉시 드러낸다(Riverpod 기본 자동 재시도 끔).
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  AuthNotifier.new,
  retry: (_, _) => null,
);

/// 세션이 만료돼 로그아웃됐는지. 로그인 화면이 안내 문구를 띄운다.
/// 다시 로그인하거나 직접 로그아웃하면 지운다.
class SessionExpiredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void mark() => state = true;
  void clear() => state = false;
}

final sessionExpiredProvider =
    NotifierProvider<SessionExpiredNotifier, bool>(SessionExpiredNotifier.new);
