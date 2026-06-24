# Fafo Design System

This document is the design source of truth for Fafo.

The product is an event discovery and social coordination app. The UI should feel lively, local, tactile, and a little playful, not sterile. The current visual language already points in the right direction: clean cool-toned surfaces, bold blue highlights, dark outlines, chunky geometry, and compact futuristic typography.

## Brand Direction

Fafo should feel like:

- A city flyer wall cleaned up into an app
- Social and energetic, not luxury or corporate
- Tactile and slightly comic-book, not glassy or soft
- High-contrast and fast to scan

Fafo should not feel like:

- Generic SaaS
- Premium-black nightlife branding
- Pastel lifestyle UI
- Ultra-minimal monochrome product design

## Core Aesthetic

The system is built on four visual moves:

1. Clean cool-toned surfaces
2. Bold blue action color
3. Dark outline chrome
4. Offset shadows that make controls feel pressable

This gives the app a poster-like feel. The user should feel like they are tapping physical stickers, cards, and buttons pinned onto a board.

## Color System

### Primary Light Theme

These values are defined in [app_colors.dart](lib/src/core/theme/app_colors.dart).

- `lightBgPrimary`: `#F8FBFD`
- `lightBgSecondary`: `#FCFDFE`
- `lightBgTertiary`: `#D6EAFB`
- `lightSurface`: `#FCFDFE`
- `lightBorder`: `#171717`
- `lightTextPrimary`: `#0A2540`
- `lightTextSecondary`: `#3D6B8E`
- `lightTextTertiary`: `#7BA3C2`

### Primary Dark Theme

- `darkBgPrimary`: `#1A1A1E`
- `darkBgSecondary`: `#2A2A2F`
- `darkBgTertiary`: `#3A3A40`
- `darkSurface`: `#2A2A2F`
- `darkBorder`: `#34353D`
- `darkTextPrimary`: `#F5F5F7`
- `darkTextSecondary`: `#A0A0A8`
- `darkTextTertiary`: `#6B6B73`

### Accent Palette

- `accentPrimary`: `#1A87DA`
- `accentSecondary`: `#1472B8`
- `accentWarm`: `#0E5C96`
- `accentLight1`: `#5EAEE8`
- `accentLight2`: `#A3D4F4`
- `accentLightest`: `#EBF5FC`

### Category and Event-Type Colors

The blue family is the brand, but discovery surfaces (map markers, category tags, event-type badges) intentionally use a wider hue set so categories are scannable at a glance. This mapping lives in [home_page.dart](lib/src/features/home/presentation/home_page.dart) (`colorForCategory` / `colorForEventType`).

Categories that stay within the blue family use accent tokens:

- `Live Music`: `accentPrimary`
- `Comedy`: `accentWarm`
- `Nightlife`: `accentSecondary`
- `Art & Culture`: `accentLight1`
- `Workshops`: `accentLight2`

Categories that step outside the blue family use these dedicated hues:

- `Food & Drinks`: `#FF8C42` (warm orange)
- `Wellness`: `#4ADE80` (green)
- `Sports`: `#38BDF8` (sky)
- `Tech`: `#818CF8` (indigo)

Event-type accents:

- `spotlight`: `accentWarm`
- `volunteering`: `#4ADE80` (green)
- default: `accentPrimary`

Status colors:

- success / live dot: `#4ED164` (green)
- verified badge: `#FFDA37` (gold)

These are a closed, named set, not free-for-all decoration. Adding a new category color means adding it to the mapping above and to `colorForCategory`, never inventing a one-off hue inline.

### Quest Gradient Palette

The Quests / gamification surface ([quests_page.dart](lib/src/features/quests/presentation/quests_page.dart)) is the one place the app intentionally uses gradients. Each quest card carries a two-stop `LinearGradient`. Most stay in the blue family; a few "fun" categories use warm gradients to feel rewarding:

- Blue-family quests: pairs drawn from `accentPrimary`, `accentSecondary`, `accentWarm`, `accentLight1`, plus deep navy stops like `#0A2540`, `#0F2027`, `#2C5364`.
- Foodie: `#FF8A00 → #FFC837`
- Culture Vulture: `#5B7C00 → #B8E04A`
- Weekend Warrior: `#FFB703 → #FB8500`
- Host with the Most: `#FFB000 → #FFE066`

Gradients are reserved for this gamification context (and for image-overlay scrims, below). They are not a general surface treatment.

### Color Rules

- Blue is for action, selection, active state, and emphasis.
- Light cool-tone surfaces are the default backgrounds.
- Borders stay dark and visible. Avoid low-contrast gray outlines in light mode.
- Use tertiary backgrounds for disabled or muted surfaces, not for primary calls to action.
- Non-blue hues are allowed only through the named Category, Event-Type, Status, and Quest palettes above. Do not introduce other warm accents inline.
- Gradients are allowed for quest cards and for image-overlay scrims (dark fade over posters and map markers for text legibility). Do not use gradients as a default surface fill.

## Typography

Typography is defined in [app_typography.dart](lib/src/core/theme/app_typography.dart).

Primary font:

- `Tomorrow` via Google Fonts

Why it works:

- It gives the app a future-city personality.
- It feels more ownable than default system sans fonts.
- It supports the poster-and-sticker tone created by the color and chrome system.

### Type Scale

- `displayLarge`: 28/36, weight 800
- `displayMedium`: 18/24, weight 700
- `titleLarge`: 16/22, weight 600
- `bodyLarge`: 14/20, weight 500
- `bodyMedium`: 14/20, weight 500
- `labelLarge`: 12/16, weight 500
- `labelMedium`: 12/16, weight 500
- `labelSmall`: 12/16, weight 500

### Typography Rules

- Big headlines should break across lines when it improves rhythm. Current onboarding screens do this well.
- Keep body copy short and plain. This product should read fast.
- Use `displayMedium` for button labels and section headers.
- Avoid tiny microcopy below 12px.
- Avoid mixing too many font weights in a single screen.

## Spacing System

Spacing is defined in [app_spacing.dart](lib/src/core/constants/app_spacing.dart).

- `xs`: 4
- `sm`: 8
- `md`: 16
- `lg`: 24
- `xl`: 32
- `xxl`: 48

### Spacing Rules

- Most screen padding should use `lg`.
- Use `xl` and `xxl` to create breathing room between headline blocks and body content.
- Keep controls aligned to the spacing scale. Avoid custom values unless a component truly needs optical adjustment.
- Bottom safe-area padding should be additive, not a replacement for the base spacing.

## Shape, Borders, and Shadows

Chrome tokens are defined in [app_chrome.dart](lib/src/core/theme/app_chrome.dart).

- `controlRadius`: 10
- `cardRadius`: 14
- `cardRadiusLg`: 16
- `chipRadius`: 8
- `outlineWidth`: 1.5

### Surface Language

- Controls have medium rounding, not pills.
- Borders are always deliberate and visible.
- Shadows are mostly hard-offset, not blurred ambient shadows.
- Raised elements should feel stacked, almost like cut paper.

### Shadow Rules

- Use offset shadows to imply pressability or layering.
- Keep blur near zero.
- Favor dark offset shadows in light mode.
- Do not use soft floating mobile-OS shadows as the default pattern.

## Component System

### Buttons

The primary button pattern is defined in [app_button.dart](lib/src/shared/widgets/app_button.dart).

There are three variants: `primary`, `featured` (both blue fill, white text), and `secondary` (tertiary fill, primary text).

Rules:

- Primary and featured buttons use blue fill with white text.
- Active raised buttons (primary / featured) sit on a hard offset block: a solid dark (or white in dark mode) shape translated `(6, 6)` behind the button, so it reads as cut paper, not a soft shadow. Secondary and disabled buttons are flat with the lighter `cardShadowSoft`.
- Buttons press in via `AppPressable` (see Pressable Interaction) rather than rippling.
- Default button height is 54.
- Full-width CTA buttons are the default pattern on forms and onboarding.
- Disabled buttons should remain legible but visibly muted.

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

- Filled paper surface
- Rounded rectangular shape using `controlRadius`
- Strong outline
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
