import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sedae_budget/entity/auth/auth_provider.dart';

part 'auth_user.freezed.dart';

@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required AuthProvider provider,
    required String nickname,
  }) = _AuthUser;
}
