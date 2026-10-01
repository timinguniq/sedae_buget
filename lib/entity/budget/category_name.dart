import 'package:characters/characters.dart';

/// 사용자 카테고리 이름의 규칙: 앞뒤 공백을 떼고, 보이는 글자로 1~[maxLength]자.
///
/// 한 자는 사람이 보는 글자 하나다(한글 한 자·이모지 하나·이어 붙인 이모지 하나가 모두 한 자). 입력 칸의 글자 수 제한과
/// 서버가 이렇게 세므로 초안·글자 수 표시·Stub도 여기서 센다. 이름이 겹치는지는 서버만 판정한다.
abstract final class CategoryName {
  static const maxLength = 10;

  /// [text]의 글자 수(보이는 글자).
  static int lengthOf(String text) => text.characters.length;

  /// 저장할 이름([input]의 앞뒤 공백을 뗀 것). 비었거나 [maxLength]자를 넘으면 null.
  static String? tryParse(String input) {
    final name = input.trim();
    final length = lengthOf(name);
    return length == 0 || length > maxLength ? null : name;
  }
}
