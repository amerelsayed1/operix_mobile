# Tenant Mobile App Flow

This document draws the current tenant mobile app flow implemented in the KMP app.
It reflects the startup, login, session bootstrap, and permission-aware home/module experience.

## High-level flow

```mermaid
flowchart TD
    A[App launch] --> B{Selected tenant cached?}
    B -- No --> C[Tenant Setup screen]
    B -- Yes --> D[Login screen]

    C --> E[Enter tenant slug]
    E --> F[Fetch tenant config]
    F --> G{Fetch succeeded?}
    G -- Yes --> H[Cache tenant config + selected slug]
    G -- No, cache exists --> I[Allow offline login using cached config]
    G -- No, no cache --> C
    H --> D
    I --> D

    D --> J[POST /api/v1/{tenant_slug}/login]
    J --> K{Login succeeded?}
    K -- No --> D
    K -- Yes --> L[Store token in SessionStore]

    L --> M[GET /{tenant_slug}/me]
    L --> N[GET /{tenant_slug}/me/permissions]
    L --> O[GET /{tenant_slug}/config]

    M --> P[Build SessionBootstrap]
    N --> P
    O --> P

    P --> Q[Home screen]
    Q --> R{Permissions}
    R --> S[Dashboard module]
    R --> T[POS module]
    R --> U[Customers module]
    R --> V[Inventory module]
    R --> W[Finance module]
    R --> X[More module]

    Q --> Y[Logout]
    Q --> Z[Switch tenant]
    Y --> D
    Z --> C
```

## Step-by-step explanation

### 1. App launch
- The app checks whether a tenant slug is already stored in local SQLDelight state.
- If no tenant is selected, the app opens **Tenant Setup**.
- If a tenant is already selected but there is no active session, the app opens **Login**.
- If a session already exists in memory, the app opens **Home**.

### 2. Tenant setup
- The user enters a tenant slug.
- The app resolves tenant context using the path-based tenant pattern.
- Tenant configuration is fetched and cached locally.
- If the network call fails but a cached tenant config already exists, the app still allows login in offline mode.

### 3. Login
- The login screen is enabled only after tenant config is available.
- Fields currently used on the screen:
  - `tenant_slug` (selected earlier during Tenant Setup; not typed again on Login)
  - `username`
  - `password`
- Display-only values shown on the screen:
  - tenant name
  - tenant slug
- The app sends tenant-safe login to:
  - `POST /api/v1/{tenant_slug}/login`
- Request body currently uses:
  - `username`
  - `password`
- If login succeeds, the token is stored in `SessionStore`.

### 4. Session bootstrap
After login, the app loads the rest of the mobile session in parallel:
- `GET /api/v1/{tenant_slug}/me`
- `GET /api/v1/{tenant_slug}/me/permissions`
- `GET /api/v1/{tenant_slug}/config`

Those responses are combined into one in-memory `SessionBootstrap` object.

## 5. Home screen and module selection
The Home screen reads the session and exposes app screens based on permissions.

Current module logic:
- `dashboard.view` -> Dashboard
- `pos.view` or `pos.create` -> POS
- `sales.view`, `sales.create`, or `sales.pay_credit` -> Sales Invoices
- `purchases.view`, `purchases.create`, or `purchases.update` -> Purchase Invoices
- `clients.view`, `clients.create`, `sales.collect_payment`, or `pos.clients` -> Clients
- `suppliers.view`, `suppliers.create`, or `purchases.view` -> Suppliers
- `inventory.view` or `products.view` -> Inventory
- always available -> More

That means two users in the same tenant may see different app screens depending on returned permissions.

## 6. Logout and tenant switching
### Logout
- Clears session state.
- Returns the user to **Login** for the same tenant.

### Switch tenant
- Clears session state.
- Returns the user to **Tenant Setup**.
- The next tenant can then be selected and loaded.

## Screen map

```text
Tenant Setup
  -> Login
    -> Home
      -> Dashboard
      -> POS
      -> Sales Invoices
      -> Purchase Invoices
      -> Clients
      -> Suppliers
      -> Inventory
      -> More
```

## Current implementation notes
- Tenant config is cached locally in SQLDelight.
- Session data is currently stored in-memory in `SessionStore`.
- Authorized calls read the bearer token from `SessionStore`.
- The Home screen is permission-aware, so it behaves like a shell for future real feature screens.
