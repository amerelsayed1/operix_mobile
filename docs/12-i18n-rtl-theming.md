# 12 — Internationalization, RTL & Theming

## 12.1 Languages

| Locale | Language | Direction | Default for |
|--------|----------|-----------|-------------|
| `en` | English | LTR | Global default |
| `ar` | Arabic | RTL | MENA tenants |

Other locales are **out of scope** in Phase 1.

## 12.2 String Source

The mobile app MUST use the **same translation key space** as the web app:

- `business-finance-manager-frontend/apps/tenant-app/src/locales/en.json`
- `business-finance-manager-frontend/apps/tenant-app/src/locales/ar.json`

These files contain ~3,558 keys across ~36 modules (menu, common, auth, dashboard, pos, sales, products, clients, suppliers, expenses, accounts, billing, reports, shifts, settings, employees, printSettings, invoiceConfig, branches, profile, impersonation, paymentMethods, transfers, salesReturns, etc.).

### Synchronization Strategy

1. **Manual sync (Phase 1):** Mirror the web keys into `assets/i18n/en.arb` / `ar.arb` once; maintain deltas via PR.
2. **Automated sync (Phase 2):** CI pipeline converts JSON to ARB on every release.
3. Keys NOT present in web (mobile-specific) live under a `mobile.*` namespace.

## 12.3 Key Naming Conventions

- `module.feature.label`
- `module.feature.error.code`
- `common.save` / `common.cancel` / `common.delete`
- Placeholders use ICU syntax: `{count}`, `{name}`, plurals via `{count, plural, ...}`

## 12.4 RTL Rules

### Layout

- Use `Directionality` wrapping rooted in `MaterialApp`'s locale resolution.
- Prefer `Alignment.centerStart` / `.centerEnd` over `.centerLeft` / `.centerRight`.
- Use `EdgeInsetsDirectional.only(start:, end:)` not `EdgeInsets.only(left:, right:)`.
- `Row` children reverse automatically when direction is RTL. Do **not** manually reverse.
- For `ListView.builder`, stay default — it respects locale direction.

### Icons

| Icon type | RTL behavior |
|-----------|-------------|
| Directional (chevron, back arrow) | mirror (`Transform.flip(flipX: true)` or use auto-mirroring icon sets) |
| Non-directional (user, cart, settings) | no change |
| Brand logos | no change |

### Text

- Arabic text is laid out RTL; numbers remain LTR within.
- Use `BidiFormatter` when concatenating mixed-direction strings.
- For Arabic numerals (Eastern Arabic-Indic `٠١٢٣٤٥٦٧٨٩`), check `TenantConfig.feature_flags.arabic_numerals`. Default to Western digits.

### Numbers, Dates, Currency

```dart
final formatter = NumberFormat.currency(
  locale: Intl.getCurrentLocale(),
  symbol: tenant.currencySymbol,
  decimalDigits: 2,
);
formatter.format(amount.toDouble()); // displays "EGP 1,234.56" or "١٬٢٣٤٫٥٦ ج.م"

final date = DateFormat.yMMMd(Intl.getCurrentLocale()).format(dateTime);
```

### Testing RTL

- Add widget tests that pump with `Directionality(textDirection: TextDirection.rtl)`.
- Visual regression: take golden screenshots for each screen in both LTR and RTL.

## 12.5 Language Switching

- Preference stored in `shared_preferences` under `app.locale`.
- Switch is hot (no app restart). Rebuild MaterialApp with new locale.
- Arabic also switches root `Directionality` to RTL.

## 12.6 Theming

### Tenant Branding

Every tenant has a `theme_primary_color` hex. Apply at runtime:

```dart
ThemeData tenantTheme(Color seed) => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: seed),
  textTheme: GoogleFonts.interTextTheme(),
  ...
);
```

For Arabic: swap text theme to `GoogleFonts.cairoTextTheme()`.

### Dark Mode

Phase 1: follow system theme (auto). No in-app override.

Phase 2: toggle in Profile.

### Light Theme Defaults

- Background: white
- Surface: white / grey-50
- Primary: tenant color
- Error: red-600
- Success: green-600
- Warning: amber-600

### Dark Theme Defaults

- Background: grey-950
- Surface: grey-900
- Primary: tenant color (slightly lighter if contrast insufficient)

### Elevation

- Cards: `elevation: 0` with border, per material 3 conventions
- Buttons: filled primary, filled tonal secondary, outlined tertiary

## 12.7 Typography Scale

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Display L | 32 | 700 | Hero numbers (receipt totals) |
| Display M | 24 | 700 | Screen titles |
| Headline | 20 | 600 | Section titles |
| Title | 16 | 600 | Card titles |
| Body L | 16 | 400 | Primary body |
| Body M | 14 | 400 | Secondary body |
| Caption | 12 | 400 | Timestamps, footnotes |
| Overline | 11 | 500 | Labels |

All sizes respect OS dynamic type scaling.

## 12.8 Spacing Scale

Use a 4-point grid:

- `xs: 4`
- `sm: 8`
- `md: 16`
- `lg: 24`
- `xl: 32`
- `xxl: 48`

## 12.9 Component Style Guide

### Buttons

- Filled primary — main CTA
- Filled tonal — secondary
- Outlined — tertiary
- Text — destructive (delete, cancel)

### Chips

- Status chip: small, pill-shaped, colored by status (success/warning/danger/info)

### Cards

- 12dp border radius
- 1px border color `outline` instead of shadow

### Input fields

- Outlined style, 8dp radius
- Floating label
- Error text below field in `colorScheme.error`

### Lists

- Single-line: 56dp height
- Two-line: 72dp
- Three-line with trailing action: 88dp
- Divider between sections, not between items

### Bottom Navigation

- 3–5 tabs
- Icons + labels
- Active tab highlighted with primary color

## 12.10 Accessibility Hooks

- Every icon-only button has `tooltip` and `Semantics(label: ...)`.
- Every card/list tile has a meaningful semantic label (e.g., "Client Khaled Hassan, outstanding 500 EGP").
- Form errors are announced via `announceForAccessibility`.
- Live regions for KPI updates (dashboard refresh).

## 12.11 Pluralization

Arabic has 6 plural categories (zero, one, two, few, many, other). Always use ICU MessageFormat:

```
"client.count": "{count, plural, =0{No clients} =1{1 client} other{# clients}}"
```

Arabic ARB:

```
"client.count": "{count, plural, =0{لا يوجد عملاء} =1{عميل واحد} =2{عميلان} few{# عملاء} many{# عميلًا} other{# عميل}}"
```

## 12.12 Currency Placement

- Arabic + Egyptian pound: `١٬٢٣٤ ج.م`
- Arabic + SAR: `١٬٢٣٤ ر.س`
- English + EGP: `EGP 1,234.00`
- English + USD: `$ 1,234.00`

Use `intl`'s `NumberFormat.simpleCurrency(locale:, name: currencyCode)`.

## 12.13 Mixed-Direction Strings

When rendering a phone number inside Arabic text:

```
اتصل على +201234567890 لمزيد من المعلومات.
```

Wrap the phone with `\u202A...\u202C` (LRE + PDF) or use `BidiFormatter.rtl().wrapWithSpanDir(phone)`.

## 12.14 Translation Contribution Workflow

1. Developer adds a key to `en.arb` and `ar.arb`.
2. If Arabic translation pending, mark with `@@locale: "ar"` and a `TODO: translate` comment.
3. Translator reviews via PR or an i18n dashboard (e.g., Lokalise, Crowdin) — Phase 2.
4. CI fails if `ar.arb` is missing any key present in `en.arb`.

## 12.15 Key Inventory (High-Level, Mobile Scope)

Mobile app must include keys from the following modules (aligned with web):

- `menu.*`
- `common.*`
- `auth.*`
- `pos.*`
- `salesInvoices.*`
- `salesReturns.*`
- `products.*`
- `inventories.*`
- `clients.*`
- `suppliers.*` (Phase 2)
- `purchases.*` (Phase 2)
- `expenses.*`
- `accounts.*`
- `transfers.*`
- `billing.*`
- `shift.*`
- `paymentMethods.*`
- `reports.*` (Phase 3)
- `dashboard.*`
- `profile.*`
- `settings.*` (read subset)
- `pageTitles.*`
- `permissions.*`
- `mobile.*` (mobile-only keys like offline banner, connectivity)

Refer to `en.json` / `ar.json` in the web frontend for the canonical list.
