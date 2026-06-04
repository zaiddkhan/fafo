// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'creator_application.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreatorApplicationRequest {

 String get purpose;@JsonKey(name: 'social_links') List<String> get socialLinks; String get phone;@JsonKey(name: 'relevant_links') List<String> get relevantLinks;
/// Create a copy of CreatorApplicationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatorApplicationRequestCopyWith<CreatorApplicationRequest> get copyWith => _$CreatorApplicationRequestCopyWithImpl<CreatorApplicationRequest>(this as CreatorApplicationRequest, _$identity);

  /// Serializes this CreatorApplicationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatorApplicationRequest&&(identical(other.purpose, purpose) || other.purpose == purpose)&&const DeepCollectionEquality().equals(other.socialLinks, socialLinks)&&(identical(other.phone, phone) || other.phone == phone)&&const DeepCollectionEquality().equals(other.relevantLinks, relevantLinks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,purpose,const DeepCollectionEquality().hash(socialLinks),phone,const DeepCollectionEquality().hash(relevantLinks));

@override
String toString() {
  return 'CreatorApplicationRequest(purpose: $purpose, socialLinks: $socialLinks, phone: $phone, relevantLinks: $relevantLinks)';
}


}

/// @nodoc
abstract mixin class $CreatorApplicationRequestCopyWith<$Res>  {
  factory $CreatorApplicationRequestCopyWith(CreatorApplicationRequest value, $Res Function(CreatorApplicationRequest) _then) = _$CreatorApplicationRequestCopyWithImpl;
@useResult
$Res call({
 String purpose,@JsonKey(name: 'social_links') List<String> socialLinks, String phone,@JsonKey(name: 'relevant_links') List<String> relevantLinks
});




}
/// @nodoc
class _$CreatorApplicationRequestCopyWithImpl<$Res>
    implements $CreatorApplicationRequestCopyWith<$Res> {
  _$CreatorApplicationRequestCopyWithImpl(this._self, this._then);

  final CreatorApplicationRequest _self;
  final $Res Function(CreatorApplicationRequest) _then;

/// Create a copy of CreatorApplicationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? purpose = null,Object? socialLinks = null,Object? phone = null,Object? relevantLinks = null,}) {
  return _then(_self.copyWith(
purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,socialLinks: null == socialLinks ? _self.socialLinks : socialLinks // ignore: cast_nullable_to_non_nullable
as List<String>,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,relevantLinks: null == relevantLinks ? _self.relevantLinks : relevantLinks // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CreatorApplicationRequest].
extension CreatorApplicationRequestPatterns on CreatorApplicationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatorApplicationRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatorApplicationRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatorApplicationRequest value)  $default,){
final _that = this;
switch (_that) {
case _CreatorApplicationRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatorApplicationRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CreatorApplicationRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String purpose, @JsonKey(name: 'social_links')  List<String> socialLinks,  String phone, @JsonKey(name: 'relevant_links')  List<String> relevantLinks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatorApplicationRequest() when $default != null:
return $default(_that.purpose,_that.socialLinks,_that.phone,_that.relevantLinks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String purpose, @JsonKey(name: 'social_links')  List<String> socialLinks,  String phone, @JsonKey(name: 'relevant_links')  List<String> relevantLinks)  $default,) {final _that = this;
switch (_that) {
case _CreatorApplicationRequest():
return $default(_that.purpose,_that.socialLinks,_that.phone,_that.relevantLinks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String purpose, @JsonKey(name: 'social_links')  List<String> socialLinks,  String phone, @JsonKey(name: 'relevant_links')  List<String> relevantLinks)?  $default,) {final _that = this;
switch (_that) {
case _CreatorApplicationRequest() when $default != null:
return $default(_that.purpose,_that.socialLinks,_that.phone,_that.relevantLinks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreatorApplicationRequest implements CreatorApplicationRequest {
  const _CreatorApplicationRequest({required this.purpose, @JsonKey(name: 'social_links') final  List<String> socialLinks = const [], required this.phone, @JsonKey(name: 'relevant_links') final  List<String> relevantLinks = const []}): _socialLinks = socialLinks,_relevantLinks = relevantLinks;
  factory _CreatorApplicationRequest.fromJson(Map<String, dynamic> json) => _$CreatorApplicationRequestFromJson(json);

@override final  String purpose;
 final  List<String> _socialLinks;
@override@JsonKey(name: 'social_links') List<String> get socialLinks {
  if (_socialLinks is EqualUnmodifiableListView) return _socialLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_socialLinks);
}

@override final  String phone;
 final  List<String> _relevantLinks;
@override@JsonKey(name: 'relevant_links') List<String> get relevantLinks {
  if (_relevantLinks is EqualUnmodifiableListView) return _relevantLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relevantLinks);
}


/// Create a copy of CreatorApplicationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatorApplicationRequestCopyWith<_CreatorApplicationRequest> get copyWith => __$CreatorApplicationRequestCopyWithImpl<_CreatorApplicationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreatorApplicationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatorApplicationRequest&&(identical(other.purpose, purpose) || other.purpose == purpose)&&const DeepCollectionEquality().equals(other._socialLinks, _socialLinks)&&(identical(other.phone, phone) || other.phone == phone)&&const DeepCollectionEquality().equals(other._relevantLinks, _relevantLinks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,purpose,const DeepCollectionEquality().hash(_socialLinks),phone,const DeepCollectionEquality().hash(_relevantLinks));

@override
String toString() {
  return 'CreatorApplicationRequest(purpose: $purpose, socialLinks: $socialLinks, phone: $phone, relevantLinks: $relevantLinks)';
}


}

/// @nodoc
abstract mixin class _$CreatorApplicationRequestCopyWith<$Res> implements $CreatorApplicationRequestCopyWith<$Res> {
  factory _$CreatorApplicationRequestCopyWith(_CreatorApplicationRequest value, $Res Function(_CreatorApplicationRequest) _then) = __$CreatorApplicationRequestCopyWithImpl;
@override @useResult
$Res call({
 String purpose,@JsonKey(name: 'social_links') List<String> socialLinks, String phone,@JsonKey(name: 'relevant_links') List<String> relevantLinks
});




}
/// @nodoc
class __$CreatorApplicationRequestCopyWithImpl<$Res>
    implements _$CreatorApplicationRequestCopyWith<$Res> {
  __$CreatorApplicationRequestCopyWithImpl(this._self, this._then);

  final _CreatorApplicationRequest _self;
  final $Res Function(_CreatorApplicationRequest) _then;

/// Create a copy of CreatorApplicationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? purpose = null,Object? socialLinks = null,Object? phone = null,Object? relevantLinks = null,}) {
  return _then(_CreatorApplicationRequest(
purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,socialLinks: null == socialLinks ? _self._socialLinks : socialLinks // ignore: cast_nullable_to_non_nullable
as List<String>,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,relevantLinks: null == relevantLinks ? _self._relevantLinks : relevantLinks // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$CreatorApplicationResponse {

 String get uid; String get purpose;@JsonKey(name: 'social_links') List<String> get socialLinks; String get phone;@JsonKey(name: 'relevant_links') List<String> get relevantLinks; String get status;@JsonKey(name: 'submitted_at') DateTime get submittedAt;
/// Create a copy of CreatorApplicationResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatorApplicationResponseCopyWith<CreatorApplicationResponse> get copyWith => _$CreatorApplicationResponseCopyWithImpl<CreatorApplicationResponse>(this as CreatorApplicationResponse, _$identity);

  /// Serializes this CreatorApplicationResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatorApplicationResponse&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&const DeepCollectionEquality().equals(other.socialLinks, socialLinks)&&(identical(other.phone, phone) || other.phone == phone)&&const DeepCollectionEquality().equals(other.relevantLinks, relevantLinks)&&(identical(other.status, status) || other.status == status)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,purpose,const DeepCollectionEquality().hash(socialLinks),phone,const DeepCollectionEquality().hash(relevantLinks),status,submittedAt);

@override
String toString() {
  return 'CreatorApplicationResponse(uid: $uid, purpose: $purpose, socialLinks: $socialLinks, phone: $phone, relevantLinks: $relevantLinks, status: $status, submittedAt: $submittedAt)';
}


}

/// @nodoc
abstract mixin class $CreatorApplicationResponseCopyWith<$Res>  {
  factory $CreatorApplicationResponseCopyWith(CreatorApplicationResponse value, $Res Function(CreatorApplicationResponse) _then) = _$CreatorApplicationResponseCopyWithImpl;
@useResult
$Res call({
 String uid, String purpose,@JsonKey(name: 'social_links') List<String> socialLinks, String phone,@JsonKey(name: 'relevant_links') List<String> relevantLinks, String status,@JsonKey(name: 'submitted_at') DateTime submittedAt
});




}
/// @nodoc
class _$CreatorApplicationResponseCopyWithImpl<$Res>
    implements $CreatorApplicationResponseCopyWith<$Res> {
  _$CreatorApplicationResponseCopyWithImpl(this._self, this._then);

  final CreatorApplicationResponse _self;
  final $Res Function(CreatorApplicationResponse) _then;

/// Create a copy of CreatorApplicationResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? purpose = null,Object? socialLinks = null,Object? phone = null,Object? relevantLinks = null,Object? status = null,Object? submittedAt = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,socialLinks: null == socialLinks ? _self.socialLinks : socialLinks // ignore: cast_nullable_to_non_nullable
as List<String>,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,relevantLinks: null == relevantLinks ? _self.relevantLinks : relevantLinks // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CreatorApplicationResponse].
extension CreatorApplicationResponsePatterns on CreatorApplicationResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatorApplicationResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatorApplicationResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatorApplicationResponse value)  $default,){
final _that = this;
switch (_that) {
case _CreatorApplicationResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatorApplicationResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CreatorApplicationResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String purpose, @JsonKey(name: 'social_links')  List<String> socialLinks,  String phone, @JsonKey(name: 'relevant_links')  List<String> relevantLinks,  String status, @JsonKey(name: 'submitted_at')  DateTime submittedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatorApplicationResponse() when $default != null:
return $default(_that.uid,_that.purpose,_that.socialLinks,_that.phone,_that.relevantLinks,_that.status,_that.submittedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String purpose, @JsonKey(name: 'social_links')  List<String> socialLinks,  String phone, @JsonKey(name: 'relevant_links')  List<String> relevantLinks,  String status, @JsonKey(name: 'submitted_at')  DateTime submittedAt)  $default,) {final _that = this;
switch (_that) {
case _CreatorApplicationResponse():
return $default(_that.uid,_that.purpose,_that.socialLinks,_that.phone,_that.relevantLinks,_that.status,_that.submittedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String purpose, @JsonKey(name: 'social_links')  List<String> socialLinks,  String phone, @JsonKey(name: 'relevant_links')  List<String> relevantLinks,  String status, @JsonKey(name: 'submitted_at')  DateTime submittedAt)?  $default,) {final _that = this;
switch (_that) {
case _CreatorApplicationResponse() when $default != null:
return $default(_that.uid,_that.purpose,_that.socialLinks,_that.phone,_that.relevantLinks,_that.status,_that.submittedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreatorApplicationResponse implements CreatorApplicationResponse {
  const _CreatorApplicationResponse({required this.uid, required this.purpose, @JsonKey(name: 'social_links') required final  List<String> socialLinks, required this.phone, @JsonKey(name: 'relevant_links') required final  List<String> relevantLinks, required this.status, @JsonKey(name: 'submitted_at') required this.submittedAt}): _socialLinks = socialLinks,_relevantLinks = relevantLinks;
  factory _CreatorApplicationResponse.fromJson(Map<String, dynamic> json) => _$CreatorApplicationResponseFromJson(json);

@override final  String uid;
@override final  String purpose;
 final  List<String> _socialLinks;
@override@JsonKey(name: 'social_links') List<String> get socialLinks {
  if (_socialLinks is EqualUnmodifiableListView) return _socialLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_socialLinks);
}

@override final  String phone;
 final  List<String> _relevantLinks;
@override@JsonKey(name: 'relevant_links') List<String> get relevantLinks {
  if (_relevantLinks is EqualUnmodifiableListView) return _relevantLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relevantLinks);
}

@override final  String status;
@override@JsonKey(name: 'submitted_at') final  DateTime submittedAt;

/// Create a copy of CreatorApplicationResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatorApplicationResponseCopyWith<_CreatorApplicationResponse> get copyWith => __$CreatorApplicationResponseCopyWithImpl<_CreatorApplicationResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreatorApplicationResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatorApplicationResponse&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&const DeepCollectionEquality().equals(other._socialLinks, _socialLinks)&&(identical(other.phone, phone) || other.phone == phone)&&const DeepCollectionEquality().equals(other._relevantLinks, _relevantLinks)&&(identical(other.status, status) || other.status == status)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,purpose,const DeepCollectionEquality().hash(_socialLinks),phone,const DeepCollectionEquality().hash(_relevantLinks),status,submittedAt);

@override
String toString() {
  return 'CreatorApplicationResponse(uid: $uid, purpose: $purpose, socialLinks: $socialLinks, phone: $phone, relevantLinks: $relevantLinks, status: $status, submittedAt: $submittedAt)';
}


}

/// @nodoc
abstract mixin class _$CreatorApplicationResponseCopyWith<$Res> implements $CreatorApplicationResponseCopyWith<$Res> {
  factory _$CreatorApplicationResponseCopyWith(_CreatorApplicationResponse value, $Res Function(_CreatorApplicationResponse) _then) = __$CreatorApplicationResponseCopyWithImpl;
@override @useResult
$Res call({
 String uid, String purpose,@JsonKey(name: 'social_links') List<String> socialLinks, String phone,@JsonKey(name: 'relevant_links') List<String> relevantLinks, String status,@JsonKey(name: 'submitted_at') DateTime submittedAt
});




}
/// @nodoc
class __$CreatorApplicationResponseCopyWithImpl<$Res>
    implements _$CreatorApplicationResponseCopyWith<$Res> {
  __$CreatorApplicationResponseCopyWithImpl(this._self, this._then);

  final _CreatorApplicationResponse _self;
  final $Res Function(_CreatorApplicationResponse) _then;

/// Create a copy of CreatorApplicationResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? purpose = null,Object? socialLinks = null,Object? phone = null,Object? relevantLinks = null,Object? status = null,Object? submittedAt = null,}) {
  return _then(_CreatorApplicationResponse(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,socialLinks: null == socialLinks ? _self._socialLinks : socialLinks // ignore: cast_nullable_to_non_nullable
as List<String>,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,relevantLinks: null == relevantLinks ? _self._relevantLinks : relevantLinks // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
