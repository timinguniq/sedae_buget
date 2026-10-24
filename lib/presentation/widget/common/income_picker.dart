import 'package:flutter/material.dart';
import 'package:sedae_budget/presentation/widget/common/won_text.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 소득 슬라이더 상한 (디자인 `₩6,000,000+`). 온보딩과 프로필 수정이 같은 상한을 쓴다.
const int _incomeMax = 6000000;

/// 월 소득 고르기: 금액 + '월 평균 실수령액' + 슬라이더(0 ~ [_incomeMax], 10만 단위) + 범위.
/// 온보딩과 프로필 수정이 함께 쓴다. 상한보다 큰 [income]은 금액은 그대로 보이고 슬라이더만 끝에 선다.
class IncomePicker extends StatelessWidget {
  const IncomePicker({super.key, required this.income, required this.onChanged});
  final double income; final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final rangeStyle = context.typo.caption2W500.copyWith(fontSize: 11, color: c.label.assistive);
    return Column(children: [
      Center(child: Column(children: [
        Text(WonText.full.of(income.round()),
          style: context.typo.amountDisplay.copyWith(fontSize: 38, letterSpacing: -1.2, color: c.label.normal)),
        const SizedBox(height: 5),
        Text('월 평균 실수령액', style: context.typo.caption1W600.copyWith(color: c.label.assistive)),
      ])),
      const SizedBox(height: 40),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(padding: EdgeInsets.zero),
        child: Slider(
          min: 0, max: _incomeMax.toDouble(), divisions: 60,
          value: income.clamp(0, _incomeMax.toDouble()), onChanged: onChanged),
      ),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(WonText.full.of(0), style: rangeStyle),
        Text('${WonText.full.of(_incomeMax)}+', style: rangeStyle),
      ]),
    ]);
  }
}
