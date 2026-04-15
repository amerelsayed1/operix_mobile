# Operix Mobile App — Software Requirements Specification (SRS)

This folder contains the complete, implementation-ready Software Requirements Specification for the **Operix Tenant Mobile App**.

It is intentionally split into multiple files so that each area can be picked up, versioned, and reviewed independently. It is designed to be **self-contained**: a new engineering session should be able to implement the mobile app end-to-end by reading these documents without additional context hunting.

## Document Structure

| # | File | Purpose |
|---|------|---------|
| 00 | [README.md](./00-README.md) | Index and reading order |
| 01 | [01-introduction.md](./01-introduction.md) | Purpose, scope, goals, glossary |
| 02 | [02-system-overview.md](./02-system-overview.md) | System architecture, backend, integration points |
| 03 | [03-user-roles-permissions.md](./03-user-roles-permissions.md) | Personas, roles, permission catalogue |
| 04 | [04-functional-requirements.md](./04-functional-requirements.md) | Full functional requirements per module |
| 05 | [05-screens-specification.md](./05-screens-specification.md) | Every screen, fields, actions, navigation |
| 06 | [06-api-reference.md](./06-api-reference.md) | Every API endpoint, request & response contract |
| 07 | [07-data-models.md](./07-data-models.md) | Domain data models used by the mobile app |
| 08 | [08-business-rules.md](./08-business-rules.md) | Validation rules, calculations, state machines |
| 09 | [09-non-functional-requirements.md](./09-non-functional-requirements.md) | Performance, security, availability, compliance |
| 10 | [10-mobile-tech-stack.md](./10-mobile-tech-stack.md) | Recommended tech stack & project structure |
| 11 | [11-offline-sync-strategy.md](./11-offline-sync-strategy.md) | Offline caching & sync strategy |
| 12 | [12-i18n-rtl-theming.md](./12-i18n-rtl-theming.md) | Localization, RTL, tenant theming |
| 13 | [13-error-handling.md](./13-error-handling.md) | Error taxonomy and handling |
| 14 | [14-testing-strategy.md](./14-testing-strategy.md) | Testing approach and acceptance criteria |
| 15 | [15-delivery-phases.md](./15-delivery-phases.md) | Phased rollout plan (MVP → v2 → v3) |
| 16 | [16-appendices.md](./16-appendices.md) | Code samples, field catalogues, references |

## Recommended Reading Order

1. **Start here** → `01-introduction.md`
2. Understand the backend you are integrating with → `02-system-overview.md`
3. Understand who uses it → `03-user-roles-permissions.md`
4. Understand WHAT to build → `04-functional-requirements.md`
5. Understand HOW it looks → `05-screens-specification.md`
6. Understand the API contract → `06-api-reference.md`
7. Understand the data you handle → `07-data-models.md` + `08-business-rules.md`
8. Choose your tech → `10-mobile-tech-stack.md`
9. Plan delivery → `15-delivery-phases.md`

## Related Existing Documents

These existing documents in `docs/` remain the **business reference**. The SRS in this folder is built on top of them and supersedes them for implementation detail:

- `docs/TENANT_MOBILE_APP_BUSINESS_BRIEF.md` — business context (read for "why")
- `docs/TENANT_MOBILE_APP_API_GUIDE.md` — API groupings (superseded by `06-api-reference.md`)
- `docs/TENANT_MOBILE_APP_IMPLEMENTATION_GUIDE.md` — early implementation notes (superseded by `10-mobile-tech-stack.md` and `11-offline-sync-strategy.md`)

Root-of-project context:

- `.ai/architecture.md` — full platform architecture
- `.ai/database.md` — full database schema
- `.ai/coding_rules.md` — platform coding standards

## Versioning

- **Document version:** 1.0.0
- **Target backend:** Laravel 12 API (`business_finance_manager_api/`)
- **Base URL pattern:** `/api/v1/{tenant_slug}/...`
- **Auth:** JWT Bearer (`tymon/jwt-auth`)
- **Last updated:** 2026-04-13

## Scope Summary

The mobile app is the **tenant operational companion** — a phone-first tool for:

- **Cashiers** running POS transactions & shifts
- **Managers** overseeing daily operations
- **Owners** tracking business health
- **Storekeepers** managing inventory
- **Accountants** tracking receivables, payables, expenses

It is **NOT** a replacement for the full web app. Super-admin and complex configuration workflows remain on web.
