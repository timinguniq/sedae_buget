import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';
import 'package:sedae_budget/presentation/service/dependency_provider.dart';

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  UserProfileRepository get _repo => ref.read(userProfileRepositoryProvider);

  /// 프로필은 서버 세션에 묶여 있다. 미로그인이면 요청 없이 null이고,
  /// 로그인·로그아웃으로 세션이 바뀌면 다시 읽는다.
  @override
  Future<UserProfile?> build() async {
    final user = await ref.watch(authProvider.future);
    if (user == null) return null;
    return (await _repo.current()).unwrap();
  }

  /// 저장에 실패하면 상태를 바꾸지 않고 실패를 돌려준다(입력을 잃지 않는다).
  Future<Result<void>> save(UserProfile profile) async {
    final res = await _repo.save(profile);
    if (res.failureOrNull == null) state = AsyncData(profile);
    return res;
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(UserProfileNotifier.new);
