import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:maplibre/maplibre.dart';

import 'package:fafu/src/core/config/map_config.dart';
import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/categories/data/categories_repository.dart';
import 'package:fafu/src/features/categories/domain/category.dart';
import 'package:fafu/src/features/events/data/events_repository.dart';
import 'package:fafu/src/features/events/domain/event.dart';
import 'package:fafu/src/features/home/data/mock_events.dart';
import 'package:fafu/src/features/location/selected_area_controller.dart';
import 'package:fafu/src/features/search/presentation/search_page.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/core/services/shared_preferences_provider.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

class HomeMapFocusTarget {
  const HomeMapFocusTarget({
    required this.eventId,
    required this.lat,
    required this.lng,
  });

  final String eventId;
  final double lat;
  final double lng;
}

final homeMapFocusProvider =
    NotifierProvider<HomeMapFocusNotifier, HomeMapFocusTarget?>(HomeMapFocusNotifier.new);

class HomeMapFocusNotifier extends Notifier<HomeMapFocusTarget?> {
  @override
  HomeMapFocusTarget? build() => null;

  void setFocus(HomeMapFocusTarget target) => state = target;

  void clear() => state = null;
}

enum _DateTimeFilter {
  any('Any time'),
  today('Today'),
  tonight('Tonight'),
  weekend('Weekend');

  const _DateTimeFilter(this.label);

  final String label;
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const routeName = 'home';
  static const routePath = '/home';

  @override
  ConsumerState<HomePage> createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {
  static const double _initialMapZoom = 14.0;
  static const double _minEventVisibilityZoom = 13.5;
  static const double _defaultLat = 12.9716;
  static const double _defaultLng = 77.5946;
  // Radius starts at 1 km so the slider can never read an invalid "0-0 km"
  // range (which would match no activities).
  static const double _radiusMinKm = 1;
  static const double _radiusMaxKm = 20;
  static const int _radiusDivisions = 19;
  static const RangeValues _defaultRadiusRange = RangeValues(1, 20);
  static const _participantOptions = [0, 25, 50, 100];

  MapController? _mapController;
  MockEvent? _selectedEvent;
  List<EventResponse> _rawEvents = const [];
  StreamSubscription<List<EventResponse>>? _eventsSub;
  Map<String, String> _categoryNames = const {};
  Map<String, String> _categoryEmojis = const {};
  List<MockEvent> _events = [];
  PageController? _eventPagerController;
  double _currentZoom = _initialMapZoom;
  bool _eventsVisibleOnMap = _initialMapZoom >= _minEventVisibilityZoom;
  _DateTimeFilter _selectedDateTime = _DateTimeFilter.any;
  RangeValues _selectedRadiusRange = _defaultRadiusRange;
  int _minimumParticipants = _participantOptions.first;
  List<CategoryResponse> _categories = const [];
  String? _selectedCategoryId;
  EventType? _selectedEventType;
  // When the user taps "View on map" from an event detail page, this holds the
  // focused event's id so its pin is always shown, bypassing the active
  // category/type/radius/participants/date filters. Cleared when the user
  // changes a filter or re-centres the map.
  String? _focusedEventId;

  double _lat = _defaultLat;
  double _lng = _defaultLng;
  // The user's real device position (when available). Drives the "you are
  // here" marker on the map, which is independent of the map centre (the centre
  // may be a chosen area, profile area or cached fix).
  double? _userLat;
  double? _userLng;
  bool _locationReady = false;
  bool _loadingEvents = true;
  bool _locatingUser = false;
  String? _eventsError;
  String? _locationNotice;

  @override
  void initState() {
    super.initState();
    _finishLocation();
  }

  Future<void> _finishLocation() async {
    setState(() {
      _loadingEvents = true;
      _eventsError = null;
    });

    try {
      await _resolveUserLocation();
      await _loadCategories();
      _subscribeToEvents();
    } catch (e) {
      if (mounted) {
        setState(() {
          _events = const [];
          _eventsError = e.toString();
          _loadingEvents = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _locationReady = true);
        if (_locationNotice != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _locationNotice == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_locationNotice!),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: Geolocator.openLocationSettings,
                ),
              ),
            );
          });
        }
      }
    }
  }

  static const _cachedLatKey = 'home_map_last_lat';
  static const _cachedLngKey = 'home_map_last_lng';

  Future<void> _resolveUserLocation() async {
    // A manually chosen area (Settings) takes priority over everything else.
    final chosen = ref.read(selectedAreaProvider);
    if (chosen != null) {
      _lat = chosen.lat;
      _lng = chosen.lng;
      return;
    }

    // If the user has already granted location permission, the live GPS fix is
    // the most accurate centre available. Use it directly (this does not show a
    // new prompt) so the map isn't stuck on a stale cached / profile area that
    // can be a couple of kilometres away from where the user actually is.
    final permission = await Geolocator.checkPermission();
    final alreadyGranted =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (alreadyGranted && await _tryUseDeviceLocation(moveCamera: false)) {
      return;
    }

    // Prefer the area the user set during onboarding / in their profile.
    // This prevents the map from asking for current location on every launch.
    try {
      final profile = await ref.read(currentProfileProvider.future);
      final area = profile.area;
      if (area != null) {
        _lat = area.lat;
        _lng = area.lng;
        return;
      }
    } catch (_) {
      // Profile may not be available yet, fall through to cached/GPS/default.
    }

    final prefs = ref.read(sharedPreferencesProvider).value;

    // Reuse the last known fix without prompting again.
    final cachedLat = prefs?.getDouble(_cachedLatKey);
    final cachedLng = prefs?.getDouble(_cachedLngKey);
    if (cachedLat != null && cachedLng != null) {
      _lat = cachedLat;
      _lng = cachedLng;
      return;
    }

    // Only ask GPS automatically when there is no saved area or cached fix.
    final gpsResolved = await _tryUseDeviceLocation(moveCamera: false);
    if (gpsResolved) return;

    _lat = _defaultLat;
    _lng = _defaultLng;
  }

  Future<bool> _tryUseDeviceLocation({required bool moveCamera}) async {
    final prefs = ref.read(sharedPreferencesProvider).value;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationNotice = 'Turn on device location to show where you are.';
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _locationNotice =
            'Location permission is needed to show where you are.';
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        _locationNotice =
            'Enable location permission in settings to show where you are.';
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _lat = position.latitude;
      _lng = position.longitude;
      _userLat = position.latitude;
      _userLng = position.longitude;
      _locationNotice = null;
      await prefs?.setDouble(_cachedLatKey, _lat);
      await prefs?.setDouble(_cachedLngKey, _lng);

      if (moveCamera) {
        await _mapController?.animateCamera(
          center: Geographic(lon: _lng, lat: _lat),
          zoom: _initialMapZoom,
          nativeDuration: const Duration(milliseconds: 700),
        );
        _rebuildVisibleEvents();
      }
      return true;
    } catch (_) {
      _locationNotice = 'Could not refresh your location. Try again.';
      return false;
    }
  }

  Future<void> _centerOnUserLocation() async {
    if (_locatingUser) return;
    setState(() {
      _locatingUser = true;
      _locationNotice = null;
    });

    final resolved = await _tryUseDeviceLocation(moveCamera: true);
    if (!mounted) return;

    setState(() => _locatingUser = false);
    if (!resolved && _locationNotice != null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_locationNotice!),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: Geolocator.openLocationSettings,
          ),
        ),
      );
    }
  }

  Future<void> _loadCategories() async {
    final categories = await ref
        .read(categoriesRepositoryProvider)
        .getCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _categoryNames = {for (final c in categories) c.id: c.name};
      _categoryEmojis = {for (final c in categories) c.id: c.emoji};
    });
  }

  /// Subscribes to the live Firestore event stream so the map reflects new and
  /// edited events in real time.
  void _subscribeToEvents() {
    _eventsSub?.cancel();
    _eventsSub = ref
        .read(eventsRepositoryProvider)
        .streamEvents()
        .listen(
          (events) {
            _rawEvents = events;
            _rebuildVisibleEvents();
            if (mounted && (_loadingEvents || _eventsError != null)) {
              setState(() {
                _loadingEvents = false;
                _eventsError = null;
              });
            }
          },
          onError: (Object e) {
            if (mounted) {
              setState(() {
                _eventsError = e.toString();
                _loadingEvents = false;
              });
            }
          },
        );
  }

  /// Recomputes the mapped/displayed events from the latest raw stream data and
  /// the currently selected category / event-type / visibility filters.
  void _rebuildVisibleEvents() {
    final cutoff = DateTime.now().toUtc().subtract(const Duration(minutes: 10));
    final visible = _rawEvents
        .where((event) {
          // A focused event (tapped via "View on map") always stays visible so
          // its pin can be shown regardless of the active filters.
          if (event.id == _focusedEventId) return true;
          // An event stays visible until 10 minutes after its start time.
          if (event.dateTime.toUtc().isBefore(cutoff)) return false;
          if (_selectedCategoryId != null &&
              event.categoryId != _selectedCategoryId) {
            return false;
          }
          if (_selectedEventType != null &&
              event.eventType != _selectedEventType) {
            return false;
          }
          return true;
        })
        .map(
          (event) => _eventResponseToMockEvent(
            event,
            _categoryNames[event.categoryId] ?? event.categoryId,
            _categoryEmojis[event.categoryId],
          ),
        );

    final next = visible.toList(growable: false);
    if (!mounted) {
      _events = next;
      return;
    }
    setState(() {
      _events = next;
      final ids = _filteredEvents.map((e) => e.id).toSet();
      if (_selectedEvent != null && !ids.contains(_selectedEvent!.id)) {
        _selectedEvent = null;
      }
    });
  }

  Future<void> _refreshBackendEvents() async {
    setState(() {
      _eventsError = null;
    });
    try {
      await _loadCategories();
      _subscribeToEvents();
    } catch (e) {
      if (mounted) setState(() => _eventsError = e.toString());
    }
  }

  MockEvent _eventResponseToMockEvent(
    EventResponse event,
    String categoryName,
    String? categoryEmoji,
  ) {
    final dateTime = event.dateTime.toLocal();
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(dateTime, now);
    final isWeekend =
        dateTime.weekday == DateTime.saturday ||
        dateTime.weekday == DateTime.sunday;
    final timing = isToday
        ? (dateTime.hour >= 17
              ? MockEventTiming.tonight
              : MockEventTiming.today)
        : isWeekend
        ? MockEventTiming.weekend
        : MockEventTiming.today;
    final effectiveType = isToday && event.eventType == EventType.normal
        ? 'spotlight'
        : event.eventType.name;

    return MockEvent(
      id: event.id,
      title: event.title,
      category: categoryName,
      time: DateFormat('h:mm a').format(dateTime),
      venue: event.locationName,
      lat: event.lat,
      lng: event.lng,
      attendees: event.joineeCount,
      isFree: true,
      friendsOnly: false,
      rating: 4.7,
      timing: timing,
      organizerName: 'FaFo Creator',
      organizerContact: '',
      organizerInstagram: '',
      organizerVerified: true,
      imageUrl:
          event.bannerUrl ?? 'https://picsum.photos/seed/${event.id}/600/800',
      eventType: effectiveType,
      customEmoji: event.customEmoji ?? categoryEmoji,
    );
  }

  List<MockEvent> get _filteredEvents {
    return _events.where((event) {
      // A focused event (tapped via "View on map") bypasses the display filters
      // so its pin is always rendered on the map.
      if (event.id == _focusedEventId) return true;
      if (_selectedDateTime != _DateTimeFilter.any) {
        final matchesDateTime = switch (_selectedDateTime) {
          _DateTimeFilter.any => true,
          _DateTimeFilter.today => event.timing == MockEventTiming.today,
          _DateTimeFilter.tonight => event.timing == MockEventTiming.tonight,
          _DateTimeFilter.weekend => event.timing == MockEventTiming.weekend,
        };

        if (!matchesDateTime) return false;
      }

      final distance = _distanceFromUserInKm(event);
      if (distance < _selectedRadiusRange.start ||
          distance > _selectedRadiusRange.end) {
        return false;
      }
      if (event.attendees < _minimumParticipants) return false;
      return true;
    }).toList();
  }

  double _distanceFromUserInKm(MockEvent event) {
    const kmPerDegreeLat = 111.32;
    final kmPerDegreeLng = 111.32 * math.cos(_lat * math.pi / 180);
    final latDistance = (event.lat - _lat) * kmPerDegreeLat;
    final lngDistance = (event.lng - _lng) * kmPerDegreeLng;
    return math.sqrt((latDistance * latDistance) + (lngDistance * lngDistance));
  }

  bool get _hasExtendedFilters =>
      _selectedRadiusRange != _defaultRadiusRange || _minimumParticipants != 0;

  String _eventTypeLabel(EventType type) {
    return switch (type) {
      EventType.normal => 'Normal',
      EventType.spotlight => 'Spotlight',
      EventType.volunteering => 'Volunteering',
    };
  }

  void _updateFilters(VoidCallback updates) {
    setState(() {
      // The user is now actively filtering, so drop any "View on map" focus
      // that was bypassing the filters.
      _focusedEventId = null;
      updates();
      final filteredIds = _filteredEvents.map((event) => event.id).toSet();

      if (_selectedEvent != null && !filteredIds.contains(_selectedEvent!.id)) {
        _selectedEvent = null;
      }
    });
  }

  Future<void> _openExtendedFiltersSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF101010) : AppColors.bgPrimary,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void applyAndRefresh(VoidCallback updates) {
              _updateFilters(updates);
              setModalState(() {});
            }

            return SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'More filters',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 16),
                          _SliderFilterSection(
                            title: 'Radius',
                            valueLabel:
                                '${_selectedRadiusRange.start.toStringAsFixed(0)}-${_selectedRadiusRange.end.toStringAsFixed(0)} km',
                            values: _selectedRadiusRange,
                            min: _radiusMinKm,
                            max: _radiusMaxKm,
                            divisions: _radiusDivisions,
                            onChanged: (value) => applyAndRefresh(
                              () => _selectedRadiusRange = value,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FilterSection(
                            title: 'Participants',
                            children: HomePageState._participantOptions
                                .map(
                                  (value) => _FilterOptionChip(
                                    label: value == 0
                                        ? 'Any size'
                                        : '$value+ people',
                                    selected: _minimumParticipants == value,
                                    onTap: () => applyAndRefresh(
                                      () => _minimumParticipants = value,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: AppButton(
                      label: 'Done',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    await _refreshBackendEvents();
  }

  Future<void> _onMapCreated(MapController controller) async {
    _mapController = controller;
    final pendingFocus = ref.read(homeMapFocusProvider);
    if (pendingFocus != null) {
      _scheduleMapFocus(pendingFocus);
    }

    // MapLibre's Android location component can throw a native
    // SecurityException if enabled without a granted runtime permission. The
    // exception is raised asynchronously from MapView.onStart, so a Dart
    // try/catch around enableLocation() is not enough to prevent an app crash.
    final permission = await Geolocator.checkPermission();
    final hasLocationPermission =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (!hasLocationPermission) return;

    try {
      await controller.enableLocation();
    } catch (_) {
      // Location permissions or platform support may be unavailable.
    }

    // Make sure the "you are here" marker has a real fix to render, even when
    // the map centre came from a saved area or cached coordinate.
    if (_userLat == null || _userLng == null) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        if (mounted) {
          setState(() {
            _userLat = position.latitude;
            _userLng = position.longitude;
          });
        }
      } catch (_) {
        // No fresh fix available; the marker simply stays hidden.
      }
    }
  }

  static Color colorForEventType(String eventType) {
    return switch (eventType) {
      'spotlight' => AppColors.accentWarm,
      'volunteering' => const Color(0xFF4ADE80),
      // Normal events use a light blue so the pin stays visible on the map.
      _ => AppColors.accentLight1,
    };
  }

  static int colorForCategory(String category) {
    return switch (category) {
      'Live Music' => AppColors.accentPrimary.toARGB32(),
      'Comedy' => AppColors.accentWarm.toARGB32(),
      'Nightlife' => AppColors.accentSecondary.toARGB32(),
      'Art & Culture' => AppColors.accentLight1.toARGB32(),
      'Food & Drinks' => const Color(0xFFFF8C42).toARGB32(),
      'Wellness' => const Color(0xFF4ADE80).toARGB32(),
      'Sports' => const Color(0xFF38BDF8).toARGB32(),
      'Tech' => const Color(0xFF818CF8).toARGB32(),
      'Workshops' => AppColors.accentLight2.toARGB32(),
      _ => AppColors.accentPrimary.toARGB32(),
    };
  }

  void _onMapEvent(MapEvent event) {
    if (event is! MapEventMoveCamera) return;

    _currentZoom = event.camera.zoom;
    final shouldShowEvents = _currentZoom >= _minEventVisibilityZoom;

    if (shouldShowEvents == _eventsVisibleOnMap) return;

    setState(() {
      _eventsVisibleOnMap = shouldShowEvents;
      if (!shouldShowEvents) {
        _selectedEvent = null;
      }
    });
  }

  /// Tapping a marker selects its event and slides the carousel to the
  /// matching card. The carousel keeps a single, stable order (the same list
  /// the markers are built from), so the centred card always maps back to the
  /// correct event — no list reordering, no controller churn.
  void _openEventPager(MockEvent anchorEvent) {
    final events = _filteredEvents;
    final index = events.indexWhere((e) => e.id == anchorEvent.id);
    if (index < 0) return;

    final alreadySelected = _selectedEvent?.id == anchorEvent.id;
    if (!alreadySelected) {
      setState(() => _selectedEvent = anchorEvent);
    }

    // Centre the tapped event's card once this frame's layout is in place.
    _animateCarouselToPage(index);

    // A marker tap is an explicit "take me here" — adjust zoom and pitch.
    _focusEvent(anchorEvent, adjustZoom: true);
  }

  /// Slides the carousel to [index] after the current frame, guarding against
  /// the controller not being attached yet (e.g. first build).
  void _animateCarouselToPage(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = _eventPagerController;
      if (controller == null || !controller.hasClients) return;
      controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Moves the camera to [event].
  ///
  /// [adjustZoom] is true for explicit jumps (marker tap, deeplink) where we
  /// want to settle at the standard event zoom/pitch. While the user is simply
  /// swiping between cards we keep the current zoom and pitch and only pan,
  /// which is far smoother and less disorienting.
  Future<void> _focusEvent(MockEvent event, {bool adjustZoom = false}) async {
    if (_mapController == null) return;

    await _mapController!.animateCamera(
      center: Geographic(lon: event.lng, lat: event.lat),
      zoom: adjustZoom ? 14.5 : null,
      pitch: adjustZoom ? 45 : null,
      nativeDuration: Duration(milliseconds: adjustZoom ? 600 : 350),
    );
  }

  /// Applies a "View on map" focus once the map is actually on screen.
  ///
  /// The map is created once and kept alive in MainShell's IndexedStack, so
  /// [_onMapCreated] does not fire again when the user returns from an event
  /// detail page. The focus listener can also fire while the detail route is
  /// still on top (map offstage). Deferring to a post-frame callback runs the
  /// camera move after `go('/main')` has revealed the map, and a short retry
  /// covers the case where the controller hasn't attached yet.
  void _scheduleMapFocus(HomeMapFocusTarget target, {int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_mapController == null) {
        // Give the platform view a few frames to attach before giving up, so a
        // cold deep link (map still building) still lands on the event.
        if (attempt >= 20) return;
        _scheduleMapFocus(target, attempt: attempt + 1);
        return;
      }
      _applyMapFocus(target);
    });
  }

  Future<void> _applyMapFocus(HomeMapFocusTarget target) async {
    if (!mounted || _mapController == null) return;
    ref.read(homeMapFocusProvider.notifier).clear();
    // Mark the event as focused and rebuild so it bypasses the active filters
    // and is guaranteed to be present in the visible/marker lists.
    _focusedEventId = target.eventId;
    _rebuildVisibleEvents();
    MockEvent? matchingEvent;
    for (final event in _events) {
      if (event.id == target.eventId) {
        matchingEvent = event;
        break;
      }
    }
    setState(() {
      _lat = target.lat;
      _lng = target.lng;
      _eventsVisibleOnMap = true;
      _selectedEvent = matchingEvent;
    });
    if (matchingEvent != null) {
      final index = _filteredEvents.indexWhere(
        (e) => e.id == matchingEvent!.id,
      );
      if (index >= 0) _animateCarouselToPage(index);
    }
    await _mapController!.animateCamera(
      center: Geographic(lon: target.lng, lat: target.lat),
      zoom: 14.5,
      pitch: 45,
      nativeDuration: const Duration(milliseconds: 700),
    );
    _rebuildVisibleEvents();
  }

  /// Re-centres the map when the user picks a new area in Settings.
  void _applySelectedArea(SelectedArea area) {
    if (!mounted) return;
    _lat = area.lat;
    _lng = area.lng;
    _selectedEvent = null;
    _focusedEventId = null;
    _mapController?.animateCamera(
      center: Geographic(lon: _lng, lat: _lat),
      zoom: _initialMapZoom,
      nativeDuration: const Duration(milliseconds: 700),
    );
    _rebuildVisibleEvents();
  }

  /// The id of the event closest to the user, so its marker can be drawn a
  /// little larger to highlight it.
  String? _nearestEventId(List<MockEvent> events) {
    String? nearestId;
    var nearestDistance = double.infinity;
    for (final event in events) {
      final distance = _distanceFromUserInKm(event);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestId = event.id;
      }
    }
    return nearestId;
  }

  List<Marker> _visibleMarkers(List<MockEvent> events) {
    final nearestId = _nearestEventId(events);
    return events
        .map((event) {
          final isNearest = event.id == nearestId;
          // The nearest event is rendered slightly larger to draw the eye.
          final size = isNearest ? const Size(60, 78) : const Size(48, 62);
          return Marker(
            point: Geographic(lon: event.lng, lat: event.lat),
            size: size,
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () => _openEventPager(event),
              child: _EventMapMarker(event: event, isNearest: isNearest),
            ),
          );
        })
        .toList(growable: false);
  }

  /// A marker showing the user's real device position, when known.
  Marker? get _userLocationMarker {
    final lat = _userLat;
    final lng = _userLng;
    if (lat == null || lng == null) return null;
    return Marker(
      point: Geographic(lon: lng, lat: lat),
      size: const Size(26, 26),
      alignment: Alignment.center,
      child: const _UserLocationMarker(),
    );
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _eventPagerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-centre the map whenever the user changes their area in Settings (and
    // when a persisted area finishes loading from storage after first frame).
    ref.listen<SelectedArea?>(selectedAreaProvider, (previous, next) {
      if (next != null && (next.lat != _lat || next.lng != _lng)) {
        _applySelectedArea(next);
      }
    });
    ref.listen<HomeMapFocusTarget?>(homeMapFocusProvider, (_, target) {
      if (target != null) _scheduleMapFocus(target);
    });

    // Compute the filtered event list exactly once per build. It used to be a
    // getter that recomputed a sqrt/cos distance for every event and was read
    // 6-8 times per build (markers, nearest-event highlight, status text,
    // locate button, carousel) — the redundant work was a major source of the
    // hitch when tapping a marker triggered a rebuild.
    final filtered = _filteredEvents;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final searchSurface = isDark
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFF4F4F4);
    final searchBorder = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.78);
    final searchText = isDark ? Colors.white70 : const Color(0xFF7A7A7A);
    final statusSurface = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final statusBorder = isDark
        ? Colors.white.withValues(alpha: 0.76)
        : const Color(0xFF171717);
    final statusText = isDark ? Colors.white : const Color(0xFF171717);

    return Scaffold(
      body: Stack(
        children: [
          // Full-bleed map
          if (_locationReady)
            MapLibreMap(
              // Stable key so the element and its native platform view are
              // reused across rebuilds. Toggling dark mode rebuilds the whole
              // tree, and main_shell keeps this map alive in an IndexedStack;
              // recreating the platform view mid-rebuild trips the
              // 'renderObject.child == child' assertion.
              key: const ValueKey('home-maplibre-map'),
              options: MapOptions(
                initStyle: MapConfig.vintageStyleUrl,
                initCenter: Geographic(lon: _lng, lat: _lat),
                initZoom: _initialMapZoom,
                initPitch: 0,
              ),
              onMapCreated: _onMapCreated,
              onEvent: _onMapEvent,
              children: [
                // Always return a WidgetLayer (with an empty marker list when
                // there are none) so the map's child slot keeps a stable widget
                // type across rebuilds. Swapping between SizedBox and
                // WidgetLayer changes the slot child's type and trips the
                // 'renderObject.child == child' assertion on theme rebuilds.
                Builder(
                  builder: (context) {
                    return WidgetLayer(
                      markers: <Marker>[
                        ..._visibleMarkers(filtered),
                        ?_userLocationMarker,
                      ],
                      allowInteraction: true,
                    );
                  },
                ),
              ],
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.accentPrimary),
            ),

          // Top overlay: search + profile
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // Search bar
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          context.push(SearchPage.routePath, extra: _events),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: searchSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: searchBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: searchText, size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Find your event...',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: searchText,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 38,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterMenuChip<_DateTimeFilter>(
                          icon: Icons.schedule_rounded,
                          label: _selectedDateTime.label,
                          selected: _selectedDateTime != _DateTimeFilter.any,
                          items: _DateTimeFilter.values,
                          value: _selectedDateTime,
                          itemLabel: (value) => value.label,
                          onSelected: (value) =>
                              _updateFilters(() => _selectedDateTime = value),
                        ),
                        const SizedBox(width: 8),
                        _FilterMenuChip<String?>(
                          icon: Icons.category_outlined,
                          label: _selectedCategoryId == null
                              ? 'All categories'
                              : _categories
                                        .where(
                                          (c) => c.id == _selectedCategoryId,
                                        )
                                        .map((c) => c.name)
                                        .firstOrNull ??
                                    'Category',
                          selected: _selectedCategoryId != null,
                          items: <String?>[
                            null,
                            ..._categories.map((c) => c.id),
                          ],
                          value: _selectedCategoryId,
                          itemLabel: (value) => value == null
                              ? 'All categories'
                              : _categories
                                    .firstWhere((c) => c.id == value)
                                    .name,
                          onSelected: (value) {
                            setState(() {
                              _focusedEventId = null;
                              _selectedCategoryId = value;
                            });
                            _rebuildVisibleEvents();
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterMenuChip<EventType?>(
                          icon: Icons.auto_awesome_outlined,
                          label: _selectedEventType == null
                              ? 'All types'
                              : _eventTypeLabel(_selectedEventType!),
                          selected: _selectedEventType != null,
                          items: const <EventType?>[
                            null,
                            EventType.normal,
                            EventType.spotlight,
                            EventType.volunteering,
                          ],
                          value: _selectedEventType,
                          itemLabel: (value) => value == null
                              ? 'All types'
                              : _eventTypeLabel(value),
                          onSelected: (value) {
                            setState(() {
                              _focusedEventId = null;
                              _selectedEventType = value;
                            });
                            _rebuildVisibleEvents();
                          },
                        ),
                        const SizedBox(width: 8),
                        _ToggleFilterChip(
                          icon: Icons.tune_rounded,
                          label: 'More filters',
                          selected: _hasExtendedFilters,
                          showCaret: true,
                          onTap: _openExtendedFiltersSheet,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: statusSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ED164),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _loadingEvents
                                  ? 'Loading live events around you...'
                                  : _eventsError != null
                                  ? 'Could not load events. Pulling from backend failed.'
                                  : filtered.isEmpty
                                  ? 'No activities match the selected filters'
                                  : '${filtered.length} activities match in your area',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: statusText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Raise the locate button above the event carousel whenever it is
          // visible — that includes the unselected state where the carousel
          // still shows because there are matching events.
          Positioned(
            right: 14,
            bottom: filtered.isNotEmpty ? 226 : 174,
            child: SafeArea(
              top: false,
              child: Material(
                color: statusSurface,
                elevation: 8,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _centerOnUserLocation,
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: _locatingUser
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.my_location_rounded,
                            color: AppColors.accentPrimary,
                          ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom: a single event carousel (above the nav bar). One stable
          // list + one persistent controller; the selected event simply tracks
          // whichever card is centred, so swiping always lands on the right
          // event and tapping a marker animates the carousel to its card.
          if (filtered.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 86,
              child: SafeArea(
                top: false,
                child: _EventPager(
                  events: filtered,
                  controller: _eventPagerController ??= PageController(
                    viewportFraction: 0.86,
                  ),
                  onPageChanged: (index) {
                    if (index < 0 || index >= filtered.length) return;
                    final event = filtered[index];
                    if (event.id == _selectedEvent?.id) return;
                    setState(() => _selectedEvent = event);
                    // Just a swipe — pan only, keep the current zoom/pitch.
                    _focusEvent(event);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final MockEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBackground = isDark
        ? const Color(0xFF252525)
        : const Color(0xFFF6F6F6);
    final cardBorder = isDark ? Colors.white : const Color(0xFF161616);
    final thumbBackground = isDark ? const Color(0xFF303030) : Colors.white;
    final thumbBorder = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : const Color(0xFF7B7B7B);
    final venueColor = isDark
        ? const Color(0xFFCFCFCF)
        : const Color(0xFF595959);
    final titleColor = isDark ? Colors.white : const Color(0xFF161616);
    final metaColor = isDark
        ? const Color(0xFF8C8C8C)
        : const Color(0xFF808080);

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}', extra: event),
      child: Container(
        width: 182,
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: thumbBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: thumbBorder),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: _MockEventIconTile(event: event),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.venue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: venueColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: titleColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Sat 9:00 PM',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: metaColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MapCardButton(
                      label: 'RSVP',
                      backgroundColor: AppColors.accentPrimary,
                      textColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MapCardButton(
                      label: 'MORE',
                      backgroundColor: isDark
                          ? const Color(0xFF2C2C2C)
                          : Colors.transparent,
                      textColor: isDark
                          ? AppColors.accentLight1
                          : AppColors.accentPrimary,
                      borderColor: isDark
                          ? Colors.white.withValues(alpha: 0.55)
                          : AppColors.accentPrimary,
                      outlined: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockEventIconTile extends StatelessWidget {
  const _MockEventIconTile({required this.event});

  final MockEvent event;

  @override
  Widget build(BuildContext context) {
    final accent = HomePageState.colorForEventType(event.eventType);
    final emoji = event.customEmoji?.isNotEmpty == true
        ? event.customEmoji!
        : switch (event.eventType) {
            'spotlight' => '⭐',
            'volunteering' => '🤝',
            _ => '🎉',
          };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            accent.withValues(alpha: 0.24),
          ],
        ),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
    );
  }
}

class _EventMapMarker extends StatelessWidget {
  const _EventMapMarker({required this.event, this.isNearest = false});

  final MockEvent event;

  /// The marker for the event nearest the user is drawn slightly larger.
  final bool isNearest;

  @override
  Widget build(BuildContext context) {
    final pinColor = HomePageState.colorForEventType(event.eventType);
    final emoji = event.customEmoji?.isNotEmpty == true
        ? event.customEmoji!
        : switch (event.eventType) {
            'spotlight' => '⭐',
            'volunteering' => '🤝',
            _ => '🎉',
          };

    final scale = isNearest ? 1.25 : 1.0;

    return SizedBox(
      width: 48 * scale,
      height: 62 * scale,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            child: CustomPaint(
              size: Size(46 * scale, 58 * scale),
              painter: _EmojiPinPainter(color: pinColor),
            ),
          ),
          Positioned(
            top: 7 * scale,
            child: Container(
              width: 32 * scale,
              height: 32 * scale,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEF8),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4A3829), width: 1.4),
              ),
              child: Text(emoji, style: TextStyle(fontSize: 18 * scale)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A "you are here" indicator for the user's real device position: a blue dot
/// with a white ring and a soft halo, in the style of common map apps.
class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accentPrimary.withValues(alpha: 0.18),
      ),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentPrimary,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiPinPainter extends CustomPainter {
  const _EmojiPinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final radius = size.width * 0.43;
    final circleCenter = Offset(centerX, radius + 2);
    final path = Path()
      ..addOval(Rect.fromCircle(center: circleCenter, radius: radius))
      ..moveTo(centerX - 10, size.height * 0.68)
      ..quadraticBezierTo(
        centerX,
        size.height,
        centerX + 10,
        size.height * 0.68,
      )
      ..close();

    canvas.drawShadow(path, const Color(0x66000000), 5, true);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4A3829)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _EmojiPinPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _EventPager extends StatelessWidget {
  const _EventPager({
    required this.events,
    required this.controller,
    required this.onPageChanged,
  });

  final List<MockEvent> events;
  final PageController controller;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 126,
      child: PageView.builder(
        controller: controller,
        itemCount: events.length,
        onPageChanged: onPageChanged,
        padEnds: false,
        // Symmetric horizontal padding keeps every card's visual centre
        // aligned with the PageView's snap points. The old asymmetric
        // first/last padding shifted the cards off their snap centres, which
        // made paging feel like it wouldn't settle on the right card.
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _EventCard(event: events[index]),
          );
        },
      ),
    );
  }
}

class _MapCardButton extends StatelessWidget {
  const _MapCardButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.outlined = false,
    this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool outlined;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: outlined
            ? Border.all(
                color: borderColor ?? AppColors.accentPrimary,
                width: 1.4,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FilterMenuChip<T> extends StatelessWidget {
  const _FilterMenuChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.items,
    required this.value,
    required this.itemLabel,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final List<T> items;
  final T value;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedIndex = items.indexWhere((item) => item == value);

    return PopupMenuButton<int>(
      initialValue: selectedIndex < 0 ? null : selectedIndex,
      tooltip: '',
      color: isDark ? const Color(0xFF111111) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (index) => onSelected(items[index]),
      itemBuilder: (context) => List.generate(items.length, (index) {
        final item = items[index];
        return PopupMenuItem<int>(
          value: index,
          child: Text(
            itemLabel(item),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        );
      }),
      child: _BaseFilterChip(
        icon: icon,
        label: label,
        selected: selected,
        showCaret: true,
      ),
    );
  }
}

class _ToggleFilterChip extends StatelessWidget {
  const _ToggleFilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    this.showCaret = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool showCaret;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _BaseFilterChip(
        icon: icon,
        label: label,
        selected: selected,
        showCaret: showCaret,
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _SliderFilterSection extends StatelessWidget {
  const _SliderFilterSection({
    required this.title,
    required this.valueLabel,
    required this.values,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String title;
  final String valueLabel;
  final RangeValues values;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.accentPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.accentPrimary,
                inactiveTrackColor: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : AppColors.border.withValues(alpha: 0.18),
                thumbColor: AppColors.accentPrimary,
                overlayColor: AppColors.accentPrimary.withValues(alpha: 0.18),
                rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
                trackHeight: 4,
              ),
              child: RangeSlider(
                values: values,
                min: min,
                max: max,
                divisions: divisions,
                labels: RangeLabels(
                  '${values.start.toStringAsFixed(0)} km',
                  '${values.end.toStringAsFixed(0)} km',
                ),
                onChanged: onChanged,
              ),
            ),
            Row(
              children: [
                Text(
                  '${min.toStringAsFixed(0)} km',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${max.toStringAsFixed(0)} km',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterOptionChip extends StatelessWidget {
  const _FilterOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foreground = selected
        ? Colors.white
        : (isDark ? Colors.white : AppColors.textPrimary);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentPrimary
              : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.accentPrimary
                : (isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.border.withValues(alpha: 0.18)),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BaseFilterChip extends StatelessWidget {
  const _BaseFilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.showCaret,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool showCaret;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foreground = selected
        ? Colors.white
        : (isDark ? Colors.white : AppColors.textPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.accentPrimary
            : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? AppColors.accentPrimary
              : (isDark
                    ? Colors.white.withValues(alpha: 0.72)
                    : AppColors.border.withValues(alpha: 0.9)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          if (showCaret) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: foreground,
            ),
          ],
        ],
      ),
    );
  }
}
