import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The area the user has explicitly chosen in Settings. When set, it overrides
/// GPS as the map's centre (PRD: "When a user changes their area in settings,
/// the map re-centres"). Persisted locally so it survives restarts.
class SelectedArea {
  const SelectedArea({required this.lat, required this.lng, required this.label});

  final double lat;
  final double lng;
  final String label;
}

class SelectedAreaController extends Notifier<SelectedArea?> {
  static const _kLat = 'selected_area_lat';
  static const _kLng = 'selected_area_lng';
  static const _kLabel = 'selected_area_label';

  @override
  SelectedArea? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_kLat);
    final lng = prefs.getDouble(_kLng);
    final label = prefs.getString(_kLabel);
    if (lat != null && lng != null && label != null) {
      state = SelectedArea(lat: lat, lng: lng, label: label);
    }
  }

  Future<void> setArea({required double lat, required double lng, required String label}) async {
    state = SelectedArea(lat: lat, lng: lng, label: label);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLat, lat);
    await prefs.setDouble(_kLng, lng);
    await prefs.setString(_kLabel, label);
  }
}

final selectedAreaProvider = NotifierProvider<SelectedAreaController, SelectedArea?>(
  SelectedAreaController.new,
);
