import 'package:json_annotation/json_annotation.dart';
import 'package:sedae_budget/entity/entity.dart';

part 'user_profile_dto.g.dart';

/// `/v1/me/profile` 요청·응답.
@JsonSerializable()
class UserProfileDto {
  const UserProfileDto({required this.ageGroup, required this.monthlyIncome});

  factory UserProfileDto.fromJson(Map<String, dynamic> json) => _$UserProfileDtoFromJson(json);

  factory UserProfileDto.fromEntity(UserProfile p) =>
      UserProfileDto(ageGroup: p.ageGroup, monthlyIncome: p.monthlyIncome);

  final AgeGroup ageGroup;
  final int monthlyIncome;

  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);

  UserProfile toEntity() => UserProfile(ageGroup: ageGroup, monthlyIncome: monthlyIncome);
}
