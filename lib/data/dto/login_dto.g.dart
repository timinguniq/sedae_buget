// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$LoginRequestDtoToJson(LoginRequestDto instance) =>
    <String, dynamic>{
      'provider': _$AuthProviderEnumMap[instance.provider]!,
      'idToken': instance.idToken,
    };

const _$AuthProviderEnumMap = {
  AuthProvider.kakao: 'kakao',
  AuthProvider.naver: 'naver',
  AuthProvider.google: 'google',
};

LoginResponseDto _$LoginResponseDtoFromJson(Map<String, dynamic> json) =>
    LoginResponseDto(
      accessToken: json['accessToken'] as String,
      user: AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
