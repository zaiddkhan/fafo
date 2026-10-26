import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fafu/src/core/config/feature_flags.dart';
import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/users/data/users_providers.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/features/users/domain/profile.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';
import 'package:fafu/src/shared/widgets/location_search_sheet.dart';

/// Edit Profile — lets the user change their core profile fields (PRD: "all
/// core fields editable"): display name, username, area, and photo.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({required this.profile, super.key});

  final ProfileResponse profile;

  static const routeName = 'edit-profile';

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _displayName;
  late final TextEditingController _username;
  final _picker = ImagePicker();

  Timer? _debounce;
  bool _checkingUsername = false;
  bool? _usernameAvailable;
  Area? _area;
  String? _areaLabel;
  XFile? _pickedPhoto;
  Uint8List? _pickedBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.profile.displayName);
    _username = TextEditingController(text: widget.profile.username);
    _area = widget.profile.area;
    _usernameAvailable = true; // current username is valid by definition
    // Area is parked with the map (V3 brief 1.2): no geocoding call.
    if (FeatureFlags.map && _area != null) _resolveAreaLabel();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _displayName.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _resolveAreaLabel() async {
    final area = _area;
    if (area == null) return;
    final label = await reverseGeocodeLabel(area.lat, area.lng);
    if (mounted) {
      setState(
        () => _areaLabel =
            label ??
            '${area.lat.toStringAsFixed(3)}, ${area.lng.toStringAsFixed(3)}',
      );
    }
  }

  void _onUsernameChanged(String value) {
    _debounce?.cancel();
    final username = value.trim().toLowerCase();
    if (username == widget.profile.username) {
      setState(() {
        _usernameAvailable = true;
        _checkingUsername = false;
      });
      return;
    }
    if (username.length < 3) {
      setState(() => _usernameAvailable = null);
      return;
    }
    setState(() => _checkingUsername = true);
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final result = await ref
            .read(usersRepositoryProvider)
            .checkUsername(username);
        if (mounted) setState(() => _usernameAvailable = result.available);
      } catch (_) {
        if (mounted) setState(() => _usernameAvailable = null);
      } finally {
        if (mounted) setState(() => _checkingUsername = false);
      }
    });
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) {
      setState(() {
        _pickedPhoto = picked;
        _pickedBytes = bytes;
      });
    }
  }

  Future<void> _changeArea() async {
    final result = await showLocationSearchSheet(context);
    if (result == null) return;
    setState(() {
      _area = Area(lat: result.lat, lng: result.lng);
      _areaLabel = result.label
          .split(',')
          .take(2)
          .map((s) => s.trim())
          .join(', ');
    });
  }

  bool get _canSave {
    final name = _displayName.text.trim();
    final username = _username.text.trim();
    return !_saving &&
        !_checkingUsername &&
        name.isNotEmpty &&
        username.length >= 3 &&
        (_usernameAvailable ?? false);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(usersRepositoryProvider);
      if (_pickedPhoto != null) {
        await repo.uploadProfilePhoto(_pickedPhoto!);
      }
      final updated = await repo.setupProfile(
        ProfileSetupRequest(
          displayName: _displayName.text.trim(),
          username: _username.text.trim().toLowerCase(),
          area: _area,
        ),
      );
      // Seed the cache with the authoritative profile the backend just returned
      // so the UI reflects the saved values immediately. Relying on
      // `invalidate` alone would trigger a `GET /users/me` refetch that can
      // momentarily return stale data (read-after-write lag), making the save
      // look like it didn't persist.
      ref.read(currentProfileProvider.notifier).setProfile(updated);
      ref.invalidate(profileStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.profile.photoUrl;
    final fieldStyle = AppTypography.ui(17, fontWeight: FontWeight.w700);
    const fieldDecoration = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 12),
    );
    final helper = _usernameHelper();
    final hasPhoto = _pickedBytes != null || currentPhoto != null;

    return FafoFormPage(
      eyebrow: 'Profile',
      title: 'Edit profile',
      footer: FafoPill(
        label: _saving ? 'Saving…' : 'Save changes',
        block: true,
        busy: _saving,
        onPressed: _canSave ? _save : null,
      ),
      children: [
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Change photo',
              child: GestureDetector(
                onTap: _pickPhoto,
                child: hasPhoto
                    ? Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 2.5),
                          image: DecorationImage(
                            image: _pickedBytes != null
                                ? MemoryImage(_pickedBytes!)
                                : NetworkImage(currentPhoto!) as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : FafoAvatar(name: _displayName.text, size: FafoAvatarSize.lg),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FafoInlineLink(
                label: hasPhoto ? 'Change photo' : 'Add a photo',
                onTap: _pickPhoto,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const FafoFieldLabel('Name'),
        TextField(
          controller: _displayName,
          style: fieldStyle,
          textCapitalization: TextCapitalization.words,
          decoration: fieldDecoration,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 22),
        const FafoFieldLabel('Username'),
        TextField(
          controller: _username,
          style: fieldStyle,
          autocorrect: false,
          decoration: fieldDecoration.copyWith(
            prefixIcon: Text('@', style: fieldStyle),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
          onChanged: _onUsernameChanged,
        ),
        if (helper != null) ...[
          const SizedBox(height: 8),
          Text(
            helper,
            style: AppTypography.ui(
              13,
              fontWeight: FontWeight.w500,
              color: _usernameAvailable == false
                  ? AppColors.signalRed
                  : _usernameAvailable == true
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ],
        // Parked with the map (V3 brief 1.2).
        if (FeatureFlags.map) ...[
          const SizedBox(height: 22),
          const FafoFieldLabel('Area'),
          FafoListRow(
            title: _area == null ? 'Set your area' : (_areaLabel ?? 'Locating…'),
            onTap: _changeArea,
          ),
        ],
      ],
    );
  }

  String? _usernameHelper() {
    if (_username.text.trim() == widget.profile.username) return null;
    if (_checkingUsername) return 'Checking…';
    if (_usernameAvailable == true) return 'That one’s yours.';
    if (_usernameAvailable == false) return 'Taken. Try another.';
    return 'At least 3 characters';
  }
}
