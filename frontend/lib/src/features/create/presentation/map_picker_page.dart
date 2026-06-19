import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

import 'package:fafu/src/core/config/map_config.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/shared/services/mapbox_search_service.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

/// Result returned by [MapPickerPage]: the picked coordinates, venue name, an
/// optional full address, and optional free-text details (floor/room/landmark).
class MapPickResult {
  const MapPickResult({
    required this.lat,
    required this.lng,
    required this.locationName,
    this.address,
    this.locationDetails,
  });

  final double lat;
  final double lng;
  final String locationName;
  final String? address;
  final String? locationDetails;
}

/// Full-screen, search-first location picker. The user searches for a place
/// (Mapbox Search Box autocomplete), which fills the venue name, address and
/// exact coordinates; they can then nudge the pin on the map and add extra
/// details. Returns a [MapPickResult] via [Navigator.pop].
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.initialName,
    this.initialAddress,
    this.initialDetails,
    this.hasInitialPin = false,
  });

  final double initialLat;
  final double initialLng;
  final String? initialName;
  final String? initialAddress;
  final String? initialDetails;

  /// When true, [initialLat]/[initialLng] represent an already-chosen pin
  /// (editing an event) rather than just a map center.
  final bool hasInitialPin;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _detailsController;
  final _searchController = TextEditingController();
  final _searchService = MapboxSearchService();

  MapController? _mapController;
  Geographic? _picked;
  String? _address;

  List<MapboxSuggestion> _suggestions = const [];
  bool _searching = false;
  String? _searchError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _detailsController = TextEditingController(text: widget.initialDetails ?? '');
    _address = widget.initialAddress;
    if (widget.hasInitialPin) {
      _picked = Geographic(lon: widget.initialLng, lat: widget.initialLat);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _detailsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = const [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(value));
  }

  Future<void> _runSearch(String query) async {
    if (!_searchService.isConfigured) {
      setState(() => _searchError = 'Search unavailable — tap the map to place a pin.');
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final center = _picked;
      final results = await _searchService.suggest(
        query,
        proximityLat: center?.lat ?? widget.initialLat,
        proximityLng: center?.lon ?? widget.initialLng,
      );
      if (!mounted) return;
      setState(() => _suggestions = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchError = 'Could not search right now. Try again.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _selectSuggestion(MapboxSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _suggestions = const [];
      _searchController.text = suggestion.name;
    });
    try {
      final place = await _searchService.retrieve(suggestion);
      if (!mounted || place == null) {
        if (mounted) setState(() => _searchError = 'Could not load that place.');
        return;
      }
      setState(() {
        _picked = Geographic(lon: place.lng, lat: place.lat);
        _address = place.address.isEmpty ? null : place.address;
        if (_nameController.text.trim().isEmpty ||
            _nameController.text.trim() == suggestion.name) {
          _nameController.text = place.name;
        }
        _searchError = null;
      });
      await _mapController?.animateCamera(
        center: Geographic(lon: place.lng, lat: place.lat),
        zoom: 16,
        nativeDuration: const Duration(milliseconds: 600),
      );
    } catch (_) {
      if (mounted) setState(() => _searchError = 'Could not load that place.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onMapEvent(MapEvent event) {
    if (event is! MapEventClick) return;
    // Manually nudging the pin clears any auto-filled address — the new point
    // may not match it.
    setState(() {
      _picked = event.point;
      _address = null;
      _suggestions = const [];
    });
    FocusScope.of(context).unfocus();
  }

  bool get _canConfirm =>
      _picked != null && _nameController.text.trim().isNotEmpty;

  void _confirm() {
    final picked = _picked;
    if (picked == null) return;
    final details = _detailsController.text.trim();
    Navigator.of(context).pop(
      MapPickResult(
        lat: picked.lat,
        lng: picked.lon,
        locationName: _nameController.text.trim(),
        address: _address,
        locationDetails: details.isEmpty ? null : details,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picked = _picked;

    return Scaffold(
      appBar: AppBar(title: const Text('Pick location')),
      body: Column(
        children: [
          _buildSearchField(theme),
          Expanded(
            child: Stack(
              children: [
                MapLibreMap(
                  options: MapOptions(
                    initStyle: MapConfig.vintageStyleUrl,
                    initCenter: Geographic(
                      lon: widget.initialLng,
                      lat: widget.initialLat,
                    ),
                    initZoom: widget.hasInitialPin ? 16 : 13,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onEvent: _onMapEvent,
                  children: [
                    if (picked != null)
                      WidgetLayer(
                        markers: [
                          Marker(
                            point: picked,
                            size: const Size(44, 52),
                            alignment: Alignment.bottomCenter,
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.accentPrimary,
                              size: 48,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_suggestions.isNotEmpty) _buildSuggestionList(theme),
                if (_suggestions.isEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          picked == null
                              ? 'Search above, or tap the map to drop a pin'
                              : 'Tap the map to fine-tune the exact spot',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildBottomPanel(theme, picked),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search for a place or address',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : (_searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _suggestions = const [];
                            _searchError = null;
                          });
                        },
                      )
                    : null),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildSuggestionList(ThemeData theme) {
    return Positioned(
      left: 8,
      right: 8,
      top: 8,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _suggestions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = _suggestions[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.place_outlined),
                title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: s.placeFormatted.isEmpty
                    ? null
                    : Text(
                        s.placeFormatted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                onTap: () => _selectSuggestion(s),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(ThemeData theme, Geographic? picked) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_searchError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _searchError!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFFE5484D),
                  ),
                ),
              ),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Venue name',
                hintText: 'e.g. Phoenix Marketcity',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Floor, room, unit or landmark (optional)',
                hintText: 'e.g. 3rd floor, Hall B, near the food court',
                counterText: '',
              ),
            ),
            if (_address != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.place, size: 14, color: AppColors.accentPrimary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _address!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
              ),
            if (picked != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${picked.lat.toStringAsFixed(5)}, '
                  '${picked.lon.toStringAsFixed(5)}',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Confirm location',
              variant: AppButtonVariant.featured,
              onPressed: _canConfirm ? _confirm : null,
            ),
          ],
        ),
      ),
    );
  }
}
