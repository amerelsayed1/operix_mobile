# Tenant Mobile App Flow

This document draws the current tenant mobile app flow implemented in the KMP app.
It reflects the direct login, session bootstrap, and mockup-inspired tabbed home experience.

## High-level flow

```mermaid
flowchart TD
    A[App launch] --> B[Login screen]
    B --> C[Enter company code / tenant slug]
    C --> D[Enter identity + security key]
    D --> E[Resolve tenant config]
    E --> F{Fetch succeeded?}
    F -- Yes --> G[Cache tenant config + selected slug]
    F -- No, cache exists --> H[Allow login using cached tenant config]
    F -- No, no cache --> B
    G --> I[POST /api/v1/{tenant_slug}/login]
    H --> I

    I --> J{Login succeeded?}
    J -- No --> B
    J -- Yes --> K[Store token in SessionStore]

    K --> L[GET /{tenant_slug}/me]
    K --> M[GET /{tenant_slug}/me/permissions]
    K --> N[GET /{tenant_slug}/config]

    L --> O[Build SessionBootstrap]
    M --> O
    N --> O

    O --> P[Home screen]
    P --> Q[Dashboard tab]
    P --> R[POS tab]
    P --> S[Invoices tab]
    P --> T[Products tab]
    P --> U[More tab]

    P --> V[Logout]
    V --> B
```

## Step-by-step explanation

### 1. App launch
- The app opens directly to **Login** unless an in-memory session already exists.
- Tenant selection is no longer a separate screen.

### 2. Direct login
- The user enters:
  - `company code` / `tenant_slug`
  - `username` or identity value
  - `password`
- The app resolves tenant context from the entered company code.
- Tenant configuration is fetched and cached locally before login continues.
- If the network call fails but a cached tenant config already exists, login can continue in offline-aware mode.
- The app sends tenant-safe login to:
  - `POST /api/v1/{tenant_slug}/login`
- Request body currently uses:
  - `username`
  - `password`
- If login succeeds, the token is stored in `SessionStore`.

### 3. Session bootstrap
After login, the app loads the rest of the mobile session in parallel:
- `GET /api/v1/{tenant_slug}/me`
- `GET /api/v1/{tenant_slug}/me/permissions`
- `GET /api/v1/{tenant_slug}/config`

Those responses are combined into one in-memory `SessionBootstrap` object.

## 4. Home screen and tab selection
The Home screen reads the session and exposes mockup-inspired tabs based on permissions.

Current tab logic:
- `dashboard.view` -> Dashboard
- `pos.view` or `pos.create` -> POS
- `sales.view`, `sales.create`, `purchases.view`, `clients.view`, or `suppliers.view` -> Invoices
- `products.view` or `inventory.view` -> Products
- always available -> More

## 5. Logout
- Clears session state.
- Returns the user to **Login**.
- The next company code can be entered directly on the same screen.

## Screen map

```text
Login
  -> Home
    -> Dashboard
    -> POS
    -> Invoices
    -> Products
    -> More
```

## Current implementation notes
- Tenant config is cached locally in SQLDelight.
- Session data is currently stored in-memory in `SessionStore`.
- Authorized calls read the bearer token from `SessionStore`.
- The Login screen owns company code entry now; there is no separate tenant setup step.
