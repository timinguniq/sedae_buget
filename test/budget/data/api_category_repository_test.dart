import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

class _Tokens implements AuthTokenStore {
  String? t = 'stub.kakao';
  @override
  Future<String?> read() async => t;
  @override
  Future<void> write(String token) async => t = token;
  @override
  Future<void> clear() async => t = null;
}

void main() {
  late CategoryRepository repo;

  setUp(() {
    repo = ApiCategoryRepository(ApiClient(Dio()
      ..interceptors.add(AuthTokenInterceptor(_Tokens()))
      ..interceptors.add(StubApiInterceptor())));
  });

  List<CustomCategory> unwrap(Result<List<CustomCategory>> r) =>
      (r as Success<List<CustomCategory>>).data;

  test('upsert → getAll round-trips through the Stub contract', () async {
    final pet = CustomCategory.create(name: '반려동물', baseCategoryId: 12);
    final res = await repo.upsert(pet);
    expect(res, isA<Success<CustomCategory>>());
    expect((res as Success<CustomCategory>).data, pet);

    final all = unwrap(await repo.getAll());
    expect(all.single.name, '반려동물');
    expect(all.single.base, BudgetCategory.etc);
  });

  test('duplicate name → Failure with the server code', () async {
    await repo.upsert(CustomCategory.create(name: '반려동물', baseCategoryId: 12));
    final res = await repo.upsert(CustomCategory.create(name: '반려동물', baseCategoryId: 9));
    expect(res, isA<Error<CustomCategory>>());
    expect((res as Error<CustomCategory>).error.resultCode, 'CATEGORY_DUPLICATE');
  });

  test('too long name → Failure VALIDATION', () async {
    final res = await repo.upsert(CustomCategory.create(
        name: 'a' * (CustomCategory.maxNameLength + 1), baseCategoryId: 1));
    expect((res as Error<CustomCategory>).error.resultCode, 'VALIDATION');
  });

  test('delete removes it and returns the deleted category', () async {
    final pet = CustomCategory.create(name: '반려동물', baseCategoryId: 12);
    await repo.upsert(pet);
    final res = await repo.delete(pet);
    expect((res as Success<CustomCategory>).data, pet);
    expect(unwrap(await repo.getAll()), isEmpty);
  });
}
