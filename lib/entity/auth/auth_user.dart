import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sedae_budget/entity/auth/auth_provider.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required AuthProvider provider,
    required String nickname,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}
