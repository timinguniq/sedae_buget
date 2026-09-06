import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';
import 'package:go_router/go_router.dart';

class CDialog<T> extends StatelessWidget {
  const CDialog({
    super.key,
    required this.title,
    required this.description,
    required this.buttons,
    this.direction = Axis.vertical,
    this.cancelable = true,
  });

  final String title;
  final String description;
  final List<CDialogButton<T>> buttons;
  final Axis direction;
  final bool cancelable;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: context.color.fill.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 30), // 상단 여백

                /// 타이틀
                Text(title, style: context.typo.title3W600),

                const SizedBox(height: 30), // 간격

                /// 설명
                Text(
                  description,
                  style: context.typo.headline1W500.copyWith(color: const Color(0xCC000000)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          /// 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: LayoutBuilder(
              builder: (_, constraints) {
                assert(buttons.length <= 2, '버튼은 최대 2개까지만 지원합니다.');
                const spacer = 16.0;

                return direction == Axis.vertical
                    ? Column(
                  children: [
                    /// 상단 버튼
                    _Button(item: buttons[0]),

                    /// 하단 버튼
                    if (buttons.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: spacer),
                        child: _Button(item: buttons[1]),
                      ),
                  ],
                )
                    : Row(
                  children: [
                    /// 왼쪽 버튼
                    SizedBox(
                      width: (constraints.maxWidth - spacer) / 2,
                      child: _Button(item: buttons[0]),
                    ),

                    /// 오른쪽 버튼
                    if (buttons.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(left: spacer),
                        child: SizedBox(
                          width: (constraints.maxWidth - spacer) / 2,
                          child: _Button(item: buttons[1]),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Button<T> extends StatelessWidget {
  const _Button({
    super.key,
    required this.item,
  });

  final CDialogButton item;

  @override
  Widget build(BuildContext context) {
    return CButton(
      label: item.label,
      labelStyle: context.typo.titleReadingW600.copyWith(
        color: item.labelColor ?? Palette.labelWhite,
      ),
      buttonColor: item.color ?? Palette.primaryStrong,
      size: CButtonSize.lg,
      type: item.type ?? CButtonType.fill,
      onTap: () => context.pop<T>(item.result),
    );
  }
}

class CDialogButton<T> {
  CDialogButton({
    required this.label,
    this.labelColor,
    required this.result,
    this.color,
    this.type,
  });

  final String label;
  final Color? labelColor;
  final T result;
  final Color? color;
  final CButtonType? type;
}
