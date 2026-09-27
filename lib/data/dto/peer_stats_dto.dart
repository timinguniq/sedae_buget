import 'package:json_annotation/json_annotation.dart';
import 'package:sedae_budget/data/dto/age_group_wire.dart';
import 'package:sedae_budget/entity/entity.dart';

part 'peer_stats_dto.g.dart';

/// `/v1/peer/stats` 응답. `avgByCategory` 키는 categoryId 문자열("1".."19").
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
        ageGroup: s.ageGroup.wire,
        avgMonthlyExpense: s.avgMonthlyExpense,
        avgSavingsRate: s.avgSavingsRate,
        avgByCategory: {for (final e in s.avgByCategory.entries) '${e.key.id}': e.value},
        samples: s.samples,
      );

  /// API 값 그대로. 앱은 요청한 나이대로 읽는다([toEntity]).
  final String ageGroup;
  final int avgMonthlyExpense;
  final double avgSavingsRate;
  final Map<String, int> avgByCategory;
  final List<int> samples;

  Map<String, dynamic> toJson() => _$PeerStatsDtoToJson(this);

  /// [requested] 나이대로 요청한 응답을 읽는다(응답의 나이대 값은 보지 않는다).
  /// 모르는 분류 키는 버린다(그 분류만 또래 값 없음이 된다).
  PeerStats toEntity(AgeGroup requested) => PeerStats(
        ageGroup: requested,
        avgMonthlyExpense: avgMonthlyExpense,
        avgSavingsRate: avgSavingsRate,
        avgByCategory: {
          for (final e in avgByCategory.entries) ?BudgetCategory.tryFromId(int.tryParse(e.key) ?? 0): e.value,
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

  /// API 값 그대로.
  final String ageGroup;
  final int avgMonthlyExpense;

  /// 이 행의 나이대. 모르는 나이대면 null(그 행은 버린다).
  AgeGroup? get group => ageGroupFromWire(ageGroup);
}
