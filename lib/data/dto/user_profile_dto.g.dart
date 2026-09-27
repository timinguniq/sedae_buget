// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileDto _$UserProfileDtoFromJson(Map<String, dynamic> json) =>
    UserProfileDto(
      ageGroup: json['ageGroup'] as String,
      monthlyIncome: (json['monthlyIncome'] as num).toInt(),
    );

Map<String, dynamic> _$UserProfileDtoToJson(UserProfileDto instance) =>
    <String, dynamic>{
      'ageGroup': instance.ageGroup,
      'monthlyIncome': instance.monthlyIncome,
    };
