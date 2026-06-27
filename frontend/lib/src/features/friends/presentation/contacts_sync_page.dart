import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';

class ContactsSyncPage extends ConsumerStatefulWidget {
  const ContactsSyncPage({super.key});

  static const routeName = 'contacts-sync';
  static const routePath = '/friends/contacts';

  @override
  ConsumerState<ContactsSyncPage> createState() => _ContactsSyncPageState();
}

class _ContactsSyncPageState extends ConsumerState<ContactsSyncPage> {
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String _query = '';
  final Set<String> _busyContactKeys = <String>{};
  List<_ContactListItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        setState(() {
          _items = const [];
          _error =
              'Contacts permission denied. Enable it in Settings to find friends.';
        });
        return;
      }

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      final localItems =
          contacts
              .map(_ContactListItem.fromContact)
              .where((item) => item.normalizedPhones.isNotEmpty)
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      final phoneNumbers = localItems
          .expand((item) => item.normalizedPhones)
          .toSet()
          .toList();
      final matches = await ref
          .read(friendsRepositoryProvider)
          .syncContacts(phoneNumbers);
      final matchesByPhone = <String, PublicUserResponse>{};
      for (final match in matches) {
        matchesByPhone[_normalizePhone(match.normalizedPhone)] = match.user;
        matchesByPhone[_normalizePhone(match.phone)] = match.user;
      }

      final merged =
          localItems.map((item) {
            PublicUserResponse? user;
            for (final phone in item.normalizedPhones) {
              user ??= matchesByPhone[phone];
            }
            return item.copyWith(user: user);
          }).toList()..sort((a, b) {
            if (a.user != null && b.user == null) return -1;
            if (a.user == null && b.user != null) return 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

      if (mounted) setState(() => _items = merged);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addFriend(PublicUserResponse user) async {
    final key = 'user:${user.uid}';
    if (_busyContactKeys.contains(key)) return;
    setState(() => _busyContactKeys.add(key));
    try {
      await ref
          .read(friendsRepositoryProvider)
          .sendFriendRequest(uid: user.uid);
      ref.invalidate(friendsListProvider);
      ref.invalidate(incomingFriendRequestsProvider);
      ref.invalidate(outgoingFriendRequestsProvider);
      ref.invalidate(friendStatsProvider);
      await _loadContacts();
      if (mounted) _showSnack('Friend request sent');
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _busyContactKeys.remove(key));
    }
  }

  Future<void> _invite(_ContactListItem item) async {
    final key = item.key;
    if (_busyContactKeys.contains(key)) return;
    setState(() => _busyContactKeys.add(key));
    try {
      final invite = await ref.read(friendsRepositoryProvider).createInvite();
      final text = 'Join me on Fafo: ${invite.inviteUrl}';
      await Clipboard.setData(ClipboardData(text: invite.inviteUrl));

      final opened = await _openSmsComposer(item.primaryPhone, text);
      if (mounted) {
        _showSnack(
          opened ? 'Invite copied and SMS opened' : 'Invite link copied',
        );
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _busyContactKeys.remove(key));
    }
  }

  Future<bool> _openSmsComposer(String? phone, String message) async {
    final recipient = (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    final body = Uri.encodeComponent(message);
    final candidates = <Uri>[
      Uri.parse(
        recipient.isEmpty ? 'sms:?body=$body' : 'sms:$recipient?body=$body',
      ),
      Uri.parse(
        recipient.isEmpty ? 'smsto:?body=$body' : 'smsto:$recipient?body=$body',
      ),
    ];

    for (final uri in candidates) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (_) {
        // Try the next supported SMS URI form.
      }
    }
    return false;
  }

  List<_ContactListItem> get _filteredItems {
    final query = _query.toLowerCase();
    if (query.isEmpty) return _items;
    final queryPhone = _normalizePhone(query);
    return _items.where((item) {
      final user = item.user;
      return item.name.toLowerCase().contains(query) ||
          item.phones.any((phone) => phone.toLowerCase().contains(query)) ||
          item.normalizedPhones.any((phone) => phone.contains(queryPhone)) ||
          (user?.displayName.toLowerCase().contains(query) ?? false) ||
          (user?.username.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _showSnack(String text) {
    // Replace any queued/visible snackbar so rapid-fire actions (e.g. sending
    // several friend requests in a row) surface a single toast instead of a
    // long backlog that plays one after another until exhausted.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final usersOnApp = _items.where((item) => item.user != null).length;
    final visibleItems = _filteredItems;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadContacts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadContacts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
            children: [
              Text(
                'Find friends from contacts',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.accentPrimary,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 16),
              _ContactsSearchBox(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
              const SizedBox(height: 18),
              if (!_loading && _error == null)
                Text(
                  '$usersOnApp on Fafo • ${_items.length - usersOnApp} inviteable',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentPrimary,
                    ),
                  ),
                )
              else if (_error != null)
                _MessageBlock(
                  text: _error!,
                  actionLabel: 'Try again',
                  onAction: _loadContacts,
                )
              else if (_items.isEmpty)
                _MessageBlock(
                  text: 'No contacts with phone numbers found.',
                  actionLabel: 'Refresh',
                  onAction: _loadContacts,
                )
              else if (visibleItems.isEmpty)
                _MessageBlock(
                  text: 'No contacts match your search.',
                  actionLabel: 'Clear search',
                  onAction: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              else
                ...visibleItems.map(
                  (item) => _ContactRow(
                    item: item,
                    busy: _busyContactKeys.contains(
                      item.user == null ? item.key : 'user:${item.user!.uid}',
                    ),
                    onAdd: item.user == null
                        ? null
                        : () => _addFriend(item.user!),
                    onInvite: () => _invite(item),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactsSearchBox extends StatelessWidget {
  const _ContactsSearchBox({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          prefixIcon: Icon(Icons.search, color: Colors.black54, size: 22),
          hintText: 'Search contacts...',
          hintStyle: TextStyle(
            color: Color(0xFF6D6D78),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ContactListItem {
  const _ContactListItem({
    required this.name,
    required this.phones,
    required this.normalizedPhones,
    this.user,
  });

  final String name;
  final List<String> phones;
  final List<String> normalizedPhones;
  final PublicUserResponse? user;

  String? get primaryPhone => phones.isEmpty ? null : phones.first;
  String get key => normalizedPhones.isNotEmpty
      ? 'phone:${normalizedPhones.first}'
      : 'name:$name';

  factory _ContactListItem.fromContact(Contact contact) {
    final phones = contact.phones
        .map((phone) => phone.number.trim())
        .where((phone) => phone.isNotEmpty)
        .toSet()
        .toList();
    final normalized = phones
        .map(_normalizePhone)
        .where((phone) => phone.isNotEmpty)
        .toSet()
        .toList();
    final name = contact.displayName.trim().isEmpty
        ? (phones.isEmpty ? 'Unknown contact' : phones.first)
        : contact.displayName.trim();
    return _ContactListItem(
      name: name,
      phones: phones,
      normalizedPhones: normalized,
    );
  }

  _ContactListItem copyWith({PublicUserResponse? user}) {
    return _ContactListItem(
      name: name,
      phones: phones,
      normalizedPhones: normalizedPhones,
      user: user ?? this.user,
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.item,
    required this.busy,
    required this.onAdd,
    required this.onInvite,
  });

  final _ContactListItem item;
  final bool busy;
  final VoidCallback? onAdd;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final user = item.user;
    final title = user == null
        ? item.name
        : (user.displayName.isEmpty ? '@${user.username}' : user.displayName);
    final subtitle = user == null
        ? (item.primaryPhone ?? '')
        : '@${user.username} • ${item.name}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.ink, width: 1.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ContactAvatar(user: user, name: item.name),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.accentPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF74747D),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (user == null)
            FilledButton(
              onPressed: busy ? null : onInvite,
              child: const Text('Invite'),
            )
          else
            FilledButton(
              onPressed: user.friendshipStatus == FriendshipStatus.none && !busy
                  ? onAdd
                  : null,
              child: Text(switch (user.friendshipStatus) {
                FriendshipStatus.friends => 'Friends',
                FriendshipStatus.requestSent => 'Pending',
                FriendshipStatus.requestReceived => 'Requested',
                FriendshipStatus.blocked ||
                FriendshipStatus.blockedBy => 'Unavailable',
                FriendshipStatus.none => 'Add',
              }),
            ),
        ],
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({required this.user, required this.name});

  final PublicUserResponse? user;
  final String name;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoUrl;
    final label = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : name;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(8),
        image: photoUrl == null
            ? null
            : DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover),
      ),
      child: photoUrl == null
          ? Center(
              child: Text(
                label.isEmpty ? '🙂' : label.characters.first.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
    );
  }
}

class _MessageBlock extends StatelessWidget {
  const _MessageBlock({
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

String _normalizePhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D+'), '');
  if (digits.length == 10) return '+91$digits';
  if (digits.startsWith('91') && digits.length == 12) return '+$digits';
  if (phone.trim().startsWith('+') && digits.isNotEmpty) return '+$digits';
  return digits.isNotEmpty ? digits : phone.trim();
}
