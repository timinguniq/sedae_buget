import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sedae_budget/presentation/presentation.dart';

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
      appBar: AppBar(title: const Text('설정')),
      child: ListView(padding: const EdgeInsets.all(20), children: [
        const ProfileCard(),
        const SizedBox(height: 20),
        Text('화면', style: context.typo.label2W600.copyWith(color: context.color.label.assistive)),
        const SizedBox(height: 8),
        ThemeModeSelector(
          value: themeService.themeMode,
          onChanged: (m) => themeService.setMode(m)),
        const SizedBox(height: 20),
        Text('일반', style: context.typo.label2W600.copyWith(color: context.color.label.assistive)),
        const SizedBox(height: 8),
        SettingsTile(label: '앱 버전', value: _version.isEmpty ? '...' : 'v$_version'),
        const SizedBox(height: 8),
        SettingsTile(label: '이용약관 · 개인정보', trailing: const Icon(Icons.chevron_right), onTap: () {}),
      ]),
    );
  }
}
