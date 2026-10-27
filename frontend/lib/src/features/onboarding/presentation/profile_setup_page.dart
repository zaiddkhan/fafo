import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fafu/src/core/config/feature_flags.dart';
import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/router/app_router.dart';
import 'package:fafu/src/core/services/deep_link_service.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/home/presentation/main_shell.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/features/users/domain/profile.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';

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
  // Optional friend's referral code (V3 brief 3.8).
  final _codeController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final code = prefs.getString(pendingReferralCodeKey);
      if (code != null && mounted && _codeController.text.isEmpty) {
        _codeController.text = code;
      }
    });
    // Nothing in V3 needs location, so the app never asks (brief 1.2).
    if (FeatureFlags.map) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
    }
  }

  String _fallbackAreaLabel(Area area) {
    return '${area.lat.toStringAsFixed(4)}, ${area.lng.toStringAsFixed(4)}';
  }

  Future<String> _reverseGeocodeArea(Area area) async {
    try {
      final response = await Dio()
          .get<Map<String, dynamic>>(
            'https://nominatim.openstreetmap.org/reverse',
            queryParameters: {
              'format': 'jsonv2',
              'lat': area.lat,
              'lon': area.lng,
            },
            options: Options(headers: {'User-Agent': 'Fafo Flutter Web'}),
          )
          .timeout(const Duration(seconds: 8));
      final data = response.data;
      final address = data?['address'] as Map<String, dynamic>?;
      final neighborhood =
          address?['neighbourhood'] ??
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
        if (mounted) FafoToasts.show(friendlyErrorMessage(e), kind: FafoToastKind.error);
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
        (!FeatureFlags.map || _selectedArea != null) &&
        !_saving;
  }

  Future<void> _saveProfile() async {
    if (!_canContinue) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
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
              .catchError(
                (_) => PhotoUploadResponse(uploadPath: '', photoUrl: ''),
              ),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(onboardingCompleteKey, true);

      // Signing up with a code makes both people friends. Never blocks
      // onboarding: a bad code just says so.
      final code = _codeController.text.trim();
      if (code.isNotEmpty) {
        try {
          final result = await ref.read(friendsRepositoryProvider).redeemReferralCode(code);
          messenger.toast('You and ${result.friend.displayName} are friends now.');
        } catch (e) {
          messenger.toast('Code didn’t work: ${friendlyErrorMessage(e)}', kind: FafoToastKind.error);
        }
      }
      await prefs.remove(pendingReferralCodeKey);

      if (mounted) {
        final pendingPath = await consumePendingDeepLinkPath();
        if (!mounted) return;
        context.go(pendingPath ?? MainShell.routePath);
      }
    } catch (e) {
      if (mounted) FafoToasts.show(friendlyErrorMessage(e), kind: FafoToastKind.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = _usernameController.text.trim();
    final usernameHelper =
        !_isUsernameShapeValid(username) && username.isNotEmpty
        ? 'Use 3-30 lowercase letters, numbers, dots, or underscores.'
        : _checkingUsername
        ? 'Checking…'
        : _usernameAvailable == true
        ? 'That one’s yours.'
        : _usernameAvailable == false
        ? 'Taken. Try another.'
        : 'Friends find you by this.';
    final helperColor = _usernameAvailable == false ||
            (!_isUsernameShapeValid(username) && username.isNotEmpty)
        ? AppColors.signalRed
        : _usernameAvailable == true
        ? AppColors.textPrimary
        : AppColors.textSecondary;
    final fieldStyle = AppTypography.ui(17, fontWeight: FontWeight.w700);
    const fieldDecoration = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 12),
    );
    final name = _nameController.text.trim();

    return FafoFormPage(
      eyebrow: 'Profile',
      title: 'Who’s this?',
      subtitle: 'Your name and handle are how friends find you.',
      showBack: false,
      footer: FafoPill(
        label: _saving ? 'Saving…' : 'Continue',
        block: true,
        busy: _saving,
        onPressed: _canContinue ? _saveProfile : null,
      ),
      children: [
        // Avatar: the photo if picked, else the red initial the app uses.
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Add a photo',
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (_selectedAvatarBytes != null)
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 2.5),
                          image: DecorationImage(
                            image: MemoryImage(_selectedAvatarBytes!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      FafoAvatar(name: name.isEmpty ? '+' : name, size: FafoAvatarSize.lg),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: Icon(Icons.camera_alt_outlined, size: 15, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FafoInlineLink(
                label: _selectedAvatarBytes == null ? 'Add a photo' : 'Change photo',
                onTap: _pickAvatar,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const FafoFieldLabel('Name'),
        TextField(
          controller: _nameController,
          style: fieldStyle,
          textCapitalization: TextCapitalization.words,
          decoration: fieldDecoration.copyWith(hintText: 'Maya'),
        ),
        const SizedBox(height: 22),
        const FafoFieldLabel('Username'),
        TextField(
          controller: _usernameController,
          style: fieldStyle,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          onChanged: _onUsernameChanged,
          decoration: fieldDecoration.copyWith(
            hintText: 'maya',
            // Always visible, unlike prefixText (which hides until focus).
            prefixIcon: Text('@', style: fieldStyle),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
        const SizedBox(height: 8),
        Text(usernameHelper, style: AppTypography.ui(13, fontWeight: FontWeight.w500, color: helperColor)),
        if (FeatureFlags.map) ...[
          const SizedBox(height: AppSpacing.lg),
          _AreaSetupCard(
            label: _areaLabel,
            radiusKm: _selectedArea?.radiusKm ?? 15,
            detecting: _detectingArea,
            hasArea: _selectedArea != null,
            onUseCurrentLocation: _useCurrentLocation,
            onSearchLocation: _openLocationSearchSheet,
          ),
        ],
        const SizedBox(height: 22),
        const FafoFieldLabel('Friend’s code (optional)'),
        TextField(
          controller: _codeController,
          style: fieldStyle,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          decoration: fieldDecoration.copyWith(hintText: 'MAYA-7K2QX'),
        ),
        const SizedBox(height: 8),
        Text(
          'You’ll show up in each other’s invites.',
          style: AppTypography.ui(13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        ),
      ],
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
                color: hasArea
                    ? AppColors.accentPrimary
                    : AppColors.textTertiary,
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
    });

    try {
      final results = await _searchLocations(query);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) FafoToasts.show(friendlyErrorMessage(e), kind: FafoToastKind.error);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<List<_LocationSearchResult>> _searchLocations(String query) async {
    final response = await Dio()
        .get<List<dynamic>>(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {'format': 'jsonv2', 'q': query, 'limit': 6},
          options: Options(headers: {'User-Agent': 'Fafo Flutter Web'}),
        )
        .timeout(const Duration(seconds: 10));

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
