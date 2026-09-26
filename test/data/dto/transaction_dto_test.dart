import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  test('body omits server-owned fields and sends UTC date', () {
    final tx = Transaction.create(
      amount: 12000, categoryId: 7, date: DateTime(2026, 9, 6), // 로컬 자정
      type: TransactionType.expense, memo: '버스',
    );
    final body = TransactionBodyDto.fromEntity(tx).toJson();
    expect(body.keys,
        unorderedEquals(['amount', 'categoryId', 'date', 'type', 'memo', 'customCategoryId']));
    expect(body['type'], 'expense');
    expect(body['customCategoryId'], isNull);
    expect((body['date'] as String).endsWith('Z'), isTrue);
    expect(DateTime.parse(body['date'] as String), DateTime(2026, 9, 6).toUtc());
  });

  test('fromJson → toEntity converts UTC strings to local DateTime', () {
    final tx = TransactionDto.fromJson({
      'id': 'x', 'amount': 500, 'categoryId': 2,
      'date': '2026-09-05T15:00:00.000Z', 'type': 'income', 'memo': null,
      'createdAt': '2026-09-06T01:02:03.000Z', 'updatedAt': '2026-09-06T01:02:04.000Z',
    }).toEntity();
    expect(tx.id, 'x');
    expect(tx.type, TransactionType.income);
    expect(tx.memo, isNull);
    expect(tx.date.isUtc, isFalse);
    expect(tx.date.toUtc(), DateTime.utc(2026, 9, 5, 15));
    expect(tx.createdAt.isUtc, isFalse);
    expect(tx.createdAt.toUtc(), DateTime.utc(2026, 9, 6, 1, 2, 3));
    expect(tx.updatedAt.isUtc, isFalse);
    expect(tx.updatedAt.toUtc(), DateTime.utc(2026, 9, 6, 1, 2, 4));
    expect(tx.customCategoryId, isNull);
  });

  test('customCategoryId round-trips', () {
    final body = TransactionBodyDto.fromEntity(Transaction.create(
      amount: 3000, categoryId: 12, date: DateTime(2026, 9, 6),
      type: TransactionType.expense, customCategoryId: 'cat-1',
    )).toJson();
    expect(body['customCategoryId'], 'cat-1');
    final tx = TransactionDto.fromJson({
      'id': 'x', 'amount': 3000, 'categoryId': 12,
      'date': '2026-09-05T15:00:00.000Z', 'type': 'expense', 'memo': null,
      'customCategoryId': 'cat-1',
      'createdAt': '2026-09-06T01:02:03.000Z', 'updatedAt': '2026-09-06T01:02:04.000Z',
    }).toEntity();
    expect(tx.customCategoryId, 'cat-1');
  });

  test('utcQuery formats a local instant as UTC ISO-8601', () {
    final q = utcQuery(DateTime(2026, 9, 1));
    expect(q.endsWith('Z'), isTrue);
    expect(DateTime.parse(q), DateTime(2026, 9, 1).toUtc());
  });

  // 서버가 새 분류를 늘리거나 수입에 아무 id(0 등)를 적어도, 앱 안쪽은 12개 기본 분류만 본다.
  group('모르는 분류 id', () {
    Transaction read(int categoryId, String type) => TransactionDto.fromJson({
          'id': 'x', 'amount': 500, 'categoryId': categoryId,
          'date': '2026-09-05T15:00:00.000Z', 'type': type, 'memo': null,
          'createdAt': '2026-09-06T01:02:03.000Z', 'updatedAt': '2026-09-06T01:02:04.000Z',
        }).toEntity();

    test('지출의 모르는 분류는 기타로 읽는다(돈이 합계에서 빠지지 않는다)', () {
      expect(read(13, 'expense').categoryId, BudgetCategory.etc.id);
      expect(read(0, 'expense').categoryId, BudgetCategory.etc.id);
    });

    test('수입은 분류 id가 무엇이든 읽는다', () {
      expect(BudgetCategory.values.map((c) => c.id), contains(read(0, 'income').categoryId));
    });

    test('아는 분류는 그대로다', () {
      expect(read(7, 'expense').categoryId, 7);
    });
  });
}
