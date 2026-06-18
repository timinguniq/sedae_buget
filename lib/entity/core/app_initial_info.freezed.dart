// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_initial_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppInitialInfo {

 AppVersion get android; AppVersion get ios; AppServiceStatus get serviceStatus;
/// Create a copy of AppInitialInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppInitialInfoCopyWith<AppInitialInfo> get copyWith => _$AppInitialInfoCopyWithImpl<AppInitialInfo>(this as AppInitialInfo, _$identity);

  /// Serializes this AppInitialInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppInitialInfo&&(identical(other.android, android) || other.android == android)&&(identical(other.ios, ios) || other.ios == ios)&&(identical(other.serviceStatus, serviceStatus) || other.serviceStatus == serviceStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,android,ios,serviceStatus);

@override
String toString() {
  return 'AppInitialInfo(android: $android, ios: $ios, serviceStatus: $serviceStatus)';
}


}

/// @nodoc
abstract mixin class $AppInitialInfoCopyWith<$Res>  {
  factory $AppInitialInfoCopyWith(AppInitialInfo value, $Res Function(AppInitialInfo) _then) = _$AppInitialInfoCopyWithImpl;
@useResult
$Res call({
 AppVersion android, AppVersion ios, AppServiceStatus serviceStatus
});


$AppVersionCopyWith<$Res> get android;$AppVersionCopyWith<$Res> get ios;$AppServiceStatusCopyWith<$Res> get serviceStatus;

}
/// @nodoc
class _$AppInitialInfoCopyWithImpl<$Res>
    implements $AppInitialInfoCopyWith<$Res> {
  _$AppInitialInfoCopyWithImpl(this._self, this._then);

  final AppInitialInfo _self;
  final $Res Function(AppInitialInfo) _then;

/// Create a copy of AppInitialInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? android = null,Object? ios = null,Object? serviceStatus = null,}) {
  return _then(_self.copyWith(
android: null == android ? _self.android : android // ignore: cast_nullable_to_non_nullable
as AppVersion,ios: null == ios ? _self.ios : ios // ignore: cast_nullable_to_non_nullable
as AppVersion,serviceStatus: null == serviceStatus ? _self.serviceStatus : serviceStatus // ignore: cast_nullable_to_non_nullable
as AppServiceStatus,
  ));
}
/// Create a copy of AppInitialInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppVersionCopyWith<$Res> get android {
  
  return $AppVersionCopyWith<$Res>(_self.android, (value) {
    return _then(_self.copyWith(android: value));
  });
}/// Create a copy of AppInitialInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppVersionCopyWith<$Res> get ios {
  
  return $AppVersionCopyWith<$Res>(_self.ios, (value) {
    return _then(_self.copyWith(ios: value));
  });
}/// Create a copy of AppInitialInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppServiceStatusCopyWith<$Res> get serviceStatus {
  
  return $AppServiceStatusCopyWith<$Res>(_self.serviceStatus, (value) {
    return _then(_self.copyWith(serviceStatus: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppInitialInfo].
extension AppInitialInfoPatterns on AppInitialInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppInitialInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppInitialInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppInitialInfo value)  $default,){
final _that = this;
switch (_that) {
case _AppInitialInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppInitialInfo value)?  $default,){
final _that = this;
switch (_that) {
case _AppInitialInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppVersion android,  AppVersion ios,  AppServiceStatus serviceStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppInitialInfo() when $default != null:
return $default(_that.android,_that.ios,_that.serviceStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppVersion android,  AppVersion ios,  AppServiceStatus serviceStatus)  $default,) {final _that = this;
switch (_that) {
case _AppInitialInfo():
return $default(_that.android,_that.ios,_that.serviceStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppVersion android,  AppVersion ios,  AppServiceStatus serviceStatus)?  $default,) {final _that = this;
switch (_that) {
case _AppInitialInfo() when $default != null:
return $default(_that.android,_that.ios,_that.serviceStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppInitialInfo implements AppInitialInfo {
  const _AppInitialInfo({required this.android, required this.ios, required this.serviceStatus});
  factory _AppInitialInfo.fromJson(Map<String, dynamic> json) => _$AppInitialInfoFromJson(json);

@override final  AppVersion android;
@override final  AppVersion ios;
@override final  AppServiceStatus serviceStatus;

/// Create a copy of AppInitialInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppInitialInfoCopyWith<_AppInitialInfo> get copyWith => __$AppInitialInfoCopyWithImpl<_AppInitialInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppInitialInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppInitialInfo&&(identical(other.android, android) || other.android == android)&&(identical(other.ios, ios) || other.ios == ios)&&(identical(other.serviceStatus, serviceStatus) || other.serviceStatus == serviceStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,android,ios,serviceStatus);

@override
String toString() {
  return 'AppInitialInfo(android: $android, ios: $ios, serviceStatus: $serviceStatus)';
}


}

/// @nodoc
abstract mixin class _$AppInitialInfoCopyWith<$Res> implements $AppInitialInfoCopyWith<$Res> {
  factory _$AppInitialInfoCopyWith(_AppInitialInfo value, $Res Function(_AppInitialInfo) _then) = __$AppInitialInfoCopyWithImpl;
@override @useResult
$Res call({
 AppVersion android, AppVersion ios, AppServiceStatus serviceStatus
});


@override $AppVersionCopyWith<$Res> get android;@override $AppVersionCopyWith<$Res> get ios;@override $AppServiceStatusCopyWith<$Res> get serviceStatus;

}
/// @nodoc
class __$AppInitialInfoCopyWithImpl<$Res>
    implements _$AppInitialInfoCopyWith<$Res> {
  __$AppInitialInfoCopyWithImpl(this._self, this._then);

  final _AppInitialInfo _self;
  final $Res Function(_AppInitialInfo) _then;

/// Create a copy of AppInitialInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? android = null,Object? ios = null,Object? serviceStatus = null,}) {
  return _then(_AppInitialInfo(
android: null == android ? _self.android : android // ignore: cast_nullable_to_non_nullable
as AppVersion,ios: null == ios ? _self.ios : ios // ignore: cast_nullable_to_non_nullable
as AppVersion,serviceStatus: null == serviceStatus ? _self.serviceStatus : serviceStatus // ignore: cast_nullable_to_non_nullable
as AppServiceStatus,
  ));
}

/// Create a copy of AppInitialInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppVersionCopyWith<$Res> get android {
  
  return $AppVersionCopyWith<$Res>(_self.android, (value) {
    return _then(_self.copyWith(android: value));
  });
}/// Create a copy of AppInitialInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppVersionCopyWith<$Res> get ios {
  
  return $AppVersionCopyWith<$Res>(_self.ios, (value) {
    return _then(_self.copyWith(ios: value));
  });
}/// Create a copy of AppInitialInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppServiceStatusCopyWith<$Res> get serviceStatus {
  
  return $AppServiceStatusCopyWith<$Res>(_self.serviceStatus, (value) {
    return _then(_self.copyWith(serviceStatus: value));
  });
}
}

// dart format on
