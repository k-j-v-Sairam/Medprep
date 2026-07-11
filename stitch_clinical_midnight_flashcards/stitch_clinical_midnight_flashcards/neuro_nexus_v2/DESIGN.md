---
name: Neuro-Nexus V2
colors:
  surface: '#13131b'
  surface-dim: '#13131b'
  surface-bright: '#393841'
  surface-container-lowest: '#0d0d15'
  surface-container-low: '#1b1b23'
  surface-container: '#1f1f27'
  surface-container-high: '#292932'
  surface-container-highest: '#34343d'
  on-surface: '#e4e1ed'
  on-surface-variant: '#c7c4d7'
  inverse-surface: '#e4e1ed'
  inverse-on-surface: '#303038'
  outline: '#908fa0'
  outline-variant: '#464554'
  surface-tint: '#c0c1ff'
  primary: '#c0c1ff'
  on-primary: '#1000a9'
  primary-container: '#8083ff'
  on-primary-container: '#0d0096'
  inverse-primary: '#494bd6'
  secondary: '#4fdbc8'
  on-secondary: '#003731'
  secondary-container: '#04b4a2'
  on-secondary-container: '#003f38'
  tertiary: '#4ae176'
  on-tertiary: '#003915'
  tertiary-container: '#00a74b'
  on-tertiary-container: '#003111'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e1e0ff'
  primary-fixed-dim: '#c0c1ff'
  on-primary-fixed: '#07006c'
  on-primary-fixed-variant: '#2f2ebe'
  secondary-fixed: '#71f8e4'
  secondary-fixed-dim: '#4fdbc8'
  on-secondary-fixed: '#00201c'
  on-secondary-fixed-variant: '#005048'
  tertiary-fixed: '#6bff8f'
  tertiary-fixed-dim: '#4ae176'
  on-tertiary-fixed: '#002109'
  on-tertiary-fixed-variant: '#005321'
  background: '#13131b'
  on-background: '#e4e1ed'
  surface-variant: '#34343d'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 20px
  margin-mobile: 16px
  margin-desktop: 48px
---

## Brand & Style
The design system embodies a high-fidelity, futuristic medical environment. It targets high-performing students and professionals who require a focused, deep-work atmosphere. The aesthetic is a refined evolution of **Glassmorphism**, specifically drawing inspiration from modern developer tools (Vercel/Raycast) to provide a "pro-grade" feel. 

The interface leverages depth through transparency and background blurs, creating a sense of layered information. The atmosphere is clinical yet immersive, using OLED blacks to minimize eye strain during long study sessions, punctuated by vibrant, glowing accents that guide the user's attention to critical medical data.

## Colors
The palette is rooted in a deep, nocturnal foundation. The primary background is a true OLED black to ensure maximum contrast for glass effects. 

- **Primary (Indigo):** Used for core actions, focus states, and progress tracking.
- **Secondary (Teal):** Used for navigation, categorization, and secondary interactive elements.
- **Semantic Colors:** Green is reserved strictly for "Correct" or "Mastered" states; Red is used for "Wrong" or "Critical Review" states.
- **Surface Strategy:** Surfaces are built using semi-transparent layers. Surface 1 is the base card container, while Surface 2 utilizes a heavy blur to represent modal overlays and floating menus.

## Typography
The system uses a dual-font approach to balance personality with readability. **Plus Jakarta Sans** provides a modern, geometric feel for headings and brand moments, evoking a sense of forward-thinking technology. **Inter** is utilized for all body text, flashcard content, and labels to ensure maximum legibility and a neutral, systematic feel.

- **Scale:** High contrast between display titles and body text.
- **Tracking:** Headings use slight negative letter spacing for a tighter, "editorial" look. Labels use increased tracking and uppercase styling for hierarchy.

## Layout & Spacing
The design system employs a **Fluid Grid** model with a focus on generous internal padding to create a "breathable" medical interface. 

- **Grid:** A 12-column grid for desktop, collapsing to 4 columns on mobile. 
- **Rhythm:** Spacing is based on an 8px baseline. 
- **Margins:** Desktop views utilize wide 48px margins to center-align study content, while mobile views use 16px margins to maximize horizontal real estate for flashcards.
- **Padding:** Flashcards and modals use a consistent `md` (24px) padding to ensure content does not feel cramped against the glass borders.

## Elevation & Depth
Depth is achieved through physical layering metaphors rather than traditional drop shadows.

- **Glass Effects:** All elevated surfaces utilize a `backdrop-filter: blur(24px) saturate(180%)`. 
- **Borders:** Surfaces are defined by a `1px solid rgba(255, 255, 255, 0.07)` border. 
- **Edge Highlights:** A subtle inner-top stroke of `rgba(255, 255, 255, 0.12)` is applied to mimic a top-down light source reflecting on the glass edge.
- **Glows:** Active or high-priority elements (like the current flashcard or a primary button) emit a soft, diffused outer glow using the primary Indigo or Secondary Teal colors (`box-shadow: 0 0 30px rgba(99, 102, 241, 0.15)`).

## Shapes
The shape language is sophisticated and "Rounded." 

- **Cards & Modals:** Use a standard `rounded-lg` (16px) corner radius to feel approachable and high-end.
- **Input Fields & Buttons:** Follow the same 8px to 16px radius.
- **Selection States:** Small indicators or chips use a full-pill radius to contrast against the more structural card shapes.

## Components
- **Flashcards:** The centerpiece. Features a Surface 1 background with a 1px border. On hover or focus, the indigo glow intensifies. Front-to-back transitions should be fluid, utilizing a 3D flip animation with the glass blur preserved.
- **Buttons:** Primary buttons use a solid-to-gradient Indigo fill with white text. Secondary buttons are "ghost" style with the 1px white-translucent border and a subtle blur.
- **Chips:** Used for medical tags (e.g., "Anatomy", "Neurology"). These use a semi-transparent teal background with high-contrast text.
- **Progress Ring:** A glowing, circular stroke component using the Secondary Teal to track session completion.
- **Input Fields:** Dark, recessed backgrounds with a bright Indigo border focus state. Typography inside should be Inter (Body-md).
- **Lists:** Clean, border-bottom separated rows. The active row should have a subtle background tint and a left-accent Indigo bar.