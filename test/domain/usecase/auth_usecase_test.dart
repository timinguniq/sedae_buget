import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

class _MemAuthRepo implements AuthRepository {
  AuthUser? _u;
  String? receivedIdToken;

  @override
  Future<Result<AuthUser?>> currentUser() async => Result.success(_u);

  @override
  Future<Result<AuthUser>> signIn(AuthProvider provider, String idToken) async {
    receivedIdToken = idToken;
    return Result.success(_u = AuthUser(provider: provider, nickname: '${provider.label} 사용자'));
  }

  @override
  Future<Result<void>> signOut() async {
    _u = null;
    return const Result.success(null);
  }

  @override
  Stream<void> get sessionExpired => const Stream.empty();
}

class _FixedToken implements SocialIdTokenProvider {
  @override
  Future<Result<String>> idToken(AuthProvider provider) async =>
      Result.success('t-${provider.name}');
}

/// 소셜 SDK 쪽에서 토큰을 받지 못하는 상황.
class _FailingToken implements SocialIdTokenProvider {
  @override
  Future<Result<String>> idToken(AuthProvider provider) async => const Result.failure(
        ErrorResult(reason: FailureReason.unknown, message: '소셜 로그인이 취소되었습니다.'),
      );
}

void main() {
  test('signIn fetches id_token for the provider and exchanges it', () async {
    final repo = _MemAuthRepo();
    final res = await AuthUsecase(repo, _FixedToken()).signIn(AuthProvider.kakao);
    expect(repo.receivedIdToken, 't-kakao');
    expect(res.unwrap().nickname, '카카오 사용자');
    expect((await repo.currentUser()).unwrap(), res.unwrap());
  });

  test('id_token을 못 받으면 서버를 부르지 않고 그 실패를 돌려준다', () async {
    final repo = _MemAuthRepo();
    final res = await AuthUsecase(repo, _FailingToken()).signIn(AuthProvider.kakao);
    expect(repo.receivedIdToken, isNull);
    expect(res.failureOrNull?.message, '소셜 로그인이 취소되었습니다.');
  });

  test('signOut clears', () async {
    final repo = _MemAuthRepo();
    final uc = AuthUsecase(repo, _FixedToken());
    await uc.signIn(AuthProvider.google);
    await uc.signOut();
    expect((await repo.currentUser()).unwrap(), isNull);
  });
}
