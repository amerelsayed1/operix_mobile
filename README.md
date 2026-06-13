# Operix Flutter Desktop

Operix Mobile has been reset from the previous Compose/KMP codebase into a Flutter desktop-first client.

## Stack

- Flutter desktop: macOS, Windows, and Linux project folders are scaffolded.
- Direct PostgreSQL client: `postgres` package for the early desktop build.
- UI: Material 3 desktop shell with Operix modules for POS, sales, purchases, inventory, clients, suppliers, accounting, and settings.
- Product scope: local per-client installation, not SaaS administration.

## Run

Start the local PostgreSQL database:

```sh
docker compose up -d postgres
```

Then run the desktop app:

```sh
flutter run -d macos
```

For Android emulator/device runs:

```sh
flutter run -d emulator-5554
```

The Gradle project lives under `android/`, not at the Flutter repository root. If Android Studio asks to sync Gradle, use the `android/` folder or reopen the root as a Flutter project with the Flutter plugin enabled.

By default the app connects to:

```text
postgresql://operix:operix_secret@localhost:5433/operix?sslmode=disable
```

> The bundled `docker compose` maps host port **5433** to the container's 5432 so it
> does not clash with a PostgreSQL instance already running on the host. The app
> defaults to 5433 to match.

If Postgres is not running, the app stays usable with seeded fallback data and shows the connection problem in Settings.

## Point of Sale

**No data is seeded.** The database starts empty. On first launch the app shows a
**license activation screen**, then a **business identity screen** for business
name, branch name, and optional local logo path, then a **setup screen** to
create the initial administrator account. After that it shows the normal
**login screen** (username + password). Passwords are stored as salted
PBKDF2-HMAC-SHA256 hashes (`pbkdf2_sha256$…`). All products, clients, suppliers,
and orders are entered by the user.

## Local License

Each workstation creates a stable installation id and stores its activated
license under the user's app config folder. Licenses are signed offline with
Ed25519 and validated before setup, login, POS, or inventory can open.

Generate a signing key pair:

```sh
dart run tool/license_tool.dart generate-keypair
```

Create a license for the installation id shown on the activation screen:

```sh
dart run tool/license_tool.dart create \
  --business "Style Shop" \
  --installation OPX-XXXX-XXXX-XXXX \
  --days 365 \
  --output build/licenses/style-shop.license
```

For production, keep the private seed outside the app build and pass the matching
public key with `--dart-define=OPERIX_LICENSE_PUBLIC_KEY=...` or replace the
development default in `lib/src/licensing/license_constants.dart`.

## Products & Inventory

The **Inventory** module manages the product catalogue. Use **New product** to open
the create form (mirrors the Operix web `/products/create` fields): name, SKU
(auto-suggested), barcode, category, unit, cost price, selling price, minimum stock
alert, opening stock, and an active toggle. Products are listed with search and can
be edited or deleted. Only **active** products appear in the POS grid.

The POS module flow:

1. Sign in, then open the **POS** module.
2. **Open a shift** with an opening cash float (required before selling).
3. Search / filter products by category, tap to add to the cart, adjust quantities.
4. **Charge**: take cash, card, or a custom tender (split payments supported); change is calculated.
5. The sale is saved transactionally, inventory is decremented, and a **receipt** is shown.
6. **History** lists the shift's orders; tap any to re-open its receipt.
7. **Close the shift** to reconcile counted cash against expected (float + cash sales).

## Settings

The **Settings** module follows the Operix web settings structure, adapted for a
local single-business desktop install. Company settings are active now: business
name, branch name, and local logo path can be edited after first-run setup, and
the sidebar/receipts update from that profile. The module also exposes the
reviewed local roadmap groups for documents/printing, payment methods, product
reference data, accounting/compliance, and system/license/database status.

## Run With PostgreSQL

Use a connection URL:

```sh
flutter run -d macos \
  --dart-define=OPERIX_PG_URL=postgresql://user:password@localhost:5432/operix?sslmode=disable
```

Or individual values:

```sh
flutter run -d macos \
  --dart-define=OPERIX_PG_HOST=localhost \
  --dart-define=OPERIX_PG_PORT=5433 \
  --dart-define=OPERIX_PG_DATABASE=operix \
  --dart-define=OPERIX_PG_USER=operix \
  --dart-define=OPERIX_PG_PASSWORD=secret \
  --dart-define=OPERIX_PG_SSL_MODE=disable
```

Direct PostgreSQL access is intended for this desktop-first phase. Before shipping mobile or public builds, move database access behind the Laravel/API layer so credentials are not distributed in the client.

## Local Schema

The local database schema is initialized from:

```text
database/postgres/init/001_operix_desktop_schema.sql
database/postgres/init/002_pos_schema.sql
```

`001` creates the local company profile, clients, suppliers, products, POS orders,
invoices, and journal entries. `002` adds the POS layer: local `users`,
`pos_shifts`, per-order `pos_order_payments`, extra `pos_orders` columns
(cashier/shift/money breakdown), and document-number sequences. Neither file seeds
any rows. Both are idempotent; `002` can be re-applied to an existing volume with
`docker exec -i operix-mobile-postgres psql -U operix -d operix < database/postgres/init/002_pos_schema.sql`.

## Business Requirements Baseline

The current product direction is documented in:

```text
docs/local-business-requirements.md
```
