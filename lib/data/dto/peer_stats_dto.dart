import 'package:json_annotation/json_annotation.dart';
import 'package:sedae_budget/entity/entity.dart';

part 'peer_stats_dto.g.dart';

/// `/v1/peer/stats` 응답. `avgByCategory` 키는 categoryId 문자열("1".."12").
@JsonSerializable()
class PeerStatsDto {
  const PeerStatsDto({
    required this.ageGroup,
    required this.avgMonthlyExpense,
    required this.avgSavingsRate,
    required this.avgByCategory,
    required this.samples,
  });

  factory PeerStatsDto.fromJson(Map<String, dynamic> json) => _$PeerStatsDtoFromJson(json);

  factory PeerStatsDto.fromEntity(PeerStats s) => PeerStatsDto(
        ageGroup: s.ageGroup,
        avgMonthlyExpense: s.avgMonthlyExpense,
        avgSavingsRate: s.avgSavingsRate,
        avgByCategory: {for (final e in s.avgByCategory.entries) '${e.key.id}': e.value},
        samples: s.samples,
      );

  final AgeGroup ageGroup;
  final int avgMonthlyExpense;
  final double avgSavingsRate;
  final Map<String, int> avgByCategory;
  final List<int> samples;

  Map<String, dynamic> toJson() => _$PeerStatsDtoToJson(this);

  PeerStats toEntity() => PeerStats(
        ageGroup: ageGroup,
        avgMonthlyExpense: avgMonthlyExpense,
        avgSavingsRate: avgSavingsRate,
        avgByCategory: {
          for (final e in avgByCategory.entries) BudgetCategory.fromId(int.parse(e.key)): e.value,
        },
        samples: samples,
      );
}

/// `/v1/peer/generations` 응답 한 건: 나이대별 월평균 지출.
@JsonSerializable(createToJson: false)
class GenerationAverageDto {
  const GenerationAverageDto({required this.ageGroup, required this.avgMonthlyExpense});

  factory GenerationAverageDto.fromJson(Map<String, dynamic> json) =>
      _$GenerationAverageDtoFromJson(json);

  final AgeGroup ageGroup;
  final int avgMonthlyExpense;
}
