import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../../helper/recording_interceptor.dart';

UserProfileApi _api(RecordingInterceptor server) =>
    UserProfileApi(Dio()..interceptors.add(server));

const _json = {'ageGroup': 'thirties', 'monthlyIncome': 3000000};

void main() {
  test('get → GET /v1/me/profile, 프로필을 돌려준다', () async {
    final server = RecordingInterceptor(body: _json);

    final profile = await _api(server).get();

    expect(server.single.method, 'GET');
    expect(server.single.path, '/v1/me/profile');
    expect(profile.ageGroup, AgeGroup.thirties);
    expect(profile.monthlyIncome, 3000000);
  });

  test('put → PUT /v1/me/profile {ageGroup,monthlyIncome}', () async {
    final server = RecordingInterceptor(body: _json);

    await _api(server)
        .put(const UserProfileDto(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000));

    expect(server.single.method, 'PUT');
    expect(server.single.path, '/v1/me/profile');
    expect(server.single.data, _json);
  });

  test('delete → DELETE /v1/me/profile', () async {
    final server = RecordingInterceptor(status: 204);

    await _api(server).delete();

    expect(server.single.method, 'DELETE');
    expect(server.single.path, '/v1/me/profile');
  });
}
