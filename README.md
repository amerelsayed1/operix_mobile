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
1. App opens directly to the **Login** screen.
2. User enters company code / tenant slug together with identity and password.
3. App resolves tenant config using tenant-aware endpoints and caches the selected tenant config locally.
4. App logs in and boots the session (`login` + `me` + `permissions` + `config`).
5. Home opens using the mockup-inspired tab shell.

If offline:
- Cached tenant config exists -> login can continue using cached tenant context.
- No cached config -> login is blocked with a clear error.

## App flow diagram
See [docs/app-flow.md](docs/app-flow.md) for a drawn flow of direct login, session bootstrap, and the tabbed home screens.

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
### Login flow
- Start app -> Login appears immediately.
- Enter valid company code, identity, and password -> navigates to Home.

### Offline behavior
- After successful tenant resolution once, disconnect network and login again with cached company code -> login can continue using cached tenant config.
- Clear DB, disconnect network, start app -> login cannot resolve tenant config and stays blocked.

## Printing note
Network thermal printers typically use RAW TCP on port `9100`.


## Localhost development
- Desktop/JVM default base URL: `http://127.0.0.1:8000`
- Android emulator default base URL: `http://10.0.2.2:8000`
- If you pass a `localhost` base URL on Android, the shared tenant URL builder now normalizes it to `10.0.2.2` automatically.
