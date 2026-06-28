import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/auth/auth_provider.dart';
import 'package:sedae_budget/entity/auth/auth_user.dart';

void main() {
  test('AuthUser JSON round-trips with provider name', () {
    const u = AuthUser(provider: AuthProvider.kakao, nickname: '카카오 사용자');
    final back = AuthUser.fromJson(u.toJson());
    expect(back, u);
    expect(u.toJson()['provider'], 'kakao');
  });
}
