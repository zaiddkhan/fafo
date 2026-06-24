import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/creators/data/creators_repository.dart';
import 'package:fafu/src/features/creators/domain/creator_application.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

class CreatorApplicationPage extends ConsumerStatefulWidget {
  const CreatorApplicationPage({super.key});

  static const routeName = 'creator-apply';
  static const routePath = '/creator/apply';

  @override
  ConsumerState<CreatorApplicationPage> createState() =>
      _CreatorApplicationPageState();
}

class _CreatorApplicationPageState
    extends ConsumerState<CreatorApplicationPage> {
  final _purposeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _socialLinksController = TextEditingController();
  final _relevantLinksController = TextEditingController();

  bool _submitting = false;
  String? _error;
  bool _submitted = false;

  @override
  void dispose() {
    _purposeController.dispose();
    _phoneController.dispose();
    _socialLinksController.dispose();
    _relevantLinksController.dispose();
    super.dispose();
  }

  List<String> _splitLinks(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final purpose = _purposeController.text.trim();
    final phone = _phoneController.text.trim();

    final purposeLetters = RegExp(r'[A-Za-z]').allMatches(purpose).length;
    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');

    if (purpose.length < 10 || purposeLetters < 10) {
      setState(
        () => _error =
            'Tell us a bit more about your purpose using words (min 10 letters).',
      );
      return;
    }
    if (RegExp(r'^\d+$').hasMatch(purpose)) {
      setState(() => _error = 'Purpose cannot be only numbers.');
      return;
    }
    if (phoneDigits.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit phone number.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final request = CreatorApplicationRequest(
      purpose: purpose,
      phone: phoneDigits,
      socialLinks: _splitLinks(_socialLinksController.text),
      relevantLinks: _splitLinks(_relevantLinksController.text),
    );

    try {
      await ref.read(creatorsRepositoryProvider).apply(request);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        // 409 = already applied/approved; surface the server message.
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _SubmittedView(onDone: () => Navigator.of(context).maybePop());
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Become a creator')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Text('Apply to host events', style: theme.textTheme.displayLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Creator verification is a one-time check so attendees can trust who is hosting. We review every application personally and reach out over email.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Label('Why do you want to create events?'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _purposeController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Tell us about the events you want to host',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Label('Contact phone'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '+91 9XXXXXXXXX'),
            ),
            const SizedBox(height: AppSpacing.md),
            _Label('Social links'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _socialLinksController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Instagram, X, etc. (comma or new line separated)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Label('Other relevant links (optional)'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _relevantLinksController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Past events, press, portfolio…',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFE5484D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: _submitting ? 'Submitting…' : 'Submit application',
              variant: AppButtonVariant.featured,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _SubmittedView extends StatelessWidget {
  const _SubmittedView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentPrimary,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Application sent!', style: theme.textTheme.displayLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'We review every creator personally and\nwill reach out over email soon.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: 'Done',
                  variant: AppButtonVariant.featured,
                  onPressed: onDone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
