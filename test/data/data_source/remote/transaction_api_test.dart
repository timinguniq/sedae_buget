import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../../helper/recording_interceptor.dart';

TransactionApi _api(RecordingInterceptor server) =>
    TransactionApi(Dio()..interceptors.add(server));

final _date = DateTime(2026, 9, 6, 12);

Map<String, dynamic> _row(String id) => {
      'id': id,
      'amount': 12000,
      'categoryId': 7,
      'date': _date.toUtc().toIso8601String(),
      'type': 'expense',
      'memo': '버스',
      'customCategoryId': null,
      'createdAt': '2026-09-06T01:02:03.000Z',
      'updatedAt': '2026-09-06T01:02:03.000Z',
    };

void main() {
  test('list → GET /v1/transactions?from&to, 거래 목록을 돌려준다', () async {
    final server = RecordingInterceptor(body: [_row('a'), _row('b')]);
    final from = utcQuery(DateTime(2026, 9));
    final to = utcQuery(DateTime(2026, 10));

    final list = await _api(server).list(from, to);

    expect(server.single.method, 'GET');
    expect(server.single.path, '/v1/transactions');
    expect(server.single.queryParameters, {'from': from, 'to': to});
    expect(list.map((t) => t.id), ['a', 'b']);
    expect(list.first.toEntity().date, _date);
  });

  test('put → PUT /v1/transactions/{id}, 바디에 id·타임스탬프를 넣지 않는다', () async {
    final server = RecordingInterceptor(status: 201, body: _row('tx-1'));
    final tx = Transaction.create(
      amount: 12000, categoryId: 7, date: _date, type: TransactionType.expense, memo: '버스',
    ).copyWith(id: 'tx-1');

    final saved = await _api(server).put(tx.id, TransactionBodyDto.fromEntity(tx));

    expect(server.single.method, 'PUT');
    expect(server.single.path, '/v1/transactions/tx-1');
    expect(server.single.data, {
      'amount': 12000,
      'categoryId': 7,
      'date': _date.toUtc().toIso8601String(),
      'type': 'expense',
      'memo': '버스',
      'customCategoryId': null,
    });
    expect(saved.id, 'tx-1');
    expect(saved.toEntity().createdAt, DateTime.utc(2026, 9, 6, 1, 2, 3).toLocal());
  });

  test('delete → DELETE /v1/transactions/{id}', () async {
    final server = RecordingInterceptor(status: 204);

    await _api(server).delete('tx-1');

    expect(server.single.method, 'DELETE');
    expect(server.single.path, '/v1/transactions/tx-1');
  });
}
