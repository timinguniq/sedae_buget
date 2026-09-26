/// 서버 경로 단일 출처. 실구현체와 Stub이 같은 상수를 쓴다.
/// 계약: `docs/api-contract.md`(설명), `test/contract/api_contract.dart`(기준 — 경로를 문자열 그대로 검증한다).
abstract class ApiPath {
  ApiPath._();

  static const login = '/v1/auth/login';
  static const logout = '/v1/auth/logout';
  static const me = '/v1/me';
  static const profile = '/v1/me/profile';
  static const transactions = '/v1/transactions';
  static String transaction(String id) => '$transactions/$id';

  /// 사용자 카테고리. 기본 분류(1~12)는 계약 상수라 이 경로로 다루지 않는다.
  static const categories = '/v1/categories';
  static String category(String id) => '$categories/$id';
  static const peerStats = '/v1/peer/stats';
  static const peerGenerations = '/v1/peer/generations';
}
