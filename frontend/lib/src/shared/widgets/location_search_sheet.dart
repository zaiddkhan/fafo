import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';

/// A single geocoded place result.
class LocationSearchResult {
  const LocationSearchResult({
    required this.label,
    required this.lat,
    required this.lng,
  });

  final String label;
  final double lat;
  final double lng;

  static LocationSearchResult? fromJson(Map<String, dynamic> json) {
    final label = json['display_name'];
    final lat = double.tryParse('${json['lat']}');
    final lng = double.tryParse('${json['lon']}');
    if (label is! String || label.isEmpty || lat == null || lng == null) {
      return null;
    }
    return LocationSearchResult(label: label, lat: lat, lng: lng);
  }
}

/// Reverse-geocodes a coordinate into a short human-readable place label
/// (e.g. "Indiranagar, Bengaluru"). Returns null if it can't be resolved.
Future<String?> reverseGeocodeLabel(double lat, double lng) async {
  try {
    final response = await Dio()
        .get<Map<String, dynamic>>(
          'https://nominatim.openstreetmap.org/reverse',
          queryParameters: {
            'format': 'jsonv2',
            'lat': lat,
            'lon': lng,
            'zoom': 14,
          },
          options: Options(headers: {'User-Agent': 'Fafo Flutter Web'}),
        )
        .timeout(const Duration(seconds: 8));
    final name = response.data?['display_name'];
    if (name is String && name.isNotEmpty) {
      // Keep it short — first two comma-separated parts.
      return name.split(',').take(2).map((s) => s.trim()).join(', ');
    }
  } catch (_) {
    // Fall through to null; caller shows coordinates instead.
  }
  return null;
}

/// Opens the location search bottom sheet and returns the chosen place, or null.
Future<LocationSearchResult?> showLocationSearchSheet(BuildContext context) {
  return showModalBottomSheet<LocationSearchResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const LocationSearchSheet(),
  );
}

/// Reusable place-search sheet backed by OpenStreetMap Nominatim. Used by both
/// onboarding (set initial area) and settings (change area).
class LocationSearchSheet extends StatefulWidget {
  const LocationSearchSheet({super.key});

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final _controller = TextEditingController();
  List<LocationSearchResult> _results = const [];
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.length < 2 || _searching) return;

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final results = await _searchLocations(query);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<List<LocationSearchResult>> _searchLocations(String query) async {
    final response = await Dio()
        .get<List<dynamic>>(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {'format': 'jsonv2', 'q': query, 'limit': 6},
          options: Options(headers: {'User-Agent': 'Fafo Flutter Web'}),
        )
        .timeout(const Duration(seconds: 10));

    return (response.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LocationSearchResult.fromJson)
        .whereType<LocationSearchResult>()
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search location', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: 'City, neighborhood, or venue',
                suffixIcon: IconButton(
                  onPressed: _searching ? null : _search,
                  icon: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: theme.textTheme.labelMedium?.copyWith(color: Colors.red),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(
                      result.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${result.lat.toStringAsFixed(4)}, ${result.lng.toStringAsFixed(4)}',
                    ),
                    onTap: () => Navigator.of(context).pop(result),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
