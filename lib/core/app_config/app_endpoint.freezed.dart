// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_endpoint.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppEndpoint {

 String get server;
/// Create a copy of AppEndpoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppEndpointCopyWith<AppEndpoint> get copyWith => _$AppEndpointCopyWithImpl<AppEndpoint>(this as AppEndpoint, _$identity);

  /// Serializes this AppEndpoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppEndpoint&&(identical(other.server, server) || other.server == server));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,server);

@override
String toString() {
  return 'AppEndpoint(server: $server)';
}


}

/// @nodoc
abstract mixin class $AppEndpointCopyWith<$Res>  {
  factory $AppEndpointCopyWith(AppEndpoint value, $Res Function(AppEndpoint) _then) = _$AppEndpointCopyWithImpl;
@useResult
$Res call({
 String server
});




}
/// @nodoc
class _$AppEndpointCopyWithImpl<$Res>
    implements $AppEndpointCopyWith<$Res> {
  _$AppEndpointCopyWithImpl(this._self, this._then);

  final AppEndpoint _self;
  final $Res Function(AppEndpoint) _then;

/// Create a copy of AppEndpoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? server = null,}) {
  return _then(_self.copyWith(
server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppEndpoint].
extension AppEndpointPatterns on AppEndpoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppEndpoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppEndpoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppEndpoint value)  $default,){
final _that = this;
switch (_that) {
case _AppEndpoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppEndpoint value)?  $default,){
final _that = this;
switch (_that) {
case _AppEndpoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String server)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppEndpoint() when $default != null:
return $default(_that.server);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String server)  $default,) {final _that = this;
switch (_that) {
case _AppEndpoint():
return $default(_that.server);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String server)?  $default,) {final _that = this;
switch (_that) {
case _AppEndpoint() when $default != null:
return $default(_that.server);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppEndpoint implements AppEndpoint {
  const _AppEndpoint({required this.server});
  factory _AppEndpoint.fromJson(Map<String, dynamic> json) => _$AppEndpointFromJson(json);

@override final  String server;

/// Create a copy of AppEndpoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppEndpointCopyWith<_AppEndpoint> get copyWith => __$AppEndpointCopyWithImpl<_AppEndpoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppEndpointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppEndpoint&&(identical(other.server, server) || other.server == server));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,server);

@override
String toString() {
  return 'AppEndpoint(server: $server)';
}


}

/// @nodoc
abstract mixin class _$AppEndpointCopyWith<$Res> implements $AppEndpointCopyWith<$Res> {
  factory _$AppEndpointCopyWith(_AppEndpoint value, $Res Function(_AppEndpoint) _then) = __$AppEndpointCopyWithImpl;
@override @useResult
$Res call({
 String server
});




}
/// @nodoc
class __$AppEndpointCopyWithImpl<$Res>
    implements _$AppEndpointCopyWith<$Res> {
  __$AppEndpointCopyWithImpl(this._self, this._then);

  final _AppEndpoint _self;
  final $Res Function(_AppEndpoint) _then;

/// Create a copy of AppEndpoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? server = null,}) {
  return _then(_AppEndpoint(
server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
