import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/transaction_feed.dart';

Transaction _tx(DateTime date, {int amount = 1000}) => Transaction.create(
      amount: amount,
      categoryId: 7,
      date: date,
      type: TransactionType.expense,
    );

void main() {
  group('buildTransactionFeed', () {
    test('거래가 없으면 항목도 없다 — 광고도 붙지 않는다', () {
      expect(buildTransactionFeed(const []), isEmpty);
    });

    test('날짜 내림차순으로 정렬한다 — 입력 순서와 무관하게', () {
      final feed = buildTransactionFeed([
        _tx(DateTime(2026, 6, 3)),
        _tx(DateTime(2026, 6, 5)),
        _tx(DateTime(2026, 6, 4)),
      ]);
      final days = feed.whereType<FeedDayHeader>().map((h) => h.day).toList();
      expect(days, [DateTime(2026, 6, 5), DateTime(2026, 6, 4), DateTime(2026, 6, 3)]);
    });

    test('같은 날 거래 사이에만 구분선이 들어간다', () {
      final feed = buildTransactionFeed([
        _tx(DateTime(2026, 6, 5, 9)),
        _tx(DateTime(2026, 6, 5, 20)),
        _tx(DateTime(2026, 6, 4)),
      ]);
      expect(feed.whereType<FeedDayHeader>().length, 2);
      expect(feed.whereType<FeedDivider>().length, 1);
      expect(feed.whereType<FeedTransaction>().length, 3);
    });

    test('첫 헤더만 isFirst', () {
      final feed = buildTransactionFeed([
        _tx(DateTime(2026, 6, 5)),
        _tx(DateTime(2026, 6, 4)),
      ]);
      final headers = feed.whereType<FeedDayHeader>().toList();
      expect(headers.map((h) => h.isFirst), [true, false]);
    });

    test('날짜 그룹이 끝날 때마다 광고 한 칸 — 마지막 그룹 뒤에도 붙는다', () {
      final feed = buildTransactionFeed([
        _tx(DateTime(2026, 6, 5)),
        _tx(DateTime(2026, 6, 4)),
      ]);
      final ads = feed.whereType<FeedAdSlot>().toList();
      expect(ads.map((a) => a.day), [DateTime(2026, 6, 5), DateTime(2026, 6, 4)]);
    });

    test('광고는 위에서부터 maxAds개까지만', () {
      final feed = buildTransactionFeed(
        [for (var d = 1; d <= 6; d++) _tx(DateTime(2026, 6, d))],
      );
      final ads = feed.whereType<FeedAdSlot>().toList();
      expect(ads.length, 3);
      // 가장 최근 날짜 그룹부터 채운다.
      expect(ads.map((a) => a.day),
          [DateTime(2026, 6, 6), DateTime(2026, 6, 5), DateTime(2026, 6, 4)]);
    });

    test('maxAds가 0이면 광고가 없다', () {
      final feed = buildTransactionFeed(
        [_tx(DateTime(2026, 6, 5)), _tx(DateTime(2026, 6, 4))],
        maxAds: 0,
      );
      expect(feed.whereType<FeedAdSlot>(), isEmpty);
    });

    test('항목 순서: 헤더 → 거래 → 구분선 → 거래 → 광고', () {
      final feed = buildTransactionFeed([
        _tx(DateTime(2026, 6, 5, 9)),
        _tx(DateTime(2026, 6, 5, 20)),
      ]);
      expect(feed.map((e) => e.runtimeType.toString()), [
        'FeedDayHeader',
        'FeedTransaction',
        'FeedDivider',
        'FeedTransaction',
        'FeedAdSlot',
      ]);
    });
  });

  test('dateGroupLabel: 오늘 / 어제 / M월 D일', () {
    final now = DateTime(2026, 6, 27, 15);
    expect(dateGroupLabel(DateTime(2026, 6, 27), now: now), '오늘 · 6월 27일');
    expect(dateGroupLabel(DateTime(2026, 6, 26), now: now), '어제 · 6월 26일');
    expect(dateGroupLabel(DateTime(2026, 6, 25), now: now), '6월 25일');
  });
}
