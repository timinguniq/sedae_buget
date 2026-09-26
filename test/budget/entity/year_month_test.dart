import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  final today = DateTime(2026, 9, 26, 14, 30);

  test('날짜의 연·월만 본다', () {
    expect(YearMonth.of(DateTime(2026, 9, 26, 10)), YearMonth.of(DateTime(2026, 9, 1)));
    expect(YearMonth.of(DateTime(2026, 9, 1)).year, 2026);
    expect(YearMonth.of(DateTime(2026, 9, 1)).month, 9);
  });

  test('이전·다음 달은 해를 넘는다', () {
    expect(YearMonth.of(DateTime(2026, 1)).previous, YearMonth.of(DateTime(2025, 12)));
    expect(YearMonth.of(DateTime(2025, 12)).next, YearMonth.of(DateTime(2026, 1)));
  });

  test('달은 1일 0시부터 다음 달 1일 0시 전까지다', () {
    final m = YearMonth.of(DateTime(2026, 2));
    expect(m.start, DateTime(2026, 2));
    expect(m.end, DateTime(2026, 3));
    expect(m.contains(DateTime(2026, 2, 28, 23, 59)), isTrue);
    expect(m.contains(DateTime(2026, 3)), isFalse);
    expect(m.contains(DateTime(2026, 1, 31, 23, 59)), isFalse);
  });

  test('이번 달인가·다음 달로 갈 수 있는가는 오늘과 견준다', () {
    final thisMonth = YearMonth.of(today);
    expect(thisMonth.isCurrent(today), isTrue);
    expect(thisMonth.canGoNext(today), isFalse);
    expect(thisMonth.previous.isCurrent(today), isFalse);
    expect(thisMonth.previous.canGoNext(today), isTrue);
  });

  test('이름은 이번 달이면 이번 달, 아니면 M월이고, 긴 이름은 연도까지 쓴다', () {
    expect(YearMonth.of(today).name(today), '이번 달');
    expect(YearMonth.of(DateTime(2026, 8)).name(today), '8월');
    expect(YearMonth.of(DateTime(2025, 12)).fullName, '2025년 12월');
  });

  // 지난 달을 보며 추가한 거래가 보고 있는 목록에 나타나게 한다.
  group('새 거래의 기본 날짜', () {
    test('이번 달이면 오늘이다', () {
      expect(YearMonth.of(today).draftDate(today), today);
    });

    test('지난 달이면 그 달의 오늘과 같은 날이다', () {
      expect(YearMonth.of(DateTime(2026, 8)).draftDate(today), DateTime(2026, 8, 26));
    });

    test('그 달에 그날이 없으면 말일이다', () {
      final march31 = DateTime(2026, 3, 31);
      expect(YearMonth.of(DateTime(2026, 2)).draftDate(march31), DateTime(2026, 2, 28));
    });
  });
}
