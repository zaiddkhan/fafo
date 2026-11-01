import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/groups/domain/group.dart';
import 'package:fafu/src/features/groups/presentation/new_group_page.dart';
import 'package:fafu/src/features/notifications/data/notification_nag.dart';
import 'package:fafu/src/features/right_now/data/right_now_providers.dart';
import 'package:fafu/src/features/right_now/presentation/code_sheet.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// Set once the contacts ask has been answered, so the explainer shows once.
const contactsAskedKey = 'contacts_asked';

final _referralProvider = FutureProvider.autoDispose<ReferralCode>(
  (ref) => ref.watch(friendsRepositoryProvider).getReferralCode(),
);

/// Opens Add friends. Resolves with a group made from "New group", so the
/// Friends tab can show and highlight it.
Future<GroupResponse?> showAddFriendsSheet(BuildContext context) {
  return showFafoSheet<GroupResponse>(
    context,
    title: 'Add friends',
    tall: true,
    builder: (_) => const AddFriendsSheet(),
  );
}

enum _ContactsState { unknown, ask, denied, loading, ready }

/// Add friends: search, New group, Share link, then contacts already on FaFo
/// (Add) and the rest (Invite by SMS). First time, it explains before asking
/// for contacts.
class AddFriendsSheet extends ConsumerStatefulWidget {
  const AddFriendsSheet({super.key});

  @override
  ConsumerState<AddFriendsSheet> createState() => _AddFriendsSheetState();
}

class _AddFriendsSheetState extends ConsumerState<AddFriendsSheet> {
  final _search = TextEditingController();
  _ContactsState _state = _ContactsState.unknown;
  List<_Contact> _contacts = const [];
  final Set<String> _requested = {};
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _start();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (prefs.getBool(contactsAskedKey) ?? false) {
      await _load();
    } else {
      setState(() => _state = _ContactsState.ask);
    }
  }

  Future<void> _allow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(contactsAskedKey, true);
    await _load();
  }

  Future<void> _openSettings() async {
    // Android can still show the system prompt; if not, go to the phone's
    // settings for FaFo.
    if (await FlutterContacts.requestPermission(readonly: true)) {
      await _load();
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await launchUrl(Uri.parse('app-settings:'));
    } else {
      await ref.read(notificationNagProvider.notifier).openSettings();
    }
  }

  Future<void> _load() async {
    setState(() => _state = _ContactsState.loading);
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (mounted) setState(() => _state = _ContactsState.denied);
        return;
      }
      final raw = await FlutterContacts.getContacts(withProperties: true);
      final local = [
        for (final c in raw) _Contact.fromContact(c),
      ].where((c) => c.phones.isNotEmpty).toList();
      final numbers = {for (final c in local) ...c.normalized}.toList();
      final matches = await ref.read(friendsRepositoryProvider).syncContacts(numbers);
      final byPhone = <String, PublicUserResponse>{};
      for (final m in matches) {
        byPhone[normalizePhone(m.normalizedPhone)] = m.user;
        byPhone[normalizePhone(m.phone)] = m.user;
      }
      final merged = [
        for (final c in local) c.withUser(c.normalized.map((p) => byPhone[p]).nonNulls.firstOrNull),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(contactsSyncedAtKey, DateTime.now().millisecondsSinceEpoch);
      if (mounted) {
        setState(() {
          _contacts = merged;
          _state = _ContactsState.ready;
        });
      }
    } catch (e) {
      FafoToasts.error(e);
      if (mounted) setState(() => _state = _ContactsState.ready);
    }
  }

  Future<void> _add(PublicUserResponse user) async {
    if (_busy.contains(user.uid)) return;
    setState(() => _busy.add(user.uid));
    try {
      await ref.read(friendsRepositoryProvider).sendFriendRequest(uid: user.uid);
      ref.invalidate(outgoingFriendRequestsProvider);
      await ref.read(liveFriendsProvider.notifier).refresh();
      if (mounted) setState(() => _requested.add(user.uid));
      FafoToasts.show('Sent to ${user.displayName.split(' ').first}.');
    } catch (e) {
      FafoToasts.error(e);
    } finally {
      if (mounted) setState(() => _busy.remove(user.uid));
    }
  }

  Future<void> _invite(_Contact c) async {
    final link = ref.read(_referralProvider).value?.shareUrl ?? 'getfafo.app';
    final first = c.name.split(' ').first;
    final body = Uri.encodeComponent('Hey $first, I’m on FaFo. Send me a plan and I’ll send you one. $link');
    final phone = c.phones.first.replaceAll(RegExp(r'[^0-9+]'), '');
    for (final uri in [Uri.parse('sms:$phone?body=$body'), Uri.parse('smsto:$phone?body=$body')]) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
    }
    FafoToasts.show('Couldn’t open messages.', kind: FafoToastKind.error);
  }

  Future<void> _share(ReferralCode? code) async {
    if (code == null) return;
    await SharePlus.instance.share(
      ShareParams(text: 'I’m on FaFo. Send me a plan and I’ll send you one. ${code.shareUrl}'),
    );
  }

  Future<void> _newGroup() async {
    final group = await Navigator.of(context).push(MaterialPageRoute<GroupResponse>(builder: (_) => const NewGroupPage()));
    if (group != null && mounted) Navigator.of(context).pop(group);
  }

  @override
  Widget build(BuildContext context) {
    final code = ref.watch(_referralProvider).value;
    final friendIds = {for (final f in ref.watch(liveFriendsProvider).value ?? const <FriendResponse>[]) f.user.uid};
    final q = _search.text.trim().toLowerCase();
    final qDigits = q.replaceAll(RegExp(r'\D'), '');
    bool hit(_Contact c) =>
        q.isEmpty ||
        c.name.toLowerCase().contains(q) ||
        (qDigits.length >= 3 && c.normalized.any((p) => p.contains(qDigits)));
    final onFafo = [for (final c in _contacts) if (c.user != null && !friendIds.contains(c.user!.uid) && hit(c)) c];
    final others = [for (final c in _contacts) if (c.user == null && hit(c)) c];
    final ready = _state == _ContactsState.ready;

    return FafoSheetBody(
      tall: true,
      children: [
        if (ready) ...[
          FafoSearchField(controller: _search, hint: 'Search contacts'),
          const SizedBox(height: 12),
        ],
        if (q.isEmpty) ...[
          _ActionRow(icon: Icons.add_rounded, title: 'New group', onTap: _newGroup, arrow: true),
          _ActionRow(
            icon: Icons.share_outlined,
            title: 'Share link',
            subtitle: code?.shareUrl.replaceFirst(RegExp(r'^https?://'), ''),
            onTap: code == null ? null : () => _share(code),
          ),
        ],
        switch (_state) {
          _ContactsState.unknown || _ContactsState.loading => const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          ),
          _ContactsState.ask => _ContactsCard(
            title: 'Find friends from your contacts',
            body: 'We check who’s already on FaFo. We never message anyone unless you tap Invite.',
            action: 'Allow contacts',
            onAction: _allow,
            onNotNow: () => Navigator.of(context).maybePop(),
          ),
          _ContactsState.denied => _ContactsCard(
            title: 'Contacts are off',
            body: 'Turn them on in your phone settings to find friends here.',
            action: 'Open Settings',
            onAction: _openSettings,
          ),
          _ContactsState.ready => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (onFafo.isNotEmpty) ...[
                const FafoSectionLabel('On FaFo', top: 22, bottom: 4),
                for (final c in onFafo)
                  FafoListRow(
                    title: c.name,
                    subtitle: c.phones.first,
                    leading: FafoAvatar(name: c.user!.displayName, photoUrl: c.user!.photoUrl, size: FafoAvatarSize.md),
                    trailing: _requested.contains(c.user!.uid) || c.user!.friendshipStatus == FriendshipStatus.requestSent
                        ? const _SmallPill(label: 'Sent', primary: false, onTap: null)
                        : _SmallPill(label: 'Add', busy: _busy.contains(c.user!.uid), onTap: () => _add(c.user!)),
                  ),
              ],
              if (others.isNotEmpty) ...[
                const FafoSectionLabel('From contacts', top: 22, bottom: 4),
                for (final c in others)
                  FafoListRow(
                    title: c.name,
                    subtitle: c.phones.first,
                    leading: FafoAvatar(name: c.name, size: FafoAvatarSize.md, neutral: true),
                    trailing: _SmallPill(label: 'Invite', primary: false, onTap: () => _invite(c)),
                  ),
              ],
              if (onFafo.isEmpty && others.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 2),
                  child: Text(
                    q.isEmpty ? 'No contacts with a phone number.' : 'No one called “${_search.text.trim()}”.',
                    style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        },
        if (q.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Center(
              child: FafoTextButton(
                label: 'Have a code?',
                color: AppColors.textSecondary,
                onTap: () => showCodeSheet(context),
              ),
            ),
          ),
      ],
    );
  }
}

/// A blue-circle action row: New group, Share link.
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.title, required this.onTap, this.subtitle, this.arrow = false});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool arrow;

  @override
  Widget build(BuildContext context) {
    return FafoListRow(
      title: title,
      subtitle: subtitle,
      showChevron: arrow,
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: AppColors.accentPrimary, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: AppColors.onAccent),
      ),
    );
  }
}

/// Add (ink) or Invite (outline) on a contact row.
class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label, required this.onTap, this.primary = true, this.busy = false});

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FafoPill(label: label, small: true, height: 36, primary: primary, busy: busy, onPressed: onTap);
  }
}

/// The contacts explainer (first time) or the "Contacts are off" card.
class _ContactsCard extends StatelessWidget {
  const _ContactsCard({required this.title, required this.body, required this.action, required this.onAction, this.onNotNow});

  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;
  final VoidCallback? onNotNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: EdgeInsets.fromLTRB(20, 20, 20, onNotNow == null ? 20 : 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppChrome.cardRadius),
        border: Border.all(color: AppColors.softLine, width: AppChrome.softOutlineWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.accentPrimary, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.contact_page_outlined, size: 22, color: AppColors.onAccent),
            ),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTypography.ui(19, fontWeight: FontWeight.w800).copyWith(height: 1.2)),
          const SizedBox(height: 6),
          Text(body, style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          FafoPill(label: action, block: true, height: 52, onPressed: onAction),
          if (onNotNow != null) ...[
            const SizedBox(height: 6),
            FafoTextButton(label: 'Not now', color: AppColors.textSecondary, onTap: onNotNow),
          ],
        ],
      ),
    );
  }
}

class _Contact {
  const _Contact({required this.name, required this.phones, required this.normalized, this.user});

  final String name;
  final List<String> phones;
  final List<String> normalized;
  final PublicUserResponse? user;

  factory _Contact.fromContact(Contact contact) {
    final phones = contact.phones.map((p) => p.number.trim()).where((p) => p.isNotEmpty).toSet().toList();
    final name = contact.displayName.trim();
    return _Contact(
      name: name.isEmpty ? (phones.isEmpty ? 'Unknown' : phones.first) : name,
      phones: phones,
      normalized: phones.map(normalizePhone).where((p) => p.isNotEmpty).toSet().toList(),
    );
  }

  _Contact withUser(PublicUserResponse? user) =>
      _Contact(name: name, phones: phones, normalized: normalized, user: user);
}

/// +91 for bare 10-digit Indian numbers, otherwise digits with a leading +.
String normalizePhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D+'), '');
  if (digits.length == 10) return '+91$digits';
  if (digits.startsWith('91') && digits.length == 12) return '+$digits';
  if (phone.trim().startsWith('+') && digits.isNotEmpty) return '+$digits';
  return digits.isNotEmpty ? digits : phone.trim();
}

/// When contacts were last matched against FaFo (Settings shows "Last synced").
const contactsSyncedAtKey = 'contacts_synced_at';

/// Re-sync contacts: match the address book against FaFo again. Returns false
/// (and toasts why) when contacts are off.
Future<bool> resyncContacts(WidgetRef ref) async {
  try {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      FafoToasts.show('Contacts are off. Turn them on in your phone settings.', kind: FafoToastKind.info);
      return false;
    }
    final raw = await FlutterContacts.getContacts(withProperties: true);
    final numbers = {
      for (final c in raw)
        for (final p in c.phones) normalizePhone(p.number),
    }.where((p) => p.isNotEmpty).toList();
    await ref.read(friendsRepositoryProvider).syncContacts(numbers);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(contactsAskedKey, true);
    await prefs.setInt(contactsSyncedAtKey, DateTime.now().millisecondsSinceEpoch);
    FafoToasts.show('Contacts are up to date.');
    return true;
  } catch (e) {
    FafoToasts.error(e);
    return false;
  }
}
