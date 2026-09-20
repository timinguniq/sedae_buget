import 'package:json_annotation/json_annotation.dart';
import 'package:sedae_budget/entity/entity.dart';

part 'auth_user_dto.g.dart';

/// 로그인·`/v1/me` 응답의 사용자.
@JsonSerializable(createToJson: false)
class AuthUserDto {
  const AuthUserDto({required this.provider, required this.nickname});

  factory AuthUserDto.fromJson(Map<String, dynamic> json) => _$AuthUserDtoFromJson(json);

  final AuthProvider provider;
  final String nickname;

  AuthUser toEntity() => AuthUser(provider: provider, nickname: nickname);
}
