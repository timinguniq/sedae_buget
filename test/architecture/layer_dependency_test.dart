import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// `lib/<layer>` 아래 .dart 파일(생성 파일 제외)의 import 줄에서
/// [forbidden] 패키지 경로 접두어가 나오면 위반으로 모은다.
/// [skip]이 true를 돌려주는 파일은 검사에서 제외한다.
List<String> violations(
  String layer,
  List<String> forbidden, {
  bool Function(String path)? skip,
}) {
  final out = <String>[];
  final files =
      Directory('lib/$layer').listSync(recursive: true).whereType<File>();
  for (final f in files) {
    final p = f.path;
    if (!p.endsWith('.dart') ||
        p.endsWith('.g.dart') ||
        p.endsWith('.freezed.dart')) {
      continue;
    }
    if (skip?.call(p) ?? false) continue;
    for (final line in f.readAsLinesSync()) {
      if (!line.startsWith('import ')) continue;
      for (final pkg in forbidden) {
        if (line.contains("'package:$pkg")) out.add('$p → $line');
      }
    }
  }
  return out;
}

void main() {
  test('domain은 data/presentation/core/theme/flutter를 import하지 않는다', () {
    expect(
      violations('domain', [
        'sedae_budget/data',
        'sedae_budget/presentation',
        'sedae_budget/core',
        'sedae_budget/theme',
        'flutter/',
      ]),
      isEmpty,
    );
  });

  test('data는 presentation/theme/flutter를 import하지 않는다', () {
    expect(
      violations('data', [
        'sedae_budget/presentation',
        'sedae_budget/theme',
        'flutter/',
      ]),
      isEmpty,
    );
  });

  test('presentation에서 DI(locator) 접근은 *_provider.dart 에서만 한다', () {
    expect(
      violations(
        'presentation',
        [
          'sedae_budget/core/dependency_injection',
          'sedae_budget/core/core.dart',
        ],
        skip: (p) => p.endsWith('_provider.dart'),
      ),
      isEmpty,
    );
  });

  test('presentation은 data 구현체를 직접 import하지 않는다', () {
    expect(violations('presentation', ['sedae_budget/data']), isEmpty);
  });

  test('presentation/page는 저장 기술(shared_preferences)을 직접 쓰지 않는다', () {
    expect(violations('presentation/page', ['shared_preferences']), isEmpty);
  });

  test('theme은 presentation/domain/data를 import하지 않는다', () {
    expect(
      violations('theme', [
        'sedae_budget/presentation',
        'sedae_budget/domain',
        'sedae_budget/data',
      ]),
      isEmpty,
    );
  });
}
