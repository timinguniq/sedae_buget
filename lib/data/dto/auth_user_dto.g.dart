// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthUserDto _$AuthUserDtoFromJson(Map<String, dynamic> json) => AuthUserDto(
  provider: $enumDecode(_$AuthProviderEnumMap, json['provider']),
  nickname: json['nickname'] as String,
);

const _$AuthProviderEnumMap = {
  AuthProvider.kakao: 'kakao',
  AuthProvider.naver: 'naver',
  AuthProvider.google: 'google',
};
