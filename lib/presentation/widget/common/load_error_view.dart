import 'package:flutter/material.dart';
import 'package:sedae_budget/presentation/widget/common/failure_message.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 화면이 보여줄 데이터를 불러오지 못했을 때. 이유와 '다시 시도'를 보여준다.
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({super.key, required this.error, required this.onRetry});

  /// 화면이 AsyncError로 받은 오류.
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              failureMessage(UserAction.load, error),
              textAlign: TextAlign.center,
              style: context.typo.body2W400.copyWith(color: context.color.label.alternative),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ]),
        ),
      );
}
