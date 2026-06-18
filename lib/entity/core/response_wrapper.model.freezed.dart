// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'response_wrapper.model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ResponseWrapper<T> {

 ResponseCode get resultCode; String? get message; T? get data;
/// Create a copy of ResponseWrapper
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResponseWrapperCopyWith<T, ResponseWrapper<T>> get copyWith => _$ResponseWrapperCopyWithImpl<T, ResponseWrapper<T>>(this as ResponseWrapper<T>, _$identity);

  /// Serializes this ResponseWrapper to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT);


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResponseWrapper<T>&&(identical(other.resultCode, resultCode) || other.resultCode == resultCode)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,resultCode,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'ResponseWrapper<$T>(resultCode: $resultCode, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $ResponseWrapperCopyWith<T,$Res>  {
  factory $ResponseWrapperCopyWith(ResponseWrapper<T> value, $Res Function(ResponseWrapper<T>) _then) = _$ResponseWrapperCopyWithImpl;
@useResult
$Res call({
 ResponseCode resultCode, String? message, T? data
});




}
/// @nodoc
class _$ResponseWrapperCopyWithImpl<T,$Res>
    implements $ResponseWrapperCopyWith<T, $Res> {
  _$ResponseWrapperCopyWithImpl(this._self, this._then);

  final ResponseWrapper<T> _self;
  final $Res Function(ResponseWrapper<T>) _then;

/// Create a copy of ResponseWrapper
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resultCode = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_self.copyWith(
resultCode: null == resultCode ? _self.resultCode : resultCode // ignore: cast_nullable_to_non_nullable
as ResponseCode,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T?,
  ));
}

}


/// Adds pattern-matching-related methods to [ResponseWrapper].
extension ResponseWrapperPatterns<T> on ResponseWrapper<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResponseWrapper<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResponseWrapper() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResponseWrapper<T> value)  $default,){
final _that = this;
switch (_that) {
case _ResponseWrapper():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResponseWrapper<T> value)?  $default,){
final _that = this;
switch (_that) {
case _ResponseWrapper() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResponseCode resultCode,  String? message,  T? data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResponseWrapper() when $default != null:
return $default(_that.resultCode,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResponseCode resultCode,  String? message,  T? data)  $default,) {final _that = this;
switch (_that) {
case _ResponseWrapper():
return $default(_that.resultCode,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResponseCode resultCode,  String? message,  T? data)?  $default,) {final _that = this;
switch (_that) {
case _ResponseWrapper() when $default != null:
return $default(_that.resultCode,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class _ResponseWrapper<T> implements ResponseWrapper<T> {
  const _ResponseWrapper({required this.resultCode, this.message, this.data});
  factory _ResponseWrapper.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$ResponseWrapperFromJson(json,fromJsonT);

@override final  ResponseCode resultCode;
@override final  String? message;
@override final  T? data;

/// Create a copy of ResponseWrapper
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResponseWrapperCopyWith<T, _ResponseWrapper<T>> get copyWith => __$ResponseWrapperCopyWithImpl<T, _ResponseWrapper<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$ResponseWrapperToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResponseWrapper<T>&&(identical(other.resultCode, resultCode) || other.resultCode == resultCode)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,resultCode,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'ResponseWrapper<$T>(resultCode: $resultCode, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$ResponseWrapperCopyWith<T,$Res> implements $ResponseWrapperCopyWith<T, $Res> {
  factory _$ResponseWrapperCopyWith(_ResponseWrapper<T> value, $Res Function(_ResponseWrapper<T>) _then) = __$ResponseWrapperCopyWithImpl;
@override @useResult
$Res call({
 ResponseCode resultCode, String? message, T? data
});




}
/// @nodoc
class __$ResponseWrapperCopyWithImpl<T,$Res>
    implements _$ResponseWrapperCopyWith<T, $Res> {
  __$ResponseWrapperCopyWithImpl(this._self, this._then);

  final _ResponseWrapper<T> _self;
  final $Res Function(_ResponseWrapper<T>) _then;

/// Create a copy of ResponseWrapper
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resultCode = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_ResponseWrapper<T>(
resultCode: null == resultCode ? _self.resultCode : resultCode // ignore: cast_nullable_to_non_nullable
as ResponseCode,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T?,
  ));
}


}

// dart format on
