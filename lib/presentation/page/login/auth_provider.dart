import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  AuthUsecase get _usecase => locator<AuthUsecase>();

  @override
  Future<AuthUser?> build() => _usecase.currentUser();

  /// 백엔드 없음 → 목업 로그인: 제공자별 가짜 닉네임으로 로컬 저장.
  Future<void> signInMock(AuthProvider provider) async {
    final user = await _usecase.signInMock(provider);
    state = AsyncData(user);
  }

  Future<void> signOut() async {
    await _usecase.signOut();
    state = const AsyncData(null);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUser?>(AuthNotifier.new);
