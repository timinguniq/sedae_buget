import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/presentation/route/custom_route.dart';

/// push로 연 화면(설정·프로필 수정·거래 입력·카테고리 분석·약관)을 닫는 방법.
extension CloseScreen on BuildContext {
  /// 연 화면으로 돌아간다. 돌아갈 화면이 없으면(웹에서 주소로 바로 연 경우) 홈으로 보내고,
  /// 실제 행선지(로그인·온보딩·연결 안 됨·홈)는 전역 가드(sessionRedirect)가 정한다.
  void popOrHome() => canPop() ? pop() : go(RoutePath.budgetHome.path);
}
