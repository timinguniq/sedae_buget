import 'package:sedae_budget/entity/entity.dart';

/// 서버 응답 → [PeerStats]. `avgByCategory` 키는 categoryId 문자열("1".."12").
PeerStats peerStatsFromJson(Map<String, dynamic> json) => PeerStats(
      ageGroup: AgeGroup.values.byName(json['ageGroup'] as String),
      avgMonthlyExpense: (json['avgMonthlyExpense'] as num).toInt(),
      avgSavingsRate: (json['avgSavingsRate'] as num).toDouble(),
      avgByCategory: {
        for (final e in (json['avgByCategory'] as Map<String, dynamic>).entries)
          BudgetCategory.fromId(int.parse(e.key)): (e.value as num).toInt(),
      },
      samples: (json['samples'] as List).map((e) => (e as num).toInt()).toList(),
    );

Map<String, dynamic> peerStatsToJson(PeerStats s) => {
      'ageGroup': s.ageGroup.name,
      'avgMonthlyExpense': s.avgMonthlyExpense,
      'avgSavingsRate': s.avgSavingsRate,
      'avgByCategory': {for (final e in s.avgByCategory.entries) '${e.key.id}': e.value},
      'samples': s.samples,
    };
