import 'package:sedae_budget/core/http_client/api_client.dart';
import 'package:sedae_budget/core/http_client/api_exception.dart';
import 'package:sedae_budget/data/remote/api_path.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 서버에 저장되는 사용자 프로필(나이대·월소득). 없으면(404) null.
class ApiUserProfileRepository implements UserProfileRepository {
  ApiUserProfileRepository(this._api);

  final ApiClient _api;

  @override
  Future<UserProfile?> current() async {
    try {
      return UserProfile.fromJson(await _api.get<Map<String, dynamic>>(ApiPath.profile));
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<void> save(UserProfile profile) =>
      _api.put<Map<String, dynamic>>(ApiPath.profile, body: profile.toJson());

  @override
  Future<void> clear() => _api.delete(ApiPath.profile);
}
