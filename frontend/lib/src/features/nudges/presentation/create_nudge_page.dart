import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/nudges/data/nudges_providers.dart';
import 'package:fafu/src/features/nudges/data/nudges_repository.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';

/// Full-screen "Create Nudge" form. Returns `true` when a nudge was created.
class CreateNudgePage extends ConsumerStatefulWidget {
  const CreateNudgePage({required this.feedType, required this.targetId, this.accent = AppColors.accentPrimary, super.key});

  final NudgeFeedType feedType;
  final String targetId;
  final Color accent;

  @override
  ConsumerState<CreateNudgePage> createState() => _CreateNudgePageState();
}

class _CreateNudgePageState extends ConsumerState<CreateNudgePage> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  bool _busy = false;

  // Backend only accepts these response windows. Users pick from a dropdown so
  // the value is always valid — no free-typed, out-of-range numbers.
  static const _allowedWindows = [5, 10, 15];
  int _startInMinutes = 15;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a title first.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final location = _location.text.trim();
      await ref.read(nudgesRepositoryProvider).create(
            feedType: widget.feedType,
            targetId: widget.targetId,
            title: title,
            location: location.isEmpty ? null : location,
            windowMinutes: _startInMinutes,
          );
      ref.invalidate(nudgeFeedProvider(NudgeFeedKey(widget.feedType, widget.targetId)));
      // Refresh the friends list so this friend floats to the top with an
      // updated "Nudge sent • X ago" subtitle sourced from the backend.
      if (widget.feedType == NudgeFeedType.friend) {
        ref.invalidate(friendsListProvider);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 22, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Create Nudge',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: widget.accent,
                          fontSize: 28,
                          height: 1,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                children: [
                  const _FieldLabel('Title'),
                  const SizedBox(height: 10),
                  _NudgeField(
                    controller: _title,
                    hintText: 'Meet at coffee place',
                    maxLength: 100,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: AnimatedBuilder(
                        animation: _title,
                        builder: (context, _) => Text(
                          '(${_title.text.length}/100 Characters)',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _FieldLabel('Start in (min)'),
                  const SizedBox(height: 10),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border, width: 1.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _startInMinutes,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                        dropdownColor: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        items: _allowedWindows
                            .map((m) => DropdownMenuItem<int>(value: m, child: Text('$m minutes')))
                            .toList(),
                        onChanged: _busy ? null : (value) {
                          if (value != null) setState(() => _startInMinutes = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _FieldLabel('Location (Optional)'),
                  const SizedBox(height: 10),
                  _NudgeField(
                    controller: _location,
                    hintText: 'https://www.maps',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Share', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18),
    );
  }
}

class _NudgeField extends StatelessWidget {
  const _NudgeField({
    required this.controller,
    required this.hintText,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hintText;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          isDense: true,
          counterText: '',
          contentPadding: EdgeInsets.zero,
          hintStyle: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w600, fontSize: 15),
          hintText: hintText,
        ),
      ),
    );
  }
}
