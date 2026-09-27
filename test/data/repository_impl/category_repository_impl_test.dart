import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../helper/stub_server.dart';

void main() {
  late CategoryRepository repo;

  setUp(() async {
    final server = StubServer();
    await server.signIn(AuthProvider.kakao);
    repo = server.categories;
  });

  List<CustomCategory> unwrap(Result<List<CustomCategory>> r) =>
      (r as Success<List<CustomCategory>>).data;

  test('upsert → getAll round-trips through the Stub contract', () async {
    const pet = CustomCategory(id: 'c-pet', name: '반려식물', baseCategoryId: 19);
    final res = await repo.upsert(pet);
    expect(res, isA<Success<CustomCategory>>());
    expect((res as Success<CustomCategory>).data, pet);

    final all = unwrap(await repo.getAll());
    expect(all.single.name, '반려식물');
    expect(all.single.base, BudgetCategory.etc);
  });

  test('duplicate name → Failure with the server code', () async {
    await repo.upsert(const CustomCategory(id: 'c-pet', name: '반려식물', baseCategoryId: 19));
    final res = await repo.upsert(const CustomCategory(id: 'c-pet2', name: '반려식물', baseCategoryId: 14));
    expect(res, isA<Error<CustomCategory>>());
    expect(res.failureOrNull?.code, 'CATEGORY_DUPLICATE');
    expect(res.failureOrNull?.reason, FailureReason.conflict);
  });

  test('too long name → Failure VALIDATION', () async {
    final res = await repo.upsert(CustomCategory(
        id: 'c-long', name: 'a' * (CustomCategory.maxNameLength + 1), baseCategoryId: 1));
    expect(res.failureOrNull?.code, 'VALIDATION');
    expect(res.failureOrNull?.reason, FailureReason.invalid);
  });

  test('delete removes it and returns the deleted category', () async {
    const pet = CustomCategory(id: 'c-pet', name: '반려식물', baseCategoryId: 19);
    await repo.upsert(pet);
    final res = await repo.delete(pet);
    expect((res as Success<CustomCategory>).data, pet);
    expect(unwrap(await repo.getAll()), isEmpty);
  });
}
