import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  AuthUsecase get _usecase => locator<AuthUsecase>();

  @override
  Future<AuthUser?> build() => _usecase.currentUser();

  /// 소셜 로그인 → 서버 세션. 성공 시 사용자 상태 갱신.
  Future<void> signIn(AuthProvider provider) async {
    final user = await _usecase.signIn(provider);
    state = AsyncData(user);
  }

  Future<void> signOut() async {
    await _usecase.signOut();
    state = const AsyncData(null);
  }
}

/// 전역 가드가 기다리는 provider라 실패를 즉시 드러낸다(Riverpod 기본 자동 재시도 끔).
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  AuthNotifier.new,
  retry: (_, _) => null,
);
