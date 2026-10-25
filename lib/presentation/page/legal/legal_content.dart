/// 약관 및 정책 화면의 탭. 화면 인자(`initialTab`)이자 보여줄 문서를 고르는 키다.
enum LegalTab {
  terms('이용약관'),
  privacy('개인정보처리방침');

  const LegalTab(this.label);

  final String label;
}

/// `asset/legal/legal_content.json`의 내용. 카피는 디자인 핸드오프 JSON 그대로이고, 이 파일은 형식만 안다.
class LegalContent {
  const LegalContent({
    required this.version,
    required this.effectiveDate,
    required this.terms,
    required this.privacy,
  });

  factory LegalContent.fromJson(Map<String, dynamic> json) => LegalContent(
        version: json['version'] as String,
        effectiveDate: json['effectiveDate'] as String,
        terms: LegalDocument.fromJson(json['terms'] as Map<String, dynamic>),
        privacy: LegalDocument.fromJson(json['privacy'] as Map<String, dynamic>),
      );

  final String version;
  final String effectiveDate;
  final LegalDocument terms;
  final LegalDocument privacy;

  /// 두 문서가 함께 쓰는 메타 줄. 예: "시행 2026. 6. 1 · 버전 1.0"
  String get meta => '시행 $effectiveDate · 버전 $version';

  LegalDocument of(LegalTab tab) => switch (tab) {
        LegalTab.terms => terms,
        LegalTab.privacy => privacy,
      };
}

/// 문서 하나. 개인정보처리방침만 소개 문단과 "한눈에 보기" 요약을 가진다.
class LegalDocument {
  const LegalDocument({
    required this.title,
    this.intro,
    this.summary = const [],
    required this.sections,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) => LegalDocument(
        title: json['title'] as String,
        intro: json['intro'] as String?,
        summary: [
          for (final s in json['summary'] as List? ?? const []) LegalSummaryItem.fromJson(s as Map<String, dynamic>),
        ],
        sections: [for (final s in json['sections'] as List) LegalSection.fromJson(s as Map<String, dynamic>)],
      );

  final String title;
  final String? intro;
  final List<LegalSummaryItem> summary;
  final List<LegalSection> sections;
}

class LegalSummaryItem {
  const LegalSummaryItem({required this.label, required this.value});

  factory LegalSummaryItem.fromJson(Map<String, dynamic> json) =>
      LegalSummaryItem(label: json['label'] as String, value: json['value'] as String);

  final String label;
  final String value;
}

class LegalSection {
  const LegalSection({required this.heading, required this.blocks});

  factory LegalSection.fromJson(Map<String, dynamic> json) => LegalSection(
        heading: json['heading'] as String,
        blocks: [for (final b in json['blocks'] as List) LegalBlock.fromJson(b as Map<String, dynamic>)],
      );

  final String heading;
  final List<LegalBlock> blocks;
}

/// 섹션 본문 블록 4종: 문단(p)·번호 목록(ol)·수집 항목 표(table)·라벨·값 행(kv).
sealed class LegalBlock {
  const LegalBlock();

  factory LegalBlock.fromJson(Map<String, dynamic> json) => switch (json['type']) {
        'p' => LegalParagraph(json['text'] as String),
        'ol' => LegalNumberedList([for (final i in json['items'] as List) i as String]),
        'table' => LegalTable([for (final r in json['rows'] as List) LegalTableRow.fromJson(r as Map<String, dynamic>)]),
        'kv' => LegalKeyValues([for (final r in json['rows'] as List) LegalKeyValue.fromJson(r as Map<String, dynamic>)]),
        final type => throw FormatException('모르는 약관 블록 타입: $type'),
      };
}

class LegalParagraph extends LegalBlock {
  const LegalParagraph(this.text);

  final String text;
}

class LegalNumberedList extends LegalBlock {
  const LegalNumberedList(this.items);

  final List<String> items;
}

class LegalTable extends LegalBlock {
  const LegalTable(this.rows);

  final List<LegalTableRow> rows;
}

class LegalTableRow {
  const LegalTableRow({required this.name, required this.badge, required this.detail});

  factory LegalTableRow.fromJson(Map<String, dynamic> json) => LegalTableRow(
        name: json['name'] as String,
        badge: json['badge'] as String,
        detail: json['detail'] as String,
      );

  final String name;

  /// "필수" 또는 "자동". 필수만 코랄 배지다.
  final String badge;
  final String detail;

  bool get isRequired => badge == '필수';
}

class LegalKeyValues extends LegalBlock {
  const LegalKeyValues(this.rows);

  final List<LegalKeyValue> rows;
}

class LegalKeyValue {
  const LegalKeyValue({required this.label, required this.value});

  factory LegalKeyValue.fromJson(Map<String, dynamic> json) =>
      LegalKeyValue(label: json['label'] as String, value: json['value'] as String);

  final String label;
  final String value;
}
