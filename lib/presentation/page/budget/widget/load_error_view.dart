import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/presentation/page/budget/ledger.view_model.dart';
import 'package:sedae_budget/presentation/widget/common/failure_message.dart';
import 'package:sedae_budget/presentation/widget/common/peer_text.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 달 화면이 보여줄 데이터를 불러오지 못했을 때. 이유와 '다시 시도'를 보여준다.
///
/// 다시 시도는 장부가 한다(달 화면이 읽는 서버 데이터를 모두 다시 읽는다). 이미 그린 값은 다시 읽는 동안에도 그대로다.
class LoadErrorView extends ConsumerWidget {
  /// 화면이 AsyncError로 받은 [error]. 문구는 [failureMessage]가 정한다.
  LoadErrorView({super.key, required Object error}) : _message = failureMessage(UserAction.load, error);

  /// 또래 통계를 못 읽었을 때(이달 개요에 또래가 없다).
  const LoadErrorView.peer({super.key}) : _message = peerUnavailableText;

  final String _message;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              _message,
              textAlign: TextAlign.center,
              style: context.typo.body2W400.copyWith(color: context.color.label.alternative),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: ref.read(monthlyTransactionsProvider.notifier).reload,
              child: const Text('다시 시도'),
            ),
          ]),
        ),
      );
}
