import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/widget/index.dart';
import 'package:sedae_budget/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// 점검·업데이트를 안내한다. 계속 쓸 수 있으면 true.
///
/// 점검과 강제 업데이트는 확인하면 앱을 끝낸다([exitApp]). 선택 업데이트는 닫고 계속 쓸 수 있다.
Future<bool> showAppStatusDialog(
  BuildContext context,
  AppStatus status, {
  void Function() exitApp = exitAppSoon,
  Future<void> Function(String url) openStore = _openStore,
}) async {
  switch (status) {
    case AppAvailable():
      return true;
    case AppUnderMaintenance(:final notice):
      await showDialog<bool>(
        context: context,
        barrierColor: Palette.materialScrim13,
        barrierDismissible: false,
        builder: (_) => CDialog<bool>(
          title: notice.noticeTitle,
          description: notice.noticeContent,
          buttons: [CDialogButton(label: '확인', result: true)],
        ),
      );
      exitApp();
      return false;
    case AppUpdateAvailable(:final version, :final forced):
      final update = await showDialog<bool>(
        context: context,
        barrierColor: Palette.materialScrim13,
        barrierDismissible: false,
        builder: (_) => CDialog<bool>(
          title: '새 버전이 나왔어요',
          description: forced ? '계속 쓰려면 최신 버전으로 업데이트해 주세요.' : '최신 버전으로 업데이트해 보세요.',
          buttons: [
            if (!forced)
              CDialogButton(
                  label: '닫기', result: false, color: Palette.fillGrey, labelColor: Palette.labelNeutral),
            CDialogButton(label: '업데이트', result: true),
          ],
        ),
      );
      // 닫기: 대화상자는 버튼이 이미 닫았다. 아래 화면은 그대로 둔다.
      if (!forced && update != true) return true;
      unawaited(openStore(version.link));
      exitApp();
      return false;
  }
}

/// 스토어가 열릴 시간을 두고 앱을 끝낸다. 웹은 앱을 끝낼 수 없다.
void exitAppSoon() {
  if (kIsWeb) return;
  Future<void>.delayed(const Duration(seconds: 1), () => exit(0));
}

Future<void> _openStore(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}
