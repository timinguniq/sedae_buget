/// 서버 경로 단일 출처. 실구현체와 Stub이 같은 상수를 쓴다.
/// 계약: docs/superpowers/plans/2026-09-06-api-integration.md "API 계약 (v1)".
abstract class ApiPath {
  ApiPath._();

  static const login = '/v1/auth/login';
  static const logout = '/v1/auth/logout';
  static const me = '/v1/me';
  static const profile = '/v1/me/profile';
  static const transactions = '/v1/transactions';
  static String transaction(String id) => '$transactions/$id';
  static const peerStats = '/v1/peer/stats';
  static const peerGenerations = '/v1/peer/generations';
}
