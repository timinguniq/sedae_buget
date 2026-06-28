import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sedae_budget/entity/budget/age_group.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required AgeGroup ageGroup,
    required int monthlyIncome, // 원 단위 정수
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
