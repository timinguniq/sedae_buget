import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/presentation/page/login/auth_provider.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 설정 하단 로그아웃 아웃라인 버튼: full-width h52 / r16 / surface 배경 / 연코랄 테두리 / 코랄 글씨 + 아이콘.
/// 로그인 상태일 때만 표시.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  static const Color _borderLight = Color(0xFFEFD9D2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    if (user == null) return const SizedBox.shrink();
    final coral = context.color.primary.normal;
    final dark = context.theme.brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity, height: 52,
      child: Material(
        color: context.color.background.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: dark ? context.color.line.normal : _borderLight, width: 1.5),
        ),
        child: InkWell(
          onTap: () => ref.read(authProvider.notifier).signOut(),
          borderRadius: BorderRadius.circular(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.logout, size: 16, color: coral),
            const SizedBox(width: 8),
            Text('로그아웃',
              style: context.typo.label2W600.copyWith(fontSize: 14.5, fontWeight: context.typo.bold, color: coral)),
          ]),
        ),
      ),
    );
  }
}
