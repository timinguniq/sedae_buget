// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'peer_stats_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeerStatsDto _$PeerStatsDtoFromJson(Map<String, dynamic> json) => PeerStatsDto(
  ageGroup: json['ageGroup'] as String,
  avgMonthlyExpense: (json['avgMonthlyExpense'] as num).toInt(),
  avgSavingsRate: (json['avgSavingsRate'] as num).toDouble(),
  avgByCategory: Map<String, int>.from(json['avgByCategory'] as Map),
  samples: (json['samples'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$PeerStatsDtoToJson(PeerStatsDto instance) =>
    <String, dynamic>{
      'ageGroup': instance.ageGroup,
      'avgMonthlyExpense': instance.avgMonthlyExpense,
      'avgSavingsRate': instance.avgSavingsRate,
      'avgByCategory': instance.avgByCategory,
      'samples': instance.samples,
    };

GenerationAverageDto _$GenerationAverageDtoFromJson(
  Map<String, dynamic> json,
) => GenerationAverageDto(
  ageGroup: json['ageGroup'] as String,
  avgMonthlyExpense: (json['avgMonthlyExpense'] as num).toInt(),
);
