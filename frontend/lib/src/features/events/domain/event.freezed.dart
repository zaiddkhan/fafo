// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventResponse {

 String get id;@JsonKey(name: 'creator_uid') String get creatorUid; String get title; String? get description;@JsonKey(name: 'category_id') String get categoryId;@JsonKey(name: 'event_type') EventType get eventType;@JsonKey(name: 'custom_emoji') String? get customEmoji; double get lat; double get lng;@JsonKey(name: 'location_name') String get locationName; String? get address;@JsonKey(name: 'location_details') String? get locationDetails;@JsonKey(name: 'date_time') DateTime get dateTime; int? get capacity;@JsonKey(name: 'joinee_count') int get joineeCount;@JsonKey(name: 'registration_open') bool get registrationOpen; bool get cancelled;@JsonKey(name: 'banner_url') String? get bannerUrl;@JsonKey(name: 'organizer_name') String? get organizerName;@JsonKey(name: 'organizer_contact') String? get organizerContact;@JsonKey(name: 'organizer_instagram') String? get organizerInstagram;@JsonKey(name: 'is_joined') bool get isJoined;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of EventResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventResponseCopyWith<EventResponse> get copyWith => _$EventResponseCopyWithImpl<EventResponse>(this as EventResponse, _$identity);

  /// Serializes this EventResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.creatorUid, creatorUid) || other.creatorUid == creatorUid)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.customEmoji, customEmoji) || other.customEmoji == customEmoji)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.address, address) || other.address == address)&&(identical(other.locationDetails, locationDetails) || other.locationDetails == locationDetails)&&(identical(other.dateTime, dateTime) || other.dateTime == dateTime)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.joineeCount, joineeCount) || other.joineeCount == joineeCount)&&(identical(other.registrationOpen, registrationOpen) || other.registrationOpen == registrationOpen)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled)&&(identical(other.bannerUrl, bannerUrl) || other.bannerUrl == bannerUrl)&&(identical(other.organizerName, organizerName) || other.organizerName == organizerName)&&(identical(other.organizerContact, organizerContact) || other.organizerContact == organizerContact)&&(identical(other.organizerInstagram, organizerInstagram) || other.organizerInstagram == organizerInstagram)&&(identical(other.isJoined, isJoined) || other.isJoined == isJoined)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,creatorUid,title,description,categoryId,eventType,customEmoji,lat,lng,locationName,address,locationDetails,dateTime,capacity,joineeCount,registrationOpen,cancelled,bannerUrl,organizerName,organizerContact,organizerInstagram,isJoined,createdAt,updatedAt]);

@override
String toString() {
  return 'EventResponse(id: $id, creatorUid: $creatorUid, title: $title, description: $description, categoryId: $categoryId, eventType: $eventType, customEmoji: $customEmoji, lat: $lat, lng: $lng, locationName: $locationName, address: $address, locationDetails: $locationDetails, dateTime: $dateTime, capacity: $capacity, joineeCount: $joineeCount, registrationOpen: $registrationOpen, cancelled: $cancelled, bannerUrl: $bannerUrl, organizerName: $organizerName, organizerContact: $organizerContact, organizerInstagram: $organizerInstagram, isJoined: $isJoined, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $EventResponseCopyWith<$Res>  {
  factory $EventResponseCopyWith(EventResponse value, $Res Function(EventResponse) _then) = _$EventResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'creator_uid') String creatorUid, String title, String? description,@JsonKey(name: 'category_id') String categoryId,@JsonKey(name: 'event_type') EventType eventType,@JsonKey(name: 'custom_emoji') String? customEmoji, double lat, double lng,@JsonKey(name: 'location_name') String locationName, String? address,@JsonKey(name: 'location_details') String? locationDetails,@JsonKey(name: 'date_time') DateTime dateTime, int? capacity,@JsonKey(name: 'joinee_count') int joineeCount,@JsonKey(name: 'registration_open') bool registrationOpen, bool cancelled,@JsonKey(name: 'banner_url') String? bannerUrl,@JsonKey(name: 'organizer_name') String? organizerName,@JsonKey(name: 'organizer_contact') String? organizerContact,@JsonKey(name: 'organizer_instagram') String? organizerInstagram,@JsonKey(name: 'is_joined') bool isJoined,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$EventResponseCopyWithImpl<$Res>
    implements $EventResponseCopyWith<$Res> {
  _$EventResponseCopyWithImpl(this._self, this._then);

  final EventResponse _self;
  final $Res Function(EventResponse) _then;

/// Create a copy of EventResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? creatorUid = null,Object? title = null,Object? description = freezed,Object? categoryId = null,Object? eventType = null,Object? customEmoji = freezed,Object? lat = null,Object? lng = null,Object? locationName = null,Object? address = freezed,Object? locationDetails = freezed,Object? dateTime = null,Object? capacity = freezed,Object? joineeCount = null,Object? registrationOpen = null,Object? cancelled = null,Object? bannerUrl = freezed,Object? organizerName = freezed,Object? organizerContact = freezed,Object? organizerInstagram = freezed,Object? isJoined = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,creatorUid: null == creatorUid ? _self.creatorUid : creatorUid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as EventType,customEmoji: freezed == customEmoji ? _self.customEmoji : customEmoji // ignore: cast_nullable_to_non_nullable
as String?,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,locationName: null == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,locationDetails: freezed == locationDetails ? _self.locationDetails : locationDetails // ignore: cast_nullable_to_non_nullable
as String?,dateTime: null == dateTime ? _self.dateTime : dateTime // ignore: cast_nullable_to_non_nullable
as DateTime,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,joineeCount: null == joineeCount ? _self.joineeCount : joineeCount // ignore: cast_nullable_to_non_nullable
as int,registrationOpen: null == registrationOpen ? _self.registrationOpen : registrationOpen // ignore: cast_nullable_to_non_nullable
as bool,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as bool,bannerUrl: freezed == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String?,organizerName: freezed == organizerName ? _self.organizerName : organizerName // ignore: cast_nullable_to_non_nullable
as String?,organizerContact: freezed == organizerContact ? _self.organizerContact : organizerContact // ignore: cast_nullable_to_non_nullable
as String?,organizerInstagram: freezed == organizerInstagram ? _self.organizerInstagram : organizerInstagram // ignore: cast_nullable_to_non_nullable
as String?,isJoined: null == isJoined ? _self.isJoined : isJoined // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [EventResponse].
extension EventResponsePatterns on EventResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventResponse value)  $default,){
final _that = this;
switch (_that) {
case _EventResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventResponse value)?  $default,){
final _that = this;
switch (_that) {
case _EventResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'creator_uid')  String creatorUid,  String title,  String? description, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'event_type')  EventType eventType, @JsonKey(name: 'custom_emoji')  String? customEmoji,  double lat,  double lng, @JsonKey(name: 'location_name')  String locationName,  String? address, @JsonKey(name: 'location_details')  String? locationDetails, @JsonKey(name: 'date_time')  DateTime dateTime,  int? capacity, @JsonKey(name: 'joinee_count')  int joineeCount, @JsonKey(name: 'registration_open')  bool registrationOpen,  bool cancelled, @JsonKey(name: 'banner_url')  String? bannerUrl, @JsonKey(name: 'organizer_name')  String? organizerName, @JsonKey(name: 'organizer_contact')  String? organizerContact, @JsonKey(name: 'organizer_instagram')  String? organizerInstagram, @JsonKey(name: 'is_joined')  bool isJoined, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventResponse() when $default != null:
return $default(_that.id,_that.creatorUid,_that.title,_that.description,_that.categoryId,_that.eventType,_that.customEmoji,_that.lat,_that.lng,_that.locationName,_that.address,_that.locationDetails,_that.dateTime,_that.capacity,_that.joineeCount,_that.registrationOpen,_that.cancelled,_that.bannerUrl,_that.organizerName,_that.organizerContact,_that.organizerInstagram,_that.isJoined,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'creator_uid')  String creatorUid,  String title,  String? description, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'event_type')  EventType eventType, @JsonKey(name: 'custom_emoji')  String? customEmoji,  double lat,  double lng, @JsonKey(name: 'location_name')  String locationName,  String? address, @JsonKey(name: 'location_details')  String? locationDetails, @JsonKey(name: 'date_time')  DateTime dateTime,  int? capacity, @JsonKey(name: 'joinee_count')  int joineeCount, @JsonKey(name: 'registration_open')  bool registrationOpen,  bool cancelled, @JsonKey(name: 'banner_url')  String? bannerUrl, @JsonKey(name: 'organizer_name')  String? organizerName, @JsonKey(name: 'organizer_contact')  String? organizerContact, @JsonKey(name: 'organizer_instagram')  String? organizerInstagram, @JsonKey(name: 'is_joined')  bool isJoined, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _EventResponse():
return $default(_that.id,_that.creatorUid,_that.title,_that.description,_that.categoryId,_that.eventType,_that.customEmoji,_that.lat,_that.lng,_that.locationName,_that.address,_that.locationDetails,_that.dateTime,_that.capacity,_that.joineeCount,_that.registrationOpen,_that.cancelled,_that.bannerUrl,_that.organizerName,_that.organizerContact,_that.organizerInstagram,_that.isJoined,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'creator_uid')  String creatorUid,  String title,  String? description, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'event_type')  EventType eventType, @JsonKey(name: 'custom_emoji')  String? customEmoji,  double lat,  double lng, @JsonKey(name: 'location_name')  String locationName,  String? address, @JsonKey(name: 'location_details')  String? locationDetails, @JsonKey(name: 'date_time')  DateTime dateTime,  int? capacity, @JsonKey(name: 'joinee_count')  int joineeCount, @JsonKey(name: 'registration_open')  bool registrationOpen,  bool cancelled, @JsonKey(name: 'banner_url')  String? bannerUrl, @JsonKey(name: 'organizer_name')  String? organizerName, @JsonKey(name: 'organizer_contact')  String? organizerContact, @JsonKey(name: 'organizer_instagram')  String? organizerInstagram, @JsonKey(name: 'is_joined')  bool isJoined, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _EventResponse() when $default != null:
return $default(_that.id,_that.creatorUid,_that.title,_that.description,_that.categoryId,_that.eventType,_that.customEmoji,_that.lat,_that.lng,_that.locationName,_that.address,_that.locationDetails,_that.dateTime,_that.capacity,_that.joineeCount,_that.registrationOpen,_that.cancelled,_that.bannerUrl,_that.organizerName,_that.organizerContact,_that.organizerInstagram,_that.isJoined,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventResponse implements EventResponse {
  const _EventResponse({required this.id, @JsonKey(name: 'creator_uid') required this.creatorUid, required this.title, this.description, @JsonKey(name: 'category_id') required this.categoryId, @JsonKey(name: 'event_type') required this.eventType, @JsonKey(name: 'custom_emoji') this.customEmoji, required this.lat, required this.lng, @JsonKey(name: 'location_name') required this.locationName, this.address, @JsonKey(name: 'location_details') this.locationDetails, @JsonKey(name: 'date_time') required this.dateTime, this.capacity, @JsonKey(name: 'joinee_count') required this.joineeCount, @JsonKey(name: 'registration_open') required this.registrationOpen, required this.cancelled, @JsonKey(name: 'banner_url') this.bannerUrl, @JsonKey(name: 'organizer_name') this.organizerName, @JsonKey(name: 'organizer_contact') this.organizerContact, @JsonKey(name: 'organizer_instagram') this.organizerInstagram, @JsonKey(name: 'is_joined') this.isJoined = false, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _EventResponse.fromJson(Map<String, dynamic> json) => _$EventResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'creator_uid') final  String creatorUid;
@override final  String title;
@override final  String? description;
@override@JsonKey(name: 'category_id') final  String categoryId;
@override@JsonKey(name: 'event_type') final  EventType eventType;
@override@JsonKey(name: 'custom_emoji') final  String? customEmoji;
@override final  double lat;
@override final  double lng;
@override@JsonKey(name: 'location_name') final  String locationName;
@override final  String? address;
@override@JsonKey(name: 'location_details') final  String? locationDetails;
@override@JsonKey(name: 'date_time') final  DateTime dateTime;
@override final  int? capacity;
@override@JsonKey(name: 'joinee_count') final  int joineeCount;
@override@JsonKey(name: 'registration_open') final  bool registrationOpen;
@override final  bool cancelled;
@override@JsonKey(name: 'banner_url') final  String? bannerUrl;
@override@JsonKey(name: 'organizer_name') final  String? organizerName;
@override@JsonKey(name: 'organizer_contact') final  String? organizerContact;
@override@JsonKey(name: 'organizer_instagram') final  String? organizerInstagram;
@override@JsonKey(name: 'is_joined') final  bool isJoined;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of EventResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventResponseCopyWith<_EventResponse> get copyWith => __$EventResponseCopyWithImpl<_EventResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.creatorUid, creatorUid) || other.creatorUid == creatorUid)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.customEmoji, customEmoji) || other.customEmoji == customEmoji)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.address, address) || other.address == address)&&(identical(other.locationDetails, locationDetails) || other.locationDetails == locationDetails)&&(identical(other.dateTime, dateTime) || other.dateTime == dateTime)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.joineeCount, joineeCount) || other.joineeCount == joineeCount)&&(identical(other.registrationOpen, registrationOpen) || other.registrationOpen == registrationOpen)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled)&&(identical(other.bannerUrl, bannerUrl) || other.bannerUrl == bannerUrl)&&(identical(other.organizerName, organizerName) || other.organizerName == organizerName)&&(identical(other.organizerContact, organizerContact) || other.organizerContact == organizerContact)&&(identical(other.organizerInstagram, organizerInstagram) || other.organizerInstagram == organizerInstagram)&&(identical(other.isJoined, isJoined) || other.isJoined == isJoined)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,creatorUid,title,description,categoryId,eventType,customEmoji,lat,lng,locationName,address,locationDetails,dateTime,capacity,joineeCount,registrationOpen,cancelled,bannerUrl,organizerName,organizerContact,organizerInstagram,isJoined,createdAt,updatedAt]);

@override
String toString() {
  return 'EventResponse(id: $id, creatorUid: $creatorUid, title: $title, description: $description, categoryId: $categoryId, eventType: $eventType, customEmoji: $customEmoji, lat: $lat, lng: $lng, locationName: $locationName, address: $address, locationDetails: $locationDetails, dateTime: $dateTime, capacity: $capacity, joineeCount: $joineeCount, registrationOpen: $registrationOpen, cancelled: $cancelled, bannerUrl: $bannerUrl, organizerName: $organizerName, organizerContact: $organizerContact, organizerInstagram: $organizerInstagram, isJoined: $isJoined, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$EventResponseCopyWith<$Res> implements $EventResponseCopyWith<$Res> {
  factory _$EventResponseCopyWith(_EventResponse value, $Res Function(_EventResponse) _then) = __$EventResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'creator_uid') String creatorUid, String title, String? description,@JsonKey(name: 'category_id') String categoryId,@JsonKey(name: 'event_type') EventType eventType,@JsonKey(name: 'custom_emoji') String? customEmoji, double lat, double lng,@JsonKey(name: 'location_name') String locationName, String? address,@JsonKey(name: 'location_details') String? locationDetails,@JsonKey(name: 'date_time') DateTime dateTime, int? capacity,@JsonKey(name: 'joinee_count') int joineeCount,@JsonKey(name: 'registration_open') bool registrationOpen, bool cancelled,@JsonKey(name: 'banner_url') String? bannerUrl,@JsonKey(name: 'organizer_name') String? organizerName,@JsonKey(name: 'organizer_contact') String? organizerContact,@JsonKey(name: 'organizer_instagram') String? organizerInstagram,@JsonKey(name: 'is_joined') bool isJoined,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$EventResponseCopyWithImpl<$Res>
    implements _$EventResponseCopyWith<$Res> {
  __$EventResponseCopyWithImpl(this._self, this._then);

  final _EventResponse _self;
  final $Res Function(_EventResponse) _then;

/// Create a copy of EventResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? creatorUid = null,Object? title = null,Object? description = freezed,Object? categoryId = null,Object? eventType = null,Object? customEmoji = freezed,Object? lat = null,Object? lng = null,Object? locationName = null,Object? address = freezed,Object? locationDetails = freezed,Object? dateTime = null,Object? capacity = freezed,Object? joineeCount = null,Object? registrationOpen = null,Object? cancelled = null,Object? bannerUrl = freezed,Object? organizerName = freezed,Object? organizerContact = freezed,Object? organizerInstagram = freezed,Object? isJoined = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_EventResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,creatorUid: null == creatorUid ? _self.creatorUid : creatorUid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as EventType,customEmoji: freezed == customEmoji ? _self.customEmoji : customEmoji // ignore: cast_nullable_to_non_nullable
as String?,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,locationName: null == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,locationDetails: freezed == locationDetails ? _self.locationDetails : locationDetails // ignore: cast_nullable_to_non_nullable
as String?,dateTime: null == dateTime ? _self.dateTime : dateTime // ignore: cast_nullable_to_non_nullable
as DateTime,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,joineeCount: null == joineeCount ? _self.joineeCount : joineeCount // ignore: cast_nullable_to_non_nullable
as int,registrationOpen: null == registrationOpen ? _self.registrationOpen : registrationOpen // ignore: cast_nullable_to_non_nullable
as bool,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as bool,bannerUrl: freezed == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String?,organizerName: freezed == organizerName ? _self.organizerName : organizerName // ignore: cast_nullable_to_non_nullable
as String?,organizerContact: freezed == organizerContact ? _self.organizerContact : organizerContact // ignore: cast_nullable_to_non_nullable
as String?,organizerInstagram: freezed == organizerInstagram ? _self.organizerInstagram : organizerInstagram // ignore: cast_nullable_to_non_nullable
as String?,isJoined: null == isJoined ? _self.isJoined : isJoined // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$EventCreateRequest {

 String get title; String? get description;@JsonKey(name: 'category_id') String get categoryId;@JsonKey(name: 'event_type') EventType get eventType;@JsonKey(name: 'custom_emoji') String? get customEmoji; double get lat; double get lng;@JsonKey(name: 'location_name') String get locationName; String? get address;@JsonKey(name: 'location_details') String? get locationDetails;@JsonKey(name: 'date_time') DateTime get dateTime; int? get capacity;@JsonKey(name: 'organizer_name') String? get organizerName;@JsonKey(name: 'organizer_contact') String? get organizerContact;@JsonKey(name: 'organizer_instagram') String? get organizerInstagram;
/// Create a copy of EventCreateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventCreateRequestCopyWith<EventCreateRequest> get copyWith => _$EventCreateRequestCopyWithImpl<EventCreateRequest>(this as EventCreateRequest, _$identity);

  /// Serializes this EventCreateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventCreateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.customEmoji, customEmoji) || other.customEmoji == customEmoji)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.address, address) || other.address == address)&&(identical(other.locationDetails, locationDetails) || other.locationDetails == locationDetails)&&(identical(other.dateTime, dateTime) || other.dateTime == dateTime)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.organizerName, organizerName) || other.organizerName == organizerName)&&(identical(other.organizerContact, organizerContact) || other.organizerContact == organizerContact)&&(identical(other.organizerInstagram, organizerInstagram) || other.organizerInstagram == organizerInstagram));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,categoryId,eventType,customEmoji,lat,lng,locationName,address,locationDetails,dateTime,capacity,organizerName,organizerContact,organizerInstagram);

@override
String toString() {
  return 'EventCreateRequest(title: $title, description: $description, categoryId: $categoryId, eventType: $eventType, customEmoji: $customEmoji, lat: $lat, lng: $lng, locationName: $locationName, address: $address, locationDetails: $locationDetails, dateTime: $dateTime, capacity: $capacity, organizerName: $organizerName, organizerContact: $organizerContact, organizerInstagram: $organizerInstagram)';
}


}

/// @nodoc
abstract mixin class $EventCreateRequestCopyWith<$Res>  {
  factory $EventCreateRequestCopyWith(EventCreateRequest value, $Res Function(EventCreateRequest) _then) = _$EventCreateRequestCopyWithImpl;
@useResult
$Res call({
 String title, String? description,@JsonKey(name: 'category_id') String categoryId,@JsonKey(name: 'event_type') EventType eventType,@JsonKey(name: 'custom_emoji') String? customEmoji, double lat, double lng,@JsonKey(name: 'location_name') String locationName, String? address,@JsonKey(name: 'location_details') String? locationDetails,@JsonKey(name: 'date_time') DateTime dateTime, int? capacity,@JsonKey(name: 'organizer_name') String? organizerName,@JsonKey(name: 'organizer_contact') String? organizerContact,@JsonKey(name: 'organizer_instagram') String? organizerInstagram
});




}
/// @nodoc
class _$EventCreateRequestCopyWithImpl<$Res>
    implements $EventCreateRequestCopyWith<$Res> {
  _$EventCreateRequestCopyWithImpl(this._self, this._then);

  final EventCreateRequest _self;
  final $Res Function(EventCreateRequest) _then;

/// Create a copy of EventCreateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = freezed,Object? categoryId = null,Object? eventType = null,Object? customEmoji = freezed,Object? lat = null,Object? lng = null,Object? locationName = null,Object? address = freezed,Object? locationDetails = freezed,Object? dateTime = null,Object? capacity = freezed,Object? organizerName = freezed,Object? organizerContact = freezed,Object? organizerInstagram = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as EventType,customEmoji: freezed == customEmoji ? _self.customEmoji : customEmoji // ignore: cast_nullable_to_non_nullable
as String?,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,locationName: null == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,locationDetails: freezed == locationDetails ? _self.locationDetails : locationDetails // ignore: cast_nullable_to_non_nullable
as String?,dateTime: null == dateTime ? _self.dateTime : dateTime // ignore: cast_nullable_to_non_nullable
as DateTime,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,organizerName: freezed == organizerName ? _self.organizerName : organizerName // ignore: cast_nullable_to_non_nullable
as String?,organizerContact: freezed == organizerContact ? _self.organizerContact : organizerContact // ignore: cast_nullable_to_non_nullable
as String?,organizerInstagram: freezed == organizerInstagram ? _self.organizerInstagram : organizerInstagram // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventCreateRequest].
extension EventCreateRequestPatterns on EventCreateRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventCreateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventCreateRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventCreateRequest value)  $default,){
final _that = this;
switch (_that) {
case _EventCreateRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventCreateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _EventCreateRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String? description, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'event_type')  EventType eventType, @JsonKey(name: 'custom_emoji')  String? customEmoji,  double lat,  double lng, @JsonKey(name: 'location_name')  String locationName,  String? address, @JsonKey(name: 'location_details')  String? locationDetails, @JsonKey(name: 'date_time')  DateTime dateTime,  int? capacity, @JsonKey(name: 'organizer_name')  String? organizerName, @JsonKey(name: 'organizer_contact')  String? organizerContact, @JsonKey(name: 'organizer_instagram')  String? organizerInstagram)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventCreateRequest() when $default != null:
return $default(_that.title,_that.description,_that.categoryId,_that.eventType,_that.customEmoji,_that.lat,_that.lng,_that.locationName,_that.address,_that.locationDetails,_that.dateTime,_that.capacity,_that.organizerName,_that.organizerContact,_that.organizerInstagram);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String? description, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'event_type')  EventType eventType, @JsonKey(name: 'custom_emoji')  String? customEmoji,  double lat,  double lng, @JsonKey(name: 'location_name')  String locationName,  String? address, @JsonKey(name: 'location_details')  String? locationDetails, @JsonKey(name: 'date_time')  DateTime dateTime,  int? capacity, @JsonKey(name: 'organizer_name')  String? organizerName, @JsonKey(name: 'organizer_contact')  String? organizerContact, @JsonKey(name: 'organizer_instagram')  String? organizerInstagram)  $default,) {final _that = this;
switch (_that) {
case _EventCreateRequest():
return $default(_that.title,_that.description,_that.categoryId,_that.eventType,_that.customEmoji,_that.lat,_that.lng,_that.locationName,_that.address,_that.locationDetails,_that.dateTime,_that.capacity,_that.organizerName,_that.organizerContact,_that.organizerInstagram);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String? description, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'event_type')  EventType eventType, @JsonKey(name: 'custom_emoji')  String? customEmoji,  double lat,  double lng, @JsonKey(name: 'location_name')  String locationName,  String? address, @JsonKey(name: 'location_details')  String? locationDetails, @JsonKey(name: 'date_time')  DateTime dateTime,  int? capacity, @JsonKey(name: 'organizer_name')  String? organizerName, @JsonKey(name: 'organizer_contact')  String? organizerContact, @JsonKey(name: 'organizer_instagram')  String? organizerInstagram)?  $default,) {final _that = this;
switch (_that) {
case _EventCreateRequest() when $default != null:
return $default(_that.title,_that.description,_that.categoryId,_that.eventType,_that.customEmoji,_that.lat,_that.lng,_that.locationName,_that.address,_that.locationDetails,_that.dateTime,_that.capacity,_that.organizerName,_that.organizerContact,_that.organizerInstagram);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventCreateRequest implements EventCreateRequest {
  const _EventCreateRequest({required this.title, this.description, @JsonKey(name: 'category_id') required this.categoryId, @JsonKey(name: 'event_type') this.eventType = EventType.normal, @JsonKey(name: 'custom_emoji') this.customEmoji, required this.lat, required this.lng, @JsonKey(name: 'location_name') required this.locationName, this.address, @JsonKey(name: 'location_details') this.locationDetails, @JsonKey(name: 'date_time') required this.dateTime, this.capacity, @JsonKey(name: 'organizer_name') this.organizerName, @JsonKey(name: 'organizer_contact') this.organizerContact, @JsonKey(name: 'organizer_instagram') this.organizerInstagram});
  factory _EventCreateRequest.fromJson(Map<String, dynamic> json) => _$EventCreateRequestFromJson(json);

@override final  String title;
@override final  String? description;
@override@JsonKey(name: 'category_id') final  String categoryId;
@override@JsonKey(name: 'event_type') final  EventType eventType;
@override@JsonKey(name: 'custom_emoji') final  String? customEmoji;
@override final  double lat;
@override final  double lng;
@override@JsonKey(name: 'location_name') final  String locationName;
@override final  String? address;
@override@JsonKey(name: 'location_details') final  String? locationDetails;
@override@JsonKey(name: 'date_time') final  DateTime dateTime;
@override final  int? capacity;
@override@JsonKey(name: 'organizer_name') final  String? organizerName;
@override@JsonKey(name: 'organizer_contact') final  String? organizerContact;
@override@JsonKey(name: 'organizer_instagram') final  String? organizerInstagram;

/// Create a copy of EventCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventCreateRequestCopyWith<_EventCreateRequest> get copyWith => __$EventCreateRequestCopyWithImpl<_EventCreateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventCreateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventCreateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.customEmoji, customEmoji) || other.customEmoji == customEmoji)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.address, address) || other.address == address)&&(identical(other.locationDetails, locationDetails) || other.locationDetails == locationDetails)&&(identical(other.dateTime, dateTime) || other.dateTime == dateTime)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.organizerName, organizerName) || other.organizerName == organizerName)&&(identical(other.organizerContact, organizerContact) || other.organizerContact == organizerContact)&&(identical(other.organizerInstagram, organizerInstagram) || other.organizerInstagram == organizerInstagram));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,categoryId,eventType,customEmoji,lat,lng,locationName,address,locationDetails,dateTime,capacity,organizerName,organizerContact,organizerInstagram);

@override
String toString() {
  return 'EventCreateRequest(title: $title, description: $description, categoryId: $categoryId, eventType: $eventType, customEmoji: $customEmoji, lat: $lat, lng: $lng, locationName: $locationName, address: $address, locationDetails: $locationDetails, dateTime: $dateTime, capacity: $capacity, organizerName: $organizerName, organizerContact: $organizerContact, organizerInstagram: $organizerInstagram)';
}


}

/// @nodoc
abstract mixin class _$EventCreateRequestCopyWith<$Res> implements $EventCreateRequestCopyWith<$Res> {
  factory _$EventCreateRequestCopyWith(_EventCreateRequest value, $Res Function(_EventCreateRequest) _then) = __$EventCreateRequestCopyWithImpl;
@override @useResult
$Res call({
 String title, String? description,@JsonKey(name: 'category_id') String categoryId,@JsonKey(name: 'event_type') EventType eventType,@JsonKey(name: 'custom_emoji') String? customEmoji, double lat, double lng,@JsonKey(name: 'location_name') String locationName, String? address,@JsonKey(name: 'location_details') String? locationDetails,@JsonKey(name: 'date_time') DateTime dateTime, int? capacity,@JsonKey(name: 'organizer_name') String? organizerName,@JsonKey(name: 'organizer_contact') String? organizerContact,@JsonKey(name: 'organizer_instagram') String? organizerInstagram
});




}
/// @nodoc
class __$EventCreateRequestCopyWithImpl<$Res>
    implements _$EventCreateRequestCopyWith<$Res> {
  __$EventCreateRequestCopyWithImpl(this._self, this._then);

  final _EventCreateRequest _self;
  final $Res Function(_EventCreateRequest) _then;

/// Create a copy of EventCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = freezed,Object? categoryId = null,Object? eventType = null,Object? customEmoji = freezed,Object? lat = null,Object? lng = null,Object? locationName = null,Object? address = freezed,Object? locationDetails = freezed,Object? dateTime = null,Object? capacity = freezed,Object? organizerName = freezed,Object? organizerContact = freezed,Object? organizerInstagram = freezed,}) {
  return _then(_EventCreateRequest(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as EventType,customEmoji: freezed == customEmoji ? _self.customEmoji : customEmoji // ignore: cast_nullable_to_non_nullable
as String?,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,locationName: null == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,locationDetails: freezed == locationDetails ? _self.locationDetails : locationDetails // ignore: cast_nullable_to_non_nullable
as String?,dateTime: null == dateTime ? _self.dateTime : dateTime // ignore: cast_nullable_to_non_nullable
as DateTime,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,organizerName: freezed == organizerName ? _self.organizerName : organizerName // ignore: cast_nullable_to_non_nullable
as String?,organizerContact: freezed == organizerContact ? _self.organizerContact : organizerContact // ignore: cast_nullable_to_non_nullable
as String?,organizerInstagram: freezed == organizerInstagram ? _self.organizerInstagram : organizerInstagram // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$EventUpdateRequest {

 String? get title; String? get description;@JsonKey(name: 'category_id') String? get categoryId;@JsonKey(name: 'event_type') EventType? get eventType;@JsonKey(name: 'custom_emoji') String? get customEmoji; double? get lat; double? get lng;@JsonKey(name: 'location_name') String? get locationName; String? get address;@JsonKey(name: 'location_details') String? get locationDetails;@JsonKey(name: 'date_time') DateTime? get dateTime; int? get capacity;@JsonKey(name: 'registration_open') bool? get registrationOpen;@JsonKey(name: 'organizer_name') String? get organizerName;@JsonKey(name: 'organizer_contact') String? get organizerContact;@JsonKey(name: 'organizer_instagram') String? get organizerInstagram;
/// Create a copy of EventUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventUpdateRequestCopyWith<EventUpdateRequest> get copyWith => _$EventUpdateRequestCopyWithImpl<EventUpdateRequest>(this as EventUpdateRequest, _$identity);

  /// Serializes this EventUpdateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventUpdateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.customEmoji, customEmoji) || other.customEmoji == customEmoji)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.address, address) || other.address == address)&&(identical(other.locationDetails, locationDetails) || other.locationDetails == locationDetails)&&(identical(other.dateTime, dateTime) || other.dateTime == dateTime)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.registrationOpen, registrationOpen) || other.registrationOpen == registrationOpen)&&(identical(other.organizerName, organizerName) || other.organizerName == organizerName)&&(identical(other.organizerContact, organizerContact) || other.organizerContact == organizerContact)&&(identical(other.organizerInstagram, organizerInstagram) || other.organizerInstagram == organizerInstagram));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,categoryId,eventType,customEmoji,lat,lng,locationName,address,locationDetails,dateTime,capacity,registrationOpen,organizerName,organizerContact,organizerInstagram);

@override
String toString() {
  return 'EventUpdateRequest(title: $title, description: $description, categoryId: $categoryId, eventType: $eventType, customEmoji: $customEmoji, lat: $lat, lng: $lng, locationName: $locationName, address: $address, locationDetails: $locationDetails, dateTime: $dateTime, capacity: $capacity, registrationOpen: $registrationOpen, organizerName: $organizerName, organizerContact: $organizerContact, organizerInstagram: $organizerInstagram)';
}


}

/// @nodoc
abstract mixin class $EventUpdateRequestCopyWith<$Res>  {
  factory $EventUpdateRequestCopyWith(EventUpdateRequest value, $Res Function(EventUpdateRequest) _then) = _$EventUpdateRequestCopyWithImpl;
@useResult
$Res call({
 String? title, String? description,@JsonKey(name: 'category_id') String? categoryId,@JsonKey(name: 'event_type') EventType? eventType,@JsonKey(name: 'custom_emoji') String? customEmoji, double? lat, double? lng,@JsonKey(name: 'location_name') String? locationName, String? address,@JsonKey(name: 'location_details') String? locationDetails,@JsonKey(name: 'date_time') DateTime? dateTime, int? capacity,@JsonKey(name: 'registration_open') bool? registrationOpen,@JsonKey(name: 'organizer_name') String? organizerName,@JsonKey(name: 'organizer_contact') String? organizerContact,@JsonKey(name: 'organizer_instagram') String? organizerInstagram
});




}
/// @nodoc
class _$EventUpdateRequestCopyWithImpl<$Res>
    implements $EventUpdateRequestCopyWith<$Res> {
  _$EventUpdateRequestCopyWithImpl(this._self, this._then);

  final EventUpdateRequest _self;
  final $Res Function(EventUpdateRequest) _then;

/// Create a copy of EventUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? description = freezed,Object? categoryId = freezed,Object? eventType = freezed,Object? customEmoji = freezed,Object? lat = freezed,Object? lng = freezed,Object? locationName = freezed,Object? address = freezed,Object? locationDetails = freezed,Object? dateTime = freezed,Object? capacity = freezed,Object? registrationOpen = freezed,Object? organizerName = freezed,Object? organizerContact = freezed,Object? organizerInstagram = freezed,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,eventType: freezed == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as EventType?,customEmoji: freezed == customEmoji ? _self.customEmoji : customEmoji // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,locationDetails: freezed == locationDetails ? _self.locationDetails : locationDetails // ignore: cast_nullable_to_non_nullable
as String?,dateTime: freezed == dateTime ? _self.dateTime : dateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,registrationOpen: freezed == registrationOpen ? _self.registrationOpen : registrationOpen // ignore: cast_nullable_to_non_nullable
as bool?,organizerName: freezed == organizerName ? _self.organizerName : organizerName // ignore: cast_nullable_to_non_nullable
as String?,organizerContact: freezed == organizerContact ? _self.organizerContact : organizerContact // ignore: cast_nullable_to_non_nullable
as String?,organizerInstagram: freezed == organizerInstagram ? _self.organizerInstagram : organizerInstagram // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventUpdateRequest].
extension EventUpdateRequestPatterns on EventUpdateRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventUpdateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventUpdateRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventUpdateRequest value)  $default,){
final _that = this;
switch (_that) {
case _EventUpdateRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventUpdateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _EventUpdateRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? description, @JsonKey(name: 'category_id')  String? categoryId, @JsonKey(name: 'event_type')  EventType? eventType, @JsonKey(name: 'custom_emoji')  String? customEmoji,  double? lat,  double? lng, @JsonKey(name: 'location_name')  String? locationName,  String? address, @JsonKey(name: 'location_details')  String? locationDetails, @JsonKey(name: 'date_time')  DateTime? dateTime,  int? capacity, @JsonKey(name: 'registration_open')  bool? registrationOpen, @JsonKey(name: 'organizer_name')  String? organizerName, @JsonKey(name: 'organizer_contact')  String? organizerContact, @JsonKey(name: 'organizer_instagram')  String? organizerInstagram)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventUpdateRequest() when $default != null:
return $default(_that.title,_that.description,_that.categoryId,_that.eventType,_that.customEmoji,_that.lat,_that.lng,_that.locationName,_that.address,_that.locationDetails,_that.dateTime,_that.capacity,_that.registrationOpen,_that.organizerName,_that.organizerContact,_that.organizerInstagram);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? description, @JsonKey(name: 'category_id')  String? categoryId, @JsonKey(name: 'event_type')  EventType? eventType, @JsonKey(name: 'custom_emoji')  String? customEmoji,  double? lat,  double? lng, @JsonKey(name: 'location_name')  String? locationName,  String? address, @JsonKey(name: 'location_details')  String? locationDetails, @JsonKey(name: 'date_time')  DateTime? dateTime,  int? capacity, @JsonKey(name: 'registration_open')  bool? registrationOpen, @JsonKey(name: 'organizer_name')  String? organizerName, @JsonKey(name: 'organizer_contact')  String? organizerContact, @JsonKey(name: 'organizer_instagram')  String? organizerInstagram)  $default,) {final _that = this;
switch (_that) {
case _EventUpdateRequest():
return $default(_that.title,_that.description,_that.categoryId,_that.eventType,_that.customEmoji,_that.lat,_that.lng,_that.locationName,_that.address,_that.locationDetails,_that.dateTime,_that.capacity,_that.registrationOpen,_that.organizerName,_that.organizerContact,_that.organizerInstagram);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? description, @JsonKey(name: 'category_id')  String? categoryId, @JsonKey(name: 'event_type')  EventType? eventType, @JsonKey(name: 'custom_emoji')  String? customEmoji,  double? lat,  double? lng, @JsonKey(name: 'location_name')  String? locationName,  String? address, @JsonKey(name: 'location_details')  String? locationDetails, @JsonKey(name: 'date_time')  DateTime? dateTime,  int? capacity, @JsonKey(name: 'registration_open')  bool? registrationOpen, @JsonKey(name: 'organizer_name')  String? organizerName, @JsonKey(name: 'organizer_contact')  String? organizerContact, @JsonKey(name: 'organizer_instagram')  String? organizerInstagram)?  $default,) {final _that = this;
switch (_that) {
case _EventUpdateRequest() when $default != null:
return $default(_that.title,_that.description,_that.categoryId,_that.eventType,_that.customEmoji,_that.lat,_that.lng,_that.locationName,_that.address,_that.locationDetails,_that.dateTime,_that.capacity,_that.registrationOpen,_that.organizerName,_that.organizerContact,_that.organizerInstagram);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventUpdateRequest implements EventUpdateRequest {
  const _EventUpdateRequest({this.title, this.description, @JsonKey(name: 'category_id') this.categoryId, @JsonKey(name: 'event_type') this.eventType, @JsonKey(name: 'custom_emoji') this.customEmoji, this.lat, this.lng, @JsonKey(name: 'location_name') this.locationName, this.address, @JsonKey(name: 'location_details') this.locationDetails, @JsonKey(name: 'date_time') this.dateTime, this.capacity, @JsonKey(name: 'registration_open') this.registrationOpen, @JsonKey(name: 'organizer_name') this.organizerName, @JsonKey(name: 'organizer_contact') this.organizerContact, @JsonKey(name: 'organizer_instagram') this.organizerInstagram});
  factory _EventUpdateRequest.fromJson(Map<String, dynamic> json) => _$EventUpdateRequestFromJson(json);

@override final  String? title;
@override final  String? description;
@override@JsonKey(name: 'category_id') final  String? categoryId;
@override@JsonKey(name: 'event_type') final  EventType? eventType;
@override@JsonKey(name: 'custom_emoji') final  String? customEmoji;
@override final  double? lat;
@override final  double? lng;
@override@JsonKey(name: 'location_name') final  String? locationName;
@override final  String? address;
@override@JsonKey(name: 'location_details') final  String? locationDetails;
@override@JsonKey(name: 'date_time') final  DateTime? dateTime;
@override final  int? capacity;
@override@JsonKey(name: 'registration_open') final  bool? registrationOpen;
@override@JsonKey(name: 'organizer_name') final  String? organizerName;
@override@JsonKey(name: 'organizer_contact') final  String? organizerContact;
@override@JsonKey(name: 'organizer_instagram') final  String? organizerInstagram;

/// Create a copy of EventUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventUpdateRequestCopyWith<_EventUpdateRequest> get copyWith => __$EventUpdateRequestCopyWithImpl<_EventUpdateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventUpdateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventUpdateRequest&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.customEmoji, customEmoji) || other.customEmoji == customEmoji)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.address, address) || other.address == address)&&(identical(other.locationDetails, locationDetails) || other.locationDetails == locationDetails)&&(identical(other.dateTime, dateTime) || other.dateTime == dateTime)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.registrationOpen, registrationOpen) || other.registrationOpen == registrationOpen)&&(identical(other.organizerName, organizerName) || other.organizerName == organizerName)&&(identical(other.organizerContact, organizerContact) || other.organizerContact == organizerContact)&&(identical(other.organizerInstagram, organizerInstagram) || other.organizerInstagram == organizerInstagram));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,categoryId,eventType,customEmoji,lat,lng,locationName,address,locationDetails,dateTime,capacity,registrationOpen,organizerName,organizerContact,organizerInstagram);

@override
String toString() {
  return 'EventUpdateRequest(title: $title, description: $description, categoryId: $categoryId, eventType: $eventType, customEmoji: $customEmoji, lat: $lat, lng: $lng, locationName: $locationName, address: $address, locationDetails: $locationDetails, dateTime: $dateTime, capacity: $capacity, registrationOpen: $registrationOpen, organizerName: $organizerName, organizerContact: $organizerContact, organizerInstagram: $organizerInstagram)';
}


}

/// @nodoc
abstract mixin class _$EventUpdateRequestCopyWith<$Res> implements $EventUpdateRequestCopyWith<$Res> {
  factory _$EventUpdateRequestCopyWith(_EventUpdateRequest value, $Res Function(_EventUpdateRequest) _then) = __$EventUpdateRequestCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? description,@JsonKey(name: 'category_id') String? categoryId,@JsonKey(name: 'event_type') EventType? eventType,@JsonKey(name: 'custom_emoji') String? customEmoji, double? lat, double? lng,@JsonKey(name: 'location_name') String? locationName, String? address,@JsonKey(name: 'location_details') String? locationDetails,@JsonKey(name: 'date_time') DateTime? dateTime, int? capacity,@JsonKey(name: 'registration_open') bool? registrationOpen,@JsonKey(name: 'organizer_name') String? organizerName,@JsonKey(name: 'organizer_contact') String? organizerContact,@JsonKey(name: 'organizer_instagram') String? organizerInstagram
});




}
/// @nodoc
class __$EventUpdateRequestCopyWithImpl<$Res>
    implements _$EventUpdateRequestCopyWith<$Res> {
  __$EventUpdateRequestCopyWithImpl(this._self, this._then);

  final _EventUpdateRequest _self;
  final $Res Function(_EventUpdateRequest) _then;

/// Create a copy of EventUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? description = freezed,Object? categoryId = freezed,Object? eventType = freezed,Object? customEmoji = freezed,Object? lat = freezed,Object? lng = freezed,Object? locationName = freezed,Object? address = freezed,Object? locationDetails = freezed,Object? dateTime = freezed,Object? capacity = freezed,Object? registrationOpen = freezed,Object? organizerName = freezed,Object? organizerContact = freezed,Object? organizerInstagram = freezed,}) {
  return _then(_EventUpdateRequest(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,eventType: freezed == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as EventType?,customEmoji: freezed == customEmoji ? _self.customEmoji : customEmoji // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,locationDetails: freezed == locationDetails ? _self.locationDetails : locationDetails // ignore: cast_nullable_to_non_nullable
as String?,dateTime: freezed == dateTime ? _self.dateTime : dateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,registrationOpen: freezed == registrationOpen ? _self.registrationOpen : registrationOpen // ignore: cast_nullable_to_non_nullable
as bool?,organizerName: freezed == organizerName ? _self.organizerName : organizerName // ignore: cast_nullable_to_non_nullable
as String?,organizerContact: freezed == organizerContact ? _self.organizerContact : organizerContact // ignore: cast_nullable_to_non_nullable
as String?,organizerInstagram: freezed == organizerInstagram ? _self.organizerInstagram : organizerInstagram // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$EventCancelRequest {

 String get reason;
/// Create a copy of EventCancelRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventCancelRequestCopyWith<EventCancelRequest> get copyWith => _$EventCancelRequestCopyWithImpl<EventCancelRequest>(this as EventCancelRequest, _$identity);

  /// Serializes this EventCancelRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventCancelRequest&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'EventCancelRequest(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $EventCancelRequestCopyWith<$Res>  {
  factory $EventCancelRequestCopyWith(EventCancelRequest value, $Res Function(EventCancelRequest) _then) = _$EventCancelRequestCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$EventCancelRequestCopyWithImpl<$Res>
    implements $EventCancelRequestCopyWith<$Res> {
  _$EventCancelRequestCopyWithImpl(this._self, this._then);

  final EventCancelRequest _self;
  final $Res Function(EventCancelRequest) _then;

/// Create a copy of EventCancelRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reason = null,}) {
  return _then(_self.copyWith(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EventCancelRequest].
extension EventCancelRequestPatterns on EventCancelRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventCancelRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventCancelRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventCancelRequest value)  $default,){
final _that = this;
switch (_that) {
case _EventCancelRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventCancelRequest value)?  $default,){
final _that = this;
switch (_that) {
case _EventCancelRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventCancelRequest() when $default != null:
return $default(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reason)  $default,) {final _that = this;
switch (_that) {
case _EventCancelRequest():
return $default(_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reason)?  $default,) {final _that = this;
switch (_that) {
case _EventCancelRequest() when $default != null:
return $default(_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventCancelRequest implements EventCancelRequest {
  const _EventCancelRequest({required this.reason});
  factory _EventCancelRequest.fromJson(Map<String, dynamic> json) => _$EventCancelRequestFromJson(json);

@override final  String reason;

/// Create a copy of EventCancelRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventCancelRequestCopyWith<_EventCancelRequest> get copyWith => __$EventCancelRequestCopyWithImpl<_EventCancelRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventCancelRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventCancelRequest&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'EventCancelRequest(reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$EventCancelRequestCopyWith<$Res> implements $EventCancelRequestCopyWith<$Res> {
  factory _$EventCancelRequestCopyWith(_EventCancelRequest value, $Res Function(_EventCancelRequest) _then) = __$EventCancelRequestCopyWithImpl;
@override @useResult
$Res call({
 String reason
});




}
/// @nodoc
class __$EventCancelRequestCopyWithImpl<$Res>
    implements _$EventCancelRequestCopyWith<$Res> {
  __$EventCancelRequestCopyWithImpl(this._self, this._then);

  final _EventCancelRequest _self;
  final $Res Function(_EventCancelRequest) _then;

/// Create a copy of EventCancelRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(_EventCancelRequest(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$EventJoinResponse {

@JsonKey(name: 'event_id') String get eventId;@JsonKey(name: 'joined_at') DateTime get joinedAt;
/// Create a copy of EventJoinResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventJoinResponseCopyWith<EventJoinResponse> get copyWith => _$EventJoinResponseCopyWithImpl<EventJoinResponse>(this as EventJoinResponse, _$identity);

  /// Serializes this EventJoinResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventJoinResponse&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,joinedAt);

@override
String toString() {
  return 'EventJoinResponse(eventId: $eventId, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $EventJoinResponseCopyWith<$Res>  {
  factory $EventJoinResponseCopyWith(EventJoinResponse value, $Res Function(EventJoinResponse) _then) = _$EventJoinResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'joined_at') DateTime joinedAt
});




}
/// @nodoc
class _$EventJoinResponseCopyWithImpl<$Res>
    implements $EventJoinResponseCopyWith<$Res> {
  _$EventJoinResponseCopyWithImpl(this._self, this._then);

  final EventJoinResponse _self;
  final $Res Function(EventJoinResponse) _then;

/// Create a copy of EventJoinResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? joinedAt = null,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [EventJoinResponse].
extension EventJoinResponsePatterns on EventJoinResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventJoinResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventJoinResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventJoinResponse value)  $default,){
final _that = this;
switch (_that) {
case _EventJoinResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventJoinResponse value)?  $default,){
final _that = this;
switch (_that) {
case _EventJoinResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'joined_at')  DateTime joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventJoinResponse() when $default != null:
return $default(_that.eventId,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'joined_at')  DateTime joinedAt)  $default,) {final _that = this;
switch (_that) {
case _EventJoinResponse():
return $default(_that.eventId,_that.joinedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'joined_at')  DateTime joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _EventJoinResponse() when $default != null:
return $default(_that.eventId,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventJoinResponse implements EventJoinResponse {
  const _EventJoinResponse({@JsonKey(name: 'event_id') required this.eventId, @JsonKey(name: 'joined_at') required this.joinedAt});
  factory _EventJoinResponse.fromJson(Map<String, dynamic> json) => _$EventJoinResponseFromJson(json);

@override@JsonKey(name: 'event_id') final  String eventId;
@override@JsonKey(name: 'joined_at') final  DateTime joinedAt;

/// Create a copy of EventJoinResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventJoinResponseCopyWith<_EventJoinResponse> get copyWith => __$EventJoinResponseCopyWithImpl<_EventJoinResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventJoinResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventJoinResponse&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,joinedAt);

@override
String toString() {
  return 'EventJoinResponse(eventId: $eventId, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$EventJoinResponseCopyWith<$Res> implements $EventJoinResponseCopyWith<$Res> {
  factory _$EventJoinResponseCopyWith(_EventJoinResponse value, $Res Function(_EventJoinResponse) _then) = __$EventJoinResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'joined_at') DateTime joinedAt
});




}
/// @nodoc
class __$EventJoinResponseCopyWithImpl<$Res>
    implements _$EventJoinResponseCopyWith<$Res> {
  __$EventJoinResponseCopyWithImpl(this._self, this._then);

  final _EventJoinResponse _self;
  final $Res Function(_EventJoinResponse) _then;

/// Create a copy of EventJoinResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? joinedAt = null,}) {
  return _then(_EventJoinResponse(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$EventUnjoinRequest {

 UnjoinReason get reason;
/// Create a copy of EventUnjoinRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventUnjoinRequestCopyWith<EventUnjoinRequest> get copyWith => _$EventUnjoinRequestCopyWithImpl<EventUnjoinRequest>(this as EventUnjoinRequest, _$identity);

  /// Serializes this EventUnjoinRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventUnjoinRequest&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'EventUnjoinRequest(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $EventUnjoinRequestCopyWith<$Res>  {
  factory $EventUnjoinRequestCopyWith(EventUnjoinRequest value, $Res Function(EventUnjoinRequest) _then) = _$EventUnjoinRequestCopyWithImpl;
@useResult
$Res call({
 UnjoinReason reason
});




}
/// @nodoc
class _$EventUnjoinRequestCopyWithImpl<$Res>
    implements $EventUnjoinRequestCopyWith<$Res> {
  _$EventUnjoinRequestCopyWithImpl(this._self, this._then);

  final EventUnjoinRequest _self;
  final $Res Function(EventUnjoinRequest) _then;

/// Create a copy of EventUnjoinRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reason = null,}) {
  return _then(_self.copyWith(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as UnjoinReason,
  ));
}

}


/// Adds pattern-matching-related methods to [EventUnjoinRequest].
extension EventUnjoinRequestPatterns on EventUnjoinRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventUnjoinRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventUnjoinRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventUnjoinRequest value)  $default,){
final _that = this;
switch (_that) {
case _EventUnjoinRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventUnjoinRequest value)?  $default,){
final _that = this;
switch (_that) {
case _EventUnjoinRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UnjoinReason reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventUnjoinRequest() when $default != null:
return $default(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UnjoinReason reason)  $default,) {final _that = this;
switch (_that) {
case _EventUnjoinRequest():
return $default(_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UnjoinReason reason)?  $default,) {final _that = this;
switch (_that) {
case _EventUnjoinRequest() when $default != null:
return $default(_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventUnjoinRequest implements EventUnjoinRequest {
  const _EventUnjoinRequest({required this.reason});
  factory _EventUnjoinRequest.fromJson(Map<String, dynamic> json) => _$EventUnjoinRequestFromJson(json);

@override final  UnjoinReason reason;

/// Create a copy of EventUnjoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventUnjoinRequestCopyWith<_EventUnjoinRequest> get copyWith => __$EventUnjoinRequestCopyWithImpl<_EventUnjoinRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventUnjoinRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventUnjoinRequest&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'EventUnjoinRequest(reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$EventUnjoinRequestCopyWith<$Res> implements $EventUnjoinRequestCopyWith<$Res> {
  factory _$EventUnjoinRequestCopyWith(_EventUnjoinRequest value, $Res Function(_EventUnjoinRequest) _then) = __$EventUnjoinRequestCopyWithImpl;
@override @useResult
$Res call({
 UnjoinReason reason
});




}
/// @nodoc
class __$EventUnjoinRequestCopyWithImpl<$Res>
    implements _$EventUnjoinRequestCopyWith<$Res> {
  __$EventUnjoinRequestCopyWithImpl(this._self, this._then);

  final _EventUnjoinRequest _self;
  final $Res Function(_EventUnjoinRequest) _then;

/// Create a copy of EventUnjoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(_EventUnjoinRequest(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as UnjoinReason,
  ));
}


}


/// @nodoc
mixin _$EventBannerUploadResponse {

@JsonKey(name: 'event_id') String get eventId;@JsonKey(name: 'banner_url') String get bannerUrl;
/// Create a copy of EventBannerUploadResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventBannerUploadResponseCopyWith<EventBannerUploadResponse> get copyWith => _$EventBannerUploadResponseCopyWithImpl<EventBannerUploadResponse>(this as EventBannerUploadResponse, _$identity);

  /// Serializes this EventBannerUploadResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventBannerUploadResponse&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.bannerUrl, bannerUrl) || other.bannerUrl == bannerUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,bannerUrl);

@override
String toString() {
  return 'EventBannerUploadResponse(eventId: $eventId, bannerUrl: $bannerUrl)';
}


}

/// @nodoc
abstract mixin class $EventBannerUploadResponseCopyWith<$Res>  {
  factory $EventBannerUploadResponseCopyWith(EventBannerUploadResponse value, $Res Function(EventBannerUploadResponse) _then) = _$EventBannerUploadResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'banner_url') String bannerUrl
});




}
/// @nodoc
class _$EventBannerUploadResponseCopyWithImpl<$Res>
    implements $EventBannerUploadResponseCopyWith<$Res> {
  _$EventBannerUploadResponseCopyWithImpl(this._self, this._then);

  final EventBannerUploadResponse _self;
  final $Res Function(EventBannerUploadResponse) _then;

/// Create a copy of EventBannerUploadResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? bannerUrl = null,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,bannerUrl: null == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EventBannerUploadResponse].
extension EventBannerUploadResponsePatterns on EventBannerUploadResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventBannerUploadResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventBannerUploadResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventBannerUploadResponse value)  $default,){
final _that = this;
switch (_that) {
case _EventBannerUploadResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventBannerUploadResponse value)?  $default,){
final _that = this;
switch (_that) {
case _EventBannerUploadResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'banner_url')  String bannerUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventBannerUploadResponse() when $default != null:
return $default(_that.eventId,_that.bannerUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'banner_url')  String bannerUrl)  $default,) {final _that = this;
switch (_that) {
case _EventBannerUploadResponse():
return $default(_that.eventId,_that.bannerUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'banner_url')  String bannerUrl)?  $default,) {final _that = this;
switch (_that) {
case _EventBannerUploadResponse() when $default != null:
return $default(_that.eventId,_that.bannerUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventBannerUploadResponse implements EventBannerUploadResponse {
  const _EventBannerUploadResponse({@JsonKey(name: 'event_id') required this.eventId, @JsonKey(name: 'banner_url') required this.bannerUrl});
  factory _EventBannerUploadResponse.fromJson(Map<String, dynamic> json) => _$EventBannerUploadResponseFromJson(json);

@override@JsonKey(name: 'event_id') final  String eventId;
@override@JsonKey(name: 'banner_url') final  String bannerUrl;

/// Create a copy of EventBannerUploadResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventBannerUploadResponseCopyWith<_EventBannerUploadResponse> get copyWith => __$EventBannerUploadResponseCopyWithImpl<_EventBannerUploadResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventBannerUploadResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventBannerUploadResponse&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.bannerUrl, bannerUrl) || other.bannerUrl == bannerUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,bannerUrl);

@override
String toString() {
  return 'EventBannerUploadResponse(eventId: $eventId, bannerUrl: $bannerUrl)';
}


}

/// @nodoc
abstract mixin class _$EventBannerUploadResponseCopyWith<$Res> implements $EventBannerUploadResponseCopyWith<$Res> {
  factory _$EventBannerUploadResponseCopyWith(_EventBannerUploadResponse value, $Res Function(_EventBannerUploadResponse) _then) = __$EventBannerUploadResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'banner_url') String bannerUrl
});




}
/// @nodoc
class __$EventBannerUploadResponseCopyWithImpl<$Res>
    implements _$EventBannerUploadResponseCopyWith<$Res> {
  __$EventBannerUploadResponseCopyWithImpl(this._self, this._then);

  final _EventBannerUploadResponse _self;
  final $Res Function(_EventBannerUploadResponse) _then;

/// Create a copy of EventBannerUploadResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? bannerUrl = null,}) {
  return _then(_EventBannerUploadResponse(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,bannerUrl: null == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$JoineeResponse {

 String get uid; String get username;@JsonKey(name: 'display_name') String get displayName;@JsonKey(name: 'photo_url') String? get photoUrl; bool get online;@JsonKey(name: 'joined_at') DateTime get joinedAt;
/// Create a copy of JoineeResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoineeResponseCopyWith<JoineeResponse> get copyWith => _$JoineeResponseCopyWithImpl<JoineeResponse>(this as JoineeResponse, _$identity);

  /// Serializes this JoineeResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoineeResponse&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.online, online) || other.online == online)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,username,displayName,photoUrl,online,joinedAt);

@override
String toString() {
  return 'JoineeResponse(uid: $uid, username: $username, displayName: $displayName, photoUrl: $photoUrl, online: $online, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $JoineeResponseCopyWith<$Res>  {
  factory $JoineeResponseCopyWith(JoineeResponse value, $Res Function(JoineeResponse) _then) = _$JoineeResponseCopyWithImpl;
@useResult
$Res call({
 String uid, String username,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'photo_url') String? photoUrl, bool online,@JsonKey(name: 'joined_at') DateTime joinedAt
});




}
/// @nodoc
class _$JoineeResponseCopyWithImpl<$Res>
    implements $JoineeResponseCopyWith<$Res> {
  _$JoineeResponseCopyWithImpl(this._self, this._then);

  final JoineeResponse _self;
  final $Res Function(JoineeResponse) _then;

/// Create a copy of JoineeResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? username = null,Object? displayName = null,Object? photoUrl = freezed,Object? online = null,Object? joinedAt = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [JoineeResponse].
extension JoineeResponsePatterns on JoineeResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoineeResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoineeResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoineeResponse value)  $default,){
final _that = this;
switch (_that) {
case _JoineeResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoineeResponse value)?  $default,){
final _that = this;
switch (_that) {
case _JoineeResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String username, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'photo_url')  String? photoUrl,  bool online, @JsonKey(name: 'joined_at')  DateTime joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoineeResponse() when $default != null:
return $default(_that.uid,_that.username,_that.displayName,_that.photoUrl,_that.online,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String username, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'photo_url')  String? photoUrl,  bool online, @JsonKey(name: 'joined_at')  DateTime joinedAt)  $default,) {final _that = this;
switch (_that) {
case _JoineeResponse():
return $default(_that.uid,_that.username,_that.displayName,_that.photoUrl,_that.online,_that.joinedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String username, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'photo_url')  String? photoUrl,  bool online, @JsonKey(name: 'joined_at')  DateTime joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _JoineeResponse() when $default != null:
return $default(_that.uid,_that.username,_that.displayName,_that.photoUrl,_that.online,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JoineeResponse implements JoineeResponse {
  const _JoineeResponse({required this.uid, required this.username, @JsonKey(name: 'display_name') required this.displayName, @JsonKey(name: 'photo_url') this.photoUrl, this.online = false, @JsonKey(name: 'joined_at') required this.joinedAt});
  factory _JoineeResponse.fromJson(Map<String, dynamic> json) => _$JoineeResponseFromJson(json);

@override final  String uid;
@override final  String username;
@override@JsonKey(name: 'display_name') final  String displayName;
@override@JsonKey(name: 'photo_url') final  String? photoUrl;
@override@JsonKey() final  bool online;
@override@JsonKey(name: 'joined_at') final  DateTime joinedAt;

/// Create a copy of JoineeResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoineeResponseCopyWith<_JoineeResponse> get copyWith => __$JoineeResponseCopyWithImpl<_JoineeResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JoineeResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoineeResponse&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.online, online) || other.online == online)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,username,displayName,photoUrl,online,joinedAt);

@override
String toString() {
  return 'JoineeResponse(uid: $uid, username: $username, displayName: $displayName, photoUrl: $photoUrl, online: $online, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$JoineeResponseCopyWith<$Res> implements $JoineeResponseCopyWith<$Res> {
  factory _$JoineeResponseCopyWith(_JoineeResponse value, $Res Function(_JoineeResponse) _then) = __$JoineeResponseCopyWithImpl;
@override @useResult
$Res call({
 String uid, String username,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'photo_url') String? photoUrl, bool online,@JsonKey(name: 'joined_at') DateTime joinedAt
});




}
/// @nodoc
class __$JoineeResponseCopyWithImpl<$Res>
    implements _$JoineeResponseCopyWith<$Res> {
  __$JoineeResponseCopyWithImpl(this._self, this._then);

  final _JoineeResponse _self;
  final $Res Function(_JoineeResponse) _then;

/// Create a copy of JoineeResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? username = null,Object? displayName = null,Object? photoUrl = freezed,Object? online = null,Object? joinedAt = null,}) {
  return _then(_JoineeResponse(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
