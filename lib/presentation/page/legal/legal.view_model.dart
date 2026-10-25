import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/presentation/page/legal/legal_content.dart';

/// 약관·개인정보처리방침 본문. 앱에 실린 `asset/legal/legal_content.json`을 한 번 읽는다.
/// 결과는 이 provider가 쥐므로 번들의 문자열 캐시는 쓰지 않는다
/// (캐시된 Future는 처음 읽은 테스트의 가짜 시간대에 묶여 다음 테스트에서 끝나지 않는다).
final legalContentProvider = FutureProvider<LegalContent>((ref) async {
  final text = await rootBundle.loadString('asset/legal/legal_content.json', cache: false);
  return LegalContent.fromJson(jsonDecode(text) as Map<String, dynamic>);
});
