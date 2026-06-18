// 서버의 응답코드
import 'package:sedae_budget/entity/entity.dart';

enum ResponseCode {
  //------------------------- new server -------------------------\\

  SUCCESS('성공'),
  //--------------------//
  COMMON_001('알 수 없는 에러가 발생되었습니다.'),
  COMMON_002('에러가 발생되었습니다.'),
  COMMON_003('잘못된 요청입니다.'), //
  COMMON_004('허용되지 않는 메소드입니다.'),
  COMMON_005('API가 존재하지 않습니다.'),
  COMMON_006('잘못된 API 요청입니다.'), // Invalid API usage
  COMMON_031('이미 존재하는 데이터입니다.'),
  COMMON_032('알 수 없는 롤백이 발생되었습니다.'),
  COMMON_033('사용자 취소가 요청되었습니다.'),
  COMMON_041('잘못된 날짜 형식입니다.'),
  COMMON_051('요청이 너무 많습니다.'),

  //--------------------//
  AUTH_001('인증 에러가 발생되었습니다.'), // 일반
  AUTH_002('로그인이 필요합니다.'),
  AUTH_003('카카오 로그인 검증에 실패했습니다.'),
  AUTH_004('잘못된 토큰입니다.'),
  AUTH_005('만료된 토큰입니다.'),
  AUTH_006('Firebase ID Token이 유효하지 않습니다.'),
  AUTH_007('Firebase user 정보가 유효하지 않습니다.'),
  AUTH_008('providerId가 잘못된 값입니다.'),
  AUTH_009('회원가입이 필요한데, email값이 없습니다.'),
  AUTH_010('비밀번호가 null이어서 리셋이 필요합니다. 리셋 이메일을 보냈습니다.'),
  AUTH_011('이미 등록된 email입니다.'),
  AUTH_012('email 또는 password가 일치하지 않습니다.'),
  LOGIN_001('회원가입이 필요합니다.'),
  //--------------------//
  USER_001('탈퇴한 사용자입니다.'),
  USER_002('이미 가입된 사용자입니다.'),
  USER_003('재가입 허용 기간이 아닙니다.'),
  USER_010('사용자 정보가 존재하지 않습니다.'),
  //--------------------//
  POINT_001('포인트가 부족합니다.'),
  //--------------------//
  LANGUAGE_001('지원하지 않는 언어코드 입니다.'),
  COUNTRY_001('지원하지 않는 국가코드 입니다.'),
  USERNAME_001('잘못된 형식의 유저네임입니다.'),

  //------------------------- old server -------------------------\\

  // common --------------------//
  INVALID_PARAMETER('INVALID_PARAMETER'),
  INVALID_BODY('INVALID_BODY'),
  NOT_FOUND('NOT_FOUND'),
  DATA_FETCH_ERROR('DATA_FETCH_ERROR'),
  DATA_NULL('DATA_NULL'),

  // auth --------------------//
  AUTH_SIGN_UP_ERROR('AUTH_SIGN_UP_ERROR'),
  AUTH_SIGN_IN_ERROR('AUTH_SIGN_IN_ERROR'),
  SIGN_IN_WITH_OTHER_SOCIAL_LOGIN('SIGN_IN_WITH_OTHER_SOCIAL_LOGIN'),
  AUTH_SIGN_IN_APP_TO_WEB_ERROR('AUTH_SIGN_IN_APP_TO_WEB_ERROR'),
  AUTH_STORAGE_ERROR('AUTH_STORAGE_ERROR'),
  SIGN_OUT_ERROR('SIGN_OUT_ERROR'),
  AUTH_PASSWORD_REQUIRED('AUTH_PASSWORD_REQUIRED'),
  AUTH_SNS_ID_OR_TOKEN_REQUIRED('AUTH_SNS_ID_OR_TOKEN_REQUIRED'),
  AUTH_OAUTH_ERROR('AUTH_OAUTH_ERROR'),
  AUTH_OAUTH_SIGN_UP_REQUIRED_ACCOUNT('AUTH_OAUTH_SIGN_UP_REQUIRED_ACCOUNT'),
  AUTH_ALREADY_REGISTERED_EMAIL('AUTH_ALREADY_REGISTERED_EMAIL'),
  AUTH_ALREADY_REGISTERED_SNS_ID('AUTH_ALREADY_REGISTERED_SNS_ID'),
  AUTH_NOT_REGISTERED_EMAIL('AUTH_NOT_REGISTERED_EMAIL'),
  AUTH_APP_TO_WEB_TOKEN_NOT_EXIST('AUTH_APP_TO_WEB_TOKEN_NOT_EXIST'),
  AUTH_APP_TO_WEB_TOKEN_EXPIRED('AUTH_APP_TO_WEB_TOKEN_EXPIRED'),
  AUTH_TOKEN_INVALIDED('AUTH_TOKEN_INVALIDED'),
  AUTH_EMAIL_OR_PASSWORD_INVALIDED('Please confirm your email or password'),

  // vote --------------------//
  VOTE_FINISHED('VOTE_FINISHED'),

  // Http --------------------//
  HTTP_SOCKET_EXCEPTION('Http_Socket_Exception'),
  HTTP_500_INTERNAL_SERVER_ERROR('Http_500_Internal_Server_Error'),
  HTTP_CONNECT_TIMEOUT('Connect Timeout'),
  HTTP_SEND_TIMEOUT('HTTP_SEND_TIMEOUT'),
  HTTP_RECEIVE_TIMEOUT('HTTP_RECEIVE_TIMEOUT'),

  // unexpected --------------------//
  UNDEFINED('아직 등록되지 않은 에러코드'),
  UNKNOWN('예상 못한 에러 에러코드'),
  ;

  const ResponseCode(this.logMessage);

  final String logMessage;

  ResponseWrapper<T> toResponseWrapper<T>() {
    return ResponseWrapper(resultCode: this, message: logMessage);
  }
}
