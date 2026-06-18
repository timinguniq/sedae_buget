// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_wrapper.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ResponseWrapper<T> _$ResponseWrapperFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => _ResponseWrapper<T>(
  resultCode: $enumDecode(_$ResponseCodeEnumMap, json['resultCode']),
  message: json['message'] as String?,
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
);

Map<String, dynamic> _$ResponseWrapperToJson<T>(
  _ResponseWrapper<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'resultCode': _$ResponseCodeEnumMap[instance.resultCode]!,
  'message': instance.message,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
};

const _$ResponseCodeEnumMap = {
  ResponseCode.SUCCESS: 'SUCCESS',
  ResponseCode.COMMON_001: 'COMMON_001',
  ResponseCode.COMMON_002: 'COMMON_002',
  ResponseCode.COMMON_003: 'COMMON_003',
  ResponseCode.COMMON_004: 'COMMON_004',
  ResponseCode.COMMON_005: 'COMMON_005',
  ResponseCode.COMMON_006: 'COMMON_006',
  ResponseCode.COMMON_031: 'COMMON_031',
  ResponseCode.COMMON_032: 'COMMON_032',
  ResponseCode.COMMON_033: 'COMMON_033',
  ResponseCode.COMMON_041: 'COMMON_041',
  ResponseCode.COMMON_051: 'COMMON_051',
  ResponseCode.AUTH_001: 'AUTH_001',
  ResponseCode.AUTH_002: 'AUTH_002',
  ResponseCode.AUTH_003: 'AUTH_003',
  ResponseCode.AUTH_004: 'AUTH_004',
  ResponseCode.AUTH_005: 'AUTH_005',
  ResponseCode.AUTH_006: 'AUTH_006',
  ResponseCode.AUTH_007: 'AUTH_007',
  ResponseCode.AUTH_008: 'AUTH_008',
  ResponseCode.AUTH_009: 'AUTH_009',
  ResponseCode.AUTH_010: 'AUTH_010',
  ResponseCode.AUTH_011: 'AUTH_011',
  ResponseCode.AUTH_012: 'AUTH_012',
  ResponseCode.LOGIN_001: 'LOGIN_001',
  ResponseCode.USER_001: 'USER_001',
  ResponseCode.USER_002: 'USER_002',
  ResponseCode.USER_003: 'USER_003',
  ResponseCode.USER_010: 'USER_010',
  ResponseCode.POINT_001: 'POINT_001',
  ResponseCode.LANGUAGE_001: 'LANGUAGE_001',
  ResponseCode.COUNTRY_001: 'COUNTRY_001',
  ResponseCode.USERNAME_001: 'USERNAME_001',
  ResponseCode.INVALID_PARAMETER: 'INVALID_PARAMETER',
  ResponseCode.INVALID_BODY: 'INVALID_BODY',
  ResponseCode.NOT_FOUND: 'NOT_FOUND',
  ResponseCode.DATA_FETCH_ERROR: 'DATA_FETCH_ERROR',
  ResponseCode.DATA_NULL: 'DATA_NULL',
  ResponseCode.AUTH_SIGN_UP_ERROR: 'AUTH_SIGN_UP_ERROR',
  ResponseCode.AUTH_SIGN_IN_ERROR: 'AUTH_SIGN_IN_ERROR',
  ResponseCode.SIGN_IN_WITH_OTHER_SOCIAL_LOGIN:
      'SIGN_IN_WITH_OTHER_SOCIAL_LOGIN',
  ResponseCode.AUTH_SIGN_IN_APP_TO_WEB_ERROR: 'AUTH_SIGN_IN_APP_TO_WEB_ERROR',
  ResponseCode.AUTH_STORAGE_ERROR: 'AUTH_STORAGE_ERROR',
  ResponseCode.SIGN_OUT_ERROR: 'SIGN_OUT_ERROR',
  ResponseCode.AUTH_PASSWORD_REQUIRED: 'AUTH_PASSWORD_REQUIRED',
  ResponseCode.AUTH_SNS_ID_OR_TOKEN_REQUIRED: 'AUTH_SNS_ID_OR_TOKEN_REQUIRED',
  ResponseCode.AUTH_OAUTH_ERROR: 'AUTH_OAUTH_ERROR',
  ResponseCode.AUTH_OAUTH_SIGN_UP_REQUIRED_ACCOUNT:
      'AUTH_OAUTH_SIGN_UP_REQUIRED_ACCOUNT',
  ResponseCode.AUTH_ALREADY_REGISTERED_EMAIL: 'AUTH_ALREADY_REGISTERED_EMAIL',
  ResponseCode.AUTH_ALREADY_REGISTERED_SNS_ID: 'AUTH_ALREADY_REGISTERED_SNS_ID',
  ResponseCode.AUTH_NOT_REGISTERED_EMAIL: 'AUTH_NOT_REGISTERED_EMAIL',
  ResponseCode.AUTH_APP_TO_WEB_TOKEN_NOT_EXIST:
      'AUTH_APP_TO_WEB_TOKEN_NOT_EXIST',
  ResponseCode.AUTH_APP_TO_WEB_TOKEN_EXPIRED: 'AUTH_APP_TO_WEB_TOKEN_EXPIRED',
  ResponseCode.AUTH_TOKEN_INVALIDED: 'AUTH_TOKEN_INVALIDED',
  ResponseCode.AUTH_EMAIL_OR_PASSWORD_INVALIDED:
      'AUTH_EMAIL_OR_PASSWORD_INVALIDED',
  ResponseCode.VOTE_FINISHED: 'VOTE_FINISHED',
  ResponseCode.HTTP_SOCKET_EXCEPTION: 'HTTP_SOCKET_EXCEPTION',
  ResponseCode.HTTP_500_INTERNAL_SERVER_ERROR: 'HTTP_500_INTERNAL_SERVER_ERROR',
  ResponseCode.HTTP_CONNECT_TIMEOUT: 'HTTP_CONNECT_TIMEOUT',
  ResponseCode.HTTP_SEND_TIMEOUT: 'HTTP_SEND_TIMEOUT',
  ResponseCode.HTTP_RECEIVE_TIMEOUT: 'HTTP_RECEIVE_TIMEOUT',
  ResponseCode.UNDEFINED: 'UNDEFINED',
  ResponseCode.UNKNOWN: 'UNKNOWN',
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);
