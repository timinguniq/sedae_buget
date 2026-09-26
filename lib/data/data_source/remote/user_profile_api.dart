import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:sedae_budget/data/data_source/remote/api_path.dart';
import 'package:sedae_budget/data/dto/user_profile_dto.dart';

part 'user_profile_api.g.dart';

/// 프로필 엔드포인트(`/v1/me/profile`) 명세. 프로필이 없으면 404.
@RestApi()
abstract class UserProfileApi {
  factory UserProfileApi(Dio dio) = _UserProfileApi;

  @GET(ApiPath.profile)
  Future<UserProfileDto> get();

  @PUT(ApiPath.profile)
  Future<void> put(@Body() UserProfileDto body);
}
