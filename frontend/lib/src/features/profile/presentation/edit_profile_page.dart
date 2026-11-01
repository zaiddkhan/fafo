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
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';

/// Edit Profile — lets the user change their core profile fields (PRD: "all
/// core fields editable"): display name, username, area, and photo.
/// Opens Edit profile from the header photo, its Edit pill, or Profile.
Future<void> showEditProfileSheet(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final profile = container.read(currentProfileProvider).value;
  if (profile == null) {
    FafoToasts.show('Profile still loading…', kind: FafoToastKind.info);
    return;
  }
  await showFafoSheet<bool>(
    context,
    title: 'Edit profile',
    builder: (_) => EditProfilePage(profile: profile),
  );
}

/// Edit profile (a sheet): photo, name, username with a live check.
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

  bool get _dirty =>
      _pickedPhoto != null ||
      _displayName.text.trim() != widget.profile.displayName ||
      _username.text.trim().toLowerCase() != widget.profile.username ||
      _area != widget.profile.area;

  bool get _canSave {
    final name = _displayName.text.trim();
    final username = _username.text.trim();
    return _dirty &&
        !_saving &&
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
        FafoToasts.show('Profile updated.');
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        FafoToasts.show(e.message, kind: FafoToastKind.error);
      }
    } catch (e) {
      if (mounted) {
        FafoToasts.error(e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.profile.photoUrl;
    final helper = _usernameHelper();
    final hasPhoto = _pickedBytes != null || (currentPhoto != null && currentPhoto.isNotEmpty);

    return FafoSheetBody(
      footer: FafoPill(
        label: 'Save',
        block: true,
        busy: _saving,
        onPressed: _canSave ? _save : null,
      ),
      children: [
        Center(
          child: Semantics(
            button: true,
            label: 'Change photo',
            child: GestureDetector(
              onTap: _pickPhoto,
              child: FafoProfilePhoto(
                photoUrl: currentPhoto,
                size: 104,
                bytes: _pickedBytes == null ? null : MemoryImage(_pickedBytes!),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: FafoTextButton(label: hasPhoto ? 'Change photo' : 'Add a photo', onTap: _pickPhoto),
        ),
        const FafoSectionLabel('Name', top: 18, bottom: 10),
        FafoInput(
          controller: _displayName,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${_displayName.text.characters.length}/30',
              style: AppTypography.label(fontSize: 11, color: AppColors.textSecondary).copyWith(letterSpacing: 0),
            ),
          ),
        ),
        const FafoSectionLabel('Username', top: 10, bottom: 10),
        FafoInput(
          controller: _username,
          prefix: '@',
          maxLength: 30,
          autocorrect: false,
          error: _usernameAvailable == false ? helper : null,
          onChanged: _onUsernameChanged,
        ),
        const SizedBox(height: 8),
        _UsernameHelper(
          text: helper ?? 'Friends find you by this.',
          available: helper == null ? null : _usernameAvailable,
          checking: _checkingUsername,
        ),
        if (FeatureFlags.map) ...[
          const FafoSectionLabel('Area'),
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
    final u = _username.text.trim().toLowerCase();
    if (_usernameAvailable == true) return '@$u is yours if you want it.';
    if (_usernameAvailable == false) return '@$u is taken. Try another.';
    return '3 to 30 lowercase letters, numbers, . or _';
  }
}

/// Under the username: the hint, or the live check (Checking, available with
/// a blue dot, taken in red).
class _UsernameHelper extends StatelessWidget {
  const _UsernameHelper({required this.text, required this.available, required this.checking});

  final String text;
  final bool? available;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final color = available == false && !checking ? AppColors.errorText : AppColors.textSecondary;
    return Row(
      children: [
        if (available == true && !checking) ...[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.accentPrimary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(text, style: AppTypography.ui(13, fontWeight: FontWeight.w400, color: color)),
        ),
      ],
    );
  }
}
