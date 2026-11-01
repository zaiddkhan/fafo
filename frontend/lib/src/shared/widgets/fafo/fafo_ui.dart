import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/core/utils/server_clock.dart';
import 'package:fafu/src/shared/widgets/app_pressable.dart';

/// The V3 component set (brief 2.3), matched to the client prototype. Screens
/// build from these rather than styling ad hoc.

/// Mono, uppercase, tracked label: eyebrows and card header strips.
class FafoEyebrow extends StatelessWidget {
  const FafoEyebrow(this.text, {super.key, this.color, this.fontSize = 11});

  final String text;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      semanticsLabel: text,
      style: AppTypography.label(fontSize: fontSize, color: color),
    );
  }
}

/// Display headline (Anton). Kept sentence case in code, uppercased here so
/// screen readers read it normally.
class FafoDisplay extends StatelessWidget {
  const FafoDisplay(
    this.text, {
    super.key,
    this.fontSize = 36,
    this.color,
    this.maxLines,
  });

  final String text;
  final double fontSize;
  final Color? color;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      semanticsLabel: text.replaceAll('\n', ' '),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: AppTypography.display(fontSize, color: color),
    );
  }
}

enum FafoAvatarSize { xs, sm, md, lg }

/// Red initial circle with an ink ring, or the photo once one is set. [free]
/// adds the blue "free now" dot. [neutral] is for contacts not on FaFo: grey
/// initials, so red always means a FaFo person.
class FafoAvatar extends StatelessWidget {
  const FafoAvatar({
    super.key,
    required this.name,
    this.size = FafoAvatarSize.sm,
    this.square = false,
    this.photoUrl,
    this.free = false,
    this.neutral = false,
    this.ringColor,
  });

  final String name;
  final FafoAvatarSize size;

  /// Kept for parked callers; groups now show overlapping member avatars.
  final bool square;
  final String? photoUrl;
  final bool free;
  final bool neutral;

  /// Colour of the gap around the free dot (the surface the avatar sits on).
  final Color? ringColor;

  static double dimensionOf(FafoAvatarSize size) => switch (size) {
    FafoAvatarSize.xs => 26,
    FafoAvatarSize.sm => 28,
    FafoAvatarSize.md => 40,
    FafoAvatarSize.lg => 84,
  };

  @override
  Widget build(BuildContext context) {
    final dim = dimensionOf(size);
    final circle = FafoAvatarCircle(
      name: name,
      dimension: dim,
      photoUrl: photoUrl,
      neutral: neutral,
    );
    if (!free) return circle;
    final big = size == FafoAvatarSize.lg;
    final dot = big ? 18.0 : 12.0;
    return Semantics(
      label: 'Free now',
      child: SizedBox(
        width: dim,
        height: dim,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            circle,
            Positioned(
              right: big ? 0 : -2,
              bottom: big ? 2 : -2,
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor ?? AppColors.bgPrimary, width: big ? 3 : 2.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One avatar circle at any size: red with an ink ring and an Anton initial,
/// the photo, or (for contacts not on FaFo) neutral grey initials.
class FafoAvatarCircle extends StatelessWidget {
  const FafoAvatarCircle({
    super.key,
    required this.name,
    required this.dimension,
    this.photoUrl,
    this.neutral = false,
    this.ring,
  });

  final String name;
  final double dimension;
  final String? photoUrl;
  final bool neutral;

  /// A 2px outer ring so overlapping avatars read as separate circles.
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final border = dimension >= 60 ? 2.0 : 1.5;
    final Widget letter = neutral
        ? Text(
            initial,
            style: AppTypography.ui(dimension * 0.4, fontWeight: FontWeight.w500, color: AppColors.textSecondary).copyWith(height: 1),
          )
        : Text(
            initial,
            style: AppTypography.display(dimension * 0.43, color: AppColors.ink).copyWith(height: 1),
          );
    return ExcludeSemantics(
      child: Container(
        width: dimension,
        height: dimension,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: neutral ? AppColors.surface : AppColors.signalRed,
          shape: BoxShape.circle,
          border: Border.all(color: neutral ? AppColors.softLine : AppColors.ink, width: border),
          boxShadow: ring == null ? null : [BoxShadow(color: ring!, spreadRadius: 2)],
        ),
        child: hasPhoto && !neutral
            ? Image.network(
                photoUrl!,
                width: dimension,
                height: dimension,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => letter,
              )
            : letter,
      ),
    );
  }
}

/// A group: two or three member avatars overlapping (never a letter tile).
class FafoAvatarStack extends StatelessWidget {
  const FafoAvatarStack({
    super.key,
    required this.people,
    this.dimension = 32,
    this.ring,
    this.max = 3,
  });

  /// (name, photoUrl) for each member, most relevant first.
  final List<(String, String?)> people;
  final double dimension;

  /// The surface behind the stack; draws the gap between circles.
  final Color? ring;
  final int max;

  @override
  Widget build(BuildContext context) {
    final shown = people.take(max).toList();
    if (shown.isEmpty) shown.add(('?', null));
    final overlap = dimension * 0.28;
    final width = dimension + (shown.length - 1) * (dimension - overlap);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: dimension,
        child: Stack(
          children: [
            for (var i = 0; i < shown.length; i++)
              Positioned(
                left: i * (dimension - overlap),
                child: FafoAvatarCircle(
                  name: shown[i].$1,
                  photoUrl: shown[i].$2,
                  dimension: dimension,
                  ring: ring ?? AppColors.bgPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum FafoBadgeKind { easy, medium, hard, tag }

/// Mono pill badge: difficulty levels and the "Side quest" tag.
class FafoBadge extends StatelessWidget {
  const FafoBadge(this.label, {super.key, required this.kind, this.onBlue = false, this.small = false});

  final String label;
  final FafoBadgeKind kind;

  /// The tighter tag used inside list rows.
  final bool small;

  /// On a blue card the border turns white and the tag goes transparent.
  final bool onBlue;

  static FafoBadgeKind kindFor(String? difficulty) => switch (difficulty) {
    'medium' => FafoBadgeKind.medium,
    'hard' => FafoBadgeKind.hard,
    _ => FafoBadgeKind.easy,
  };

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (kind) {
      FafoBadgeKind.easy => (AppColors.accentPrimary, AppColors.onAccent),
      FafoBadgeKind.medium => (AppColors.amber, AppColors.ink),
      FafoBadgeKind.hard => (AppColors.signalRed, AppColors.ink),
      FafoBadgeKind.tag =>
        onBlue
            ? (Colors.white, AppColors.ink)
            : (AppColors.surface, AppColors.textPrimary),
    };
    // On a blue card: "Side quest" is white with ink, the level is white
    // with blue text and a white edge.
    final (Color fill, Color text) = onBlue && kind != FafoBadgeKind.tag
        ? (Colors.white, AppColors.accentPrimary)
        : (bg, fg);
    final borderColor = onBlue
        ? (kind == FafoBadgeKind.tag ? AppColors.ink : Colors.white)
        : kind == FafoBadgeKind.tag
        ? AppColors.border
        : AppColors.ink;
    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppChrome.pillRadius),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        label.toUpperCase(),
        semanticsLabel: label,
        style: AppTypography.label(fontSize: small ? 9.5 : 10.5, color: text).copyWith(
          letterSpacing: (small ? 9.5 : 10.5) * 0.08,
          height: 1,
        ),
      ),
    );
  }
}

/// "Side quest" + level tags on quest nudges (brief 5.3).
class FafoQuestTags extends StatelessWidget {
  const FafoQuestTags({super.key, required this.difficulty, this.onBlue = false});

  final String? difficulty;
  final bool onBlue;

  static String levelLabel(String? difficulty) => switch (difficulty) {
    'medium' => 'Medium',
    'hard' => 'Hard',
    _ => 'Easy',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        FafoBadge('Side quest', kind: FafoBadgeKind.tag, onBlue: onBlue),
        FafoBadge(
          levelLabel(difficulty),
          kind: FafoBadge.kindFor(difficulty),
          onBlue: onBlue,
        ),
      ],
    );
  }
}

/// Full-radius pill button. Primary: solid ink (inverts in dark mode).
/// Secondary: 2px outline. Never a shadow. [onBlue] gives the receiver card's
/// treatment: primary stays solid ink, secondary turns white.
class FafoPill extends StatelessWidget {
  const FafoPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.block = false,
    this.small = false,
    this.onBlue = false,
    this.height,
    this.busy = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  /// Red fill, ink text. Only for the action in a destructive confirm.
  final bool danger;
  final bool block;
  final bool small;
  final bool onBlue;
  final double? height;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color edge;
    final Color text;
    if (danger) {
      fill = AppColors.signalRed;
      edge = AppColors.signalRed;
      text = AppColors.ink;
    } else if (onBlue) {
      fill = primary ? AppColors.ink : Colors.transparent;
      edge = primary ? AppColors.ink : AppColors.onAccent;
      text = AppColors.onAccent;
    } else {
      fill = primary ? AppColors.primaryFill : Colors.transparent;
      edge = AppColors.primaryFill;
      text = primary ? AppColors.onPrimaryFill : AppColors.textPrimary;
    }
    final h = height ?? (block ? 56.0 : small ? 38.0 : 50.0);
    final disabled = onPressed == null || busy;
    return Semantics(
      button: true,
      enabled: !disabled,
      child: AppPressable(
        onTap: disabled ? null : onPressed,
        // Small pills keep their look but get a 44pt tap area.
        child: _MinTap(height: h, child: Opacity(
          opacity: onPressed == null ? 0.35 : 1,
          child: Container(
            height: h,
            width: block ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: small ? 15 : 22),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppChrome.pillRadius),
              border: Border.all(color: edge, width: AppChrome.outlineWidth),
            ),
            // Hugs the label unless the parent forces a width (Expanded, block).
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: text),
                  )
                : Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.ui(
                      small ? 13.5 : 15,
                      fontWeight: FontWeight.w700,
                      color: text,
                    ).copyWith(height: 1),
                  )),
              ],
            ),
          ),
        )),
      ),
    );
  }
}

/// Pads a short control up to a 44pt-tall tap area without changing its look.
class _MinTap extends StatelessWidget {
  const _MinTap({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (height >= 44) return child;
    final pad = (44 - height) / 2;
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(vertical: pad),
      child: child,
    );
  }
}

/// Choice chip, radius 11. Unselected: soft 1.5px border, no shadow. Selected:
/// blue with white text, 2px ink border, 3px offset.
class FafoChip extends StatelessWidget {
  const FafoChip({
    super.key,
    required this.child,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.dashed = false,
    this.minHeight = 48,
    this.semanticLabel,
  });

  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  final bool dashed;
  final double minHeight;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onAccent : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel,
      child: AppPressable(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.accentPrimary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppChrome.chipRadius),
              border: selected
                  ? Border.all(color: AppColors.ink, width: AppChrome.outlineWidth)
                  : Border.all(
                      color: AppColors.softLine,
                      width: AppChrome.softOutlineWidth,
                    ),
              boxShadow: selected ? AppChrome.cardShadowSoft : null,
            ),
            child: DefaultTextStyle.merge(
              style: AppTypography.ui(15, color: fg),
              textAlign: TextAlign.center,
              child: IconTheme.merge(data: IconThemeData(color: fg), child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// A grid of chips, three to a row, as in the prototype.
class FafoChipGrid extends StatelessWidget {
  const FafoChipGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final w = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final c in children) SizedBox(width: w, child: c)],
        );
      },
    );
  }
}

/// "I’m busy" / "I’m free". Off: card fill, hollow dot. On: blue, white text
/// and dot, 3px offset. Stays on until switched off.
class FafoFreePill extends StatelessWidget {
  const FafoFreePill({super.key, required this.free, required this.onTap});

  final bool free;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = free ? AppColors.onAccent : AppColors.textPrimary;
    return Semantics(
      button: true,
      toggled: free,
      child: AppPressable(
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: free ? AppColors.accentPrimary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppChrome.pillRadius),
            border: Border.all(
              color: free ? AppColors.ink : AppColors.border,
              width: AppChrome.outlineWidth,
            ),
            boxShadow: free ? AppChrome.cardShadowSoft : null,
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: free ? AppColors.onAccent : Colors.transparent,
                  border: Border.all(
                    color: free ? AppColors.onAccent : AppColors.textPrimary,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                free ? 'I’m free' : 'I’m busy',
                style: AppTypography.ui(15, fontWeight: FontWeight.w700, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2px rule.
class FafoRule extends StatelessWidget {
  const FafoRule({super.key, this.color, this.thickness = 2});

  final Color? color;
  final double thickness;

  @override
  Widget build(BuildContext context) =>
      Container(height: thickness, color: color ?? AppColors.rule);
}

/// Hairline between list rows.
class FafoHairline extends StatelessWidget {
  const FafoHairline({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: AppColors.hairline);
}

/// Section header: mono eyebrow, display title. Rule above when [ruled].
class FafoSectionHeader extends StatelessWidget {
  const FafoSectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.titleSize = 42,
  });

  final String eyebrow;
  final String title;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FafoEyebrow(eyebrow),
        const SizedBox(height: 6),
        FafoDisplay(title, fontSize: titleSize),
      ],
    );
  }
}

/// List row: optional leading, title over a meta line, arrow (or [trailing])
/// on the right. Spacing separates rows; there is no divider.
class FafoListRow extends StatelessWidget {
  const FafoListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.leading,
    this.trailing,
    this.titleBadge,
    this.onTap,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;

  /// Replaces [subtitle] with a custom meta line (state + tag).
  final Widget? meta;
  final Widget? leading;
  final Widget? trailing;

  /// A small tag next to the title ("Admin").
  final Widget? titleBadge;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.ui(15, fontWeight: FontWeight.w600),
    );
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        padding: EdgeInsets.symmetric(vertical: leading == null ? 12 : 8, horizontal: 2),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (titleBadge == null)
                    titleText
                  else
                    Row(
                      children: [
                        Flexible(child: titleText),
                        const SizedBox(width: 8),
                        titleBadge!,
                      ],
                    ),
                  if (meta != null) ...[
                    const SizedBox(height: 5),
                    meta!,
                  ] else if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.ui(
                        12.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ] else if (showChevron) ...[
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward, size: 17, color: AppColors.textPrimary),
            ],
          ],
        ),
      ),
    );
  }
}

/// A plan in a list (Recent, a friend's or group's plans): title, then
/// "Active" with a blue dot or a muted state word, then a Nudge / Side quest
/// tag.
class FafoPlanRow extends StatelessWidget {
  const FafoPlanRow({
    super.key,
    required this.title,
    required this.state,
    required this.active,
    required this.isQuest,
    this.onTap,
  });

  final String title;
  final String state;
  final bool active;
  final bool isQuest;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FafoListRow(
      title: title,
      onTap: onTap,
      meta: Row(
        children: [
          if (active) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.accentPrimary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            state,
            style: AppTypography.ui(
              12.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          FafoBadge(isQuest ? 'Side quest' : 'Nudge', kind: FafoBadgeKind.tag, small: true),
        ],
      ),
    );
  }
}

/// Mono section label above content ("On FaFo", "Members"), with an optional
/// action on the right ("Remove").
class FafoSectionLabel extends StatelessWidget {
  const FafoSectionLabel(this.text, {super.key, this.action, this.top = 26, this.bottom = 12});

  final String text;
  final Widget? action;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: Row(
        children: [
          Expanded(child: FafoEyebrow(text, fontSize: 10.5)),
          ?action,
        ],
      ),
    );
  }
}

/// Card with a mono header strip and 2px zone rules. White (sender) or blue
/// (receiver). On blue, inner rules and text turn white; the outer border and
/// offset shadow stay ink.
class FafoCard extends StatelessWidget {
  const FafoCard({
    super.key,
    required this.stripLeft,
    required this.stripRight,
    required this.zones,
    this.blue = false,
  });

  final String stripLeft;
  final String stripRight;
  final List<Widget> zones;
  final bool blue;

  @override
  Widget build(BuildContext context) {
    final fg = blue ? AppColors.onAccent : AppColors.textPrimary;
    final inner = blue ? AppColors.onAccent : AppColors.border;
    final children = <Widget>[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: inner, width: 2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: FafoEyebrow(stripLeft, color: fg, fontSize: 10.5)),
            FafoEyebrow(stripRight, color: fg, fontSize: 10.5),
          ],
        ),
      ),
    ];
    for (var i = 0; i < zones.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FafoRule(color: blue ? AppColors.onAccent : fg),
          ),
        );
      }
      children.add(zones[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: blue ? AppColors.accentPrimary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppChrome.cardRadius),
        border: Border.all(
          color: blue ? AppColors.ink : AppColors.border,
          width: AppChrome.outlineWidth,
        ),
        boxShadow: AppChrome.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppChrome.cardRadius - 2),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: fg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Padding for one card zone.
class FafoZone extends StatelessWidget {
  const FafoZone({super.key, required this.children, this.big = false, this.gap = 10});

  final List<Widget> children;
  final bool big;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, big ? 24 : 20, 20, big ? 26 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Ticks once a second. Timers derive from a target instant, never a local
/// counter, so they stay right across backgrounding and app kills.
class FafoTicker extends StatefulWidget {
  const FafoTicker({super.key, required this.builder});

  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<FafoTicker> createState() => _FafoTickerState();
}

class _FafoTickerState extends State<FafoTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, ServerClock.now());
}

String fafoMmss(Duration d) {
  final secs = d.isNegative ? 0 : (d.inMilliseconds / 1000).ceil();
  final m = secs ~/ 60;
  final s = secs % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String _spoken(Duration d, String label) {
  final secs = d.isNegative ? 0 : (d.inMilliseconds / 1000).ceil();
  return '${secs ~/ 60} minutes ${secs % 60} seconds $label';
}

/// Big mm:ss timer with its short label under it ("left to answer").
class FafoCountdown extends StatelessWidget {
  const FafoCountdown({
    super.key,
    required this.to,
    required this.label,
    this.color,
    this.fontSize = 54,
    this.labelColor,
  });

  /// Null renders a static 00:00 (go time).
  final DateTime? to;
  final String label;
  final Color? color;

  /// Label colour when it differs from the digits (red timer, ink label).
  final Color? labelColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (to == null) return _render(Duration.zero);
    return FafoTicker(builder: (context, now) => _render(to!.difference(now)));
  }

  Widget _render(Duration left) {
    return Semantics(
      label: _spoken(left, label),
      liveRegion: false,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimerDigits(text: fafoMmss(left), fontSize: fontSize, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.ui(12.5, fontWeight: FontWeight.w700, color: labelColor ?? color),
            ),
          ],
        ),
      ),
    );
  }
}

/// "09 : 58": the colon gets a little air and sits slightly high, as in the
/// prototype.
class _TimerDigits extends StatelessWidget {
  const _TimerDigits({required this.text, required this.fontSize, this.color});

  final String text;
  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.timer(fontSize, color: color);
    final parts = text.split(':');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(parts.first, style: style),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: fontSize * 0.07),
          child: Transform.translate(
            offset: Offset(0, -fontSize * 0.05),
            child: Text(':', style: style),
          ),
        ),
        Text(parts.last, style: style),
      ],
    );
  }
}

/// The space the page header takes; sheets stop just below it.
const double fafoHeaderHeight = 84;

/// Paper bottom sheet: 24px top corners, no drag handle, × on the left and the
/// [title] centred. Sized to its content up to just below the page header;
/// [tall] keeps it at that height (long searchable lists, so it doesn't
/// jump). Closes with ×, a tap on the dim, or back.
Future<T?> showFafoSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  bool tall = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgPrimary,
    showDragHandle: false,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(duration: Duration(milliseconds: 300), reverseDuration: Duration(milliseconds: 220)),
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      final maxHeight = media.size.height - media.padding.top - fafoHeaderHeight;
      final body = Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Column(
          mainAxisSize: tall ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FafoSheetHeader(title: title),
            Flexible(fit: tall ? FlexFit.tight : FlexFit.loose, child: builder(sheetContext)),
          ],
        ),
      );
      return Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: title != null,
        label: title,
        child: tall
            ? SizedBox(height: maxHeight, child: body)
            : ConstrainedBox(constraints: BoxConstraints(maxHeight: maxHeight), child: body),
      );
    },
  );
}

/// × on the left, title centred. Used by every sheet.
class FafoSheetHeader extends StatelessWidget {
  const FafoSheetHeader({super.key, this.title, this.onClose});

  final String? title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Close',
            child: InkResponse(
              onTap: onClose ?? () => Navigator.of(context).maybePop(),
              radius: 24,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.close_rounded, size: 24, color: AppColors.textPrimary),
              ),
            ),
          ),
          Expanded(
            child: title == null
                ? const SizedBox.shrink()
                : Text(
                    title!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.ui(18, fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// A choice in a [showFafoModal].
class FafoModalAction<T> {
  const FafoModalAction(this.label, this.value, {this.danger = false, this.primary = false});

  final String label;
  final T value;

  /// Red pill. Otherwise [primary] gives an ink pill and the rest are plain
  /// text buttons (Cancel).
  final bool danger;
  final bool primary;
}

/// Centred card, max 340px, for destructive or branching choices. Title names
/// the thing, one line on the consequence, then the actions top to bottom.
Future<T?> showFafoModal<T>(
  BuildContext context, {
  required String title,
  String? message,
  Widget? body,
  required List<FafoModalAction<T>> actions,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    transitionDuration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(curved), child: child),
      );
    },
    pageBuilder: (dialogContext, _, _) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppChrome.cardRadius),
                  border: Border.all(color: AppColors.border, width: AppChrome.outlineWidth),
                  boxShadow: AppChrome.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: AppTypography.ui(21, fontWeight: FontWeight.w800).copyWith(height: 1.2)),
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: AppTypography.ui(15, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                      ),
                    ],
                    ?body,
                    const SizedBox(height: 20),
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      if (actions[i].danger || actions[i].primary)
                        FafoPill(
                          label: actions[i].label,
                          block: true,
                          height: 52,
                          danger: actions[i].danger,
                          onPressed: () => Navigator.of(dialogContext).pop(actions[i].value),
                        )
                      else
                        FafoTextButton(
                          label: actions[i].label,
                          onTap: () => Navigator.of(dialogContext).pop(actions[i].value),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Destructive yes/no: red [confirmLabel], then Cancel. True only on confirm.
Future<bool> showFafoConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = true,
}) async {
  final result = await showFafoModal<bool>(
    context,
    title: title,
    message: message,
    actions: [
      FafoModalAction(confirmLabel, true, danger: destructive, primary: !destructive),
      FafoModalAction(cancelLabel, false),
    ],
  );
  return result ?? false;
}

/// Plain text button, 46px tall ("Cancel", "Not now").
class FafoTextButton extends StatelessWidget {
  const FafoTextButton({super.key, required this.label, required this.onTap, this.color});

  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppChrome.pillRadius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 46),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: AppTypography.ui(15, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Quiet links under a detail sheet: "Unfriend  Block", "Leave group  Delete
/// group". Muted, with the destructive one in red.
class FafoQuietLinks extends StatelessWidget {
  const FafoQuietLinks({super.key, required this.links});

  /// (label, onTap, red)
  final List<(String, VoidCallback?, bool)> links;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < links.length; i++) ...[
            if (i > 0) const SizedBox(width: 20),
            FafoTextButton(
              label: links[i].$1,
              onTap: links[i].$2,
              color: links[i].$3 ? AppColors.errorText : AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

/// Scrolling body of a sheet, 20px gutter. With a [footer], the action stays
/// pinned under the scroll.
class FafoSheetBody extends StatelessWidget {
  const FafoSheetBody({super.key, required this.children, this.gap = 0, this.footer, this.controller, this.tall = false});

  final List<Widget> children;
  final double gap;
  final Widget? footer;
  final ScrollController? controller;

  /// In a `tall` sheet: fill it and lay out only the rows on screen, for long
  /// lists (contacts). Otherwise the list shrinks to its content.
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final list = ListView(
      controller: controller,
      shrinkWrap: !tall,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 10, 20, footer == null ? 24 + bottomSafe : 6),
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 && gap > 0) SizedBox(height: gap),
          children[i],
        ],
      ],
    );
    if (footer == null) return list;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(fit: tall ? FlexFit.tight : FlexFit.loose, child: list),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 16 + bottomSafe),
          child: footer,
        ),
      ],
    );
  }
}

/// Underlined text link with a trailing arrow ("Preview both sides →").
class FafoTextLink extends StatelessWidget {
  const FafoTextLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(top: 6, bottom: 7),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.rule, width: 2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTypography.ui(15, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 15, color: AppColors.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square checkbox, 26px, ink border; filled with the primary fill when on.
class FafoCheckBox extends StatelessWidget {
  const FafoCheckBox({super.key, required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: checked ? AppColors.primaryFill : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? AppColors.primaryFill : AppColors.textPrimary,
          width: AppChrome.outlineWidth,
        ),
      ),
      child: checked
          ? Icon(Icons.check, size: 16, color: AppColors.onPrimaryFill)
          : null,
    );
  }
}

/// A full-width row that toggles a checkbox: Quick defaults' "Side quest
/// invites" and group member pickers.
class FafoCheckRow extends StatelessWidget {
  const FafoCheckRow({
    super.key,
    required this.title,
    required this.checked,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.topBorder = false,
    this.radio = false,
  });

  /// One of a single-choice list (Assign admin): announces as a radio.
  final bool radio;

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool checked;
  final VoidCallback? onTap;
  final bool topBorder;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      inMutuallyExclusiveGroup: radio,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.ui(15, fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.ui(
                          12.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Opacity(
                opacity: onTap == null ? 0.45 : 1,
                child: FafoSelectCircle(selected: checked),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round back button, matching the sheets' round ×.
class FafoBackButton extends StatelessWidget {
  const FafoBackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FafoRoundButton(
      icon: Icons.arrow_back_ios_new_rounded,
      label: 'Back',
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
    );
  }
}

/// 44px round icon button: card fill, soft border (back, settings, add).
/// [active] turns it blue (the gear while you're on Settings).
class FafoRoundButton extends StatelessWidget {
  const FafoRoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.size = 44,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: active,
      child: AppPressable(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.accentPrimary : AppColors.surface,
            border: Border.all(
              color: active ? AppColors.accentPrimary : AppColors.softLine,
              width: AppChrome.softOutlineWidth,
            ),
          ),
          child: Icon(icon, size: 20, color: active ? AppColors.onAccent : AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Quick-action tile: card, soft border, 18px radius, icon over label. Three
/// to a row. [busy] spins the icon (Re-sync).
class FafoTile extends StatelessWidget {
  const FafoTile({super.key, required this.icon, required this.label, required this.onTap, this.busy = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: AppPressable(
        onTap: onTap,
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.softLine, width: AppChrome.softOutlineWidth),
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                busy
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                      )
                    : Icon(icon, size: 24, color: AppColors.textPrimary),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.ui(13.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 52 x 32 switch with a white knob; blue track when on.
class FafoSwitch extends StatelessWidget {
  const FafoSwitch({super.key, required this.value, required this.onChanged, this.label});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: label,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Opacity(
          opacity: onChanged == null ? 0.45 : 1,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 160),
            width: 52,
            height: 32,
            padding: const EdgeInsets.all(3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: value ? AppColors.accentPrimary : AppColors.softLine,
              borderRadius: BorderRadius.circular(AppChrome.pillRadius),
            ),
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}

/// 26px select circle: a ring, or blue with a white tick when selected.
class FafoSelectCircle extends StatelessWidget {
  const FafoSelectCircle({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.accentPrimary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.accentPrimary : AppColors.softLine,
          width: 2,
        ),
      ),
      child: selected ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : null,
    );
  }
}

/// Filter pill: label plus a small mono count. Selected: blue, ink border,
/// 3px offset.
class FafoFilterChip extends StatelessWidget {
  const FafoFilterChip({super.key, required this.label, required this.selected, required this.onTap, this.count});

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onAccent : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      child: AppPressable(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentPrimary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppChrome.pillRadius),
            border: selected
                ? Border.all(color: AppColors.ink, width: AppChrome.outlineWidth)
                : Border.all(color: AppColors.softLine, width: AppChrome.softOutlineWidth),
            boxShadow: selected ? AppChrome.cardShadowSoft : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.ui(14, fontWeight: FontWeight.w700, color: fg).copyWith(height: 1),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: AppTypography.label(
                    fontSize: 11,
                    color: selected ? AppColors.onAccent.withValues(alpha: 0.85) : AppColors.textSecondary,
                  ).copyWith(letterSpacing: 0),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded search field: card fill, soft border, blue when focused.
class FafoSearchField extends StatelessWidget {
  const FafoSearchField({super.key, required this.controller, this.hint = 'Search', this.onChanged});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppChrome.pillRadius),
      borderSide: BorderSide(color: AppColors.softLine, width: AppChrome.softOutlineWidth),
    );
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTypography.ui(15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.ui(15, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.accentPrimary, width: AppChrome.softOutlineWidth),
          ),
        ),
      ),
    );
  }
}

/// Text input: card fill, 1.5px soft border, 14px radius, 52px tall. Blue
/// border on focus; red border plus [error] under it.
class FafoInput extends StatelessWidget {
  const FafoInput({
    super.key,
    required this.controller,
    this.hint,
    this.prefix,
    this.error,
    this.maxLength,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.keyboardType,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String? hint;
  final String? prefix;
  final String? error;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final TextInputType? keyboardType;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder side(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: AppChrome.softOutlineWidth),
    );
    final hasError = error != null;
    final style = AppTypography.ui(16, fontWeight: FontWeight.w600);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLength: maxLength,
      enabled: enabled,
      autofocus: autofocus,
      autocorrect: autocorrect,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: style,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.ui(16, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        prefixIcon: prefix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 18, right: 2),
                child: Text(prefix!, style: style.copyWith(fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: side(AppColors.softLine),
        enabledBorder: side(hasError ? AppColors.signalRed : AppColors.softLine),
        disabledBorder: side(AppColors.softLine),
        focusedBorder: side(hasError ? AppColors.signalRed : AppColors.accentPrimary),
        errorText: null,
      ),
    );
  }
}

/// Full-screen onboarding-style page: round back button, display title, a
/// muted line, content, and the primary action pinned at the bottom.
class FafoFormPage extends StatelessWidget {
  const FafoFormPage({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.children = const [],
    this.footer,
    this.showBack = true,
    this.onBack,
    this.titleSize = 36,
    this.step,
  });

  /// Onboarding step (1 to 3): dots on the right of the back row.
  final int? step;

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Pinned under the scrolling content, above the keyboard.
  final Widget? footer;
  final bool showBack;
  final VoidCallback? onBack;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        if (showBack) FafoBackButton(onTap: onBack),
                        const Spacer(),
                        if (step != null) _StepDots(step: step!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (eyebrow != null) ...[
                    FafoEyebrow(eyebrow!),
                    const SizedBox(height: 10),
                  ],
                  FafoDisplay(title, fontSize: titleSize),
                  if (subtitle != null) ...[
                    const SizedBox(height: 10),
                    Text(subtitle!, style: AppTypography.ui(15.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 26),
                  ...children,
                ],
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Onboarding progress: 8px soft dots, the current one a 20px blue bar.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $step of 3',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 3; i++) ...[
            if (i > 1) const SizedBox(width: 6),
            Container(
              width: i == step ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == step ? AppColors.accentPrimary : AppColors.softLine,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "I'm 18 or older and I agree to…": a 24px rounded box (blue with a tick
/// when on) and a line of muted copy.
class FafoConsentCheck extends StatelessWidget {
  const FafoConsentCheck({super.key, required this.checked, required this.onChanged, required this.label});

  final bool checked;
  final ValueChanged<bool> onChanged;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: checked ? AppColors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: checked ? AppColors.accentPrimary : AppColors.softLine, width: 2),
                ),
                child: checked ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                  child: label,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label above a field, as in the composer ("Invite", "Countdown after yes").
class FafoFieldLabel extends StatelessWidget {
  const FafoFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: FafoEyebrow(text, fontSize: 10.5),
  );
}

/// Underlined inline text action ("Log in", "Resend code").
class FafoInlineLink extends StatelessWidget {
  const FafoInlineLink({super.key, required this.label, this.onTap, this.color});

  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = onTap == null ? AppColors.textSecondary : (color ?? AppColors.textPrimary);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: AppTypography.ui(14, fontWeight: FontWeight.w700, color: c).copyWith(
            decoration: onTap == null ? null : TextDecoration.underline,
            decorationColor: c,
            decorationThickness: 1.5,
          ),
        ),
      ),
    );
  }
}

class FafoNavItem {
  const FafoNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The menu: a floating card-coloured pill 12px above the bottom safe area
/// and 16px from each side. Three equal buttons, icon over a 12px label; the
/// active one is a blue pill with white text. Content scrolls behind it.
class FafoBottomNav extends StatelessWidget {
  const FafoBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<FafoNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Height of the pill itself (52px buttons + 6px padding + border).
  static const double height = 67;

  /// Bottom padding a screen needs so its last row clears the menu.
  static double clearance(BuildContext context) => MediaQuery.paddingOf(context).bottom + 12 + height + 32;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + MediaQuery.paddingOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppChrome.pillRadius),
          border: Border.all(color: AppColors.softLine, width: AppChrome.softOutlineWidth),
          boxShadow: dark
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 32, offset: const Offset(0, 12), spreadRadius: -6)]
              : [
                  BoxShadow(color: AppColors.ink.withValues(alpha: 0.38), blurRadius: 28, offset: const Offset(0, 10), spreadRadius: -8),
                  BoxShadow(color: AppColors.ink.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2)),
                ],
        ),
        child: _NavBody(items: items, currentIndex: currentIndex, onTap: onTap),
      ),
    );
  }
}

/// The tabs plus the blue pill that travels between them. The pill moves
/// like a drop of liquid: its leading edge springs ahead (with a touch of
/// overshoot) and the trailing edge catches up, so it stretches mid-flight
/// and settles back to size. Interrupting mid-move starts from where it is.
class _NavBody extends StatefulWidget {
  const _NavBody({required this.items, required this.currentIndex, required this.onTap});

  final List<FafoNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<_NavBody> createState() => _NavBodyState();
}

class _NavBodyState extends State<_NavBody> with SingleTickerProviderStateMixin {
  static const _gap = 4.0;
  static const _lead = Cubic(0.3, 1.32, 0.5, 1); // springy, slight overshoot
  static const _trail = Curves.easeInOutCubic;

  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: 1,
  );

  /// Pill edges in tab units (0 = left edge of the first tab).
  late double _fromL = widget.currentIndex.toDouble();
  late double _fromR = widget.currentIndex + 1.0;

  /// The tab the pill is heading for.
  late int _to = widget.currentIndex;

  /// Bumped on every switch so only a real switch makes the icon pop.
  int _switches = 0;

  @override
  void didUpdateWidget(_NavBody old) {
    super.didUpdateWidget(old);
    if (old.currentIndex == widget.currentIndex) return;
    // Start from wherever the pill is now, even mid-flight.
    final (l, r) = _edges();
    _fromL = l;
    _fromR = r;
    _to = widget.currentIndex;
    _switches++;
    if (MediaQuery.disableAnimationsOf(context)) {
      _move.value = 1;
    } else {
      _move.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  /// Current pill edges, heading for [_to] from the last start.
  (double, double) _edges() {
    final to = _to.toDouble();
    final t = _move.value;
    final right = to > _fromL;
    final leadT = _lead.transform(t);
    final trailT = _trail.transform(t);
    // Moving right, the right edge leads; moving left, the left edge leads.
    final l = _fromL + (to - _fromL) * (right ? trailT : leadT);
    final r = _fromR + (to + 1 - _fromR) * (right ? leadT : trailT);
    return (l, r);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - _gap * (n - 1)) / n;
        // Tab k spans [k(w+gap), k(w+gap)+w]: a left edge at unit L sits at
        // L(w+gap), a right edge at unit R at R(w+gap) - gap.
        double x(double units) => units * (w + _gap);
        return SizedBox(
          height: 52,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _move,
                builder: (context, _) {
                  final (l, r) = _edges();
                  final left = x(l);
                  final right = x(r) - _gap;
                  return Positioned(
                    left: left,
                    width: (right - left).clamp(24.0, constraints.maxWidth),
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary,
                        borderRadius: BorderRadius.circular(AppChrome.pillRadius),
                      ),
                    ),
                  );
                },
              ),
              Row(
                children: [
                  for (var i = 0; i < n; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    Expanded(
                      child: _NavTab(
                        item: widget.items[i],
                        selected: i == widget.currentIndex,
                        pop: _switches,
                        onTap: () {
                          if (i != widget.currentIndex) HapticFeedback.selectionClick();
                          widget.onTap(i);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One tab: icon over label. Colour eases between muted and white as the pill
/// arrives; the icon gives a small pop when its tab is picked.
class _NavTab extends StatelessWidget {
  const _NavTab({required this.item, required this.selected, required this.onTap, this.pop = 0});

  final FafoNavItem item;
  final bool selected;
  final VoidCallback onTap;

  /// How many switches so far; 0 means the menu just appeared (no pop).
  final int pop;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final fg = selected ? AppColors.onAccent : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: ExcludeSemantics(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: fg),
              duration: still ? Duration.zero : const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              builder: (context, color, _) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    key: ValueKey('$selected$pop'),
                    tween: Tween(begin: selected && pop > 0 && !still ? 0.72 : 1, end: 1),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                    child: Icon(item.icon, size: 21, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.ui(12, fontWeight: FontWeight.w700, color: color).copyWith(height: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Your photo in a circle with a 3px card ring and a soft shadow, or the
/// default silhouette until one is set.
class FafoProfilePhoto extends StatelessWidget {
  const FafoProfilePhoto({super.key, required this.photoUrl, required this.size, this.shadow, this.bytes});

  final String? photoUrl;
  final double size;
  final Color? shadow;

  /// A freshly picked photo, before it's uploaded.
  final ImageProvider? bytes;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image =
        bytes ?? (photoUrl != null && photoUrl!.isNotEmpty ? NetworkImage(photoUrl!) : null);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.amber,
          border: Border.all(color: AppColors.surface, width: size >= 80 ? 4 : 3),
          boxShadow: [
            BoxShadow(
              color: shadow ?? AppColors.ink.withValues(alpha: AppColors.isDark ? 0.6 : 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          image: image == null ? null : DecorationImage(image: image, fit: BoxFit.cover),
        ),
        child: image == null ? CustomPaint(painter: _SilhouettePainter()) : null,
      ),
    );
  }
}

/// Head and shoulders in ink on amber, from the design's default photo.
class _SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.ink;
    final u = size.width / 40;
    canvas.drawCircle(Offset(20 * u, 16 * u), 7 * u, paint);
    final body = Path()
      ..moveTo(6 * u, 40 * u)
      ..cubicTo(7.6 * u, 32 * u, 13.2 * u, 28 * u, 20 * u, 28 * u)
      ..cubicTo(26.8 * u, 28 * u, 32.4 * u, 32 * u, 34 * u, 40 * u)
      ..close();
    canvas.drawPath(body, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
