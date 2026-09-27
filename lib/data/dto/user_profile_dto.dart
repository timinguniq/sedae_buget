import 'package:json_annotation/json_annotation.dart';
import 'package:sedae_budget/data/dto/age_group_wire.dart';
import 'package:sedae_budget/entity/entity.dart';

part 'user_profile_dto.g.dart';

/// `/v1/me/profile` 요청·응답. 나이대는 API 값 그대로 두고 [toEntity]에서만 해석한다.
@JsonSerializable()
class UserProfileDto {
  const UserProfileDto({required this.ageGroup, required this.monthlyIncome});

  factory UserProfileDto.fromJson(Map<String, dynamic> json) => _$UserProfileDtoFromJson(json);

  factory UserProfileDto.fromEntity(UserProfile p) =>
      UserProfileDto(ageGroup: p.ageGroup.wire, monthlyIncome: p.monthlyIncome);

  final String ageGroup;
  final int monthlyIncome;

  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);

  /// 모르는 나이대(서버가 늘렸거나 바꾼 나이대)면 null: 그 프로필로는 또래를 고를 수 없어 없는 프로필로 본다.
  UserProfile? toEntity() {
    final group = ageGroupFromWire(ageGroup);
    return group == null ? null : UserProfile(ageGroup: group, monthlyIncome: monthlyIncome);
  }
}
