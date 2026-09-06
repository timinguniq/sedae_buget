import 'package:flutter/material.dart';
import 'package:sedae_budget/presentation/presentation.dart';

/// 금액 입력 순수 상태(원 단위 정수). 위젯과 분리해 테스트 가능.
class KeypadInput {
  const KeypadInput(this.amount);
  final int amount;
  static const _max = 999999999;

  KeypadInput press(String key) {
    final next = key == '00' ? amount * 100 : amount * 10 + int.parse(key);
    return next > _max ? this : KeypadInput(next);
  }

  KeypadInput backspace() => KeypadInput(amount ~/ 10);
}

/// 디자인 키패드: 버튼 h52 / surface 배경 + line.normal 테두리 / r14 / 600·22, 간격 5. `⌫`는 투명.
/// `00` 키는 앱이 원 단위 정수라 유지(디자인의 `.` 자리).
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.value, required this.onChanged});
  final KeypadInput value;
  final ValueChanged<KeypadInput> onChanged;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['00', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (var r = 0; r < _rows.length; r++) ...[
        if (r > 0) const SizedBox(height: 5),
        Row(children: [
          for (var i = 0; i < _rows[r].length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(child: _key(context, _rows[r][i])),
          ],
        ]),
      ],
    ]);
  }

  Widget _key(BuildContext context, String k) {
    final erase = k == '⌫';
    return GestureDetector(
      onTap: () => onChanged(erase ? value.backspace() : value.press(k)),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: erase
            ? null
            : BoxDecoration(
                color: context.color.background.surface,
                border: Border.all(color: context.color.line.normal),
                borderRadius: BorderRadius.circular(14),
              ),
        child: erase
            ? Icon(Icons.backspace_outlined, size: 22, color: context.color.label.alternative)
            : Text(k, style: context.typo.heading1W600.copyWith(color: context.color.label.normal)),
      ),
    );
  }
}
