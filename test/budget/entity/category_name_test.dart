import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  test('최대 길이는 10자다', () {
    expect(CategoryName.maxLength, 10);
  });

  // 사람이 보는 글자 하나가 한 자다. UTF-16으로 세면 이모지 하나가 두 자, 이어 붙인 이모지는 여러 자가 된다.
  test('보이는 글자로 센다', () {
    expect(CategoryName.lengthOf('반려식물'), 4);
    expect(CategoryName.lengthOf('🐶'), 1);
    expect(CategoryName.lengthOf('👨‍👩‍👧'), 1); // 이어 붙인 이모지
    expect(CategoryName.lengthOf('é'), 1); // e + 결합 악센트
    expect(CategoryName.lengthOf(''), 0);
  });

  test('앞뒤 공백을 떼고 1~10자면 이름이다', () {
    expect(CategoryName.tryParse('  반려식물 '), '반려식물');
    expect(CategoryName.tryParse('가' * 10), '가' * 10);
    expect(CategoryName.tryParse('🐶' * 10), '🐶' * 10);
  });

  test('다듬은 이름이 비었거나 10자를 넘으면 이름이 아니다', () {
    expect(CategoryName.tryParse(''), isNull);
    expect(CategoryName.tryParse('   '), isNull);
    expect(CategoryName.tryParse('가' * 11), isNull);
    expect(CategoryName.tryParse('🐶' * 11), isNull);
  });
}
