---
version: alpha
name: coefficiency
description: Design system for coefficiency frontend
colors:
  primary: "#0F172A"
  on-primary: "#FFFFFF"
  primary-container: "#E2E8F0"
  on-primary-container: "#1E293B"
  secondary: "#475569"
  on-secondary: "#FFFFFF"
  secondary-container: "#F1F5F9"
  on-secondary-container: "#334155"
  tertiary: "#2563EB"
  on-tertiary: "#FFFFFF"
  tertiary-container: "#DBEAFE"
  on-tertiary-container: "#1E40AF"
  error: "#DC2626"
  on-error: "#FFFFFF"
  error-container: "#FEE2E2"
  on-error-container: "#991B1B"
  background: "#FFFFFF"
  on-background: "#0F172A"
  surface: "#FFFFFF"
  on-surface: "#0F172A"
  surface-variant: "#F8FAFC"
  on-surface-variant: "#475569"
  outline: "#CBD5E1"
  outline-variant: "#E2E8F0"
  shadow: "#000000"
  scrim: "#000000"
  inverse-surface: "#1E293B"
  inverse-on-surface: "#F1F5F9"
  inverse-primary: "#94A3B8"
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 3.5rem
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: -0.02em
  display-md:
    fontFamily: Inter
    fontSize: 2.8rem
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: -0.015em
  display-sm:
    fontFamily: Inter
    fontSize: 2.2rem
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Inter
    fontSize: 2rem
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 1.75rem
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: -0.005em
  headline-sm:
    fontFamily: Inter
    fontSize: 1.5rem
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: 0
  title-lg:
    fontFamily: Inter
    fontSize: 1.25rem
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: 0
  title-md:
    fontFamily: Inter
    fontSize: 1rem
    fontWeight: 600
    lineHeight: 1.5
    letterSpacing: 0.005em
  title-sm:
    fontFamily: Inter
    fontSize: 0.875rem
    fontWeight: 500
    lineHeight: 1.5
    letterSpacing: 0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 1rem
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: 0.01em
  body-md:
    fontFamily: Inter
    fontSize: 0.875rem
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: 0.015em
  body-sm:
    fontFamily: Inter
    fontSize: 0.75rem
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: 0.02em
  label-lg:
    fontFamily: Inter
    fontSize: 0.875rem
    fontWeight: 500
    lineHeight: 1.5
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 0.75rem
    fontWeight: 500
    lineHeight: 1.5
    letterSpacing: 0.02em
    fontFeature: "case"
  label-sm:
    fontFamily: Inter
    fontSize: 0.6875rem
    fontWeight: 500
    lineHeight: 1.5
    letterSpacing: 0.025em
    fontFeature: "case"
rounded:
  none: 0px
  sm: 4px
  md: 8px
  lg: 12px
  xl: 16px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  2xl: 48px
  3xl: 64px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.md}"
    padding: "12px 24px"
  button-primary-hover:
    backgroundColor: "{colors.secondary}"
    textColor: "{colors.on-secondary}"
  button-secondary:
    backgroundColor: "{colors.surface-variant}"
    textColor: "{colors.on-surface-variant}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.md}"
    padding: "12px 24px"
    outline: "1px solid {colors.outline}"
  button-secondary-hover:
    backgroundColor: "{colors.secondary-container}"
    textColor: "{colors.on-secondary-container}"
  button-tertiary:
    backgroundColor: "transparent"
    textColor: "{colors.tertiary}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.md}"
    padding: "12px 24px"
  button-tertiary-hover:
    backgroundColor: "{colors.tertiary-container}"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
    outline: "1px solid {colors.outline-variant}"
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-md}"
    rounded: "{rounded.md}"
    padding: "10px 14px"
    outline: "1px solid {colors.outline}"
  input-focus:
    outline: "2px solid {colors.tertiary}"
  app-bar:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    height: 64px
    padding: "0 {spacing.md}"
  navigation-rail:
    backgroundColor: "{colors.surface-variant}"
    textColor: "{colors.on-surface-variant}"
    width: 80px
    padding: "{spacing.md} 0"
---

## Overview

coefficiency uses a clean, modern design system optimized for developer tools and dashboards. The aesthetic balances professionalism with approachability — using deep slate tones as a foundation, vibrant blue for action, and generous whitespace to reduce cognitive load.

## Colors

The palette follows Material Design 3 principles with a custom color mapping:

- **Primary (#0F172A):** Deep slate for primary surfaces, navigation, and emphasis.
- **Secondary (#475569):** Muted slate for secondary text, borders, and subtle UI elements.
- **Tertiary (#2563EB):** Vibrant blue for interactive elements, links, and calls-to-action.
- **Error (#DC2626):** Standard red for validation errors and destructive actions.
- **Background (#FFFFFF):** Pure white for main content areas.
- **Surface (#FFFFFF):** White for cards, sheets, and elevated components.
- **Surface Variant (#F8FAFC):** Subtle off-white for alternating backgrounds and navigation rails.

### Usage Rules

- Always use `on-*` colors for text/icons on top of their corresponding container colors
- Tertiary color is reserved exclusively for interactive elements (buttons, links, focus states)
- Error color should never be used for non-error purposes (avoid red for branding)

## Typography

Inter is the sole typeface — chosen for its excellent legibility at small sizes and modern geometric character.

### Scale Usage

| Token | Use Case |
|-------|----------|
| `display-lg` | Hero sections, landing page headlines |
| `display-md` | Page titles in dashboards |
| `headline-lg` | Section headers, modal titles |
| `title-lg` | Card titles, list section headers |
| `body-md` | Primary body text, descriptions |
| `label-lg` | Button text, form labels |
| `label-md` | Tags, badges, metadata |

### Rules

- Display sizes use tight line-height and negative letter-spacing for impact
- Body text uses positive letter-spacing for readability
- Labels use uppercase transforms via `fontFeature: "case"`
- Minimum font size for interactive text: `body-md` (0.875rem)

## Layout

### Spacing Scale

All spacing follows an 8px base grid:

- `xs` (4px): Icon padding, tight internal spacing
- `sm` (8px): Button internal padding, inline element gaps
- `md` (16px): Card padding, form field gaps
- `lg` (24px): Section padding, modal internal spacing
- `xl` (32px): Page section gaps
- `2xl` (48px): Major section separators
- `3xl` (64px): Hero section padding

### Grid

- 12-column grid for desktop (≥1024px)
- 8-column grid for tablet (768px–1023px)
- 4-column grid for mobile (<768px)
- Gutter: 24px (desktop), 16px (tablet), 12px (mobile)
- Max content width: 1280px, centered

## Elevation & Depth

Elevation is communicated through borders and subtle backgrounds rather than shadows:

- **Level 0:** No elevation (base background)
- **Level 1:** `outline-variant` border (cards, inputs)
- **Level 2:** `outline` border + `surface-variant` background (hover states, elevated cards)
- **Level 3:** `shadow` at 8% opacity (modals, popovers)
- **Level 4:** `shadow` at 16% opacity (drawers, full-screen dialogs)

### Shadow Values

```
shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05)
shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)
shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)
shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)
```

## Shapes

- **Buttons:** `rounded.md` (8px)
- **Cards:** `rounded.lg` (12px)
- **Inputs:** `rounded.md` (8px)
- **Tags/Badges:** `rounded.full` (pill shape)
- **Modals/Dialogs:** `rounded.xl` (16px)
- **Avatars:** `rounded.full` (circle)
- **Full-screen elements:** `rounded.none` (0px)

## Components

### Buttons

**Primary Button**
- Background: `colors.primary`
- Text: `colors.on-primary`
- Hover: `colors.secondary` background
- Padding: 12px 24px
- Used for: Main call-to-action, form submission

**Secondary Button**
- Background: `colors.surface-variant`
- Text: `colors.on-surface-variant`
- Border: 1px solid `colors.outline`
- Hover: `colors.secondary-container` background
- Used for: Cancel, back, secondary actions

**Tertiary Button**
- Background: transparent
- Text: `colors.tertiary`
- Hover: `colors.tertiary-container` background
- Used for: Links, text-only actions

### Cards

- Background: `colors.surface`
- Border: 1px solid `colors.outline-variant`
- Border radius: `rounded.lg`
- Padding: `spacing.lg` (24px)
- Shadow: none (elevation via border only)

### Inputs

- Background: `colors.surface`
- Border: 1px solid `colors.outline`
- Border radius: `rounded.md`
- Focus: 2px solid `colors.tertiary` border
- Placeholder text: `colors.on-surface-variant` at 60% opacity
- Error state: `colors.error` border

## Do's and Don'ts

### Do
- Use `spacing.md` (16px) as the default gap between related elements
- Maintain 4.5:1 minimum contrast ratio for all text (WCAG AA)
- Use `tertiary` color exclusively for interactive elements
- Apply `fontFeature: "case"` for uppercase labels to prevent fake small caps

### Don't
- Use pure black (#000000) — always use `colors.primary` (#0F172A) for dark text
- Use shadows without borders — prefer `outline-variant` for subtle elevation
- Mix more than two font weights in a single view
- Use `display-*` sizes for UI elements — reserve for marketing/landing content
