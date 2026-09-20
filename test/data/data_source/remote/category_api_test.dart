import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../../helper/recording_interceptor.dart';

CategoryApi _api(RecordingInterceptor server) => CategoryApi(Dio()..interceptors.add(server));

const _pet = {'id': 'c-1', 'name': '반려동물', 'baseCategoryId': 12};

void main() {
  test('list → GET /v1/categories, 사용자 카테고리 목록을 돌려준다', () async {
    final server = RecordingInterceptor(body: [_pet]);

    final list = await _api(server).list();

    expect(server.single.method, 'GET');
    expect(server.single.path, '/v1/categories');
    expect(
      list.map((dto) => dto.toEntity()),
      [const CustomCategory(id: 'c-1', name: '반려동물', baseCategoryId: 12)],
    );
  });

  test('put → PUT /v1/categories/{id} {name,baseCategoryId} (id는 경로에만)', () async {
    final server = RecordingInterceptor(status: 201, body: _pet);

    final saved = await _api(server).put(
      'c-1',
      CustomCategoryBodyDto.fromEntity(
        const CustomCategory(id: 'c-1', name: '반려동물', baseCategoryId: 12),
      ),
    );

    expect(server.single.method, 'PUT');
    expect(server.single.path, '/v1/categories/c-1');
    expect(server.single.data, {'name': '반려동물', 'baseCategoryId': 12});
    expect(saved.id, 'c-1');
    expect(saved.name, '반려동물');
  });

  test('delete → DELETE /v1/categories/{id}', () async {
    final server = RecordingInterceptor(status: 204);

    await _api(server).delete('c-1');

    expect(server.single.method, 'DELETE');
    expect(server.single.path, '/v1/categories/c-1');
  });
}
