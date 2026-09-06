import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sedae_budget/presentation/service/ad_provider.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 내역 하루 그룹 끝의 배너 광고. 디자인: 위 16px / `광고` 칩(700·8.5) + `AdMob · 320×100` 캡션(500·9) /
/// 1px 테두리 프레임(r12, surface) 안에 320×100 배너.
/// 로드되기 전이거나 실패하면 아무것도 그리지 않는다(빈 프레임을 남기지 않음).
class DayAdBanner extends ConsumerStatefulWidget {
  const DayAdBanner({super.key});

  @override
  ConsumerState<DayAdBanner> createState() => _DayAdBannerState();
}

class _DayAdBannerState extends ConsumerState<DayAdBanner> {
  BannerAd? _ad;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final ad = await ref.read(adServiceProvider).loadBanner();
    if (ad == null) return;
    if (!mounted) {
      await ad.dispose();
      return;
    }
    setState(() => _ad = ad);
  }

  @override
  void dispose() {
    unawaited(_ad?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    final width = ad.size.width.toDouble();
    final height = ad.size.height.toDouble();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: context.color.background.alternative,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('광고',
                style: context.typo.caption2W600.copyWith(
                    fontSize: 8.5, letterSpacing: 0.4,
                    fontWeight: context.typo.bold, color: context.color.label.alternative)),
          ),
          Text('AdMob · ${ad.size.width}×${ad.size.height}',
              style: context.typo.caption2W500.copyWith(fontSize: 9, color: context.color.label.disable)),
        ]),
        const SizedBox(height: 6),
        Container(
          height: height + 2, // 1px 테두리가 광고를 가리지 않게
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.color.background.surface,
            border: Border.all(color: context.color.line.neutral),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: SizedBox(width: width, height: height, child: AdWidget(ad: ad)),
          ),
        ),
      ]),
    );
  }
}
