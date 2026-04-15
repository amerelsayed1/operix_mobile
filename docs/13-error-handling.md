# 13 — Error Handling

## 13.1 Error Taxonomy

| Class | Origin | Example | User-facing? |
|-------|--------|---------|--------------|
| Network error | Device offline, DNS fail, timeout | `SocketException` | Yes — "Check your connection" |
| HTTP 4xx | Backend business rule | 422 validation, 403 permission | Yes — field or toast |
| HTTP 5xx | Backend outage | 502, 503 | Yes — snackbar + retry |
| Auth error | 401 | Expired token | Redirect to login |
| Billing error | 402 | Subscription suspended | Full-screen billing banner |
| Validation error | 422 | Missing / invalid fields | Inline field errors |
| Parse error | JSON malformed | (shouldn't happen in prod) | Generic error + report |
| Native error | OS exception (camera, storage) | Permission denied | Contextual message |
| Unknown | Uncaught | Null dereference, cast fail | Generic error + report |

## 13.2 Error Normalization

Every Dio error passes through `ErrorNormalizer` which returns a typed `AppError`:

```dart
sealed class AppError {
  const AppError();
}

class NetworkError extends AppError { final String message; }
class ValidationError extends AppError { final Map<String, List<String>> fields; final String? message; }
class AuthError extends AppError { final String? message; }
class BillingError extends AppError { final String message; final String? renewalUrl; }
class PermissionError extends AppError { final String? requiredPermission; }
class NotFoundError extends AppError { final String? resource; }
class RateLimitError extends AppError { final int retryAfterSeconds; }
class ServerError extends AppError { final int statusCode; final String? message; }
class UnknownError extends AppError { final Object? cause; }
```

Mapping rules:

| HTTP | Response shape | Mapped to |
|------|----------------|-----------|
| 401 | `{message}` | `AuthError` — triggers logout |
| 402 | `{message, renewal_url?}` | `BillingError` — full-screen SCR-152 |
| 403 | `{message, required_permission?}` | `PermissionError` — toast |
| 404 | `{message?}` | `NotFoundError` — SCR-202 if full screen, inline otherwise |
| 422 | `{message, errors: {field: [msgs]}}` | `ValidationError` — map to form fields |
| 429 | header `Retry-After` | `RateLimitError` — backoff snackbar |
| 500–599 | any | `ServerError` — snackbar + retry option |
| DioException type == connectionError / receiveTimeout | — | `NetworkError` |

## 13.3 UI Presentation

### 13.3.1 Toast / Snackbar

Transient errors: permission denied, network failure (after retry), 5xx after retry, rate limit.

- Material `SnackBar` with an action (Retry / Dismiss).
- Max 1 visible at a time.
- Duration: 4s for info, 6s for errors.

### 13.3.2 Inline Form Errors

Validation errors (422):

```json
{ "errors": { "email": ["The email has already been taken."] } }
```

- Show red text beneath the field.
- Scroll the first erroneous field into view.
- Focus the first field.

### 13.3.3 Full-Screen Error Pages

- **SCR-200 Generic** — for uncaught / unrecoverable.
- **SCR-201 No Connection** — initial load has no network.
- **SCR-202 Not Found** — deep-linked resource 404.
- **SCR-203 Permission Denied** — user routed to blocked screen.
- **SCR-152 Subscription Blocked** — 402 response.

### 13.3.4 Modal Dialogs

- Confirmation required for destructive errors (e.g., "Order submission failed. Retry or discard?").
- Never use modal dialogs for routine errors (prefer snackbar).

## 13.4 Retry Policy

| Operation | Retry? | Policy |
|-----------|--------|--------|
| GET reads | ✅ | Up to 3 attempts, exponential backoff (500ms, 1s, 2s) |
| POST / PUT / PATCH / DELETE | ❌ | Never auto-retry. Manual retry via snackbar action. |
| POS order submit | ❌ | Manual only. Show clear "Check if the sale went through" prompt. |
| Login | ❌ | Rate limited by backend (10/min). Let user retry manually. |
| Uploads | ✅ (safe ones) | Retry on 5xx, backoff 1s/2s/4s. User-canceled = no retry. |

## 13.5 Retry UX

- Loading spinner during retry.
- After final failure: snackbar with "Retry" + "Report" actions.
- "Report" opens email composer with pre-filled diagnostic (build, user, endpoint, error code).

## 13.6 Timeouts

- Connect timeout: 10s
- Receive timeout: 30s
- Upload timeout: 2 minutes
- On timeout: treat as `NetworkError` with message "Request timed out. Try again.".

## 13.7 Offline Handling

- Before firing a mutation, check `connectivityProvider`.
- If offline, short-circuit the call: show snackbar "You're offline. This action needs a connection."
- For reads, serve cache with banner: "Offline. Last updated X ago."

## 13.8 Logout Flow on 401

1. Show toast: "Your session expired. Please sign in again."
2. Clear secure storage (JWT, slug optional).
3. Clear Riverpod session state.
4. Navigate to SCR-003 Login (preserve tenant slug for convenience).
5. **Do not** clear draft forms (users can resume after re-login).

## 13.9 Billing Blocked Flow on 402

1. Navigate to SCR-152 (full-screen, non-dismissible).
2. Show message from server (`message` field).
3. If user has `billing.manage`, show CTA "Renew on Web" — external `url_launcher`.
4. Provide "Sign out" as secondary action.

## 13.10 Permission Denied Flow on 403

- If the screen itself requires the missing permission → SCR-203.
- If an action on a visible screen failed → toast: `"You don't have permission to {action}."`
- Telemetry event: `permission_denied` with `required_permission`.

## 13.11 Common Error Messages (i18n keys)

```
errors.network.offline
errors.network.timeout
errors.network.generic
errors.auth.session_expired
errors.auth.invalid_credentials
errors.permission.denied
errors.billing.subscription_inactive
errors.not_found.resource
errors.rate_limit
errors.server.generic
errors.unknown
errors.form.required
errors.form.invalid_email
errors.form.invalid_phone
errors.form.min_length
errors.form.max_length
errors.form.mismatch
```

## 13.12 Sentry / Crashlytics Integration

- Capture **all** `UnknownError` and `ServerError` with full stack.
- Capture `AuthError` only if unexpected (e.g., 401 on public endpoint).
- **Do NOT** capture `ValidationError` or `NetworkError` as crashes — they are expected UX flows.
- Add breadcrumb for each navigation, each API call (method, path, status, duration).
- Tag with `tenant_id` and hashed `user_id`.
- Scrub PII from breadcrumbs (strip `password`, `token`, `Authorization`).

## 13.13 Debug Mode Helpers

In dev builds:

- Show exact endpoint and status on the toast / error screen.
- "Copy error" button.
- "Toggle API base URL" in a dev menu.

In release builds:

- User-friendly message only.
- Internal error ID (UUID) shown so support can cross-reference Sentry.

## 13.14 Form Error Mapping Pattern

```dart
try {
  await api.postOrder(payload);
} on ValidationError catch (e) {
  form.applyServerErrors(e.fields); // reactive_forms helper
  showSnackbar(tr('errors.form.generic'));
} on NetworkError {
  showSnackbar(tr('errors.network.offline'));
} on ServerError {
  showSnackbar(tr('errors.server.generic'), action: Retry(...));
} on AppError catch (e) {
  showSnackbar(e.displayMessage);
}
```

## 13.15 Global Error Boundary

A root `FlutterError.onError` + `PlatformDispatcher.instance.onError` handler:

- Routes uncaught exceptions to Sentry.
- Shows SCR-200 if the main isolate crashed mid-navigation.
- Never leaves the user on a blank white screen.
