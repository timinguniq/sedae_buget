// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileDto _$UserProfileDtoFromJson(Map<String, dynamic> json) =>
    UserProfileDto(
      ageGroup: $enumDecode(_$AgeGroupEnumMap, json['ageGroup']),
      monthlyIncome: (json['monthlyIncome'] as num).toInt(),
    );

Map<String, dynamic> _$UserProfileDtoToJson(UserProfileDto instance) =>
    <String, dynamic>{
      'ageGroup': _$AgeGroupEnumMap[instance.ageGroup]!,
      'monthlyIncome': instance.monthlyIncome,
    };

const _$AgeGroupEnumMap = {
  AgeGroup.teens: 'teens',
  AgeGroup.twenties: 'twenties',
  AgeGroup.thirties: 'thirties',
  AgeGroup.forties: 'forties',
  AgeGroup.fiftiesPlus: 'fiftiesPlus',
};
