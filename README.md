# BFM KMP App

Kotlin Multiplatform app targeting:
- Android (Jetpack Compose)
- Desktop (Compose Multiplatform JVM)

## Shared modules
- `:shared:core`
- `:shared:domain`
- `:shared:data` (tenant bootstrap + SQLDelight + Ktor)
- `:shared:printing` (ESC/POS network printing)

## Tenant bootstrapping flow
1. First run shows **Tenant Setup** screen.
2. Enter tenant slug (`^[a-z0-9-]{3,50}$`) and press **Connect**.
3. App fetches `GET /api/v1/{tenant_slug}/bootstrap`.
4. Config is cached in SQLDelight (`selected_tenant`, `tenant_config`) before login.
5. Login is enabled only when tenant + config are available.

If offline:
- Cached tenant config exists -> login allowed (offline mode message shown).
- No cached config -> login blocked with clear error.

## Switching tenant
From Login/POS screen, use **Change tenant / Switch Tenant**:
- Re-opens tenant setup.
- Clears tenant-scoped cache tables (`employee_cache`, `product_cache`, `order_cache`) for previous tenant.
- App-level settings are preserved.

## Running
### Android
```bash
./gradlew :composeApp:installDebug
```

### Desktop
```bash
./gradlew :composeApp:run
```

## Testing checklist
### First run (no cache)
- Start app -> Tenant Setup appears.
- Enter valid slug and connect online -> navigates to Login.

### Second run (cache exists)
- Restart app -> opens Login directly.

### Offline behavior
- After successful bootstrap once, disconnect network and restart -> Login still works with cached tenant config.
- Clear DB, disconnect network, start app -> Tenant Setup cannot proceed and Login remains blocked.

## Printing note
Network thermal printers typically use RAW TCP on port `9100`.

## Desktop logging
- Logback config is loaded from `composeApp/src/desktopMain/resources/logback.xml`.
- Default levels:
  - `root` = `INFO`
  - `me.amermahsoub` = `DEBUG`
- To change log level, edit `<root level="...">` or the package logger level in `logback.xml`.
- File logging is optional: uncomment `<appender-ref ref="ROLLING_FILE" />` in `logback.xml`.
- When enabled, log files are written to `./logs/` (relative to the desktop app working directory).
