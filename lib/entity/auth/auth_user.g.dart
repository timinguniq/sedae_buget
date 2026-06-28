// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthUser _$AuthUserFromJson(Map<String, dynamic> json) => _AuthUser(
  provider: $enumDecode(_$AuthProviderEnumMap, json['provider']),
  nickname: json['nickname'] as String,
);

Map<String, dynamic> _$AuthUserToJson(_AuthUser instance) => <String, dynamic>{
  'provider': _$AuthProviderEnumMap[instance.provider]!,
  'nickname': instance.nickname,
};

const _$AuthProviderEnumMap = {
  AuthProvider.kakao: 'kakao',
  AuthProvider.naver: 'naver',
  AuthProvider.google: 'google',
};
