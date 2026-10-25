import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/presentation/page/legal/legal_content.dart';

/// 앱이 싣는 실제 asset을 읽는다. 카피는 핸드오프 JSON 그대로여야 한다.
LegalContent _load() => LegalContent.fromJson(
      jsonDecode(File('asset/legal/legal_content.json').readAsStringSync()) as Map<String, dynamic>,
    );

void main() {
  final content = _load();

  test('메타는 시행일과 버전을 합친 한 줄이다', () {
    expect(content.meta, '시행 2026. 6. 1 · 버전 1.0');
  });

  test('이용약관: 제목, 8개 조항, 문단·번호 목록 블록', () {
    final terms = content.of(LegalTab.terms);
    expect(terms.title, '세대 가계부 이용약관');
    expect(terms.intro, isNull);
    expect(terms.summary, isEmpty);
    expect(terms.sections.map((s) => s.heading), [
      '제1조 (목적)', '제2조 (정의)', '제3조 (회원가입)', '제4조 (서비스 내용)',
      '제5조 (또래 통계의 한계)', '제6조 (광고)', '제7조 (회원 탈퇴)', '제8조 (약관의 변경)',
    ]);
    expect(terms.sections.first.blocks.single,
        isA<LegalParagraph>().having((b) => b.text, 'text', startsWith('이 약관은 세대 가계부(이하 "서비스")')));
    expect(terms.sections[1].blocks.single,
        isA<LegalNumberedList>().having((b) => b.items, 'items', hasLength(2)));
  });

  test('개인정보처리방침: 소개, 요약 4칸, 수집 항목 표, 책임자 라벨·값', () {
    final privacy = content.of(LegalTab.privacy);
    expect(privacy.title, '개인정보처리방침');
    expect(privacy.intro, startsWith('세대 가계부는 또래 비교에 필요한 정보만'));
    expect(privacy.summary.map((s) => s.label), ['수집 항목', '이용 목적', '보유 기간', '제3자 제공']);
    expect(privacy.summary.last.value, '없음');
    expect(privacy.sections, hasLength(7));

    final table = privacy.sections.first.blocks.single as LegalTable;
    expect(table.rows.map((r) => r.name), ['로그인', '프로필', '지출 기록', '광고']);
    expect(table.rows.map((r) => r.badge), ['필수', '필수', '필수', '자동']);
    expect(table.rows.first.detail, '소셜 계정 식별자, 닉네임, 이메일');

    final kv = privacy.sections.last.blocks.single as LegalKeyValues;
    expect(kv.rows.map((r) => r.label), ['담당', '이메일']);
    expect(kv.rows.map((r) => r.value), ['[담당자 이름]', '[문의 이메일]']); // 법률 검토 전 플레이스홀더
  });

  test('모르는 블록 타입은 asset 오류로 드러낸다', () {
    expect(() => LegalBlock.fromJson({'type': 'img', 'src': 'x'}), throwsFormatException);
  });
}
