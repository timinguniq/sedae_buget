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

  // 입력 칸의 글자 수 표시와 입력 제한은 저장할 이름(앞뒤 공백을 뗀 것)으로 센다.
  test('입력은 앞뒤 공백을 떼고 보이는 글자로 센다', () {
    expect(CategoryName.countOf('  반려식물 '), 4);
    expect(CategoryName.countOf(' 🐶 '), 1);
    expect(CategoryName.countOf('반려 식물'), 5); // 가운데 공백은 센다
    expect(CategoryName.countOf('   '), 0);
  });

  test('앞뒤 공백을 뺀 글자가 10자 이하면 입력 칸이 받는다(비어도 된다)', () {
    expect(CategoryName.fits('  ${'가' * 10}  '), isTrue);
    expect(CategoryName.fits('🐶' * 10), isTrue);
    expect(CategoryName.fits(''), isTrue);
    expect(CategoryName.fits('가' * 11), isFalse);
    expect(CategoryName.fits(' ${'🐶' * 11} '), isFalse);
  });

  // 입력 칸에 다 들어가지 않는 입력(붙여넣기 등)은 들어가는 앞부분까지 남긴다.
  test('넘치는 입력은 앞뒤 공백을 빼고 10자가 되는 가장 긴 앞부분까지 남긴다', () {
    expect(CategoryName.fittingPrefix('가나다라마바사아자차카타'), '가나다라마바사아자차');
    expect(CategoryName.fittingPrefix('  ${'가' * 12}'), '  ${'가' * 10}'); // 앞 공백은 세지 않는다
    expect(CategoryName.fittingPrefix('${'가' * 10}  나'), '${'가' * 10}  '); // 뒤 공백도 세지 않는다
    expect(CategoryName.fittingPrefix('반려 식물${'가' * 6}'), '반려 식물${'가' * 5}'); // 가운데 공백은 센다
    expect(CategoryName.fittingPrefix('${'가' * 11} 나'), '가' * 10); // 처음 넘친 글자 뒤는 남기지 않는다
    expect(CategoryName.fittingPrefix('🐶' * 11), '🐶' * 10);
    expect(CategoryName.fittingPrefix('👨‍👩‍👧' * 11), '👨‍👩‍👧' * 10); // 이어 붙인 이모지를 가르지 않는다
  });

  test('이미 들어가는 입력은 그대로 둔다', () {
    expect(CategoryName.fittingPrefix(''), '');
    expect(CategoryName.fittingPrefix('   '), '   ');
    expect(CategoryName.fittingPrefix('  반려식물 '), '  반려식물 ');
    expect(CategoryName.fittingPrefix('  ${'가' * 10}  '), '  ${'가' * 10}  ');
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
