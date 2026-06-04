import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/home/data/mock_events.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  static const routeName = 'chat';
  static const routePath = '/chat';

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isTyping = false,
    this.recommendedEvents = const [],
  });

  final String text;
  final bool isUser;
  final bool isTyping;
  final List<MockEvent> recommendedEvents;
}

class _ChatReply {
  const _ChatReply({required this.text, this.recommendedEvents = const []});

  final String text;
  final List<MockEvent> recommendedEvents;
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  late final List<MockEvent> _events;
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          "Hey! I'm Popn, your group discovery buddy 🎉\nWhat kind of vibe are you looking for tonight?",
      isUser: false,
    ),
  ];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _events = generateMockEvents(19.0544, 72.8264);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Simulate typing delay then reply
    Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final reply = _getReply(text);
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            text: reply.text,
            isUser: false,
            recommendedEvents: reply.recommendedEvents,
          ),
        );
      });
      _scrollToBottom();
    });
  }

  _ChatReply _getReply(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('music')) {
      final event = _findEvent((event) => event.category == 'Live Music');
      return _ChatReply(
        text:
            "🎸 There's a great ${event.title} happening at ${event.time} at ${event.venue}. It's got ${event.attendees} people going already, perfect for a chill live music night!",
        recommendedEvents: _eventsForCategory('Live Music'),
      );
    }
    if (lower.contains('food')) {
      final event = _findEvent((event) => event.category == 'Food & Drinks');
      return _ChatReply(
        text:
            "🍜 You should check out ${event.title} at ${event.venue}. It starts at ${event.time} and already has ${event.attendees} people interested.",
        recommendedEvents: _eventsForCategory('Food & Drinks'),
      );
    }
    if (lower.contains('night')) {
      final event = _findEvent((event) => event.title == 'Warehouse Rave');
      return _ChatReply(
        text:
            "🪩 ${event.title} at ${event.venue} starts at ${event.time}, and ${event.attendees} people are already going. Good pick if you want a louder late-night plan.",
        recommendedEvents: _eventsForCategory('Nightlife'),
      );
    }
    if (lower.contains('chill')) {
      final event = _findEvent((event) => event.title == 'Beach Yoga');
      return _ChatReply(
        text:
            "🧘 ${event.title} at ${event.venue} is a calmer option at ${event.time}. Only ${event.attendees} people are going, so it stays peaceful.",
        recommendedEvents: [
          _findEvent((event) => event.title == 'Beach Yoga'),
          _findEvent((event) => event.title == 'Acoustic Night'),
        ],
      );
    }
    if (lower.contains('art')) {
      final event = _findEvent((event) => event.category == 'Art & Culture');
      return _ChatReply(
        text:
            "🎨 ${event.title} at ${event.venue} starts at ${event.time}. It's a curated smaller group with ${event.attendees} attendees.",
        recommendedEvents: _eventsForCategory('Art & Culture'),
      );
    }
    if (lower.contains('comedy')) {
      final event = _findEvent((event) => event.category == 'Comedy');
      return _ChatReply(
        text:
            "🎤 ${event.title} at ${event.venue} starts at ${event.time}, with ${event.attendees} people already in. Good choice if you want something easy and social.",
        recommendedEvents: _eventsForCategory('Comedy'),
      );
    }
    if (lower.contains('plan')) {
      return const _ChatReply(
        text:
            "Sure! Tell me what you're into, music, food, nightlife, art, comedy, or something chill, and I'll find the perfect group for you nearby.",
      );
    }
    if (lower.contains('help')) {
      return const _ChatReply(
        text:
            "I can help you find groups, suggest plans based on your mood, or tell you what's trending nearby. Just ask! 🔥",
      );
    }

    final fallbackEvent = _findEvent((event) => event.category == 'Nightlife');
    return _ChatReply(
      text:
          "Sounds fun! I'd start with ${fallbackEvent.title} at ${fallbackEvent.venue}. If you want, I can narrow things down further by vibe like chill, nightlife, food, art, or comedy. 🎯",
      recommendedEvents: _eventsForCategory('Nightlife'),
    );
  }

  MockEvent _findEvent(bool Function(MockEvent event) predicate) {
    return _events.firstWhere(predicate, orElse: () => _events.first);
  }

  List<MockEvent> _eventsForCategory(String category) {
    return _events
        .where((event) => event.category == category)
        .take(3)
        .toList();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgSecondary,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentPrimary,
                    ),
                    child: const Center(
                      child: Text(
                        '✦',
                        style: TextStyle(
                          fontFamily: 'Tomorrow',
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Popn', style: theme.textTheme.displayMedium),
                        Text(
                          'Your group discovery assistant',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.border, height: 1),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length && _isTyping) {
                    return const _TypingIndicator();
                  }
                  return _MessageBubble(message: _messages[i]);
                },
              ),
            ),

            // Suggestion chips
            if (_messages.length <= 2)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  children: [
                    _SuggestionChip(
                      label: '🎵 Live music tonight',
                      onTap: () {
                        _controller.text = 'Live music tonight';
                        _sendMessage();
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SuggestionChip(
                      label: '🍜 Food groups',
                      onTap: () {
                        _controller.text = 'Food groups nearby';
                        _sendMessage();
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SuggestionChip(
                      label: '🪩 Nightlife',
                      onTap: () {
                        _controller.text = 'Nightlife plans';
                        _sendMessage();
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SuggestionChip(
                      label: '😌 Something chill',
                      onTap: () {
                        _controller.text = 'Something chill';
                        _sendMessage();
                      },
                    ),
                  ],
                ),
              ),
            if (_messages.length <= 2) const SizedBox(height: AppSpacing.sm),

            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: theme.textTheme.bodyLarge,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentPrimary,
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.message.isUser;
    final events = widget.message.recommendedEvents;

    return SlideTransition(
      position: _slideIn,
      child: FadeTransition(
        opacity: _fadeIn,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.accentPrimary.withValues(alpha: 0.2)
                        : AppColors.bgSecondary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppSpacing.lg),
                      topRight: const Radius.circular(AppSpacing.lg),
                      bottomLeft: isUser
                          ? const Radius.circular(AppSpacing.lg)
                          : const Radius.circular(AppSpacing.xs),
                      bottomRight: isUser
                          ? const Radius.circular(AppSpacing.xs)
                          : const Radius.circular(AppSpacing.lg),
                    ),
                    border: Border.all(
                      color: isUser
                          ? AppColors.accentPrimary.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    widget.message.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                if (!isUser && events.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _RecommendedEventPager(events: events),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendedEventPager extends StatefulWidget {
  const _RecommendedEventPager({required this.events});

  final List<MockEvent> events;

  @override
  State<_RecommendedEventPager> createState() => _RecommendedEventPagerState();
}

class _RecommendedEventPagerState extends State<_RecommendedEventPager> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    final hasMultipleEvents = events.length > 1;

    return SizedBox(
      height: hasMultipleEvents ? 142 : 122,
      child: Column(
        children: [
          SizedBox(
            height: 112,
            child: PageView.builder(
              controller: _pageController,
              itemCount: events.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _RecommendedEventCard(event: events[index]),
                  ),
                );
              },
            ),
          ),
          if (hasMultipleEvents)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(events.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accentPrimary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _RecommendedEventCard extends StatelessWidget {
  const _RecommendedEventCard({required this.event});

  final MockEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}', extra: event),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppChrome.cardRadius),
          border: AppChrome.outlineBorder,
          boxShadow: AppChrome.cardShadowSoft,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppChrome.controlRadius),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.network(
                  event.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) =>
                      Container(color: AppColors.bgTertiary),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.accentLight1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${event.time}  ·  ${event.venue}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.lg),
            topRight: Radius.circular(AppSpacing.lg),
            bottomLeft: Radius.circular(AppSpacing.xs),
            bottomRight: Radius.circular(AppSpacing.lg),
          ),
          border: AppChrome.outlineBorder,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i * 0.2;
                final t = (_controller.value - delay).clamp(0.0, 1.0);
                final opacity =
                    0.3 +
                    0.7 *
                        (0.5 + 0.5 * math.sin(t * math.pi * 2)).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentLight1.withValues(alpha: opacity),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppChrome.controlRadius),
          border: AppChrome.outlineBorder,
          boxShadow: AppChrome.cardShadowSoft,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
