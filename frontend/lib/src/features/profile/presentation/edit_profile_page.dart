import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/users/data/users_providers.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/features/users/domain/profile.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';
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
    if (_area != null) _resolveAreaLabel();
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
      setState(() => _areaLabel = label ?? '${area.lat.toStringAsFixed(3)}, ${area.lng.toStringAsFixed(3)}');
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
        final result = await ref.read(usersRepositoryProvider).checkUsername(username);
        if (mounted) setState(() => _usernameAvailable = result.available);
      } catch (_) {
        if (mounted) setState(() => _usernameAvailable = null);
      } finally {
        if (mounted) setState(() => _checkingUsername = false);
      }
    });
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
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
      _areaLabel = result.label.split(',').take(2).map((s) => s.trim()).join(', ');
    });
  }

  bool get _canSave {
    final name = _displayName.text.trim();
    final username = _username.text.trim();
    return !_saving && !_checkingUsername && name.isNotEmpty && username.length >= 3 && (_usernameAvailable ?? false);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(usersRepositoryProvider);
      if (_pickedPhoto != null) {
        await repo.uploadProfilePhoto(_pickedPhoto!);
      }
      await repo.setupProfile(ProfileSetupRequest(
        displayName: _displayName.text.trim(),
        username: _username.text.trim().toLowerCase(),
        area: _area,
      ));
      ref.invalidate(currentProfileProvider);
      ref.invalidate(profileStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPhoto = widget.profile.photoUrl;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.bgSecondary,
                    backgroundImage: _pickedBytes != null
                        ? MemoryImage(_pickedBytes!)
                        : (currentPhoto != null ? NetworkImage(currentPhoto) as ImageProvider : null),
                    child: (_pickedBytes == null && currentPhoto == null)
                        ? const Icon(Icons.person, size: 42)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bgPrimary, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(onPressed: _pickPhoto, child: const Text('Change photo')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _displayName,
            decoration: const InputDecoration(labelText: 'Display name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _username,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixText: '@',
              helperText: _usernameHelper(),
              helperStyle: TextStyle(
                color: _usernameAvailable == false ? const Color(0xFFE5484D) : AppColors.textSecondary,
              ),
              suffixIcon: _checkingUsername
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : (_usernameAvailable == true
                      ? const Icon(Icons.check_circle, color: Color(0xFF38A849))
                      : null),
            ),
            onChanged: _onUsernameChanged,
          ),
          const SizedBox(height: 16),
          Text('Area', style: theme.textTheme.labelLarge?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          InkWell(
            onTap: _changeArea,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _area == null ? 'Set your area' : (_areaLabel ?? 'Locating…'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: _saving ? 'Saving…' : 'Save changes',
            onPressed: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }

  String? _usernameHelper() {
    if (_username.text.trim() == widget.profile.username) return null;
    if (_checkingUsername) return 'Checking availability…';
    if (_usernameAvailable == true) return 'Username available';
    if (_usernameAvailable == false) return 'Username already taken';
    return 'At least 3 characters';
  }
}
