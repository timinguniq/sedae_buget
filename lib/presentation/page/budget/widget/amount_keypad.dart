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

class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.value, required this.onChanged});
  final KeypadInput value;
  final ValueChanged<KeypadInput> onChanged;

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '00', '0', '⌫'];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.9,
      children: _keys
          .map((k) => InkWell(
                onTap: () => onChanged(k == '⌫' ? value.backspace() : value.press(k)),
                child: Center(
                  child: k == '⌫'
                      ? Icon(Icons.backspace_outlined, color: context.color.label.neutral)
                      : Text(k, style: context.typo.title3W600),
                ),
              ))
          .toList(),
    );
  }
}
