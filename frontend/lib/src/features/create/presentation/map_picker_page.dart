import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

import 'package:fafu/src/core/config/map_config.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

/// Result returned by [MapPickerPage]: the picked coordinates and a venue name.
class MapPickResult {
  const MapPickResult({
    required this.lat,
    required this.lng,
    required this.locationName,
  });

  final double lat;
  final double lng;
  final String locationName;
}

/// Full-screen location picker. The user taps the map to drop a pin and names
/// the venue. Returns a [MapPickResult] via [Navigator.pop].
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.initialName,
  });

  final double initialLat;
  final double initialLng;
  final String? initialName;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late final TextEditingController _nameController;
  Geographic? _picked;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    if (event is! MapEventClick) return;
    setState(() => _picked = event.point);
  }

  bool get _canConfirm =>
      _picked != null && _nameController.text.trim().isNotEmpty;

  void _confirm() {
    final picked = _picked;
    if (picked == null) return;
    Navigator.of(context).pop(
      MapPickResult(
        lat: picked.lat,
        lng: picked.lon,
        locationName: _nameController.text.trim(),
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
                    initZoom: 13,
                  ),
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
                if (picked == null)
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
                          'Tap the map to drop a pin',
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Venue name',
                      hintText: 'e.g. Phoenix Marketcity',
                    ),
                  ),
                  if (picked != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${picked.lat.toStringAsFixed(5)}, '
                        '${picked.lon.toStringAsFixed(5)}',
                        style: theme.textTheme.labelMedium,
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
          ),
        ],
      ),
    );
  }
}
