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

/// `lib/<path>` 바로 아래 폴더 이름.
List<String> subfolders(String path) => Directory('lib/$path')
    .listSync()
    .whereType<Directory>()
    .map((d) => d.uri.pathSegments.lastWhere((s) => s.isNotEmpty))
    .toList();

void main() {
  test('data는 data_source(local/remote)·dto·repository_impl 폴더로만 구성한다', () {
    expect(
      subfolders('data'),
      unorderedEquals(['data_source', 'dto', 'repository_impl']),
    );
    expect(subfolders('data/data_source'), unorderedEquals(['local', 'remote']));
  });

  test('domain은 manager·repository·usecase 폴더로만 구성한다', () {
    expect(
      subfolders('domain'),
      everyElement(isIn(['manager', 'repository', 'usecase'])),
    );
  });

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

  test('presentation에서 DI(locator) 접근은 화면 viewmodel과 service provider에서만 한다', () {
    expect(
      violations(
        'presentation',
        [
          'sedae_budget/core/dependency_injection',
          'sedae_budget/core/core.dart',
        ],
        skip: (p) =>
            p.endsWith('.view_model.dart') ||
            (p.startsWith('lib/presentation/service/') && p.endsWith('_provider.dart')),
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

  test('entity는 상위 계층/flutter를 import하지 않는다', () {
    expect(
      violations('entity', [
        'sedae_budget/core',
        'sedae_budget/domain',
        'sedae_budget/data',
        'sedae_budget/presentation',
        'sedae_budget/theme',
        'flutter/',
      ]),
      isEmpty,
    );
  });

  test('core는 composition root 외에는 domain/data를 import하지 않는다', () {
    expect(
      violations(
        'core',
        ['sedae_budget/domain', 'sedae_budget/data'],
        skip: (p) => p.startsWith('lib/core/dependency_injection/'),
      ),
      isEmpty,
    );
  });

  test('HTTP(dio)는 core/data에만 있다', () {
    for (final layer in ['domain', 'entity', 'presentation', 'theme']) {
      expect(violations(layer, ['dio/']), isEmpty, reason: layer);
    }
  });

  test('data의 로컬 저장 기술은 data_source/local에서만 쓴다', () {
    expect(
      violations(
        'data',
        ['drift/', 'shared_preferences/', 'flutter_secure_storage/'],
        skip: (p) => p.startsWith('lib/data/data_source/local/'),
      ),
      isEmpty,
    );
  });
}
