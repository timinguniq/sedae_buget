import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:sedae_budget/data/data_source/remote/api_path.dart';
import 'package:sedae_budget/data/dto/auth_user_dto.dart';
import 'package:sedae_budget/data/dto/login_dto.dart';

part 'auth_api.g.dart';

/// 인증 엔드포인트(`/v1/auth/*`, `/v1/me`) 명세.
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio) = _AuthApi;

  @POST(ApiPath.login)
  Future<LoginResponseDto> login(@Body() LoginRequestDto body);

  @POST(ApiPath.logout)
  Future<void> logout();

  @GET(ApiPath.me)
  Future<AuthUserDto> me();
}
