// 서버의 응답코드와 별개로 APP에서 Wrapping하여 사용하는 에러코드

enum ResultCode {
  SUCCESS('SUCCESS'),
  UNDEFINED('UNDEFINED'),
  UNKNOWN('UNKNOWN'),
  COMMON_051('Too many requests, please try again later.'),
  AUTH_011('This email is already registered.'),
  AUTH_012('Please check your email and password.'),
  ;

  const ResultCode(this.message);

  final String message;
}
