// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Area {

 double get lat; double get lng;@JsonKey(name: 'radius_km') double get radiusKm;
/// Create a copy of Area
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AreaCopyWith<Area> get copyWith => _$AreaCopyWithImpl<Area>(this as Area, _$identity);

  /// Serializes this Area to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Area&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,radiusKm);

@override
String toString() {
  return 'Area(lat: $lat, lng: $lng, radiusKm: $radiusKm)';
}


}

/// @nodoc
abstract mixin class $AreaCopyWith<$Res>  {
  factory $AreaCopyWith(Area value, $Res Function(Area) _then) = _$AreaCopyWithImpl;
@useResult
$Res call({
 double lat, double lng,@JsonKey(name: 'radius_km') double radiusKm
});




}
/// @nodoc
class _$AreaCopyWithImpl<$Res>
    implements $AreaCopyWith<$Res> {
  _$AreaCopyWithImpl(this._self, this._then);

  final Area _self;
  final $Res Function(Area) _then;

/// Create a copy of Area
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? radiusKm = null,}) {
  return _then(_self.copyWith(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Area].
extension AreaPatterns on Area {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Area value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Area() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Area value)  $default,){
final _that = this;
switch (_that) {
case _Area():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Area value)?  $default,){
final _that = this;
switch (_that) {
case _Area() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng, @JsonKey(name: 'radius_km')  double radiusKm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Area() when $default != null:
return $default(_that.lat,_that.lng,_that.radiusKm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng, @JsonKey(name: 'radius_km')  double radiusKm)  $default,) {final _that = this;
switch (_that) {
case _Area():
return $default(_that.lat,_that.lng,_that.radiusKm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng, @JsonKey(name: 'radius_km')  double radiusKm)?  $default,) {final _that = this;
switch (_that) {
case _Area() when $default != null:
return $default(_that.lat,_that.lng,_that.radiusKm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Area implements Area {
  const _Area({required this.lat, required this.lng, @JsonKey(name: 'radius_km') this.radiusKm = 15.0});
  factory _Area.fromJson(Map<String, dynamic> json) => _$AreaFromJson(json);

@override final  double lat;
@override final  double lng;
@override@JsonKey(name: 'radius_km') final  double radiusKm;

/// Create a copy of Area
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AreaCopyWith<_Area> get copyWith => __$AreaCopyWithImpl<_Area>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AreaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Area&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,radiusKm);

@override
String toString() {
  return 'Area(lat: $lat, lng: $lng, radiusKm: $radiusKm)';
}


}

/// @nodoc
abstract mixin class _$AreaCopyWith<$Res> implements $AreaCopyWith<$Res> {
  factory _$AreaCopyWith(_Area value, $Res Function(_Area) _then) = __$AreaCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng,@JsonKey(name: 'radius_km') double radiusKm
});




}
/// @nodoc
class __$AreaCopyWithImpl<$Res>
    implements _$AreaCopyWith<$Res> {
  __$AreaCopyWithImpl(this._self, this._then);

  final _Area _self;
  final $Res Function(_Area) _then;

/// Create a copy of Area
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? radiusKm = null,}) {
  return _then(_Area(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ProfileSetupRequest {

@JsonKey(name: 'display_name') String get displayName; String get username; Area? get area;
/// Create a copy of ProfileSetupRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileSetupRequestCopyWith<ProfileSetupRequest> get copyWith => _$ProfileSetupRequestCopyWithImpl<ProfileSetupRequest>(this as ProfileSetupRequest, _$identity);

  /// Serializes this ProfileSetupRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileSetupRequest&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.area, area) || other.area == area));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayName,username,area);

@override
String toString() {
  return 'ProfileSetupRequest(displayName: $displayName, username: $username, area: $area)';
}


}

/// @nodoc
abstract mixin class $ProfileSetupRequestCopyWith<$Res>  {
  factory $ProfileSetupRequestCopyWith(ProfileSetupRequest value, $Res Function(ProfileSetupRequest) _then) = _$ProfileSetupRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'display_name') String displayName, String username, Area? area
});


$AreaCopyWith<$Res>? get area;

}
/// @nodoc
class _$ProfileSetupRequestCopyWithImpl<$Res>
    implements $ProfileSetupRequestCopyWith<$Res> {
  _$ProfileSetupRequestCopyWithImpl(this._self, this._then);

  final ProfileSetupRequest _self;
  final $Res Function(ProfileSetupRequest) _then;

/// Create a copy of ProfileSetupRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? username = null,Object? area = freezed,}) {
  return _then(_self.copyWith(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as Area?,
  ));
}
/// Create a copy of ProfileSetupRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AreaCopyWith<$Res>? get area {
    if (_self.area == null) {
    return null;
  }

  return $AreaCopyWith<$Res>(_self.area!, (value) {
    return _then(_self.copyWith(area: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProfileSetupRequest].
extension ProfileSetupRequestPatterns on ProfileSetupRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileSetupRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileSetupRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileSetupRequest value)  $default,){
final _that = this;
switch (_that) {
case _ProfileSetupRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileSetupRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileSetupRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'display_name')  String displayName,  String username,  Area? area)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileSetupRequest() when $default != null:
return $default(_that.displayName,_that.username,_that.area);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'display_name')  String displayName,  String username,  Area? area)  $default,) {final _that = this;
switch (_that) {
case _ProfileSetupRequest():
return $default(_that.displayName,_that.username,_that.area);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'display_name')  String displayName,  String username,  Area? area)?  $default,) {final _that = this;
switch (_that) {
case _ProfileSetupRequest() when $default != null:
return $default(_that.displayName,_that.username,_that.area);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileSetupRequest implements ProfileSetupRequest {
  const _ProfileSetupRequest({@JsonKey(name: 'display_name') required this.displayName, required this.username, this.area});
  factory _ProfileSetupRequest.fromJson(Map<String, dynamic> json) => _$ProfileSetupRequestFromJson(json);

@override@JsonKey(name: 'display_name') final  String displayName;
@override final  String username;
@override final  Area? area;

/// Create a copy of ProfileSetupRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileSetupRequestCopyWith<_ProfileSetupRequest> get copyWith => __$ProfileSetupRequestCopyWithImpl<_ProfileSetupRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileSetupRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileSetupRequest&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.area, area) || other.area == area));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayName,username,area);

@override
String toString() {
  return 'ProfileSetupRequest(displayName: $displayName, username: $username, area: $area)';
}


}

/// @nodoc
abstract mixin class _$ProfileSetupRequestCopyWith<$Res> implements $ProfileSetupRequestCopyWith<$Res> {
  factory _$ProfileSetupRequestCopyWith(_ProfileSetupRequest value, $Res Function(_ProfileSetupRequest) _then) = __$ProfileSetupRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'display_name') String displayName, String username, Area? area
});


@override $AreaCopyWith<$Res>? get area;

}
/// @nodoc
class __$ProfileSetupRequestCopyWithImpl<$Res>
    implements _$ProfileSetupRequestCopyWith<$Res> {
  __$ProfileSetupRequestCopyWithImpl(this._self, this._then);

  final _ProfileSetupRequest _self;
  final $Res Function(_ProfileSetupRequest) _then;

/// Create a copy of ProfileSetupRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? username = null,Object? area = freezed,}) {
  return _then(_ProfileSetupRequest(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as Area?,
  ));
}

/// Create a copy of ProfileSetupRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AreaCopyWith<$Res>? get area {
    if (_self.area == null) {
    return null;
  }

  return $AreaCopyWith<$Res>(_self.area!, (value) {
    return _then(_self.copyWith(area: value));
  });
}
}


/// @nodoc
mixin _$ProfileResponse {

 String get uid; String get phone;@JsonKey(name: 'display_name') String get displayName; String get username;@JsonKey(name: 'photo_url') String? get photoUrl; Area? get area;@JsonKey(name: 'onboarding_complete') bool get onboardingComplete;@JsonKey(name: 'first_launch_tooltip_complete') bool get firstLaunchTooltipComplete;@JsonKey(name: 'is_creator') bool get isCreator;
/// Create a copy of ProfileResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileResponseCopyWith<ProfileResponse> get copyWith => _$ProfileResponseCopyWithImpl<ProfileResponse>(this as ProfileResponse, _$identity);

  /// Serializes this ProfileResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileResponse&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.area, area) || other.area == area)&&(identical(other.onboardingComplete, onboardingComplete) || other.onboardingComplete == onboardingComplete)&&(identical(other.firstLaunchTooltipComplete, firstLaunchTooltipComplete) || other.firstLaunchTooltipComplete == firstLaunchTooltipComplete)&&(identical(other.isCreator, isCreator) || other.isCreator == isCreator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,phone,displayName,username,photoUrl,area,onboardingComplete,firstLaunchTooltipComplete,isCreator);

@override
String toString() {
  return 'ProfileResponse(uid: $uid, phone: $phone, displayName: $displayName, username: $username, photoUrl: $photoUrl, area: $area, onboardingComplete: $onboardingComplete, firstLaunchTooltipComplete: $firstLaunchTooltipComplete, isCreator: $isCreator)';
}


}

/// @nodoc
abstract mixin class $ProfileResponseCopyWith<$Res>  {
  factory $ProfileResponseCopyWith(ProfileResponse value, $Res Function(ProfileResponse) _then) = _$ProfileResponseCopyWithImpl;
@useResult
$Res call({
 String uid, String phone,@JsonKey(name: 'display_name') String displayName, String username,@JsonKey(name: 'photo_url') String? photoUrl, Area? area,@JsonKey(name: 'onboarding_complete') bool onboardingComplete,@JsonKey(name: 'first_launch_tooltip_complete') bool firstLaunchTooltipComplete,@JsonKey(name: 'is_creator') bool isCreator
});


$AreaCopyWith<$Res>? get area;

}
/// @nodoc
class _$ProfileResponseCopyWithImpl<$Res>
    implements $ProfileResponseCopyWith<$Res> {
  _$ProfileResponseCopyWithImpl(this._self, this._then);

  final ProfileResponse _self;
  final $Res Function(ProfileResponse) _then;

/// Create a copy of ProfileResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? phone = null,Object? displayName = null,Object? username = null,Object? photoUrl = freezed,Object? area = freezed,Object? onboardingComplete = null,Object? firstLaunchTooltipComplete = null,Object? isCreator = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as Area?,onboardingComplete: null == onboardingComplete ? _self.onboardingComplete : onboardingComplete // ignore: cast_nullable_to_non_nullable
as bool,firstLaunchTooltipComplete: null == firstLaunchTooltipComplete ? _self.firstLaunchTooltipComplete : firstLaunchTooltipComplete // ignore: cast_nullable_to_non_nullable
as bool,isCreator: null == isCreator ? _self.isCreator : isCreator // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ProfileResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AreaCopyWith<$Res>? get area {
    if (_self.area == null) {
    return null;
  }

  return $AreaCopyWith<$Res>(_self.area!, (value) {
    return _then(_self.copyWith(area: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProfileResponse].
extension ProfileResponsePatterns on ProfileResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileResponse value)  $default,){
final _that = this;
switch (_that) {
case _ProfileResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String phone, @JsonKey(name: 'display_name')  String displayName,  String username, @JsonKey(name: 'photo_url')  String? photoUrl,  Area? area, @JsonKey(name: 'onboarding_complete')  bool onboardingComplete, @JsonKey(name: 'first_launch_tooltip_complete')  bool firstLaunchTooltipComplete, @JsonKey(name: 'is_creator')  bool isCreator)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileResponse() when $default != null:
return $default(_that.uid,_that.phone,_that.displayName,_that.username,_that.photoUrl,_that.area,_that.onboardingComplete,_that.firstLaunchTooltipComplete,_that.isCreator);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String phone, @JsonKey(name: 'display_name')  String displayName,  String username, @JsonKey(name: 'photo_url')  String? photoUrl,  Area? area, @JsonKey(name: 'onboarding_complete')  bool onboardingComplete, @JsonKey(name: 'first_launch_tooltip_complete')  bool firstLaunchTooltipComplete, @JsonKey(name: 'is_creator')  bool isCreator)  $default,) {final _that = this;
switch (_that) {
case _ProfileResponse():
return $default(_that.uid,_that.phone,_that.displayName,_that.username,_that.photoUrl,_that.area,_that.onboardingComplete,_that.firstLaunchTooltipComplete,_that.isCreator);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String phone, @JsonKey(name: 'display_name')  String displayName,  String username, @JsonKey(name: 'photo_url')  String? photoUrl,  Area? area, @JsonKey(name: 'onboarding_complete')  bool onboardingComplete, @JsonKey(name: 'first_launch_tooltip_complete')  bool firstLaunchTooltipComplete, @JsonKey(name: 'is_creator')  bool isCreator)?  $default,) {final _that = this;
switch (_that) {
case _ProfileResponse() when $default != null:
return $default(_that.uid,_that.phone,_that.displayName,_that.username,_that.photoUrl,_that.area,_that.onboardingComplete,_that.firstLaunchTooltipComplete,_that.isCreator);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileResponse implements ProfileResponse {
  const _ProfileResponse({required this.uid, required this.phone, @JsonKey(name: 'display_name') required this.displayName, required this.username, @JsonKey(name: 'photo_url') this.photoUrl, this.area, @JsonKey(name: 'onboarding_complete') required this.onboardingComplete, @JsonKey(name: 'first_launch_tooltip_complete') this.firstLaunchTooltipComplete = false, @JsonKey(name: 'is_creator') this.isCreator = false});
  factory _ProfileResponse.fromJson(Map<String, dynamic> json) => _$ProfileResponseFromJson(json);

@override final  String uid;
@override final  String phone;
@override@JsonKey(name: 'display_name') final  String displayName;
@override final  String username;
@override@JsonKey(name: 'photo_url') final  String? photoUrl;
@override final  Area? area;
@override@JsonKey(name: 'onboarding_complete') final  bool onboardingComplete;
@override@JsonKey(name: 'first_launch_tooltip_complete') final  bool firstLaunchTooltipComplete;
@override@JsonKey(name: 'is_creator') final  bool isCreator;

/// Create a copy of ProfileResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileResponseCopyWith<_ProfileResponse> get copyWith => __$ProfileResponseCopyWithImpl<_ProfileResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileResponse&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.area, area) || other.area == area)&&(identical(other.onboardingComplete, onboardingComplete) || other.onboardingComplete == onboardingComplete)&&(identical(other.firstLaunchTooltipComplete, firstLaunchTooltipComplete) || other.firstLaunchTooltipComplete == firstLaunchTooltipComplete)&&(identical(other.isCreator, isCreator) || other.isCreator == isCreator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,phone,displayName,username,photoUrl,area,onboardingComplete,firstLaunchTooltipComplete,isCreator);

@override
String toString() {
  return 'ProfileResponse(uid: $uid, phone: $phone, displayName: $displayName, username: $username, photoUrl: $photoUrl, area: $area, onboardingComplete: $onboardingComplete, firstLaunchTooltipComplete: $firstLaunchTooltipComplete, isCreator: $isCreator)';
}


}

/// @nodoc
abstract mixin class _$ProfileResponseCopyWith<$Res> implements $ProfileResponseCopyWith<$Res> {
  factory _$ProfileResponseCopyWith(_ProfileResponse value, $Res Function(_ProfileResponse) _then) = __$ProfileResponseCopyWithImpl;
@override @useResult
$Res call({
 String uid, String phone,@JsonKey(name: 'display_name') String displayName, String username,@JsonKey(name: 'photo_url') String? photoUrl, Area? area,@JsonKey(name: 'onboarding_complete') bool onboardingComplete,@JsonKey(name: 'first_launch_tooltip_complete') bool firstLaunchTooltipComplete,@JsonKey(name: 'is_creator') bool isCreator
});


@override $AreaCopyWith<$Res>? get area;

}
/// @nodoc
class __$ProfileResponseCopyWithImpl<$Res>
    implements _$ProfileResponseCopyWith<$Res> {
  __$ProfileResponseCopyWithImpl(this._self, this._then);

  final _ProfileResponse _self;
  final $Res Function(_ProfileResponse) _then;

/// Create a copy of ProfileResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? phone = null,Object? displayName = null,Object? username = null,Object? photoUrl = freezed,Object? area = freezed,Object? onboardingComplete = null,Object? firstLaunchTooltipComplete = null,Object? isCreator = null,}) {
  return _then(_ProfileResponse(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as Area?,onboardingComplete: null == onboardingComplete ? _self.onboardingComplete : onboardingComplete // ignore: cast_nullable_to_non_nullable
as bool,firstLaunchTooltipComplete: null == firstLaunchTooltipComplete ? _self.firstLaunchTooltipComplete : firstLaunchTooltipComplete // ignore: cast_nullable_to_non_nullable
as bool,isCreator: null == isCreator ? _self.isCreator : isCreator // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ProfileResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AreaCopyWith<$Res>? get area {
    if (_self.area == null) {
    return null;
  }

  return $AreaCopyWith<$Res>(_self.area!, (value) {
    return _then(_self.copyWith(area: value));
  });
}
}


/// @nodoc
mixin _$UsernameCheckResponse {

 String get username; bool get available;
/// Create a copy of UsernameCheckResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsernameCheckResponseCopyWith<UsernameCheckResponse> get copyWith => _$UsernameCheckResponseCopyWithImpl<UsernameCheckResponse>(this as UsernameCheckResponse, _$identity);

  /// Serializes this UsernameCheckResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsernameCheckResponse&&(identical(other.username, username) || other.username == username)&&(identical(other.available, available) || other.available == available));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,available);

@override
String toString() {
  return 'UsernameCheckResponse(username: $username, available: $available)';
}


}

/// @nodoc
abstract mixin class $UsernameCheckResponseCopyWith<$Res>  {
  factory $UsernameCheckResponseCopyWith(UsernameCheckResponse value, $Res Function(UsernameCheckResponse) _then) = _$UsernameCheckResponseCopyWithImpl;
@useResult
$Res call({
 String username, bool available
});




}
/// @nodoc
class _$UsernameCheckResponseCopyWithImpl<$Res>
    implements $UsernameCheckResponseCopyWith<$Res> {
  _$UsernameCheckResponseCopyWithImpl(this._self, this._then);

  final UsernameCheckResponse _self;
  final $Res Function(UsernameCheckResponse) _then;

/// Create a copy of UsernameCheckResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? available = null,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UsernameCheckResponse].
extension UsernameCheckResponsePatterns on UsernameCheckResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UsernameCheckResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UsernameCheckResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UsernameCheckResponse value)  $default,){
final _that = this;
switch (_that) {
case _UsernameCheckResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UsernameCheckResponse value)?  $default,){
final _that = this;
switch (_that) {
case _UsernameCheckResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  bool available)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UsernameCheckResponse() when $default != null:
return $default(_that.username,_that.available);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  bool available)  $default,) {final _that = this;
switch (_that) {
case _UsernameCheckResponse():
return $default(_that.username,_that.available);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  bool available)?  $default,) {final _that = this;
switch (_that) {
case _UsernameCheckResponse() when $default != null:
return $default(_that.username,_that.available);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UsernameCheckResponse implements UsernameCheckResponse {
  const _UsernameCheckResponse({required this.username, required this.available});
  factory _UsernameCheckResponse.fromJson(Map<String, dynamic> json) => _$UsernameCheckResponseFromJson(json);

@override final  String username;
@override final  bool available;

/// Create a copy of UsernameCheckResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsernameCheckResponseCopyWith<_UsernameCheckResponse> get copyWith => __$UsernameCheckResponseCopyWithImpl<_UsernameCheckResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UsernameCheckResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UsernameCheckResponse&&(identical(other.username, username) || other.username == username)&&(identical(other.available, available) || other.available == available));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,available);

@override
String toString() {
  return 'UsernameCheckResponse(username: $username, available: $available)';
}


}

/// @nodoc
abstract mixin class _$UsernameCheckResponseCopyWith<$Res> implements $UsernameCheckResponseCopyWith<$Res> {
  factory _$UsernameCheckResponseCopyWith(_UsernameCheckResponse value, $Res Function(_UsernameCheckResponse) _then) = __$UsernameCheckResponseCopyWithImpl;
@override @useResult
$Res call({
 String username, bool available
});




}
/// @nodoc
class __$UsernameCheckResponseCopyWithImpl<$Res>
    implements _$UsernameCheckResponseCopyWith<$Res> {
  __$UsernameCheckResponseCopyWithImpl(this._self, this._then);

  final _UsernameCheckResponse _self;
  final $Res Function(_UsernameCheckResponse) _then;

/// Create a copy of UsernameCheckResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? available = null,}) {
  return _then(_UsernameCheckResponse(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PhotoUploadResponse {

@JsonKey(name: 'upload_path') String get uploadPath;@JsonKey(name: 'photo_url') String get photoUrl;
/// Create a copy of PhotoUploadResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhotoUploadResponseCopyWith<PhotoUploadResponse> get copyWith => _$PhotoUploadResponseCopyWithImpl<PhotoUploadResponse>(this as PhotoUploadResponse, _$identity);

  /// Serializes this PhotoUploadResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhotoUploadResponse&&(identical(other.uploadPath, uploadPath) || other.uploadPath == uploadPath)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uploadPath,photoUrl);

@override
String toString() {
  return 'PhotoUploadResponse(uploadPath: $uploadPath, photoUrl: $photoUrl)';
}


}

/// @nodoc
abstract mixin class $PhotoUploadResponseCopyWith<$Res>  {
  factory $PhotoUploadResponseCopyWith(PhotoUploadResponse value, $Res Function(PhotoUploadResponse) _then) = _$PhotoUploadResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'upload_path') String uploadPath,@JsonKey(name: 'photo_url') String photoUrl
});




}
/// @nodoc
class _$PhotoUploadResponseCopyWithImpl<$Res>
    implements $PhotoUploadResponseCopyWith<$Res> {
  _$PhotoUploadResponseCopyWithImpl(this._self, this._then);

  final PhotoUploadResponse _self;
  final $Res Function(PhotoUploadResponse) _then;

/// Create a copy of PhotoUploadResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uploadPath = null,Object? photoUrl = null,}) {
  return _then(_self.copyWith(
uploadPath: null == uploadPath ? _self.uploadPath : uploadPath // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PhotoUploadResponse].
extension PhotoUploadResponsePatterns on PhotoUploadResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PhotoUploadResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PhotoUploadResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PhotoUploadResponse value)  $default,){
final _that = this;
switch (_that) {
case _PhotoUploadResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PhotoUploadResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PhotoUploadResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'upload_path')  String uploadPath, @JsonKey(name: 'photo_url')  String photoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PhotoUploadResponse() when $default != null:
return $default(_that.uploadPath,_that.photoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'upload_path')  String uploadPath, @JsonKey(name: 'photo_url')  String photoUrl)  $default,) {final _that = this;
switch (_that) {
case _PhotoUploadResponse():
return $default(_that.uploadPath,_that.photoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'upload_path')  String uploadPath, @JsonKey(name: 'photo_url')  String photoUrl)?  $default,) {final _that = this;
switch (_that) {
case _PhotoUploadResponse() when $default != null:
return $default(_that.uploadPath,_that.photoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PhotoUploadResponse implements PhotoUploadResponse {
  const _PhotoUploadResponse({@JsonKey(name: 'upload_path') required this.uploadPath, @JsonKey(name: 'photo_url') required this.photoUrl});
  factory _PhotoUploadResponse.fromJson(Map<String, dynamic> json) => _$PhotoUploadResponseFromJson(json);

@override@JsonKey(name: 'upload_path') final  String uploadPath;
@override@JsonKey(name: 'photo_url') final  String photoUrl;

/// Create a copy of PhotoUploadResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhotoUploadResponseCopyWith<_PhotoUploadResponse> get copyWith => __$PhotoUploadResponseCopyWithImpl<_PhotoUploadResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PhotoUploadResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhotoUploadResponse&&(identical(other.uploadPath, uploadPath) || other.uploadPath == uploadPath)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uploadPath,photoUrl);

@override
String toString() {
  return 'PhotoUploadResponse(uploadPath: $uploadPath, photoUrl: $photoUrl)';
}


}

/// @nodoc
abstract mixin class _$PhotoUploadResponseCopyWith<$Res> implements $PhotoUploadResponseCopyWith<$Res> {
  factory _$PhotoUploadResponseCopyWith(_PhotoUploadResponse value, $Res Function(_PhotoUploadResponse) _then) = __$PhotoUploadResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'upload_path') String uploadPath,@JsonKey(name: 'photo_url') String photoUrl
});




}
/// @nodoc
class __$PhotoUploadResponseCopyWithImpl<$Res>
    implements _$PhotoUploadResponseCopyWith<$Res> {
  __$PhotoUploadResponseCopyWithImpl(this._self, this._then);

  final _PhotoUploadResponse _self;
  final $Res Function(_PhotoUploadResponse) _then;

/// Create a copy of PhotoUploadResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uploadPath = null,Object? photoUrl = null,}) {
  return _then(_PhotoUploadResponse(
uploadPath: null == uploadPath ? _self.uploadPath : uploadPath // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
