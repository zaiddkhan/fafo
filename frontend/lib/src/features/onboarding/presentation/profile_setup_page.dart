import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/router/app_router.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/home/presentation/main_shell.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/features/users/domain/profile.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  static const routeName = 'profile-setup';
  static const routePath = '/onboarding/profile';

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _imagePicker = ImagePicker();

  XFile? _selectedAvatar;
  Uint8List? _selectedAvatarBytes;
  Area? _selectedArea;
  String? _areaLabel;
  bool _detectingArea = false;
  Timer? _usernameDebounce;
  bool? _usernameAvailable;
  bool _checkingUsername = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
  }

  String _fallbackAreaLabel(Area area) {
    return '${area.lat.toStringAsFixed(4)}, ${area.lng.toStringAsFixed(4)}';
  }

  Future<String> _reverseGeocodeArea(Area area) async {
    try {
      final response = await Dio().get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': area.lat,
          'lon': area.lng,
        },
        options: Options(headers: {'User-Agent': 'WhatsPopn Flutter Web'}),
      ).timeout(const Duration(seconds: 8));
      final data = response.data;
      final address = data?['address'] as Map<String, dynamic>?;
      final neighborhood = address?['neighbourhood'] ??
          address?['suburb'] ??
          address?['city'] ??
          address?['town'] ??
          address?['state'];
      if (neighborhood is String && neighborhood.isNotEmpty) {
        return neighborhood;
      }
      final displayName = data?['display_name'];
      if (displayName is String && displayName.isNotEmpty) {
        return displayName.split(',').take(2).join(',');
      }
    } catch (_) {}
    return _fallbackAreaLabel(area);
  }

  Future<Area?> _resolveArea() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return Area(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_detectingArea) return;
    setState(() {
      _detectingArea = true;
      _error = null;
    });

    try {
      final area = await _resolveArea().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (area == null) {
        if (mounted) {
          setState(() {
            _areaLabel = 'Location permission unavailable. Search manually.';
          });
        }
        return;
      }
      final label = await _reverseGeocodeArea(area);
      if (mounted) {
        setState(() {
          _selectedArea = area;
          _areaLabel = label;
        });
      }
    } finally {
      if (mounted) setState(() => _detectingArea = false);
    }
  }

  Future<void> _openLocationSearchSheet() async {
    final selected = await showModalBottomSheet<_LocationSearchResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _LocationSearchSheet(),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _selectedArea = Area(lat: selected.lat, lng: selected.lng);
      _areaLabel = selected.label;
      _error = null;
    });
  }

  Future<void> _pickAvatar() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image == null || !mounted) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedAvatar = image;
      _selectedAvatarBytes = bytes;
    });
  }

  void _onUsernameChanged(String value) {
    final normalized = value.toLowerCase().trim();
    if (value != normalized) {
      _usernameController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }

    _usernameDebounce?.cancel();
    setState(() {
      _usernameAvailable = null;
      _error = null;
    });

    if (!_isUsernameShapeValid(normalized)) return;

    _usernameDebounce = Timer(const Duration(milliseconds: 450), () async {
      setState(() => _checkingUsername = true);
      try {
        final result = await ref
            .read(usersRepositoryProvider)
            .checkUsername(normalized);
        if (mounted) setState(() => _usernameAvailable = result.available);
      } catch (e) {
        if (mounted) setState(() => _error = e.toString());
      } finally {
        if (mounted) setState(() => _checkingUsername = false);
      }
    });
  }

  bool _isUsernameShapeValid(String username) {
    return RegExp(r'^[a-z0-9._]{3,30}$').hasMatch(username);
  }

  bool get _canContinue {
    return _nameController.text.trim().isNotEmpty &&
        _isUsernameShapeValid(_usernameController.text.trim()) &&
        _usernameAvailable == true &&
        _selectedArea != null &&
        !_saving;
  }

  Future<void> _saveProfile() async {
    if (!_canContinue) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final area = _selectedArea;
      await usersRepo.setupProfile(
        ProfileSetupRequest(
          displayName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          area: area,
        ),
      );

      // Do not block onboarding on profile photo upload. On Flutter Web,
      // Firebase Storage can hang because of CORS/network rules; the profile is
      // already created, so continue and let the user reach the app.
      if (_selectedAvatar != null) {
        unawaited(
          usersRepo
              .uploadProfilePhoto(_selectedAvatar!)
              .timeout(const Duration(seconds: 12))
              .catchError((_) => PhotoUploadResponse(uploadPath: '', photoUrl: '')),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(onboardingCompleteKey, true);

      if (mounted) context.go(MainShell.routePath);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final username = _usernameController.text.trim();
    final usernameHelper =
        !_isUsernameShapeValid(username) && username.isNotEmpty
        ? 'Use 3-30 lowercase letters, numbers, dots, or underscores.'
        : _checkingUsername
        ? 'Checking availability...'
        : _usernameAvailable == true
        ? 'Username is available.'
        : _usernameAvailable == false
        ? 'Username is already taken.'
        : 'Choose a unique username.';

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg + viewInsets.bottom,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'Set up your\nprofile',
                        style: theme.textTheme.displayLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Add your name, unique username, and profile photo.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.bgSecondary,
                              border: Border.all(color: AppColors.border),
                              image: _selectedAvatarBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_selectedAvatarBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _selectedAvatarBytes == null
                                ? Icon(
                                    Icons.camera_alt_outlined,
                                    color: AppColors.textTertiary,
                                    size: AppSpacing.lg,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextField(
                        controller: _nameController,
                        style: theme.textTheme.bodyLarge,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() => _error = null),
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _usernameController,
                        style: theme.textTheme.bodyLarge,
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        onChanged: _onUsernameChanged,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixText: '@',
                          helperText: usernameHelper,
                          helperStyle: theme.textTheme.labelMedium?.copyWith(
                            color: _usernameAvailable == true
                                ? Colors.green
                                : _usernameAvailable == false
                                ? Colors.red
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _AreaSetupCard(
                        label: _areaLabel,
                        radiusKm: _selectedArea?.radiusKm ?? 15,
                        detecting: _detectingArea,
                        hasArea: _selectedArea != null,
                        onUseCurrentLocation: _useCurrentLocation,
                        onSearchLocation: _openLocationSearchSheet,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _error!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: _saving ? 'Saving...' : 'Continue',
                        variant: AppButtonVariant.featured,
                        onPressed: _canContinue ? _saveProfile : null,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AreaSetupCard extends StatelessWidget {
  const _AreaSetupCard({
    required this.label,
    required this.radiusKm,
    required this.detecting,
    required this.hasArea,
    required this.onUseCurrentLocation,
    required this.onSearchLocation,
  });

  final String? label;
  final double radiusKm;
  final bool detecting;
  final bool hasArea;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onSearchLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasArea ? AppColors.accentPrimary : AppColors.border,
          width: hasArea ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: hasArea ? AppColors.accentPrimary : AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Your area',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            detecting
                ? 'Detecting your location...'
                : hasArea
                ? 'Detected near: ${label ?? 'your location'}'
                : (label ?? 'Choose an area to discover nearby events.'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Radius: ${radiusKm.toStringAsFixed(0)} km',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: detecting ? null : onUseCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: Text(detecting ? 'Detecting' : 'Use current'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSearchLocation,
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Search'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet();

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _controller = TextEditingController();
  List<_LocationSearchResult> _results = const [];
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

  Future<List<_LocationSearchResult>> _searchLocations(String query) async {
    final response = await Dio().get<List<dynamic>>(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'format': 'jsonv2',
        'q': query,
        'limit': 6,
      },
      options: Options(headers: {'User-Agent': 'WhatsPopn Flutter Web'}),
    ).timeout(const Duration(seconds: 10));

    return (response.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_LocationSearchResult.fromJson)
        .whereType<_LocationSearchResult>()
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
            Text(
              'Search location',
              style: theme.textTheme.headlineSmall,
            ),
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

class _LocationSearchResult {
  const _LocationSearchResult({
    required this.label,
    required this.lat,
    required this.lng,
  });

  final String label;
  final double lat;
  final double lng;

  static _LocationSearchResult? fromJson(Map<String, dynamic> json) {
    final label = json['display_name'];
    final lat = double.tryParse('${json['lat']}');
    final lng = double.tryParse('${json['lon']}');
    if (label is! String || label.isEmpty || lat == null || lng == null) {
      return null;
    }
    return _LocationSearchResult(label: label, lat: lat, lng: lng);
  }
}
