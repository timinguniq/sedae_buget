import 'package:sedae_budget/core/http_client/api_exception.dart';
import 'package:sedae_budget/data/data_source/remote/user_profile_api.dart';
import 'package:sedae_budget/data/dto/user_profile_dto.dart';
import 'package:sedae_budget/data/repository_impl/api_call.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 서버에 저장되는 사용자 프로필(나이대·월소득). 아직 만들지 않았으면(404) null.
class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl(this._api);

  final UserProfileApi _api;

  @override
  Future<Result<UserProfile?>> current() async {
    try {
      return Result.success((await callApi(_api.get)).toEntity());
    } on ApiException catch (e) {
      if (e.isNotFound) return const Result.success(null);
      return Result.failure(toErrorResult(e));
    }
  }

  @override
  Future<Result<void>> save(UserProfile profile) =>
      guardApi(() => _api.put(UserProfileDto.fromEntity(profile)));

  @override
  Future<Result<void>> clear() => guardApi(_api.delete);
}
