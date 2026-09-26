import 'package:sedae_budget/data/data_source/remote/user_profile_api.dart';
import 'package:sedae_budget/data/dto/user_profile_dto.dart';
import 'package:sedae_budget/data/repository_impl/api_call.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 서버에 저장되는 사용자 프로필(나이대·월소득). 아직 만들지 않았으면(`PROFILE_NOT_FOUND`) null.
class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl(this._api);

  final UserProfileApi _api;

  /// 다른 404(경로가 없음·주소가 틀림)는 '프로필 없음'이 아니라 실패다. 기존 사용자를 온보딩으로 보내지 않는다.
  @override
  Future<Result<UserProfile?>> current() => guardApi<UserProfile?>(
        () async => (await _api.get()).toEntity(),
        recover: (f) => f.code == 'PROFILE_NOT_FOUND' ? const Result.success(null) : null,
      );

  @override
  Future<Result<void>> save(UserProfile profile) =>
      guardApi(() => _api.put(UserProfileDto.fromEntity(profile)));
}
