import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_endpoint.freezed.dart';
part 'app_endpoint.g.dart';

@freezed
abstract class AppEndpoint with _$AppEndpoint {
  const factory AppEndpoint({
    required String server,
  }) = _AppEndpoint;

  factory AppEndpoint.fromJson(Map<String, dynamic> json) => _$AppEndpointFromJson(json);
}
