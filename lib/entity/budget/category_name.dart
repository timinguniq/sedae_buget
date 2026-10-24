import 'package:characters/characters.dart';

/// 사용자 카테고리 이름의 규칙: 앞뒤 공백을 떼고, 보이는 글자로 1~[maxLength]자.
///
/// 한 자는 사람이 보는 글자 하나다(한글 한 자·이모지 하나·이어 붙인 이모지 하나가 모두 한 자). 입력 칸의 글자 수 제한과
/// 서버가 이렇게 세므로 초안·글자 수 표시·Stub도 여기서 센다. 이름이 겹치는지는 서버만 판정한다.
abstract final class CategoryName {
  static const maxLength = 10;

  /// [text]의 글자 수(보이는 글자).
  static int lengthOf(String text) => text.characters.length;

  /// [input]을 다듬은 이름(앞뒤 공백을 뗀 것). 길이는 따지지 않는다.
  static String normalize(String input) => input.trim();

  /// 입력 칸의 [input]을 이름으로 센 글자 수([normalize]한 이름의 보이는 글자). 앞뒤 공백은 세지 않는다.
  static int countOf(String input) => lengthOf(normalize(input));

  /// 입력 칸이 [input]을 받는지: [countOf]가 [maxLength]자 이하다. 입력 중이므로 비어도 된다.
  static bool fits(String input) => countOf(input) <= maxLength;

  /// 입력 칸에 [input]이 다 들어가지 않을 때 남길 앞부분: [fits]하는 가장 긴 앞부분(보이는 글자 단위로 자른다).
  /// 이미 [fits]하면 그대로다. 앞부분이 길수록 글자 수는 줄지 않으므로, 처음 넘치는 글자 앞에서 멈춘다.
  static String fittingPrefix(String input) {
    var prefix = '';
    for (final char in input.characters) {
      final next = '$prefix$char';
      if (!fits(next)) break;
      prefix = next;
    }
    return prefix;
  }

  /// 저장할 이름([normalize]한 것). 비었거나 [maxLength]자를 넘으면 null.
  static String? tryParse(String input) {
    final name = normalize(input);
    final length = lengthOf(name);
    return length == 0 || length > maxLength ? null : name;
  }
}
