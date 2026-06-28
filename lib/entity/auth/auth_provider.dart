/// 소셜 로그인 제공자(목업).
enum AuthProvider {
  kakao('카카오'),
  naver('네이버'),
  google('Google');

  const AuthProvider(this.label);

  final String label;
}
