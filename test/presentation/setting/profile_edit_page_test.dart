import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';
import 'package:sedae_budget/presentation/page/setting/profile_edit.page.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../../helper/fakes.dart';

const _saved = UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000);
const _failed = '저장하지 못했어요. 인터넷에 연결되어 있지 않아요';
final _saveButton = find.byKey(const Key('save-button'));

/// 설정 화면을 띄우고 프로필 카드를 눌러 프로필 수정 화면을 연다.
Future<ProviderContainer> _openFromSettings(WidgetTester t, StubServer server) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  final container = fakeContainer(server: server, themeModeStore: await fakeThemeModeStore());
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => const SettingPage()),
    GoRoute(path: RoutePath.profileEdit.path, builder: (_, _) => const ProfileEditPage()),
  ]);
  await t.pumpWidget(fakeScope(container,
      MaterialApp.router(routerConfig: router, theme: materialTheme(LightTheme()))));
  await t.settle();
  await t.tap(find.byType(ProfileCard));
  await t.settle();
  return container;
}

AgeGroup? _pickedAgeGroup(WidgetTester t) => t.widget<AgeGroupPicker>(find.byType(AgeGroupPicker)).selected;

bool _canSave(WidgetTester t) => t.widget<FilledButton>(_saveButton).onPressed != null;

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'sedae', packageName: 'com.sedae.budget',
      version: '1.0.0', buildNumber: '1', buildSignature: '');
  });

  testWidgets('설정의 프로필 카드를 누르면 저장된 나이대·소득이 골라진 채로 열린다', (t) async {
    await _openFromSettings(t, await t.seedServer(profile: _saved));

    expect(find.byType(ProfileEditPage), findsOneWidget);
    expect(_pickedAgeGroup(t), AgeGroup.thirties);
    expect(find.text('₩3,000,000'), findsOneWidget);
    expect(t.widget<Slider>(find.byType(Slider)).value, 3000000);
    // 바꾼 것이 없으면 저장할 것도 없다.
    expect(_canSave(t), isFalse);
  });

  testWidgets('나이대·소득을 바꿔 저장하면 서버에 저장되고, 설정으로 돌아와 새 나이대를 보인다', (t) async {
    final server = await t.seedServer(profile: _saved);
    final container = await _openFromSettings(t, server);

    await t.tap(find.text('20대'));
    await t.pump();
    await t.drag(find.byType(Slider), const Offset(1000, 0)); // 끝까지 = 상한
    await t.pump();
    expect(find.text('₩6,000,000'), findsOneWidget);

    await t.tap(_saveButton);
    await t.settle();

    const edited = UserProfile(ageGroup: AgeGroup.twenties, monthlyIncome: 6000000);
    expect(find.byType(ProfileEditPage), findsNothing);
    expect(find.byType(SettingPage), findsOneWidget);
    expect(find.text('20대'), findsOneWidget); // 설정의 프로필 카드
    expect(container.read(userProfileProvider).value, edited);
    expect((await t.untilDone(server.profiles.current())).unwrap(), edited);
  });

  // 실패했는데 닫으면 사용자는 바뀐 줄 안다. 고른 값을 잃으면 다시 골라야 한다.
  testWidgets('저장이 실패하면 화면에 남아 고른 값을 두고 이유를 보여준다', (t) async {
    final server = await t.seedServer(profile: _saved);
    server.faults.fail('PUT', '/v1/me/profile');
    final container = await _openFromSettings(t, server);

    await t.tap(find.text('20대'));
    await t.pump();
    await t.tap(_saveButton);
    await t.settle();

    expect(find.byType(ProfileEditPage), findsOneWidget);
    expect(find.text(_failed), findsOneWidget);
    expect(_pickedAgeGroup(t), AgeGroup.twenties);
    expect(_canSave(t), isTrue); // 다시 저장할 수 있다
    expect(container.read(userProfileProvider).value, _saved);
    expect((await t.untilDone(server.profiles.current())).unwrap(), _saved);
  });

  testWidgets('저장 응답을 기다리는 동안에는 다시 눌러도 한 번만 보낸다', (t) async {
    final server = await t.seedServer(profile: _saved);
    final reply = server.faults.hold('PUT', '/v1/me/profile');
    await _openFromSettings(t, server);
    final seeded = server.faults.count('PUT', '/v1/me/profile'); // 준비할 때 심은 프로필

    await t.tap(find.text('20대'));
    await t.pump();
    await t.tap(_saveButton);
    await t.pump();
    expect(_canSave(t), isFalse);
    await t.tap(_saveButton, warnIfMissed: false);
    await t.pump();

    reply.complete();
    await t.settle();

    expect(server.faults.count('PUT', '/v1/me/profile'), seeded + 1);
    expect(find.byType(ProfileEditPage), findsNothing);
  });

  // 꺼진 버튼을 그리기 전(같은 프레임)에 다시 눌리면 버튼은 아직 켜져 있다.
  testWidgets('다시 그리기 전에 두 번 눌려도 한 번만 보낸다', (t) async {
    final server = await t.seedServer(profile: _saved);
    final reply = server.faults.hold('PUT', '/v1/me/profile');
    await _openFromSettings(t, server);
    final seeded = server.faults.count('PUT', '/v1/me/profile'); // 준비할 때 심은 프로필

    await t.tap(find.text('20대'));
    await t.pump();
    await t.tap(_saveButton);
    await t.tap(_saveButton);
    await t.pump();

    reply.complete();
    await t.settle();

    expect(server.faults.count('PUT', '/v1/me/profile'), seeded + 1);
    expect(find.byType(ProfileEditPage), findsNothing);
  });
}
