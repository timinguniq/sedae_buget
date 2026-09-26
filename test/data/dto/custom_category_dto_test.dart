import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  CustomCategory read(int baseCategoryId) =>
      CustomCategoryDto.fromJson({'id': 'c1', 'name': '반려동물', 'baseCategoryId': baseCategoryId}).toEntity();

  test('아는 상위 분류는 그대로다', () {
    expect(read(9).base, BudgetCategory.recreation);
  });

  // 서버가 분류를 늘려도 이 카테고리의 지출은 기타로 모인다(화면이 멈추지 않는다).
  test('모르는 상위 분류는 기타로 읽는다', () {
    expect(read(13).base, BudgetCategory.etc);
    expect(read(0).baseCategoryId, BudgetCategory.etc.id);
  });
}
