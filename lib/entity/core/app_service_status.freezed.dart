// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_service_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppServiceStatus {

 bool get available; String get noticeTitle; String get noticeContent;// ignore_for_file: invalid_annotation_target
@JsonKey(fromJson: _formatStringToDateTime, toJson: _dateTimeToString) DateTime get expectedTimeToBeAvailable;
/// Create a copy of AppServiceStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppServiceStatusCopyWith<AppServiceStatus> get copyWith => _$AppServiceStatusCopyWithImpl<AppServiceStatus>(this as AppServiceStatus, _$identity);

  /// Serializes this AppServiceStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppServiceStatus&&(identical(other.available, available) || other.available == available)&&(identical(other.noticeTitle, noticeTitle) || other.noticeTitle == noticeTitle)&&(identical(other.noticeContent, noticeContent) || other.noticeContent == noticeContent)&&(identical(other.expectedTimeToBeAvailable, expectedTimeToBeAvailable) || other.expectedTimeToBeAvailable == expectedTimeToBeAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,available,noticeTitle,noticeContent,expectedTimeToBeAvailable);

@override
String toString() {
  return 'AppServiceStatus(available: $available, noticeTitle: $noticeTitle, noticeContent: $noticeContent, expectedTimeToBeAvailable: $expectedTimeToBeAvailable)';
}


}

/// @nodoc
abstract mixin class $AppServiceStatusCopyWith<$Res>  {
  factory $AppServiceStatusCopyWith(AppServiceStatus value, $Res Function(AppServiceStatus) _then) = _$AppServiceStatusCopyWithImpl;
@useResult
$Res call({
 bool available, String noticeTitle, String noticeContent,@JsonKey(fromJson: _formatStringToDateTime, toJson: _dateTimeToString) DateTime expectedTimeToBeAvailable
});




}
/// @nodoc
class _$AppServiceStatusCopyWithImpl<$Res>
    implements $AppServiceStatusCopyWith<$Res> {
  _$AppServiceStatusCopyWithImpl(this._self, this._then);

  final AppServiceStatus _self;
  final $Res Function(AppServiceStatus) _then;

/// Create a copy of AppServiceStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? available = null,Object? noticeTitle = null,Object? noticeContent = null,Object? expectedTimeToBeAvailable = null,}) {
  return _then(_self.copyWith(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,noticeTitle: null == noticeTitle ? _self.noticeTitle : noticeTitle // ignore: cast_nullable_to_non_nullable
as String,noticeContent: null == noticeContent ? _self.noticeContent : noticeContent // ignore: cast_nullable_to_non_nullable
as String,expectedTimeToBeAvailable: null == expectedTimeToBeAvailable ? _self.expectedTimeToBeAvailable : expectedTimeToBeAvailable // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AppServiceStatus].
extension AppServiceStatusPatterns on AppServiceStatus {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppServiceStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppServiceStatus() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppServiceStatus value)  $default,){
final _that = this;
switch (_that) {
case _AppServiceStatus():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppServiceStatus value)?  $default,){
final _that = this;
switch (_that) {
case _AppServiceStatus() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool available,  String noticeTitle,  String noticeContent, @JsonKey(fromJson: _formatStringToDateTime, toJson: _dateTimeToString)  DateTime expectedTimeToBeAvailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppServiceStatus() when $default != null:
return $default(_that.available,_that.noticeTitle,_that.noticeContent,_that.expectedTimeToBeAvailable);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool available,  String noticeTitle,  String noticeContent, @JsonKey(fromJson: _formatStringToDateTime, toJson: _dateTimeToString)  DateTime expectedTimeToBeAvailable)  $default,) {final _that = this;
switch (_that) {
case _AppServiceStatus():
return $default(_that.available,_that.noticeTitle,_that.noticeContent,_that.expectedTimeToBeAvailable);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool available,  String noticeTitle,  String noticeContent, @JsonKey(fromJson: _formatStringToDateTime, toJson: _dateTimeToString)  DateTime expectedTimeToBeAvailable)?  $default,) {final _that = this;
switch (_that) {
case _AppServiceStatus() when $default != null:
return $default(_that.available,_that.noticeTitle,_that.noticeContent,_that.expectedTimeToBeAvailable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppServiceStatus implements AppServiceStatus {
  const _AppServiceStatus({required this.available, required this.noticeTitle, required this.noticeContent, @JsonKey(fromJson: _formatStringToDateTime, toJson: _dateTimeToString) required this.expectedTimeToBeAvailable});
  factory _AppServiceStatus.fromJson(Map<String, dynamic> json) => _$AppServiceStatusFromJson(json);

@override final  bool available;
@override final  String noticeTitle;
@override final  String noticeContent;
// ignore_for_file: invalid_annotation_target
@override@JsonKey(fromJson: _formatStringToDateTime, toJson: _dateTimeToString) final  DateTime expectedTimeToBeAvailable;

/// Create a copy of AppServiceStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppServiceStatusCopyWith<_AppServiceStatus> get copyWith => __$AppServiceStatusCopyWithImpl<_AppServiceStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppServiceStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppServiceStatus&&(identical(other.available, available) || other.available == available)&&(identical(other.noticeTitle, noticeTitle) || other.noticeTitle == noticeTitle)&&(identical(other.noticeContent, noticeContent) || other.noticeContent == noticeContent)&&(identical(other.expectedTimeToBeAvailable, expectedTimeToBeAvailable) || other.expectedTimeToBeAvailable == expectedTimeToBeAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,available,noticeTitle,noticeContent,expectedTimeToBeAvailable);

@override
String toString() {
  return 'AppServiceStatus(available: $available, noticeTitle: $noticeTitle, noticeContent: $noticeContent, expectedTimeToBeAvailable: $expectedTimeToBeAvailable)';
}


}

/// @nodoc
abstract mixin class _$AppServiceStatusCopyWith<$Res> implements $AppServiceStatusCopyWith<$Res> {
  factory _$AppServiceStatusCopyWith(_AppServiceStatus value, $Res Function(_AppServiceStatus) _then) = __$AppServiceStatusCopyWithImpl;
@override @useResult
$Res call({
 bool available, String noticeTitle, String noticeContent,@JsonKey(fromJson: _formatStringToDateTime, toJson: _dateTimeToString) DateTime expectedTimeToBeAvailable
});




}
/// @nodoc
class __$AppServiceStatusCopyWithImpl<$Res>
    implements _$AppServiceStatusCopyWith<$Res> {
  __$AppServiceStatusCopyWithImpl(this._self, this._then);

  final _AppServiceStatus _self;
  final $Res Function(_AppServiceStatus) _then;

/// Create a copy of AppServiceStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? available = null,Object? noticeTitle = null,Object? noticeContent = null,Object? expectedTimeToBeAvailable = null,}) {
  return _then(_AppServiceStatus(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,noticeTitle: null == noticeTitle ? _self.noticeTitle : noticeTitle // ignore: cast_nullable_to_non_nullable
as String,noticeContent: null == noticeContent ? _self.noticeContent : noticeContent // ignore: cast_nullable_to_non_nullable
as String,expectedTimeToBeAvailable: null == expectedTimeToBeAvailable ? _self.expectedTimeToBeAvailable : expectedTimeToBeAvailable // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
