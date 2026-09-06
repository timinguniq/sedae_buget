import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});
  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String _version = '';
  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _version = i.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.themeService;
    return DefaultLayout(
      child: Column(children: [
        // 헤더: ‹ 원형 버튼 + "설정" 800·20
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
          child: Row(children: [
            RoundIconButton(icon: Icons.chevron_left, onTap: () => context.pop()),
            const SizedBox(width: 12),
            Text('설정', style: context.typo.pageTitle.copyWith(fontSize: 20, color: context.color.label.normal)),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(22, 0, 22, 22), children: [
            const ProfileCard(),
            _sectionLabel(context, '화면', top: 22),
            ThemeModeSelector(
              value: themeService.themeMode,
              onChanged: (m) => themeService.setMode(m)),
            _sectionLabel(context, '일반', top: 20),
            SurfaceCard(
              padding: EdgeInsets.zero,
              clip: true,
              child: Column(children: [
                Consumer(builder: (context, ref, _) {
                  final customs = ref.watch(customCategoriesProvider).value;
                  return SettingsTile(
                    key: const Key('category-manage-tile'),
                    label: '카테고리 관리',
                    value: '기본 ${BudgetCategory.values.length}'
                        '${customs == null ? '' : ' · 내 ${customs.length}'}',
                    onTap: () => context.push(RoutePath.categoryManage.path),
                  );
                }),
                _divider(context),
                SettingsTile(label: '앱 버전', value: _version.isEmpty ? '...' : 'v$_version'),
                _divider(context),
                SettingsTile(label: '이용약관 · 개인정보', onTap: () {}),
              ]),
            ),
            const SizedBox(height: 18),
            const LogoutButton(),
          ]),
        ),
      ]),
    );
  }

  /// 섹션 라벨 700·11 assistive, letterSpacing .5 (디자인 margin: top 4px 9px)
  Widget _sectionLabel(BuildContext context, String text, {required double top}) => Padding(
        padding: EdgeInsets.fromLTRB(4, top, 4, 9),
        child: Text(text, style: context.typo.caption2W600.copyWith(
          fontSize: 11, fontWeight: context.typo.bold, letterSpacing: 0.5, color: context.color.label.assistive)),
      );

  Widget _divider(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17),
        child: Container(height: 1, color: context.color.line.alternative),
      );
}
