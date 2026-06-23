# Product Requirements Document
## BudgetWise — Flutter Mobile Budget Management App

**Version:** 1.0  
**Author:** Codrix.dev  
**Status:** Draft  
**Last Updated:** May 2026

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Goals & Success Metrics](#2-goals--success-metrics)
3. [Target Users](#3-target-users)
4. [Feature Scope](#4-feature-scope)
5. [Screen Inventory & User Flows](#5-screen-inventory--user-flows)
6. [Functional Requirements (Per Screen)](#6-functional-requirements-per-screen)
7. [Non-Functional Requirements](#7-non-functional-requirements)
8. [UI Style Guide](#8-ui-style-guide)
9. [Navigation Architecture](#9-navigation-architecture)
10. [State Management](#10-state-management)
11. [Data Models](#11-data-models)
12. [Out of Scope (v1.0)](#12-out-of-scope-v10)
13. [Open Questions](#13-open-questions)

---

## 1. Executive Summary

**BudgetWise** is a cross-platform Flutter mobile application that helps individuals track income, expenses, savings goals, and spending habits. It provides visual breakdowns of financial data, category-based budgeting, and transaction history — all stored locally with optional cloud sync in future versions.

The app targets everyday users aged 18–40 who want a lightweight, offline-first personal finance tool without the complexity of banking integrations.

---

## 2. Goals & Success Metrics

### Product Goals

- Help users track daily expenses with minimal friction (under 10 seconds per entry)
- Provide clear monthly budget overviews with visual feedback
- Alert users when approaching or exceeding category limits
- Build positive financial habits through savings goal tracking

### Success Metrics (v1.0 Launch)

| Metric | Target |
|---|---|
| Avg. time to log a transaction | < 10 seconds |
| Day-7 retention | ≥ 40% |
| Crash-free session rate | ≥ 99% |
| User rating (Play Store / App Store) | ≥ 4.2 stars |
| Transactions logged per active user/week | ≥ 5 |

---

## 3. Target Users

### Primary Persona — "The Aware Spender"

- Age: 20–35
- University students, early-career professionals
- Wants visibility into spending, not automation
- Comfortable with mobile apps; does not want to link bank accounts
- Checks the app weekly for summaries, daily for logging

### Secondary Persona — "The Goal Saver"

- Age: 25–40
- Saving toward a specific goal (phone, trip, emergency fund)
- Motivated by progress bars and milestone feedback
- Uses the app 2–3 times per week

---

## 4. Feature Scope

### In Scope (v1.0)

- Onboarding flow (name, currency, monthly income setup)
- Dashboard with spending summary and budget ring
- Transaction logging (income + expense)
- Category management (default + custom categories)
- Budget limits per category
- Monthly history and analytics (charts)
- Savings goals tracker
- Settings (profile, currency, theme, notifications)

### Out of Scope (v1.0)

- Bank/card integration
- Cloud sync / multi-device
- Shared budgets / family mode
- Receipt scanning (OCR)
- AI categorization

---

## 5. Screen Inventory & User Flows

### 5.1 Screen List

| # | Screen Name | Route | Description |
|---|---|---|---|
| 1 | Splash Screen | `/splash` | App logo + loading init |
| 2 | Onboarding | `/onboarding` | 3-step setup wizard |
| 3 | Dashboard (Home) | `/home` | Monthly summary, recent transactions, quick add |
| 4 | Add Transaction | `/transaction/add` | Modal sheet to log income/expense |
| 5 | Transaction Detail | `/transaction/:id` | View/edit/delete a transaction |
| 6 | Transactions List | `/transactions` | Full history with filters |
| 7 | Budgets | `/budgets` | Category budget limits and usage |
| 8 | Add/Edit Budget | `/budgets/edit` | Set or update a category budget |
| 9 | Analytics | `/analytics` | Charts: spending over time, by category |
| 10 | Savings Goals | `/goals` | List of active savings goals |
| 11 | Add/Edit Goal | `/goals/edit` | Create or update a savings goal |
| 12 | Goal Detail | `/goals/:id` | Progress, contributions, deadline |
| 13 | Settings | `/settings` | Profile, preferences, currency, theme |
| 14 | Category Manager | `/settings/categories` | Add, edit, delete transaction categories |

### 5.2 Primary User Flows

**Flow A — First-Time Setup**
```
Splash → Onboarding Step 1 (Name) → Step 2 (Currency + Income) → Step 3 (Default Categories) → Dashboard
```

**Flow B — Log a Transaction**
```
Dashboard → Tap FAB (Quick Add) → Add Transaction Sheet → Select Type / Category / Amount / Note → Save → Dashboard updates
```

**Flow C — Review Monthly Spending**
```
Dashboard → Tap "See All" (Transactions) → Transactions List (filtered by month) → Tap Transaction → Transaction Detail
```

**Flow D — Set a Budget**
```
Budgets Tab → Tap Category Card → Add/Edit Budget → Set Limit → Save → Budgets Tab (progress updated)
```

**Flow E — Create Savings Goal**
```
Goals Tab → Tap "+" → Add Goal (name, target amount, deadline, icon) → Save → Goals List → Goal Detail
```

---

## 6. Functional Requirements (Per Screen)

---

### Screen 1 — Splash Screen

**Purpose:** App initialization, check onboarding status, route accordingly.

**Requirements:**
- Display app logo and name centered on screen
- Show animated logo reveal (fade in, 1.2s)
- Check local storage: if onboarding complete → navigate to Dashboard; else → Onboarding
- Minimum display duration: 1.5 seconds
- No user interaction required

---

### Screen 2 — Onboarding (3 Steps)

**Purpose:** Collect minimum required data before first use.

**Step 1 — Welcome & Name**
- Display welcome illustration
- Input: First name (required, max 30 chars)
- CTA: "Continue"

**Step 2 — Currency & Monthly Income**
- Dropdown: Currency selection (PKR, USD, EUR, GBP, AED — at minimum)
- Input: Estimated monthly income (numeric, required)
- Toggle: "Include salary in dashboard balance"
- CTA: "Continue"

**Step 3 — Default Categories**
- Display preset categories as toggleable chips: Food, Transport, Shopping, Health, Entertainment, Utilities, Education, Rent, Other
- User can deselect any; all selected by default
- CTA: "Get Started"

**Requirements:**
- Progress indicator (step dots) at top
- Back navigation between steps
- Tapping outside input does not dismiss step
- Data persisted to local DB on completion

---

### Screen 3 — Dashboard (Home)

**Purpose:** Primary hub showing financial overview and quick actions.

**Sections:**

**Header**
- Greeting: "Good morning, [Name]"
- Current month label (e.g., "May 2026")
- Notification bell icon (top right)

**Balance Card**
- Total balance (income − expenses this month)
- Income this month
- Expenses this month
- Background: gradient card, prominent font

**Budget Ring**
- Circular progress indicator showing: total spent / total budget (all categories combined)
- Color changes: green (< 70%), amber (70–90%), red (> 90%)
- Center text: percentage spent

**Category Budget Bars**
- Horizontal scrollable row of top 4 category cards
- Each card: icon, category name, amount spent / limit, mini progress bar
- Tap → navigates to Budgets screen

**Recent Transactions**
- Last 5 transactions: icon, category, note, amount (red for expense, green for income), date
- "See All" link → Transactions List

**FAB (Floating Action Button)**
- "+" button, center-bottom
- Opens Add Transaction bottom sheet

---

### Screen 4 — Add Transaction (Bottom Sheet)

**Purpose:** Log a new income or expense quickly.

**Fields:**
- **Type toggle:** Expense | Income (segmented control, top)
- **Amount:** Large numeric input, auto-focused, currency symbol prefix
- **Category:** Horizontal scrollable icon chips (filtered by type)
- **Date:** Date picker, defaults to today
- **Note:** Optional text input, max 80 chars
- **Repeat:** Toggle for recurring transaction (frequency: daily/weekly/monthly)

**Actions:**
- "Save" button: validates → saves to DB → closes sheet → refreshes Dashboard
- "Cancel" / swipe down: dismisses without saving

**Validation:**
- Amount required, must be > 0
- Category required
- If no budgets set for category, show inline hint: "No budget set for this category. Add one?"

---

### Screen 5 — Transaction Detail

**Purpose:** View full details of a transaction; allow edit or delete.

**Displays:**
- Category icon + color header
- Amount (large)
- Type (Income / Expense) badge
- Category name
- Date and time
- Note (if any)
- Recurring badge (if recurring)

**Actions:**
- Edit button → pre-fills Add Transaction sheet with existing data
- Delete button → confirmation dialog → deletes → navigates back
- Share button → exports transaction as text (optional, nice-to-have)

---

### Screen 6 — Transactions List

**Purpose:** Browse full transaction history with filtering and search.

**Features:**
- Search bar: search by note or category name
- Filters: Month picker, Type (All / Income / Expense), Category multi-select
- Sort: Date (default), Amount (high to low / low to high)
- Grouped by date (e.g., "Today", "Yesterday", "May 28")
- Each row: icon, category, note, amount, time
- Pull-to-refresh
- Empty state illustration if no results

**Pagination:** Load 30 per page, infinite scroll

---

### Screen 7 — Budgets

**Purpose:** View and manage monthly budget limits per category.

**Sections:**

**Overall Budget Summary**
- Total budgeted vs. total spent (large card at top)
- Remaining balance label

**Category Budget Cards (List)**
- Each card: category icon, name, spent / limit, progress bar, percentage
- Color coding: green / amber / red based on usage
- Over-budget categories shown first
- Tap card → Add/Edit Budget screen

**FAB:** "Set New Budget" → Add/Edit Budget for unbudgeted categories

**Empty State:** If no budgets set, show illustration + CTA "Set your first budget"

---

### Screen 8 — Add/Edit Budget

**Purpose:** Set or update spending limit for a category.

**Fields:**
- Category selector (dropdown or chip, pre-selected if coming from Budgets screen)
- Budget limit (numeric input, currency prefix)
- Period: Monthly (v1.0 only; weekly/custom in future)
- Alert threshold: slider 50% – 90% (triggers notification when reached)

**Actions:**
- Save
- Delete Budget (if editing existing)

---

### Screen 9 — Analytics

**Purpose:** Visual breakdown of spending patterns.

**Charts (using `fl_chart` package):**

**Chart 1 — Monthly Spending Bar Chart**
- X-axis: last 6 months
- Y-axis: total expense per month
- Tap bar → show exact value tooltip

**Chart 2 — Category Pie / Donut Chart**
- Breakdown of current month's expenses by category
- Tap slice → highlight + show category name and percentage
- Legend below chart

**Chart 3 — Income vs Expense Line Chart**
- Last 6 months
- Two lines: income (green) and expense (red/orange)

**Filters:**
- Time range: This Month, Last 3 Months, Last 6 Months, This Year
- Category filter (multi-select) for bar/line charts

**Summary Stats Row:**
- Highest spending category
- Avg. daily spend
- Total saved this month (income − expense)

---

### Screen 10 — Savings Goals

**Purpose:** Track progress toward financial goals.

**Goal Card (per goal):**
- Goal name + custom icon/emoji
- Target amount
- Current saved amount
- Progress bar (animated)
- Percentage complete
- Deadline date + days remaining label
- "Add Contribution" button

**Sorting:** Active goals first, completed goals at bottom (with ✓ badge)

**FAB:** "+" → Add Goal screen

**Empty State:** Illustration + "Set your first goal" CTA

---

### Screen 11 — Add/Edit Goal

**Purpose:** Create or modify a savings goal.

**Fields:**
- Goal name (required, max 40 chars)
- Icon / emoji picker (grid of 20+ options)
- Target amount (required, numeric)
- Initial saved amount (optional, for migrating existing savings)
- Target date (date picker, must be in future)
- Notes (optional)

**Actions:**
- Save
- Delete (if editing)

---

### Screen 12 — Goal Detail

**Purpose:** Deep view of a single savings goal with contribution history.

**Sections:**
- Header: icon, name, deadline countdown
- Circular progress indicator (large, animated)
- Amounts: saved / target
- "Add Contribution" button → modal with amount + date + note
- Contribution History list (date, amount, note)
- Projected completion date based on avg. contribution rate

---

### Screen 13 — Settings

**Purpose:** User preferences and app configuration.

**Sections:**

**Profile**
- Name (editable)
- Monthly income (editable)
- Avatar / initials display

**Preferences**
- Currency selector
- Theme toggle: Light / Dark / System
- First day of week: Monday / Sunday (affects weekly reports)
- Language: English only (v1.0)

**Notifications**
- Toggle: Budget alerts
- Toggle: Weekly spending summary (push notification)
- Toggle: Goal deadline reminders

**Data**
- Export Data: CSV export of all transactions
- Clear All Data: destructive action with confirmation dialog

**About**
- App version
- Privacy Policy link
- Rate App link

---

### Screen 14 — Category Manager

**Purpose:** Customize the list of transaction categories.

**Features:**
- List of all categories (icon, name, type: income/expense/both)
- Default categories cannot be deleted (only renamed)
- Custom categories: add, edit, delete
- Tap to edit: change name, icon, color, type

**Add Category:**
- Name (required)
- Icon picker (emoji or preset icon grid)
- Color picker (10 preset swatches)
- Type: Expense / Income / Both

---

## 7. Non-Functional Requirements

### Performance
- App cold start: < 2 seconds on mid-range Android (Snapdragon 665 equivalent)
- Transaction list scroll: 60fps minimum
- Chart render: < 500ms

### Offline-First
- All core features work without internet
- Local persistence: SQLite via `sqflite` or `drift` package
- No data loss on crash (write-ahead logging)

### Reliability
- Crash-free rate: ≥ 99%
- Data corruption: 0 tolerance — all DB writes in transactions

### Security
- No sensitive financial data leaves the device (v1.0)
- Optional: local biometric lock (Face ID / fingerprint) via `local_auth`

### Accessibility
- Minimum tap target: 48×48dp
- Sufficient color contrast (WCAG AA)
- Screen reader labels on all interactive elements
- Dynamic font size support

### Platform Support
- Android: API 23+ (Android 6.0)
- iOS: iOS 13+
- Flutter: 3.x stable channel

---

## 8. UI Style Guide

### 8.1 Design Philosophy

BudgetWise follows a **clean, card-based, data-forward** design language. The UI should feel modern and calm — not overwhelming. Financial data must be readable at a glance. Every screen should have clear visual hierarchy: one primary action, clear supporting data, and zero visual noise.

**Design Principles:**
- **Clarity over decoration** — every element earns its place
- **Calm confidence** — color is used purposefully, not decoratively
- **Thumb-friendly** — primary actions reachable without shifting grip
- **Feedback-rich** — every tap, save, and error has a visible response

---

### 8.2 Color Palette

#### Light Theme

| Role | Color | Hex |
|---|---|---|
| Primary | Deep Indigo | `#4F46E5` |
| Primary Variant | Indigo 700 | `#4338CA` |
| Secondary | Teal Accent | `#0D9488` |
| Background | Off-white | `#F8F9FA` |
| Surface | White | `#FFFFFF` |
| Surface Elevated | Light Gray | `#F1F5F9` |
| On Primary | White | `#FFFFFF` |
| On Background | Near-black | `#1A1A2E` |
| On Surface | Dark Gray | `#374151` |
| Divider | Light Border | `#E5E7EB` |

#### Dark Theme

| Role | Color | Hex |
|---|---|---|
| Primary | Indigo 400 | `#818CF8` |
| Secondary | Teal 400 | `#2DD4BF` |
| Background | Deep Charcoal | `#0F172A` |
| Surface | Dark Card | `#1E293B` |
| Surface Elevated | Elevated Card | `#273549` |
| On Background | Light | `#F1F5F9` |
| On Surface | Muted White | `#CBD5E1` |
| Divider | Subtle | `#2D3748` |

#### Semantic Colors (both themes)

| State | Light | Dark |
|---|---|---|
| Success (income, under budget) | `#10B981` | `#34D399` |
| Warning (approaching limit) | `#F59E0B` | `#FCD34D` |
| Danger (over budget, expense) | `#EF4444` | `#F87171` |
| Info | `#3B82F6` | `#60A5FA` |
| Disabled | `#9CA3AF` | `#4B5563` |

---

### 8.3 Typography

**Font Family:** `Inter` (Google Fonts — include via `google_fonts` package)  
**Fallback:** System default sans-serif

#### Type Scale

| Style | Font Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| `displayLarge` | 32sp | 700 (Bold) | 40sp | Balance amount on Dashboard |
| `displayMedium` | 26sp | 600 (SemiBold) | 34sp | Card headings |
| `headlineMedium` | 22sp | 600 | 28sp | Screen titles |
| `titleLarge` | 18sp | 600 | 24sp | Section headers |
| `titleMedium` | 16sp | 500 (Medium) | 22sp | Card labels |
| `bodyLarge` | 16sp | 400 (Regular) | 24sp | Primary body text |
| `bodyMedium` | 14sp | 400 | 20sp | Secondary body, list items |
| `bodySmall` | 12sp | 400 | 16sp | Captions, timestamps |
| `labelLarge` | 14sp | 500 | 20sp | Button text |
| `labelSmall` | 11sp | 500 | 16sp | Badges, chips |

**Letter spacing:** Use Flutter defaults. Do not manually set unless needed for all-caps labels (+0.5px on labels).

---

### 8.4 Spacing System

Use an **8dp base grid** consistently.

| Token | Value | Usage |
|---|---|---|
| `spacing-2` | 2dp | Icon internal padding |
| `spacing-4` | 4dp | Chip internal padding |
| `spacing-8` | 8dp | Small gaps, between list items |
| `spacing-12` | 12dp | Card internal padding (compact) |
| `spacing-16` | 16dp | Standard card padding, screen horizontal margin |
| `spacing-20` | 20dp | Section gaps |
| `spacing-24` | 24dp | Large section separation |
| `spacing-32` | 32dp | Screen top padding, large gaps |
| `spacing-48` | 48dp | Hero section padding |

**Screen horizontal padding:** 16dp (left and right)  
**Card internal padding:** 16dp all sides  
**Between cards:** 12dp vertical gap  
**Bottom navigation height:** 64dp + safe area  

---

### 8.5 Shape & Elevation

#### Border Radius

| Component | Radius |
|---|---|
| Cards | 16dp |
| Buttons (primary) | 12dp |
| Input fields | 12dp |
| Chips / Tags | 20dp (fully rounded) |
| Bottom sheets | 24dp (top corners only) |
| Modal dialogs | 20dp |
| Small badges | 8dp |
| Category icons | 12dp (rounded square container) |

#### Elevation & Shadow

- **Cards (resting):** Shadow — `BoxShadow(blurRadius: 12, offset: Offset(0, 4), color: Colors.black.withOpacity(0.06))`
- **Cards (pressed):** Remove shadow, scale down to 0.97
- **Bottom Sheet:** Large shadow upward — `blurRadius: 32, offset: Offset(0, -4)`
- **FAB:** Material 3 tonal shadow
- Dark theme: Use surface color elevation instead of drop shadows (Material 3 tonal)

---

### 8.6 Component Specifications

#### Primary Button
```
Background: Primary color
Text: White, labelLarge
Height: 52dp
Width: Full width (preferred) or wrap content
Border radius: 12dp
Padding: horizontal 24dp
State — Pressed: opacity 0.85, scale 0.97
State — Disabled: Background #E5E7EB, text #9CA3AF
State — Loading: CircularProgressIndicator (white, size 20) replaces text
```

#### Secondary / Outlined Button
```
Border: 1.5dp, Primary color
Text: Primary color, labelLarge
Background: Transparent
All other specs same as Primary
```

#### Text Button
```
Text: Primary color
No border, no background
Padding: horizontal 12dp
Used for: "See All", "Cancel", inline links
```

#### Input Field
```
Background: SurfaceElevated
Border: 1dp, Divider color (resting); 2dp Primary (focused); 2dp Danger (error)
Border radius: 12dp
Padding: 16dp horizontal, 14dp vertical
Label: Float above on focus (Material behavior)
Helper/error text: bodySmall, 4dp below field
```

#### Card
```
Background: Surface
Border radius: 16dp
Padding: 16dp
Shadow: as defined in Elevation
No border in light theme
In dark theme: 1dp border at Divider color (optional, for separation)
```

#### Bottom Navigation Bar
```
Height: 64dp + safe area
Background: Surface
Active icon: Primary color + label
Inactive icon: Disabled color
Items: 4 tabs (Home, Budgets, Analytics, Goals)
Badge: Small red dot for alerts
Style: Material 3 NavigationBar
```

#### FAB (Floating Action Button)
```
Style: Extended FAB with "+" icon (no label on Home; labeled on Goals/Budgets)
Color: Primary
Position: Bottom center (Home), Bottom right (list screens)
Bottom offset: 16dp above bottom nav
```

#### Category Icon Container
```
Size: 44×44dp
Shape: Rounded square, radius 12dp
Background: Category color at 15% opacity
Icon: Category color, 22sp
```

#### Progress Bar (Budget usage)
```
Height: 6dp
Border radius: 3dp (fully rounded)
Background: Divider color
Fill: Green / Amber / Red based on threshold
Animated: true (on mount, 600ms ease-out)
```

#### Circular Progress (Budget ring, Goal)
```
Stroke width: 10dp (Dashboard ring), 14dp (Goal detail)
Background arc: Divider color
Progress arc: Semantic color (green/amber/red)
Center text: displayMedium
Animated: true
```

---

### 8.7 Icons

**Package:** `lucide_icons` (Flutter) or `phosphor_flutter`  
**Style:** Line icons, weight regular (not filled) for nav; filled for active nav item  
**Default size:** 22dp  
**Touch target:** Always 44×44dp minimum (wrap in GestureDetector / IconButton with padding)

**Category Icons (Preset):**

| Category | Icon |
|---|---|
| Food | `restaurant` / `fork_knife` |
| Transport | `car` / `bus` |
| Shopping | `shopping_bag` |
| Health | `heart_pulse` |
| Entertainment | `tv` / `film` |
| Utilities | `zap` |
| Education | `book_open` |
| Rent / Housing | `home` |
| Salary / Income | `briefcase` |
| Savings | `piggy_bank` |
| Other | `circle_ellipsis` |

---

### 8.8 Animations & Micro-interactions

**Principles:** Purposeful, never decorative. Every animation should communicate meaning.

| Interaction | Animation |
|---|---|
| Screen transition | Slide + fade (Material 3 default) |
| Bottom sheet open | Slide up, 300ms ease-out |
| Bottom sheet close | Slide down, 250ms ease-in |
| FAB tap | Ripple + scale 1.0 → 0.92 → 1.0 |
| Card tap | Scale 1.0 → 0.97, 100ms |
| Progress bars | Fill from 0 on mount, 600ms ease-out |
| Balance amount | Count-up animation on Dashboard load, 800ms |
| Success save | Checkmark animation in Snackbar |
| Error | Shake animation on invalid field, 300ms |
| Chart load | Bars/lines draw in sequentially, 400ms |
| Delete confirmation | Slide-out, then list reflows |

**Avoid:** Excessive bouncing, flip transitions, overly long animations > 500ms for micro-interactions.

---

### 8.9 Empty States

Each empty list/section must have:
- A centered illustration (simple SVG or Lottie — keep file size < 50KB)
- A headline (titleMedium)
- A supporting subtitle (bodyMedium, muted color)
- A CTA button (if applicable)

| Screen | Headline | Subtitle |
|---|---|---|
| Transactions | "No transactions yet" | "Start by logging your first expense or income." |
| Budgets | "No budgets set" | "Set limits for your spending categories." |
| Goals | "No savings goals" | "Create a goal and start working toward it." |
| Analytics | "Not enough data" | "Log at least a few transactions to see charts." |

---

### 8.10 Error & Feedback Patterns

| Pattern | Component | Duration |
|---|---|---|
| Successful save | `SnackBar` (green, bottom) | 2.5s |
| Validation error | Inline field error text | Until corrected |
| Delete confirmation | `AlertDialog` (destructive) | User-dismissed |
| Network error (future) | `SnackBar` with retry | 4s |
| Over-budget alert | Amber/red `Banner` on Dashboard | Until dismissed |
| Empty required field | Shake + red border + error text | Until corrected |

---

### 8.11 Data Formatting

| Data Type | Format |
|---|---|
| Currency | Symbol prefix, 2 decimal places: `PKR 1,234.50` |
| Large amounts | Abbreviate in charts only: `12.5K`, `1.2M` |
| Date (list items) | `May 28` (same year), `May 28, 2025` (past year) |
| Date (detail view) | `Wednesday, May 28, 2026` |
| Time | `2:30 PM` (12-hour, locale-aware) |
| Percentage | `0` decimals: `67%`, not `67.3%` |
| Relative time | "Today", "Yesterday", then date |

---

## 9. Navigation Architecture

```
App
├── SplashScreen
├── OnboardingFlow (if first launch)
│   ├── Step1Screen
│   ├── Step2Screen
│   └── Step3Screen
└── MainShell (BottomNavigationBar)
    ├── Tab 0 — HomeScreen (Dashboard)
    │   ├── → AddTransactionSheet (modal)
    │   ├── → TransactionDetailScreen
    │   └── → TransactionsListScreen
    ├── Tab 1 — BudgetsScreen
    │   └── → AddEditBudgetScreen
    ├── Tab 2 — AnalyticsScreen
    ├── Tab 3 — GoalsScreen
    │   ├── → AddEditGoalScreen
    │   └── → GoalDetailScreen
    └── SettingsScreen (via AppBar icon or profile tap)
        └── → CategoryManagerScreen
```

**Router:** Use `go_router` package for declarative routing with deep-link support.

---

## 10. State Management

**Recommended:** `Riverpod` (flutter_riverpod ^2.x)

### Provider Structure

```
providers/
├── transaction_provider.dart      # CRUD + filtering for transactions
├── budget_provider.dart           # Budget limits + usage calculation
├── goal_provider.dart             # Goals + contributions
├── category_provider.dart         # Category list management
├── analytics_provider.dart        # Derived data for charts
├── settings_provider.dart         # User preferences, theme
└── dashboard_provider.dart        # Aggregated dashboard data
```

**Pattern:** `AsyncNotifierProvider` for DB-backed data, `NotifierProvider` for settings/theme.

---

## 11. Data Models

### Transaction
```dart
class Transaction {
  final String id;           // UUID
  final double amount;
  final TransactionType type; // income | expense
  final String categoryId;
  final DateTime date;
  final String? note;
  final bool isRecurring;
  final RecurringFrequency? frequency;
  final DateTime createdAt;
}
```

### Category
```dart
class Category {
  final String id;
  final String name;
  final String icon;         // icon key
  final String color;        // hex
  final CategoryType type;   // income | expense | both
  final bool isDefault;      // cannot delete if true
}
```

### Budget
```dart
class Budget {
  final String id;
  final String categoryId;
  final double limit;
  final int month;           // 1–12
  final int year;
  final double alertThreshold; // 0.0–1.0
}
```

### SavingsGoal
```dart
class SavingsGoal {
  final String id;
  final String name;
  final String icon;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadline;
  final String? notes;
  final bool isCompleted;
  final List<GoalContribution> contributions;
}
```

### GoalContribution
```dart
class GoalContribution {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;
}
```

---

## 12. Out of Scope (v1.0)

- Cloud sync / Firebase backend
- Multi-currency conversion with live rates
- Bank account / card linking
- Receipt photo scanning
- AI-based category suggestions
- Family / shared budgets
- Web version
- CSV import
- Widgets (home screen)
- Recurring transaction automation (log manually, flag as recurring)

---

## 13. Open Questions

| # | Question | Owner | Status |
|---|---|---|---|
| 1 | Should recurring transactions auto-log or prompt user? | Product | Open |
| 2 | What is the default currency when Pakistan locale detected? | Dev | Open |
| 3 | Should we use `drift` or `sqflite` for local DB? | Dev | Recommend drift |
| 4 | Lottie animations or SVG for empty states? | Design | Open |
| 5 | Should Settings be a tab or accessed via AppBar icon? | Design | Prefer AppBar |
| 6 | Is biometric lock in-scope for v1.0 launch? | Product | Tentatively yes |
| 7 | What app name goes on the store? "BudgetWise" or something else? | Founder | Open |

---

*End of Document — BudgetWise PRD v1.0*  
*Prepared by Codrix.dev*
