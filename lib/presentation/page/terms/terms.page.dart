import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 약관 본문. 지금은 자리표시 문구이고, 확정된 본문이 나오면 여기만 채운다.
const _sections = [
  (title: '이용약관', body: '약관 본문을 준비하고 있어요.'),
  (title: '개인정보처리방침', body: '개인정보처리방침 본문을 준비하고 있어요.'),
];

/// 이용약관 · 개인정보처리방침 화면. 설정과 로그인 화면에서 push로 연다(세션 가드 면제).
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      child: Column(children: [
        // 헤더: 설정 화면과 같은 ‹ 원형 버튼 + 제목 800·20
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
          child: Row(children: [
            RoundIconButton(icon: Icons.chevron_left, onTap: () => _close(context)),
            const SizedBox(width: 12),
            Text('이용약관 · 개인정보', style: context.typo.pageTitle.copyWith(fontSize: 20, color: context.color.label.normal)),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(22, 0, 22, 22), children: [
            for (final s in _sections) ...[
              SurfaceCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.title, style: context.typo.sectionTitle.copyWith(color: context.color.label.normal)),
                  const SizedBox(height: 10),
                  Text(s.body, style: context.typo.caption1W400.copyWith(
                    fontSize: 12.5, height: 1.6, color: context.color.label.alternative)),
                ]),
              ),
              const SizedBox(height: 12),
            ],
          ]),
        ),
      ]),
    );
  }

  /// 연 화면으로 돌아간다. 웹에서 주소로 바로 열어 돌아갈 화면이 없으면 홈으로 보내고,
  /// 실제 행선지(로그인·온보딩·연결 안 됨·홈)는 전역 가드(sessionRedirect)가 정한다.
  void _close(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(RoutePath.budgetHome.path);
}
