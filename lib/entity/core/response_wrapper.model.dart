import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sedae_budget/entity/entity.dart';

part 'response_wrapper.model.freezed.dart';
part 'response_wrapper.model.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class ResponseWrapper<T> with _$ResponseWrapper<T> {
  const factory ResponseWrapper({
    required ResponseCode resultCode,
    String? message,
    T? data,
  }) = _ResponseWrapper;

  factory ResponseWrapper.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) =>
      _$ResponseWrapperFromJson(json, fromJsonT);
}
