import 'package:json_annotation/json_annotation.dart';
import 'package:sedae_budget/data/dto/auth_user_dto.dart';
import 'package:sedae_budget/entity/entity.dart';

part 'login_dto.g.dart';

/// `POST /v1/auth/login` 바디.
@JsonSerializable(createFactory: false)
class LoginRequestDto {
  const LoginRequestDto({required this.provider, required this.idToken});

  final AuthProvider provider;
  final String idToken;

  Map<String, dynamic> toJson() => _$LoginRequestDtoToJson(this);
}

/// 로그인 응답: 액세스 토큰과 사용자.
@JsonSerializable(createToJson: false)
class LoginResponseDto {
  const LoginResponseDto({required this.accessToken, required this.user});

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseDtoFromJson(json);

  final String accessToken;
  final AuthUserDto user;
}
