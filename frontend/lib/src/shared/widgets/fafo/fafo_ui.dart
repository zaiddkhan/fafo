import 'dart:async';

import 'package:flutter/material.dart';

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
      semanticsLabel: text,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: AppTypography.display(fontSize, color: color),
    );
  }
}

enum FafoAvatarSize { sm, md, lg }

/// Red initial circle with an ink border (rounded square for groups). Uses the
/// photo when there is one.
class FafoAvatar extends StatelessWidget {
  const FafoAvatar({
    super.key,
    required this.name,
    this.size = FafoAvatarSize.sm,
    this.square = false,
    this.photoUrl,
  });

  final String name;
  final FafoAvatarSize size;
  final bool square;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final (double dim, double font, double border, double radius) =
        switch (size) {
          FafoAvatarSize.sm => (24.0, 12.0, 1.5, 7.0),
          FafoAvatarSize.md => (36.0, 17.0, 2.0, 9.0),
          FafoAvatarSize.lg => (84.0, 44.0, 2.5, 18.0),
        };
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    final shape = square
        ? BoxShape.rectangle
        : BoxShape.circle;
    return ExcludeSemantics(
      child: Container(
        width: dim,
        height: dim,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.signalRed,
          shape: shape,
          borderRadius: square ? BorderRadius.circular(radius) : null,
          border: Border.all(color: AppColors.ink, width: border),
        ),
        child: photoUrl != null && photoUrl!.isNotEmpty && !square
            ? Image.network(
                photoUrl!,
                width: dim,
                height: dim,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initial(initial, font),
              )
            : _initial(initial, font),
      ),
    );
  }

  Widget _initial(String initial, double font) => Text(
    initial,
    style: AppTypography.display(font, color: AppColors.ink).copyWith(height: 1),
  );
}

enum FafoBadgeKind { easy, medium, hard, tag }

/// Mono pill badge: difficulty levels and the "Side quest" tag.
class FafoBadge extends StatelessWidget {
  const FafoBadge(this.label, {super.key, required this.kind, this.onBlue = false});

  final String label;
  final FafoBadgeKind kind;

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
            ? (Colors.transparent, AppColors.onAccent)
            : (AppColors.surface, AppColors.textPrimary),
    };
    final borderColor = onBlue
        ? AppColors.onAccent
        : kind == FafoBadgeKind.tag
        ? AppColors.border
        : AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppChrome.pillRadius),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        label.toUpperCase(),
        semanticsLabel: label,
        style: AppTypography.label(fontSize: 10.5, color: fg).copyWith(
          letterSpacing: 10.5 * 0.08,
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
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
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
    if (onBlue) {
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
        child: Opacity(
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
        ),
      ),
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

/// "Set me free rn" / "I'm free rn". Off: card fill, hollow dot. On: blue,
/// white text and dot, 3px offset.
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
                free ? 'I’m free rn' : 'Set me free rn',
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

/// List row: title, status line, chevron. Hairline below.
class FafoListRow extends StatelessWidget {
  const FafoListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.ui(15, fontWeight: FontWeight.w600),
                  ),
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
            if (showChevron)
              Icon(Icons.arrow_forward, size: 16, color: AppColors.textPrimary),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 18),
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
      padding: EdgeInsets.fromLTRB(18, big ? 24 : 18, 18, big ? 26 : 20),
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
  });

  /// Null renders a static 00:00 (go time).
  final DateTime? to;
  final String label;
  final Color? color;
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
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.ui(12.5, fontWeight: FontWeight.w700, color: color),
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

/// Bottom sheet over a dimmed screen with a round × in the top right. Paper
/// background, nearly full height, as in the prototype.
Future<T?> showFafoSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.bgPrimary,
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height;
      return SizedBox(
        height: height - 44 - MediaQuery.paddingOf(context).top,
        child: Stack(
          children: [
            Positioned.fill(child: builder(sheetContext)),
            Positioned(
              top: 14,
              right: 14,
              child: Semantics(
                button: true,
                label: 'Close',
                child: GestureDetector(
                  onTap: () => Navigator.of(sheetContext).maybePop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Icon(Icons.close, size: 16, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Standard scrolling body for a sheet: 20px gutter, 22px gaps.
class FafoSheetBody extends StatelessWidget {
  const FafoSheetBody({super.key, required this.children, this.gap = 22});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        22,
        20,
        36 + MediaQuery.paddingOf(context).bottom + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
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
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool checked;
  final VoidCallback? onTap;
  final bool topBorder;

  @override
  Widget build(BuildContext context) {
    final hair = BorderSide(color: AppColors.hairline);
    return Semantics(
      checked: checked,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(top: topBorder ? hair : BorderSide.none, bottom: hair),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
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
                child: FafoCheckBox(checked: checked),
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
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Icon(Icons.arrow_back, size: 16, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Full-screen page in the V3 language for the screens the prototype doesn't
/// show (auth, onboarding, settings): round back button, mono eyebrow, display
/// title, a line of copy, content, and the primary action pinned at the bottom.
class FafoFormPage extends StatelessWidget {
  const FafoFormPage({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.children = const [],
    this.footer,
    this.showBack = true,
    this.onBack,
    this.titleSize = 52,
  });

  final String eyebrow;
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  if (showBack)
                    Align(alignment: Alignment.centerLeft, child: FafoBackButton(onTap: onBack))
                  else
                    const SizedBox(height: 36),
                  const SizedBox(height: 28),
                  FafoEyebrow(eyebrow),
                  const SizedBox(height: 10),
                  FafoDisplay(title, fontSize: titleSize),
                  if (subtitle != null) ...[
                    const SizedBox(height: 12),
                    Text(subtitle!, style: AppTypography.ui(15, fontWeight: FontWeight.w400)),
                  ],
                  const SizedBox(height: 28),
                  ...children,
                ],
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: footer,
              ),
          ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
