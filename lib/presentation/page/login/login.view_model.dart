import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/service/dependency_provider.dart';

/// 로그인 세션. 값이 null이면 로그아웃 상태이고, 오류는 "세션을 확인하지 못함"(서버에 닿지 못함 등)만 뜻한다.
class AuthNotifier extends AsyncNotifier<AuthUser?> {
  AuthRepository get _auth => ref.read(authRepositoryProvider);

  @override
  Future<AuthUser?> build() async {
    final expired = _auth.sessionExpired.listen((_) => _expire());
    ref.onDispose(expired.cancel);
    return (await _auth.currentUser()).unwrap();
  }

  /// 소셜 로그인 → 서버 세션. 실패하면 로그아웃 상태로 두고 실패를 돌려준다(화면이 문구를 띄운다).
  Future<Result<AuthUser>> signIn(AuthProvider provider) async {
    state = const AsyncLoading();
    final res = await _auth.signIn(provider);
    if (res is Success<AuthUser>) ref.read(sessionExpiredProvider.notifier).clear();
    state = AsyncData(res is Success<AuthUser> ? res.data : null);
    return res;
  }

  /// 이 기기의 세션을 끝낸다. 서버가 응답하지 않아도 로그아웃되지만, 기기에서 토큰을 지우지 못하면
  /// 로그인 상태로 두고 실패를 돌려준다(화면이 문구를 띄운다). 그대로 로그아웃으로 보이면 다음 실행에 다시 로그인된다.
  Future<Result<void>> signOut() async {
    final res = await _auth.signOut();
    if (res.failureOrNull != null) return res;
    ref.read(sessionExpiredProvider.notifier).clear();
    state = const AsyncData(null);
    return res;
  }

  /// 세션을 확인하지 못했을 때 다시 확인한다.
  void retry() => ref.invalidateSelf();

  /// 세션이 끝났다(앱을 켤 때 확인하다가도, 쓰는 중에도). 로그아웃 상태로 두고 로그인 화면이 알리게 한다.
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
