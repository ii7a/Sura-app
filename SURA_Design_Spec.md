# SURA - UI/UX Design Specification
## Detect and Visualize Light Pollution Worldwide

---

## 1. Brand Identity

### App Name
**SURA** (سُرا) — meaning "light" in Arabic

### Tagline
"Detect and Visualize Light Pollution Worldwide"

### Logo
- SVG logo in navy (#133354) for light backgrounds
- White PNG variant for dark backgrounds
- Simple, modern mark suggesting stars/sky

---

## 2. Color System

### Primary Colors
| Name | Hex | Usage |
|------|-----|-------|
| Navy | `#133354` | Primary brand, buttons, AppBar |
| White | `#FFFFFF` | Backgrounds, primary text on dark |
| Dark | `#0E1720` | Text primary, dark mode base |

### Surface Colors (Light Mode)
| Name | Hex | Usage |
|------|-----|-------|
| Background | `#FFFFFF` | Main background |
| Card BG | `#F5F5F5` | Card surfaces |
| Divider | `#E8E8E8` | Lines, separators |

### Surface Colors (Dark Mode / Map Panel)
| Name | Hex | Usage |
|------|-----|-------|
| Background | `#1A1D23` | Panel background |
| Card BG | `#23272F` | Dark cards |
| Card Border | `#2E3340` | Card borders |

### Text Colors
| Name | Hex | Usage |
|------|-----|-------|
| Text Primary | `#0E1720` | Headings, body text |
| Text Secondary | `#6B7280` | Captions, metadata |
| Text Hint | `#9CA3AF` | Placeholders, hints |
| Text on Dark | `#FFFFFF` | Text on dark surfaces |
| Text Muted Dark | `#B0B8C8` | Secondary text on dark |

### Accent Colors
| Name | Hex | Usage |
|------|-----|-------|
| Purple Accent | `#6C63FF` | Map accent, highlights |
| Purple Glow | `#8B83FF` | Accent hover/glow |
| Analysis Blue | `#4D759E` | Analysis screen accent |
| Success | `#34D399` | Good results, success |
| Warning | `#FBBF24` | Caution states |
| Error | `#EF4444` | Errors, destructive |

### Bortle Scale Colors (Light Pollution Levels)
| Class | Name | Hex | Description |
|-------|------|-----|-------------|
| 1 | Excellent Dark | `#000000` | Best stargazing |
| 2 | Typical Dark | `#1A1A2E` | Very dark sky |
| 3 | Rural Sky | `#16213E` | Rural areas |
| 4 | Rural/Suburban | `#0F3460` | Transition zone |
| 5 | Suburban | `#533483` | Light dome visible |
| 6 | Bright Suburban | `#E94560` | Sky glow obvious |
| 7 | Suburban/Urban | `#FF6B35` | Washed-out sky |
| 8 | City Sky | `#FF9F1C` | Only bright stars |
| 9 | Inner City | `#FFFFFF` | No stars visible |

---

## 3. Typography

### Font Families
- **English:** Montserrat (Google Fonts)
- **Arabic:** Noto Sans Arabic (Google Fonts)
- Auto-switching based on locale

### Type Scale
| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Display | 32px | 800 (ExtraBold) | Hero headings |
| Heading 1 | 24px | 700 (Bold) | Page titles |
| Heading 2 | 20px | 700 (Bold) | Section titles, AppBar |
| Heading 3 | 18px | 600 (SemiBold) | Card titles |
| Body Large | 16px | 400 (Regular) | Primary body text |
| Body | 14px | 400 (Regular) | Default body text |
| Body Bold | 14px | 600 (SemiBold) | Emphasized body |
| Caption | 12px | 500 (Medium) | Metadata, timestamps |
| Overline | 10px | 600 (SemiBold) | Labels, tags |

---

## 4. Spacing & Layout

### Spacing Scale
| Token | Value |
|-------|-------|
| xs | 4px |
| sm | 8px |
| md | 12px |
| base | 16px |
| lg | 20px |
| xl | 24px |
| 2xl | 32px |
| 3xl | 48px |

### Screen Layout
- **Safe area padding:** 16px horizontal
- **Card padding:** 16px all sides
- **Card border radius:** 12px
- **Button border radius:** 8px
- **Avatar sizes:** 40px (small), 48px (medium), 80px (large), 120px (profile)
- **Bottom nav height:** 80px
- **AppBar height:** 56px

### Grid
- Single column layout (mobile-first)
- Image grids: 2 columns with 8px gap
- Trip cards: Full-width with 16px margin

---

## 5. Screen Specifications

---

### 5.1 Splash Screen
- **Background:** `#0E1720` (Dark)
- **Content:** Centered logo (white variant) with fade-in animation
- **Animation:** 0 → 1 opacity over 800ms, then navigate after 2s
- **No navigation controls visible**

---

### 5.2 Login Page
- **Background:** `#0E1720` (Dark)
- **Layout (top to bottom):**
  - Logo (white, centered) — 80px from top
  - "Welcome Back" heading — White, 24px Bold
  - "Sign in to continue" — White70, 14px
  - 32px spacer
  - Email TextField — Dark input with white border (24% opacity), white text
  - 16px spacer
  - Password TextField — Same style, with visibility toggle icon
  - 8px spacer
  - "Forgot Password?" link — right-aligned, white54 text
  - 32px spacer
  - "Sign In" button — Full-width, Navy `#133354` bg, white text, 48px height, 8px radius
  - 16px spacer
  - "Don't have an account? Sign Up" — White54 with tappable "Sign Up"

### 5.3 Sign Up Page
- **Same dark theme as Login**
- **Fields:** Full Name, Username, Email, Password
- **Validation:** Real-time field validation with error messages below fields
- **CTA:** "Create Account" button (same style as Sign In)
- **Footer:** "Already have an account? Sign In"

### 5.4 Forgot Password Page
- **Same dark theme**
- **States:**
  - Default: Email input + "Send Reset Link" button
  - Success: Checkmark icon, "Email Sent!" heading, description, "Resend Email" + "Back to Login" buttons

---

### 5.5 Community Feed (Home Tab)
- **Background:** White
- **AppBar:** White bg, "SURA" title in navy (Montserrat Bold 20px), no elevation
- **Feed:** Scrollable list of `SkyPostCard` widgets
- **FAB:** Navy circle, white "+" icon, bottom-right
- **Empty state:** "No posts yet" centered text with illustration

#### SkyPostCard Component
```
┌─────────────────────────────────────┐
│  [Avatar 40px] Name ✓  @username    │
│                          · 2h ago   │
│                                     │
│  Caption text goes here...          │
│                                     │
│  ┌────────────┬────────────┐        │
│  │            │            │        │
│  │  Image 1   │  Image 2   │        │
│  │            │            │        │
│  └────────────┴────────────┘        │
│                                     │
│  💬 12    🔄 5    ❤️ 48    ↗ Share  │
│                                     │
│─────────────────────────────────────│
```
- **Avatar:** 40px circle, initials fallback with navy bg
- **Verified badge:** Blue checkmark after name
- **Premium badge:** Star icon
- **Images:** Rounded 8px, side-by-side if 2 images
- **Actions row:** Icon + count, spaced evenly, `#6B7280` color
- **Liked state:** Heart filled red `#EF4444`
- **Divider:** `#E8E8E8` between cards

---

### 5.6 Compose Post Page
- **Background:** `#0E1720` (Dark)
- **AppBar:** "Cancel" (left), "Post" button (right, navy pill)
- **Layout:**
  - User avatar + name row
  - Multiline text input (white text, no border, auto-focus)
  - Selected image preview (if any) with remove button
  - Bottom toolbar: Image picker, Camera, Location icons
- **Post button:** Disabled (gray) when empty, Navy when has content

---

### 5.7 User Profile Page
- **Background:** Starry sky custom gradient (dark blue → navy)
- **Profile Header:**
  - Banner image: 200px height, gradient fallback
  - Avatar: 120px circle, overlapping banner by 60px, white 4px border
  - Name: White, 24px Bold
  - @username: White70, 14px
  - Verified/Premium badges inline
  - Bio: White60, 14px, max 3 lines
  - "Edit Profile" button (outlined, white border)
- **Tab Bar:** Posts | Replies | Photos | Likes
  - Active: White text + underline
  - Inactive: White54 text
- **Tab Content:** Filtered list of SkyPostCards

---

### 5.8 Analysis Screen
- **Background:** `#0E1720` (always dark)

#### State: Idle (Camera Ready)
```
┌─────────────────────────────────────┐
│         Sky Pollution Detection      │
│                                     │
│     ┌───────────────────────┐       │
│     │                       │       │
│     │    Viewfinder Frame   │       │
│     │    (dashed border)    │       │
│     │                       │       │
│     │   "Point at the sky"  │       │
│     │                       │       │
│     └───────────────────────┘       │
│                                     │
│     [📷 Camera]   [🖼 Gallery]      │
│                                     │
└─────────────────────────────────────┘
```
- Viewfinder: Dashed border `#4D759E`, rounded 16px
- Instruction text: `#8899AA`, 14px
- Buttons: Outlined style, `#4D759E` border

#### State: Analyzing
- Selected image fills viewfinder area
- Circular progress overlay (white spinner)
- "Analyzing sky quality..." text below

#### State: Results
```
┌─────────────────────────────────────┐
│         Analysis Complete            │
│                                     │
│     ┌───────────────────────┐       │
│     │     Analyzed Image     │       │
│     └───────────────────────┘       │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  Sky Quality: 72/100        │   │
│   │  ████████████░░░░  72%      │   │
│   │                             │   │
│   │  Quality: Good              │   │
│   │  Bortle Class: 3 - Rural    │   │
│   │  Verdict: ✓ Good for        │   │
│   │           stargazing!       │   │
│   └─────────────────────────────┘   │
│                                     │
│   Brightness Histogram              │
│   ┌─────────────────────────────┐   │
│   │  ▓▓░▓▓▓██░░▓▓░░░░░░░░░░   │   │
│   └─────────────────────────────┘   │
│                                     │
│       [ 🔄 Re-examine ]            │
│                                     │
└─────────────────────────────────────┘
```
- Quality score: Large number, color-coded (green=good, red=bad)
- Progress bar: Gradient from red→yellow→green
- Bortle class: Colored badge matching Bortle scale
- Histogram: 256 bars, `#4D759E` fill
- Re-examine button: Outlined, centered

---

### 5.9 Map Screen
- **Full-screen map** (OpenStreetMap + light pollution overlay)
- **Dark mode tiles**

#### Overlay Controls (top-right)
- Year selector: Dropdown (2016-2024)
- Opacity slider: 0-100%
- Toggle legend button

#### Map Controls (right side)
- Zoom in (+) button
- Zoom out (-) button
- Style: Dark semi-transparent bg, white icons

#### Bortle Legend (bottom-left overlay)
- Collapsible panel
- 9 color swatches with class names
- Semi-transparent dark background

#### Dark Sky Site Pins
- Star icons on map at known dark sky locations
- Tap opens dialog with location name + "Book Trip" button

#### Location Detail Panel (draggable bottom sheet)
```
┌─────────────────────────────────────┐
│  ━━━  (drag handle)                 │
│                                     │
│  🔍 Search location...              │
│                                     │
│  ┌─ Light Pollution Level ────────┐ │
│  │  Bortle Class 4                │ │
│  │  Rural/Suburban Transition     │ │
│  │  ████████████  (color bar)     │ │
│  └────────────────────────────────┘ │
│                                     │
│  ┌─ Moon Phase ───────────────────┐ │
│  │  🌙 Waxing Gibbous  78%       │ │
│  │  Impact: Moderate              │ │
│  └────────────────────────────────┘ │
│                                     │
│  ┌─ Weather Now ──────────────────┐ │
│  │  ☁️ 22°C  Partly Cloudy        │ │
│  │  Humidity: 45%  Wind: 12 km/h  │ │
│  │  Cloud Cover: 30%              │ │
│  └────────────────────────────────┘ │
│                                     │
│  ┌─ Sun & Twilight ──────────────┐  │
│  │  ☀️ Sunrise: 6:12 AM           │ │
│  │  🌅 Sunset: 6:45 PM            │ │
│  │  Astronomical Twilight: 7:48PM │ │
│  └────────────────────────────────┘ │
│                                     │
│  ┌─ Visible Planets ─────────────┐  │
│  │  ♃ Jupiter  ★★★★  Taurus      │ │
│  │  ♄ Saturn   ★★★   Aquarius    │ │
│  │  ♂ Mars     ★★    Gemini      │ │
│  └────────────────────────────────┘ │
│                                     │
│  ┌─ Stargazing Score ────────────┐  │
│  │  ⭐ 7.5 / 10                   │ │
│  │  "Good conditions tonight"     │ │
│  └────────────────────────────────┘ │
│                                     │
│  ┌─ Cloud Cover Forecast ────────┐  │
│  │  (hourly bar chart)           │ │
│  └────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```
- Panel bg: `#1A1D23`
- Cards: `#23272F` bg, `#2E3340` border, 12px radius
- Card titles: White, 16px SemiBold
- Values: `#6C63FF` accent or white
- Secondary text: `#B0B8C8`

---

### 5.10 Reserve / Trips Screen
- **Background:** White
- **AppBar:** "Stargazing Trips" title, "My Trips" text button (right)

#### Filter Chips Row
- Horizontal scroll: All | Upcoming | Popular
- Active: Navy bg, white text
- Inactive: `#F5F5F5` bg, `#6B7280` text

#### Trip Card Component
```
┌─────────────────────────────────────┐
│  ┌─────────────────────────────┐    │
│  │  Gradient Background        │    │
│  │                             │    │
│  │  Trip Title                 │    │
│  │  📍 Location Name           │    │
│  │                             │    │
│  │  📅 Mar 15  ⏱ 4h  ⭐ 4.8   │    │
│  │  Bortle: Class 2            │    │
│  │                             │    │
│  │  Guide: Ahmad Al-Rashid     │    │
│  │                             │    │
│  │  $45 USD    3 spots left    │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```
- Card: 16px radius, gradient overlay (trip-specific colors)
- Title: White, 20px Bold
- Location: White70, with pin icon
- Metadata: White60, 12px
- Price: White, 18px Bold
- Spots: `#FBBF24` warning color if < 5

#### FAB (Premium Only)
- Navy circle, white "+" icon
- Only visible for premium users

---

### 5.11 Trip Detail Page
- **Cover image** or gradient: Full-width, 250px height
- **Content (scrollable):**
  - Title: 24px Bold
  - Location with map pin
  - Date, duration, Bortle class chips
  - Guide info: Avatar, name, rating stars
  - Description paragraph
  - "Included" list with checkmark icons
  - Price display: Large, bold
  - "Book Now" button: Full-width, Navy, 48px height
  - Spots remaining indicator

---

### 5.12 Create Trip Page (Premium)
- **Form fields:**
  - Title (text input)
  - Description (multiline)
  - Location (tap to open LocationPickerPage)
  - Date picker
  - Duration (number input)
  - Price + Currency
  - Max group size
  - Included items (add/remove chips)
- **"Create Trip"** button at bottom

---

### 5.13 Comments Sheet
- **Modal bottom sheet** (draggable)
- **Handle:** Centered gray bar, 40px wide
- **Header:** "Comments" + count
- **Comment list:**
  - Avatar (32px) + Name + timestamp
  - Comment text below
  - 8px divider between comments
- **Input bar (bottom):**
  - Text field with "Add a comment..." placeholder
  - Send button (navy icon)

---

### 5.14 Search Page (Coming Soon)
- **Centered illustration** (telescope or stars)
- **"Coming Soon"** heading
- **"Under Development"** subtitle

### 5.15 Chat Page (Coming Soon)
- Same layout as Search placeholder

---

## 6. Component Library

### Buttons
| Type | Style |
|------|-------|
| Primary | Navy bg, white text, 8px radius, 48px height |
| Secondary | White bg, navy border, navy text |
| Text | No bg, navy text |
| Destructive | `#EF4444` bg, white text |
| Disabled | `#E8E8E8` bg, `#9CA3AF` text |
| FAB | 56px circle, navy bg, white icon |

### Input Fields
| Mode | Style |
|------|-------|
| Light | White bg, `#E8E8E8` border, 8px radius, 48px height |
| Dark | Transparent bg, `#FFFFFF24` border, white text |
| Error | Red border `#EF4444`, error text below |
| Focused | Navy border (light) or `#4D759E` border (dark) |

### Cards
| Mode | Style |
|------|-------|
| Light | `#F5F5F5` bg, no border, 12px radius, 16px padding |
| Dark | `#23272F` bg, `#2E3340` border, 12px radius, 16px padding |

### Avatars
| Size | Specs |
|------|-------|
| Small (40px) | Circle, image or initials (navy bg, white text) |
| Medium (48px) | Same, used in comments |
| Large (80px) | Used in compact profile views |
| XL (120px) | Profile page, 4px white border |

### Badges
| Type | Style |
|------|-------|
| Verified | Blue circle with white checkmark, 16px |
| Premium | Gold star icon, 16px |
| Bortle | Colored pill with class number and name |

### Bottom Navigation Bar
- 6 tabs: Home, Search, Camera, Map, Reserve, Chat
- Icons: Cupertino style
- Active: Navy icon + label
- Inactive: `#9CA3AF` icon, no label
- Height: 80px
- Background: White with subtle top shadow

---

## 7. Animations & Transitions

| Element | Animation |
|---------|-----------|
| Splash logo | Fade in 800ms ease-in |
| Page transitions | Material default (slide up on iOS) |
| Like button | Scale bounce 200ms |
| FAB | Scale in on tab switch |
| Analysis spinner | Circular indeterminate, white |
| Map overlay | Opacity fade 300ms |
| Bottom sheet | Spring physics drag |
| Post cards | Fade in on load |

---

## 8. Iconography

- **Style:** Cupertino Icons (iOS-style) + Material Icons mix
- **Size:** 24px default, 20px in compact areas
- **Color:** Inherits from context (navy on light, white on dark)

### Key Icons
| Feature | Icon |
|---------|------|
| Community | `chat_bubble` |
| Search | `search` |
| Camera/Analyze | `camera` |
| Map | `map` |
| Reserve | `calendar_today` |
| Chat | `message` |
| Like | `favorite` / `favorite_border` |
| Comment | `chat_bubble_outline` |
| Repost | `repeat` |
| Share | `ios_share` |
| Location | `location_on` |
| Settings | `settings` |
| Premium | `star` |
| Verified | `verified` |

---

## 9. Localization / RTL Support

- **Languages:** English (LTR), Arabic (RTL)
- **RTL considerations:**
  - Navigation bar mirrors
  - Text alignment flips
  - Icons that imply direction flip (share, back arrow)
  - Layout padding mirrors
- **Font switching:** Montserrat ↔ Noto Sans Arabic based on locale
- **Toggle:** Available in settings/drawer

---

## 10. Accessibility

- **Minimum touch target:** 48x48px
- **Color contrast:** All text meets WCAG AA (4.5:1 ratio)
- **Semantic labels:** All icons and images have descriptive labels
- **Font scaling:** Supports system font size up to 200%
- **Screen reader:** All interactive elements have proper accessibility labels

---

## 11. Figma Page Structure (Recommended)

When building in Figma, organize as:

```
📄 Cover Page
📄 Design System
   ├── Colors
   ├── Typography
   ├── Spacing
   ├── Icons
   └── Components (Buttons, Cards, Inputs, Avatars, Badges, Nav)
📄 Auth Flow
   ├── Splash
   ├── Login
   ├── Sign Up
   └── Forgot Password
📄 Community
   ├── Feed
   ├── Compose Post
   ├── Post Card (Component)
   └── Comments Sheet
📄 Profile
   ├── Profile Page
   └── Edit Profile
📄 Analysis
   ├── Idle State
   ├── Analyzing State
   └── Results State
📄 Map
   ├── Map View
   ├── Location Panel
   └── Legend
📄 Trips
   ├── Trips List
   ├── Trip Detail
   ├── Create Trip
   └── My Trips
📄 Placeholders
   ├── Search (Coming Soon)
   └── Chat (Coming Soon)
📄 Prototype Flow
   └── Connected screens with interactions
```

---

*Generated for SURA - Light Pollution Detection App*
*Flutter + Firebase + Riverpod*
*Supports English & Arabic (RTL)*
