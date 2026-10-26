# Fafo Design System

This document is the design source of truth for Fafo. It follows the V3 brief (Linear SB-125, "Nudge, Side Quests, Profile") and the client prototype ("Adarsh's design"). Where the prototype's source and this file disagree, the prototype wins and this file gets updated.

The product is now three things: send one clear plan, get one clear answer, and have a few 15-minute ideas ready when nobody has one. Map and events are switched off behind `FeatureFlags` ([feature_flags.dart](lib/src/core/config/feature_flags.dart)); sections further down that describe map markers, discovery screens, categories or event badges document parked surfaces, not the current build.

## Core Aesthetic

- **One accent.** FaFo blue is the only "live" colour. It means selected, free, or "this is for you". Red and amber only appear on avatars and difficulty badges.
- **Offset shadow means raised or selected.** Cards (6px) and selected chips / the "I'm free rn" pill (3px) get a hard ink offset. Buttons never do.
- **Rules do the structuring.** 2px ink rules separate sections and card zones; hairlines separate list rows. No grey panels, no soft shadows, no gradients.
- **Sheets, not pages.** Profile, side quests, Code and the preview open as bottom sheets over a dimmed home with a round × top right.
- **Lots of air.** One idea per screen. Home has a single primary action.
- **Tokens, not hex.** Every colour is a named token in [app_colors.dart](lib/src/core/theme/app_colors.dart) so the parked weekly palettes can return by swapping values.

## Color System

### Light

| Token | Hex | Use |
| --- | --- | --- |
| Paper (`lightBgPrimary`) | `#EDEBE3` | App background, sheets |
| Card (`lightBgSecondary`, `lightSurface`) | `#FDFDFD` | Sender card, list rows, chips |
| Ink (`lightBorder`, `lightTextPrimary`, `ink`) | `#171714` | Text, borders, shadows, primary buttons |
| Soft line (`lightSoftLine`) | `#C9C7BF` | Unselected chip border |
| Hairline (`lightBgTertiary`) | `#D5D3CB` | Row dividers |
| Muted (`lightTextSecondary`) | `#5F5E58` | Helper text, "Expired", handles |

### Dark

Follows the phone's system setting; there is no in-app switch (parked as `FeatureFlags.inAppThemeSwitch`). Cards sit close to the background with a visible edge and no offset shadow.

| Token | Hex | Use |
| --- | --- | --- |
| Paper (`darkBgPrimary`) | `#151513` | Background, sheets |
| Card (`darkBgSecondary`) | `#1F1F1C` | Sender card, rows, chips |
| Text (`darkTextPrimary`) | `#EDEBE3` | Text, rules, primary button fill |
| Edge (`darkBorder`) | `#45464E` | Card and chip borders |
| Hairline (`darkBgTertiary`) | `#33332F` | Row dividers |
| Muted (`darkTextSecondary`) | `#A3A198` | Helper text, handles |

### Accents (same in both themes)

| Token | Hex | Use |
| --- | --- | --- |
| FaFo blue (`accentPrimary`) | `#1A6FD0` | Selected, free, receiver card, Easy badge. Always white text (`onAccent`) |
| Signal red (`signalRed`) | `#EB5147` | Avatars, Hard badge |
| Amber (`amber`) | `#F2C350` | Medium badge only |
| State green (`stateGreen`) | `#4ED164` | The live notification's post-yes bar only |

FaFo blue is `#1A6FD0`, deep enough that white text passes AA (5:1) at every size. The older blues `#1A87DA` and `#1C7CF0` are retired, as is the prototype's lime `#CFF04E`.

### Light text on blue

Anything on FaFo blue uses white text: the receiver card (title, timer, labels, header strip), selected chips, the "I'm free rn" pill and its dot, the Easy badge and side quest tags. Inner rules on a blue card turn white; its outer border and offset shadow stay ink. On the receiver card "Yes, I'm in" stays a solid ink pill and "No" becomes a white outline with white text.

## Typography

Four roles, defined in [app_typography.dart](lib/src/core/theme/app_typography.dart). Tomorrow is retired.

| Role | Face | Use |
| --- | --- | --- |
| Display (`AppTypography.display`) | Anton, always uppercase, line height 0.92 | Headlines, plan titles, profile name, section titles |
| Timer (`AppTypography.timer`) | Archivo 800, tabular figures | `mm:ss` with a short label under it ("left to answer", "until go time") |
| UI text (`AppTypography.ui`, `textTheme`) | Archivo, 600-700 for buttons and row titles, 400 for helper lines | Sentence case |
| Label (`AppTypography.label`) | IBM Plex Mono 600, uppercase, tracked 0.12em | Eyebrows, card header strips ("@maya / receiver") |

Display and Label strings stay sentence case in code and are uppercased at the call site, so screen readers read them normally.

## Spacing System

Spacing tokens live in [app_spacing.dart](lib/src/core/constants/app_spacing.dart): `xs 4`, `sm 8`, `md 16`, `lg 24`, `xl 32`, `xxl 48`. Screens use a 20px side gutter, as in the prototype.

## Shape, Borders, and Shadows

Chrome tokens are defined in [app_chrome.dart](lib/src/core/theme/app_chrome.dart).

- `cardRadius`: 22 (nudge cards, 2px border, 6px hard offset)
- `rowRadius`: 16 (side quest rows)
- `chipRadius` / `controlRadius`: 11
- `pillRadius`: 99 (buttons, free pill, badges)
- `outlineWidth`: 2; `softOutlineWidth`: 1.5 (unselected chips)

### Shadow Rules

- Cards: `cardShadow`, a 6px hard ink offset.
- Selected chips and the "I'm free rn" pill: `cardShadowSoft`, a 3px hard ink offset.
- Buttons never get a shadow. (This replaces the old rule that put an offset block behind raised buttons.)
- Dark mode: every offset shadow drops to none (`AppColors.shadow` is transparent).
- Blur is always zero.

## Component System

### Buttons

Pill buttons, defined in [app_button.dart](lib/src/shared/widgets/app_button.dart) and the Material button themes in [app_theme.dart](lib/src/core/theme/app_theme.dart).

- Primary: solid ink fill (`primaryFill`), card-coloured text. Inverts in dark mode (light fill, ink text).
- Secondary: 2px ink outline, transparent fill.
- Full radius, no shadows, 50-56 tall. Disabled drops to 35% opacity.
- `featured` is kept for older callers and renders as primary.

### Pressable Interaction

The shared press behavior is defined in [app_pressable.dart](lib/src/shared/widgets/app_pressable.dart) and is the tactile core of the system.

Rules:

- Tappable raised elements (buttons, cards, list items) should wrap their content in `AppPressable` instead of using Material ink ripples.
- On press, the element translates by a small offset (default `(3, 3)`) toward its shadow over ~70ms with an ease-out curve, so it visibly "pushes into" the board.
- Keep the press offset small and the duration short; this is feedback, not animation choreography.
- Prefer `AppPressable` over `InkWell`/`GestureDetector` anywhere the pressed-in poster feel matters.

### Inputs

Inputs are configured in [app_theme.dart](lib/src/core/theme/app_theme.dart).

Rules:

- One underline (2px ink, blue when focused), no fill, as in the composer
- Placeholder in Muted
- Labels styled with the body scale
- Input layouts must account for keyboard insets cleanly

### Chips

Used for interest selection, category selection, and map filters.

Rules:

- Unselected chips use paper or neutral fill with visible border.
- Selected chips flip to blue or strong emphasis fill.
- Chip spacing should feel dense but not cramped.
- Chip shape should stay compact and slightly rounded, never pill-heavy unless the feature truly calls for it.

### Cards

Cards are used for events, groups, and sheet content.

Rules:

- Default cards should use the paper palette in light mode.
- Borders stay visible.
- Offset shadow treatment is preferred over soft elevation.
- Cards should feel collectible and tappable, not invisible containers.

### Badges

Used for verification, featured status, quest XP, and counts.

Rules:

- Verified badges use the gold status color (`#FFDA37`).
- Featured markers use `accentLight1` stars.
- XP and count badges are full pill shapes (`BorderRadius.circular(999)`). This is the one sanctioned place for pills.
- Keep badge text legible against its fill; pair color with an icon, not color alone.

### Quests

The Quests screen is the gamification surface and has its own visual rules.

Rules:

- Each quest card uses a two-stop gradient from the [Quest Gradient Palette](#quest-gradient-palette).
- Difficulty tiers (easy / medium / hard) and progress are shown on the card.
- This is the only screen where gradients are the primary surface treatment. Do not copy the gradient pattern onto general cards elsewhere.

### Map Markers

Event pins on the map are the core discovery component.

Rules:

- Marker color comes from the Category / Event-Type palette so categories read at a glance.
- Markers and poster images use a dark bottom-fade scrim gradient so overlaid text stays legible.
- Keep marker chrome consistent with the outline + offset-shadow language used elsewhere.

### Navigation

Bottom navigation in [main_shell.dart](lib/src/features/home/presentation/main_shell.dart) follows this pattern:

- Floating tray, inset from the screen edges
- Rounded rectangle shell using `cardRadiusLg`
- Active item highlighted in blue, with the label revealed only on the active item (animated width, ~160ms)
- Compact icon-first layout

This should remain the main nav direction.

## Layout Principles

### Onboarding and Auth

The strongest current pattern is:

- Large two-line headline
- Short supporting sentence
- One main task per screen
- Full-width bottom CTA
- Generous top spacing

This is good. Keep it.

### Discovery Screens

Map and list experiences should feel energetic and dense, but not cluttered.

Rules:

- Show obvious primary actions first
- Keep filtering quick and tactile
- Let cards and chips carry most of the visual variety
- Avoid overcrowding with too many competing accent colors

### Safe Areas and Keyboard

- Keyboard-aware screens should scroll, not compress unpredictably.
- Bottom CTAs should preserve base spacing above the keyboard.
- Safe area handling should be explicit on screens with fixed bottom navigation or sheets.

## Motion

Motion in the app is currently light and should stay that way.

Good motion:

- Quick animated switches
- Small ease-out transitions
- State-change animations under 250ms

Avoid:

- Bouncy novelty animation
- Heavy parallax
- Over-designed loading choreography

Motion should support responsiveness, not become the main event.

## Imagery and Illustration

Current screens lean more on UI than illustration. That is fine.

If imagery is added:

- Prefer candid nightlife, social, creator, and local culture references
- Favor warm, slightly grainy, lived-in imagery over polished stock photos
- Keep photo treatment consistent with the paper-and-poster visual world

## Voice and Copy

Copy should be:

- Short
- Friendly
- Direct
- Slightly playful

Examples:

- Good: "Pick your vibes"
- Good: "What's your name?"
- Good: "This is how you'll appear to others."

Avoid:

- Formal product copy
- Long onboarding explanations
- Marketing language that sounds ad-like

## Accessibility Rules

- Maintain strong text contrast, especially over blue surfaces.
- Use white text on blue backgrounds for readability.
- Touch targets should remain comfortably tappable.
- Support dynamic content and keyboard overlap without clipping primary actions.
- Visual emphasis must not rely on color alone. Border, fill, and typography shifts should work together.

## Implementation Map

These files currently define the design system:

- [app_colors.dart](lib/src/core/theme/app_colors.dart)
- [app_typography.dart](lib/src/core/theme/app_typography.dart)
- [app_theme.dart](lib/src/core/theme/app_theme.dart)
- [app_chrome.dart](lib/src/core/theme/app_chrome.dart)
- [app_spacing.dart](lib/src/core/constants/app_spacing.dart)
- [app_button.dart](lib/src/shared/widgets/app_button.dart)
- [app_pressable.dart](lib/src/shared/widgets/app_pressable.dart)

## Current Drift to Watch

The Category, Quest, Status, and scrim colors documented above are intentional and sanctioned. The items below are genuine drift to pull back toward tokens.

- Several screens hardcode neutral surface colors instead of using tokens: search surfaces in [home_page.dart](lib/src/features/home/presentation/home_page.dart) (`#F4F4F4` / `#1F1F1F`), event-list backgrounds in [events_list_page.dart](lib/src/features/events/presentation/events_list_page.dart) (`#FFFEF8` cream, `#1A1A1A`), and card fills like `#252525` in place of `darkBgSecondary`.
- The bottom-nav container in [main_shell.dart](lib/src/features/home/presentation/main_shell.dart) uses hardcoded `#F8F8F8` / `#050505` and hardcoded nav-item text colors instead of theme tokens.
- Offset shadows vary by component (`AppChrome.cardShadow` is `(0, 4)`, but some cards use one-off offsets like `(5, 6)` with hardcoded colors). Prefer the `AppChrome` shadow tokens.
- Some border radii are one-off (`6`, `12`) rather than the chrome scale.
- Many semi-transparent borders use inline `withValues(alpha: …)`, which softens the "dark and visible border" rule.

This is manageable, but only if new work routes neutral surfaces, shadows, and borders through the shared tokens instead of adding more local constants.

## Non-Negotiables Going Forward

- Use the shared theme tokens first.
- Keep the cool-surface + blue + outline identity intact.
- Prefer tactile offset shadow patterns over generic Material softness.
- Keep typography compact, bold, and fast to scan.
- Build screens around one obvious action at a time.
- When introducing a new component, define the token or shared widget before repeating one-off styles.

## Design North Star

If a new screen looks like a generic Flutter template, it is wrong.

If it feels like a lively city guide printed on paper, then turned into a tactile mobile UI, it is probably right.
