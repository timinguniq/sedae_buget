// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  ageGroup: $enumDecode(_$AgeGroupEnumMap, json['ageGroup']),
  monthlyIncome: (json['monthlyIncome'] as num).toInt(),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
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
