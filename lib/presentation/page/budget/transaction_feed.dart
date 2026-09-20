import 'package:sedae_budget/entity/entity.dart';

/// 내역 화면 목록의 한 줄. 위젯이 아니라 값이라 화면 없이 검증한다.
sealed class TransactionFeedItem {
  const TransactionFeedItem();
}

/// 날짜 그룹 헤더. [isFirst]면 목록 맨 위(위 여백이 좁다).
class FeedDayHeader extends TransactionFeedItem {
  const FeedDayHeader(this.day, {required this.isFirst});

  final DateTime day;
  final bool isFirst;
}

/// 같은 날 거래 사이 구분선.
class FeedDivider extends TransactionFeedItem {
  const FeedDivider();
}

class FeedTransaction extends TransactionFeedItem {
  const FeedTransaction(this.transaction);

  final Transaction transaction;
}

/// 하루 끝 배너 광고 자리. [day]는 방금 끝난 날짜 그룹.
class FeedAdSlot extends TransactionFeedItem {
  const FeedAdSlot(this.day);

  final DateTime day;
}

/// 하루 끝 배너 광고는 위에서부터 이 개수까지만 붙인다.
const int kMaxDayAdBanners = 3;

/// 거래를 날짜 내림차순 그룹으로 묶어 화면 항목으로 만든다.
/// 그룹 사이에는 헤더, 같은 날 거래 사이에는 구분선, 그룹이 끝날 때마다
/// 위에서부터 [maxAds]개까지 배너 광고 자리를 끼운다.
List<TransactionFeedItem> buildTransactionFeed(
  List<Transaction> transactions, {
  int maxAds = kMaxDayAdBanners,
}) {
  final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
  final items = <TransactionFeedItem>[];
  var ads = 0;
  DateTime? current;

  void closeGroup() {
    final day = current;
    if (day == null || ads >= maxAds) return;
    ads++;
    items.add(FeedAdSlot(day));
  }

  for (final t in sorted) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    if (day != current) {
      closeGroup();
      items.add(FeedDayHeader(day, isFirst: current == null));
      current = day;
    } else {
      items.add(const FeedDivider());
    }
    items.add(FeedTransaction(t));
  }
  closeGroup();
  return items;
}

/// 날짜 그룹 헤더 문구: 오늘 · M월 D일 / 어제 · M월 D일 / M월 D일.
String dateGroupLabel(DateTime day, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final md = '${day.month}월 ${day.day}일';
  final diff = today.difference(DateTime(day.year, day.month, day.day)).inDays;
  if (diff == 0) return '오늘 · $md';
  if (diff == 1) return '어제 · $md';
  return md;
}
