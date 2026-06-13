# Local Business Requirements

## Product Direction

Operix Mobile is a local per-client desktop application. Each client runs their own local PostgreSQL database and works inside a single company/business file.

This project is not the SaaS admin console. It should not expose tenant management, subscription plans, payment gateway setup, platform staff, or super-admin workflows.

The main `amerelsayed1/Operix` repository remains the business-domain reference. This Flutter app should mirror Operix's operational business features, while replacing the SaaS tenancy model with local company settings.

## Primary Users

- Owner / manager: reviews daily performance, inventory, receivables, payables, and reports.
- Cashier: opens shifts, creates POS orders, captures payments, and prints receipts.
- Sales user: manages clients, sales invoices, client payments, and sales returns.
- Purchasing user: manages suppliers, purchase invoices, supplier payments, and supplier returns.
- Inventory user: manages products, stock quantities, adjustments, transfers, and stock counts.
- Accountant: manages accounts, journal entries, periods, reconciliations, and financial reports.

## In Scope

- Dashboard
- Point of Sale
- Sales invoices and client payments
- Sales returns
- Purchase invoices and supplier payments
- Supplier returns
- Product and inventory management
- Branches and stock locations
- Cash/bank accounts, deposits, withdrawals, and transfers
- Expenses and expense categories
- Client directory and receivables
- Supplier directory and payables
- Accounting review and reports
- Local settings for company profile, currency, taxes, print, and database connection

## Operix Web To Local Mapping

| Operix web module | Local desktop equivalent |
|---|---|
| Tenant profile/settings | Company profile/settings |
| Tenant users and roles | Local users and roles |
| Branches | Branches / business locations |
| Inventories | Stock locations and stock balances |
| Products | Product catalogue, categories, units, variants |
| POS | Cashier shifts, orders, payments, receipts, returns |
| Sales invoices | Sales invoices, posting, printing, client payments |
| Sales returns | Sales return/refund/restock workflow |
| Purchase invoices | Purchase invoices, receive stock, supplier payments |
| Supplier returns | Supplier return/refund/stock-out workflow |
| Clients | Customers, receivables, AR aging |
| Suppliers | Vendors, payables, AP aging |
| Expenses | Expense categories and cash/bank expenses |
| Accounts | Cash/bank accounts, drawer accounts, transfers |
| Reports | Dashboard KPIs, P&L, trial balance, account statements |
| Tenant config | Local company settings |

## Out of Scope

- SaaS subscriptions
- Tenant onboarding
- Tenant switching
- Platform billing
- Payment gateway administration
- Super-admin dashboard
- Landing, pricing, and public registration flows

## Data Requirements

- PostgreSQL is the source of truth.
- Data is local to the installed client/company.
- Schema should model one business directly rather than a multi-tenant SaaS platform.
- Future backup/sync features must be explicit business requirements before implementation.
