// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionRequest {

@JsonKey(name: 'id_token') String get idToken;
/// Create a copy of SessionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionRequestCopyWith<SessionRequest> get copyWith => _$SessionRequestCopyWithImpl<SessionRequest>(this as SessionRequest, _$identity);

  /// Serializes this SessionRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionRequest&&(identical(other.idToken, idToken) || other.idToken == idToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,idToken);

@override
String toString() {
  return 'SessionRequest(idToken: $idToken)';
}


}

/// @nodoc
abstract mixin class $SessionRequestCopyWith<$Res>  {
  factory $SessionRequestCopyWith(SessionRequest value, $Res Function(SessionRequest) _then) = _$SessionRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id_token') String idToken
});




}
/// @nodoc
class _$SessionRequestCopyWithImpl<$Res>
    implements $SessionRequestCopyWith<$Res> {
  _$SessionRequestCopyWithImpl(this._self, this._then);

  final SessionRequest _self;
  final $Res Function(SessionRequest) _then;

/// Create a copy of SessionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? idToken = null,}) {
  return _then(_self.copyWith(
idToken: null == idToken ? _self.idToken : idToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionRequest].
extension SessionRequestPatterns on SessionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionRequest value)  $default,){
final _that = this;
switch (_that) {
case _SessionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SessionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id_token')  String idToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionRequest() when $default != null:
return $default(_that.idToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id_token')  String idToken)  $default,) {final _that = this;
switch (_that) {
case _SessionRequest():
return $default(_that.idToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id_token')  String idToken)?  $default,) {final _that = this;
switch (_that) {
case _SessionRequest() when $default != null:
return $default(_that.idToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionRequest implements SessionRequest {
  const _SessionRequest({@JsonKey(name: 'id_token') required this.idToken});
  factory _SessionRequest.fromJson(Map<String, dynamic> json) => _$SessionRequestFromJson(json);

@override@JsonKey(name: 'id_token') final  String idToken;

/// Create a copy of SessionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionRequestCopyWith<_SessionRequest> get copyWith => __$SessionRequestCopyWithImpl<_SessionRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionRequest&&(identical(other.idToken, idToken) || other.idToken == idToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,idToken);

@override
String toString() {
  return 'SessionRequest(idToken: $idToken)';
}


}

/// @nodoc
abstract mixin class _$SessionRequestCopyWith<$Res> implements $SessionRequestCopyWith<$Res> {
  factory _$SessionRequestCopyWith(_SessionRequest value, $Res Function(_SessionRequest) _then) = __$SessionRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id_token') String idToken
});




}
/// @nodoc
class __$SessionRequestCopyWithImpl<$Res>
    implements _$SessionRequestCopyWith<$Res> {
  __$SessionRequestCopyWithImpl(this._self, this._then);

  final _SessionRequest _self;
  final $Res Function(_SessionRequest) _then;

/// Create a copy of SessionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? idToken = null,}) {
  return _then(_SessionRequest(
idToken: null == idToken ? _self.idToken : idToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SessionResponse {

 String get uid; String get phone;@JsonKey(name: 'is_new') bool get isNew;@JsonKey(name: 'onboarding_complete') bool get onboardingComplete;@JsonKey(name: 'is_creator') bool get isCreator;
/// Create a copy of SessionResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionResponseCopyWith<SessionResponse> get copyWith => _$SessionResponseCopyWithImpl<SessionResponse>(this as SessionResponse, _$identity);

  /// Serializes this SessionResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionResponse&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isNew, isNew) || other.isNew == isNew)&&(identical(other.onboardingComplete, onboardingComplete) || other.onboardingComplete == onboardingComplete)&&(identical(other.isCreator, isCreator) || other.isCreator == isCreator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,phone,isNew,onboardingComplete,isCreator);

@override
String toString() {
  return 'SessionResponse(uid: $uid, phone: $phone, isNew: $isNew, onboardingComplete: $onboardingComplete, isCreator: $isCreator)';
}


}

/// @nodoc
abstract mixin class $SessionResponseCopyWith<$Res>  {
  factory $SessionResponseCopyWith(SessionResponse value, $Res Function(SessionResponse) _then) = _$SessionResponseCopyWithImpl;
@useResult
$Res call({
 String uid, String phone,@JsonKey(name: 'is_new') bool isNew,@JsonKey(name: 'onboarding_complete') bool onboardingComplete,@JsonKey(name: 'is_creator') bool isCreator
});




}
/// @nodoc
class _$SessionResponseCopyWithImpl<$Res>
    implements $SessionResponseCopyWith<$Res> {
  _$SessionResponseCopyWithImpl(this._self, this._then);

  final SessionResponse _self;
  final $Res Function(SessionResponse) _then;

/// Create a copy of SessionResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? phone = null,Object? isNew = null,Object? onboardingComplete = null,Object? isCreator = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isNew: null == isNew ? _self.isNew : isNew // ignore: cast_nullable_to_non_nullable
as bool,onboardingComplete: null == onboardingComplete ? _self.onboardingComplete : onboardingComplete // ignore: cast_nullable_to_non_nullable
as bool,isCreator: null == isCreator ? _self.isCreator : isCreator // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionResponse].
extension SessionResponsePatterns on SessionResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionResponse value)  $default,){
final _that = this;
switch (_that) {
case _SessionResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SessionResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String phone, @JsonKey(name: 'is_new')  bool isNew, @JsonKey(name: 'onboarding_complete')  bool onboardingComplete, @JsonKey(name: 'is_creator')  bool isCreator)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionResponse() when $default != null:
return $default(_that.uid,_that.phone,_that.isNew,_that.onboardingComplete,_that.isCreator);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String phone, @JsonKey(name: 'is_new')  bool isNew, @JsonKey(name: 'onboarding_complete')  bool onboardingComplete, @JsonKey(name: 'is_creator')  bool isCreator)  $default,) {final _that = this;
switch (_that) {
case _SessionResponse():
return $default(_that.uid,_that.phone,_that.isNew,_that.onboardingComplete,_that.isCreator);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String phone, @JsonKey(name: 'is_new')  bool isNew, @JsonKey(name: 'onboarding_complete')  bool onboardingComplete, @JsonKey(name: 'is_creator')  bool isCreator)?  $default,) {final _that = this;
switch (_that) {
case _SessionResponse() when $default != null:
return $default(_that.uid,_that.phone,_that.isNew,_that.onboardingComplete,_that.isCreator);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionResponse implements SessionResponse {
  const _SessionResponse({required this.uid, required this.phone, @JsonKey(name: 'is_new') required this.isNew, @JsonKey(name: 'onboarding_complete') required this.onboardingComplete, @JsonKey(name: 'is_creator') this.isCreator = false});
  factory _SessionResponse.fromJson(Map<String, dynamic> json) => _$SessionResponseFromJson(json);

@override final  String uid;
@override final  String phone;
@override@JsonKey(name: 'is_new') final  bool isNew;
@override@JsonKey(name: 'onboarding_complete') final  bool onboardingComplete;
@override@JsonKey(name: 'is_creator') final  bool isCreator;

/// Create a copy of SessionResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionResponseCopyWith<_SessionResponse> get copyWith => __$SessionResponseCopyWithImpl<_SessionResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionResponse&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isNew, isNew) || other.isNew == isNew)&&(identical(other.onboardingComplete, onboardingComplete) || other.onboardingComplete == onboardingComplete)&&(identical(other.isCreator, isCreator) || other.isCreator == isCreator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,phone,isNew,onboardingComplete,isCreator);

@override
String toString() {
  return 'SessionResponse(uid: $uid, phone: $phone, isNew: $isNew, onboardingComplete: $onboardingComplete, isCreator: $isCreator)';
}


}

/// @nodoc
abstract mixin class _$SessionResponseCopyWith<$Res> implements $SessionResponseCopyWith<$Res> {
  factory _$SessionResponseCopyWith(_SessionResponse value, $Res Function(_SessionResponse) _then) = __$SessionResponseCopyWithImpl;
@override @useResult
$Res call({
 String uid, String phone,@JsonKey(name: 'is_new') bool isNew,@JsonKey(name: 'onboarding_complete') bool onboardingComplete,@JsonKey(name: 'is_creator') bool isCreator
});




}
/// @nodoc
class __$SessionResponseCopyWithImpl<$Res>
    implements _$SessionResponseCopyWith<$Res> {
  __$SessionResponseCopyWithImpl(this._self, this._then);

  final _SessionResponse _self;
  final $Res Function(_SessionResponse) _then;

/// Create a copy of SessionResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? phone = null,Object? isNew = null,Object? onboardingComplete = null,Object? isCreator = null,}) {
  return _then(_SessionResponse(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isNew: null == isNew ? _self.isNew : isNew // ignore: cast_nullable_to_non_nullable
as bool,onboardingComplete: null == onboardingComplete ? _self.onboardingComplete : onboardingComplete // ignore: cast_nullable_to_non_nullable
as bool,isCreator: null == isCreator ? _self.isCreator : isCreator // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
