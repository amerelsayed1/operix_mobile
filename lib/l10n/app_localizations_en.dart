// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Operix Desktop';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get onbBusinessHeadline => 'Set up your business';

  @override
  String get onbBusinessSubtitle =>
      'Create the local company identity used in the sidebar, receipts, sales documents, and reports.';

  @override
  String get onbBusinessIdentity => 'Business identity';

  @override
  String get onbBusinessIdentityHint =>
      'This is the name and logo customers will see.';

  @override
  String get onbBusinessNameLabel => 'Business name';

  @override
  String get onbBusinessNameRequired => 'Enter the business name';

  @override
  String get onbBranchNameLabel => 'Branch name';

  @override
  String get onbBranchNameRequired => 'Enter the branch name';

  @override
  String get onbLogoPathLabel => 'Business logo path';

  @override
  String get onbLogoPathOptional =>
      'Optional. Use a PNG or JPG path on this workstation.';

  @override
  String get onbSaving => 'Saving…';

  @override
  String get onbSaveBusiness => 'Save business identity';

  @override
  String onbSaveError(Object error) {
    return 'Could not save business profile: $error';
  }

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get enterFullScreen => 'Enter full screen';

  @override
  String get exitFullScreen => 'Exit full screen';

  @override
  String get signOut => 'Sign out';

  @override
  String get apply => 'Apply';

  @override
  String get clear => 'Clear';

  @override
  String get optional => 'Optional';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get brandLocalFirst => 'Local-first • PostgreSQL';

  @override
  String get loginHeadline => 'Operix Point of Sale';

  @override
  String get loginTagline =>
      'Run shifts, sell fast, and keep inventory and cash in sync — all on your local business database.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInSubtitle => 'Use your local Operix workstation account.';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get enterUsername => 'Enter your username';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get signingIn => 'Signing in…';

  @override
  String unexpectedError(Object error) {
    return 'Unexpected error: $error';
  }

  @override
  String get setupHeadline => 'Welcome to Operix';

  @override
  String get setupSubtitle =>
      'Create the administrator account for this workstation. You can add more users later.';

  @override
  String get setupTitle => 'Set up administrator';

  @override
  String get setupHint => 'This is the first account on a fresh database.';

  @override
  String get fullName => 'Full name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get createAccountContinue => 'Create account & continue';

  @override
  String get creating => 'Creating…';

  @override
  String get enterFullName => 'Enter a full name';

  @override
  String get chooseUsername => 'Choose a username';

  @override
  String get usernameMinChars => 'At least 3 characters';

  @override
  String get choosePassword => 'Choose a password';

  @override
  String get passwordMinChars => 'At least 8 characters';

  @override
  String get passwordNeedsLetterNumber => 'Use both letters and numbers';

  @override
  String get passwordsDontMatch => 'Passwords do not match';

  @override
  String get cannotReachDatabase => 'Cannot reach the database';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navPos => 'POS';

  @override
  String get navSales => 'Sales';

  @override
  String get navPurchases => 'Purchases';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navClients => 'Clients';

  @override
  String get navSuppliers => 'Suppliers';

  @override
  String get navReports => 'Reports';

  @override
  String get navAccounting => 'Accounting';

  @override
  String get navSettings => 'Settings';

  @override
  String get titlePointOfSale => 'Point of Sale';

  @override
  String get desktopWorkspace => 'Desktop workspace';

  @override
  String get businessFinanceDesktop => 'Business Finance Desktop';

  @override
  String get connecting => 'Connecting…';

  @override
  String get postgresql => 'PostgreSQL';

  @override
  String get demoData => 'Demo data';

  @override
  String get openCashierShift => 'Open a cashier shift';

  @override
  String get openShiftSubtitle =>
      'Start a shift to begin selling. Cash will be reconciled against the opening float when you close it.';

  @override
  String cashierLabel(Object name) {
    return 'Cashier: $name';
  }

  @override
  String get openingCashFloat => 'Opening cash float';

  @override
  String get openShift => 'Open shift';

  @override
  String get opening => 'Opening…';

  @override
  String couldNotOpenShift(Object error) {
    return 'Could not open shift: $error';
  }

  @override
  String shiftLabel(Object number) {
    return 'Shift $number';
  }

  @override
  String openedAt(Object time) {
    return 'Opened $time';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get history => 'History';

  @override
  String get closeShift => 'Close shift';

  @override
  String closeShiftTitle(Object number) {
    return 'Close shift $number';
  }

  @override
  String get openingFloat => 'Opening float';

  @override
  String get countedCashInDrawer => 'Counted cash in drawer';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get enterCountedCash => 'Enter the counted cash amount.';

  @override
  String couldNotCloseShift(Object error) {
    return 'Could not close shift: $error';
  }

  @override
  String shiftClosedTitle(Object number) {
    return 'Shift $number closed';
  }

  @override
  String get expectedCash => 'Expected cash';

  @override
  String get countedCash => 'Counted cash';

  @override
  String get balanced => 'Balanced';

  @override
  String overBy(Object amount) {
    return 'Over by $amount';
  }

  @override
  String shortBy(Object amount) {
    return 'Short by $amount';
  }

  @override
  String get currentSale => 'Current sale';

  @override
  String itemCount(Object count) {
    return '$count item(s)';
  }

  @override
  String get clearCart => 'Clear cart';

  @override
  String get customerOptional => 'Customer (optional)';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get tapProductsToAdd => 'Tap products to add them';

  @override
  String get searchProductsHint => 'Search products by name or SKU…';

  @override
  String get noProductsMatchSearch => 'No products match your search.';

  @override
  String get outBadge => 'Out';

  @override
  String get all => 'All';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Discount';

  @override
  String get tax => 'Tax';

  @override
  String get total => 'Total';

  @override
  String chargeAmount(Object amount) {
    return 'Charge $amount';
  }

  @override
  String get saving => 'Saving…';

  @override
  String get addAction => 'Add';

  @override
  String get orderDiscount => 'Order discount';

  @override
  String get discountAmount => 'Discount amount';

  @override
  String noMoreStock(Object name) {
    return 'No more \"$name\" in stock.';
  }

  @override
  String checkoutFailed(Object error) {
    return 'Checkout failed: $error';
  }

  @override
  String get takePayment => 'Take payment';

  @override
  String get totalDue => 'Total due';

  @override
  String get paid => 'Paid';

  @override
  String get remaining => 'Remaining';

  @override
  String get change => 'Change';

  @override
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String get custom => 'Custom';

  @override
  String get methodNameHint => 'Method name (e.g. Wallet, Voucher)';

  @override
  String get amount => 'Amount';

  @override
  String get referenceOptional => 'Reference (optional)';

  @override
  String get addPayment => 'Add payment';

  @override
  String get confirmPayment => 'Confirm payment';

  @override
  String confirmChange(Object amount) {
    return 'Confirm • change $amount';
  }

  @override
  String get enterValidAmount => 'Enter a valid amount.';

  @override
  String cannotExceedRemaining(Object method, Object amount) {
    return '$method cannot exceed the remaining $amount.';
  }

  @override
  String get nameCustomMethod => 'Name the custom payment method.';

  @override
  String get salesReceipt => 'Sales Receipt';

  @override
  String get receiptLabel => 'Receipt';

  @override
  String get dateLabel => 'Date';

  @override
  String get cashierShort => 'Cashier';

  @override
  String get customerLabel => 'Customer';

  @override
  String get thankYou => 'Thank you for your purchase!';

  @override
  String get salesHistory => 'Sales history';

  @override
  String get thisShiftOnly => 'This shift only';

  @override
  String get noSalesYet => 'No sales yet';

  @override
  String couldNotLoadOrders(Object error) {
    return 'Could not load orders: $error';
  }

  @override
  String get noPayment => 'No payment';

  @override
  String get products => 'Products';

  @override
  String get searchProductsShort => 'Search products…';

  @override
  String get newProduct => 'New product';

  @override
  String get noProductsYet => 'No products yet';

  @override
  String get createFirstProduct =>
      'Create your first product to start selling.';

  @override
  String get productCreated => 'Product created.';

  @override
  String get productUpdated => 'Product updated.';

  @override
  String get productDeleted => 'Product deleted.';

  @override
  String couldNotDelete(Object error) {
    return 'Could not delete: $error';
  }

  @override
  String get deleteProductTitle => 'Delete product';

  @override
  String deleteProductConfirm(Object name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get colProduct => 'PRODUCT';

  @override
  String get colCategory => 'CATEGORY';

  @override
  String get colStock => 'STOCK';

  @override
  String get colPrice => 'PRICE';

  @override
  String get tagInactive => 'Inactive';

  @override
  String get tagLow => 'Low';

  @override
  String get newProductTitle => 'New product';

  @override
  String get editProductTitle => 'Edit product';

  @override
  String get sectionProductDetails => 'Product details';

  @override
  String get productNameLabel => 'Product name *';

  @override
  String get productNameHint => 'e.g. Wireless Keyboard';

  @override
  String get skuLabel => 'SKU *';

  @override
  String get skuHint => 'Stock keeping unit';

  @override
  String get barcodeLabel => 'Barcode';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryHint => 'e.g. Electronics';

  @override
  String get unitLabel => 'Unit';

  @override
  String get sectionPricing => 'Pricing';

  @override
  String get costPriceLabel => 'Cost price';

  @override
  String get sellingPriceLabel => 'Selling price *';

  @override
  String get sectionInventory => 'Inventory';

  @override
  String get stockOnHand => 'Stock on hand';

  @override
  String get openingStock => 'Opening stock';

  @override
  String get minimumStockAlert => 'Minimum stock alert';

  @override
  String get activeLabel => 'Active';

  @override
  String get activeSubtitle => 'Inactive products are hidden from the POS';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get createProductAction => 'Create product';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get skuRequired => 'SKU is required';

  @override
  String get enterValidPrice => 'Enter a valid price';

  @override
  String get cannotBeNegative => 'Cannot be negative';

  @override
  String couldNotSaveProduct(Object error) {
    return 'Could not save product: $error';
  }

  @override
  String get pickExisting => 'Pick existing';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get statusLabel => 'Status';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get statusBlocked => 'Blocked';

  @override
  String get codeRequired => 'Code is required';

  @override
  String deleteConfirmName(Object name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get customersTitle => 'Customers';

  @override
  String get searchCustomers => 'Search customers…';

  @override
  String get newCustomer => 'New customer';

  @override
  String get editCustomerTitle => 'Edit customer';

  @override
  String get noCustomersYet => 'No customers yet';

  @override
  String get noCustomersSubtitle =>
      'Add your first customer to track sales and balances.';

  @override
  String get noCustomersMatch => 'No customers match your search.';

  @override
  String get customerCreated => 'Customer created.';

  @override
  String get customerUpdated => 'Customer updated.';

  @override
  String get customerDeleted => 'Customer deleted.';

  @override
  String couldNotLoadCustomers(Object error) {
    return 'Could not load customers: $error';
  }

  @override
  String get deleteCustomerTitle => 'Delete customer';

  @override
  String get colCustomer => 'CUSTOMER';

  @override
  String get colPhone => 'PHONE';

  @override
  String get colBalance => 'BALANCE';

  @override
  String get colStatus => 'STATUS';

  @override
  String get sectionCustomerDetails => 'Customer details';

  @override
  String get customerNameLabel => 'Name';

  @override
  String get customerNameHint => 'e.g. Cairo Trading Co.';

  @override
  String get customerCodeLabel => 'Customer code';

  @override
  String get customerCodeHint => 'e.g. CUST-0001';

  @override
  String get createCustomerAction => 'Create customer';

  @override
  String couldNotSaveCustomer(Object error) {
    return 'Could not save the customer: $error';
  }

  @override
  String get suppliersTitle => 'Suppliers';

  @override
  String get searchSuppliers => 'Search suppliers…';

  @override
  String get newSupplier => 'New supplier';

  @override
  String get editSupplierTitle => 'Edit supplier';

  @override
  String get noSuppliersYet => 'No suppliers yet';

  @override
  String get noSuppliersSubtitle =>
      'Add your first supplier to track purchases and payables.';

  @override
  String get noSuppliersMatch => 'No suppliers match your search.';

  @override
  String get supplierCreated => 'Supplier created.';

  @override
  String get supplierUpdated => 'Supplier updated.';

  @override
  String get supplierDeleted => 'Supplier deleted.';

  @override
  String couldNotLoadSuppliers(Object error) {
    return 'Could not load suppliers: $error';
  }

  @override
  String get deleteSupplierTitle => 'Delete supplier';

  @override
  String get colSupplier => 'SUPPLIER';

  @override
  String get colPayable => 'PAYABLE';

  @override
  String get sectionSupplierDetails => 'Supplier details';

  @override
  String get companyNameLabel => 'Company name';

  @override
  String get companyNameHint => 'e.g. Nile Distributors';

  @override
  String get companyNameRequired => 'Company name is required';

  @override
  String get supplierCodeLabel => 'Supplier code';

  @override
  String get supplierCodeHint => 'e.g. SUP-0001';

  @override
  String get createSupplierAction => 'Create supplier';

  @override
  String couldNotSaveSupplier(Object error) {
    return 'Could not save the supplier: $error';
  }

  @override
  String get usersTitle => 'Users';

  @override
  String get searchUsers => 'Search users…';

  @override
  String get newUser => 'New user';

  @override
  String get editUserTitle => 'Edit user';

  @override
  String get noUsersYet => 'No additional users';

  @override
  String get noUsersSubtitle =>
      'Add cashiers and managers to give them their own sign-in.';

  @override
  String get noUsersMatch => 'No users match your search.';

  @override
  String get userCreated => 'User created.';

  @override
  String get userUpdated => 'User updated.';

  @override
  String get userDeleted => 'User deleted.';

  @override
  String couldNotLoadUsers(Object error) {
    return 'Could not load users: $error';
  }

  @override
  String get deleteUserTitle => 'Delete user';

  @override
  String get colUser => 'USER';

  @override
  String get colRole => 'ROLE';

  @override
  String get colLastLogin => 'LAST LOGIN';

  @override
  String get youPill => 'You';

  @override
  String get neverLoggedIn => 'Never';

  @override
  String get sectionUserDetails => 'User details';

  @override
  String get userFullNameHint => 'e.g. Sara Hassan';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get usernameSignInHint => 'used to sign in';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get roleLabel => 'Role';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleCashier => 'Cashier';

  @override
  String get sectionAccess => 'Access';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get leaveBlankKeep => 'Leave blank to keep current';

  @override
  String get passwordRequired => 'A password is required';

  @override
  String get useAtLeast6 => 'Use at least 6 characters';

  @override
  String get inactiveCannotSignIn => 'Inactive users cannot sign in.';

  @override
  String get createUserAction => 'Create user';

  @override
  String couldNotSaveUser(Object error) {
    return 'Could not save the user: $error';
  }

  @override
  String get settingsGroupBusiness => 'Business';

  @override
  String get settingsGroupDocuments => 'Documents & printing';

  @override
  String get settingsGroupPos => 'Point of sale';

  @override
  String get settingsGroupProducts => 'Products';

  @override
  String get navCompanyInfo => 'Company information';

  @override
  String get navAccountingSettings => 'Accounting';

  @override
  String get navRolesPermissions => 'Roles & permissions';

  @override
  String get navPaymentMethods => 'Payment methods';

  @override
  String get navCostCategories => 'Cost categories';

  @override
  String get navInvoiceSettings => 'Invoice settings';

  @override
  String get navPrintSettings => 'Print settings';

  @override
  String get navPrinters => 'Printers';

  @override
  String get navPosDevices => 'Points of sale';

  @override
  String get navItemCategories => 'Item categories';

  @override
  String get navItemAttributes => 'Item attributes';

  @override
  String get navUnits => 'Units of measure';

  @override
  String get navTaxSettings => 'Tax settings';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonBody => 'This settings section will be available soon.';

  @override
  String get catSubtitle => 'Organize your products into categories.';

  @override
  String get catAdd => 'Add category';

  @override
  String get catEditTitle => 'Edit category';

  @override
  String get catSearchHint => 'Search categories…';

  @override
  String get catColName => 'Name';

  @override
  String get catColProducts => 'Products';

  @override
  String catProductCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
      zero: 'No products',
    );
    return '$_temp0';
  }

  @override
  String get catNameEn => 'Name (English)';

  @override
  String get catNameAr => 'Name (Arabic)';

  @override
  String get catNameHintEn => 'e.g. Beverages';

  @override
  String get catNameHintAr => 'مثال: مشروبات';

  @override
  String get catNameRequired => 'Enter a name in English or Arabic.';

  @override
  String get catEmpty => 'No categories yet. Add your first one.';

  @override
  String get catCreated => 'Category created.';

  @override
  String get catUpdated => 'Category updated.';

  @override
  String get catDeleted => 'Category deleted.';

  @override
  String get catDeleteTitle => 'Delete category';

  @override
  String catDeleteConfirm(Object name) {
    return 'Delete the category \"$name\"?';
  }

  @override
  String get unitSubtitle =>
      'Define the units products are sold and stocked in.';

  @override
  String get unitAdd => 'Add unit';

  @override
  String get unitEditTitle => 'Edit unit';

  @override
  String get unitColShortCode => 'Short code';

  @override
  String get unitColDecimals => 'Quantities';

  @override
  String get unitColDefault => 'Default';

  @override
  String get unitNameEn => 'Name (English)';

  @override
  String get unitNameAr => 'Name (Arabic)';

  @override
  String get unitNameHintEn => 'e.g. Piece, Box, Kilogram';

  @override
  String get unitNameHintAr => 'مثال: قطعة، صندوق، كيلوجرام';

  @override
  String get unitShortCodeLabel => 'Short code';

  @override
  String get unitShortCodeHint => 'e.g. kg, pcs, box';

  @override
  String get unitDescriptionLabel => 'Description';

  @override
  String get unitAllowDecimalLabel => 'Quantities';

  @override
  String get unitIntegerOnly => 'Whole (1, 2, 3)';

  @override
  String get unitDecimalAllowed => 'Decimal (1.5, 2.3)';

  @override
  String get unitNameRequired => 'Enter a name in English or Arabic.';

  @override
  String get unitEmpty => 'No units yet. Add your first one.';

  @override
  String get unitCreated => 'Unit created.';

  @override
  String get unitUpdated => 'Unit updated.';

  @override
  String get unitDeleted => 'Unit deleted.';

  @override
  String get unitSetDefault => 'Set as default';

  @override
  String get unitDefaultBadge => 'Default';

  @override
  String unitDefaultSet(Object name) {
    return '\"$name\" is now the default unit.';
  }

  @override
  String get unitDeleteTitle => 'Delete unit';

  @override
  String unitDeleteConfirm(Object name) {
    return 'Delete the unit \"$name\"?';
  }

  @override
  String catalogLoadError(Object error) {
    return 'Could not load the list: $error';
  }

  @override
  String catalogSaveError(Object error) {
    return 'Could not save: $error';
  }

  @override
  String get rolesSubtitle => 'Manage roles and their permissions';

  @override
  String get addRole => 'Add role';

  @override
  String get permissionsAction => 'Permissions';

  @override
  String membersLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
      zero: 'No members',
    );
    return '$_temp0';
  }

  @override
  String get roleDeleteTitle => 'Delete role';

  @override
  String roleDeleteConfirm(Object name) {
    return 'Delete the role \"$name\"?';
  }

  @override
  String get roleCreated => 'Role created.';

  @override
  String get roleUpdated => 'Role updated.';

  @override
  String get roleDeleted => 'Role deleted.';

  @override
  String couldNotLoadRoles(Object error) {
    return 'Could not load roles: $error';
  }

  @override
  String couldNotSaveRole(Object error) {
    return 'Could not save the role: $error';
  }

  @override
  String permissionsForRole(Object name) {
    return 'Permissions — $name';
  }

  @override
  String get newRoleTitle => 'New role';

  @override
  String get permissionsDialogSubtitle =>
      'Choose the actions allowed for this role';

  @override
  String get roleNameLabel => 'Role name';

  @override
  String get roleNameHint => 'e.g. Cashier';

  @override
  String get roleNameRequired => 'Role name is required';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint => 'Description';

  @override
  String get savePermissions => 'Save permissions';

  @override
  String actionsCount(int granted, int total) {
    return '$granted / $total actions';
  }

  @override
  String modulesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modules',
      one: '1 module',
    );
    return '$_temp0';
  }

  @override
  String get companyInfoSubtitle => 'Reviewed from Operix Company Settings.';

  @override
  String get businessLogoLabel => 'Business logo';

  @override
  String get logoUploadHint =>
      'Click to change the logo. Accepted formats: JPG, PNG, GIF (max 2 MB)';

  @override
  String get companySettingsNameLabel => 'Name';

  @override
  String get companySettingsNameRequired => 'Name is required';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get phoneFieldLabel => 'Phone';

  @override
  String get commercialRegLabel => 'Commercial registration number';

  @override
  String get commercialRegHint => 'Enter the commercial registration number';

  @override
  String get cityLabel => 'City';

  @override
  String get regionLabel => 'Region / Governorate';

  @override
  String get countryLabel => 'Country';

  @override
  String get postalCodeLabel => 'Postal code';

  @override
  String get postalCodeHint => 'Enter the postal code';

  @override
  String get addressLabel => 'Address';

  @override
  String get companySettingsSaved => 'Company information saved';

  @override
  String get logoPathDialogTitle => 'Logo image path';

  @override
  String get accessDeniedTitle => 'Access denied';

  @override
  String get accessDeniedBody =>
      'You don\'t have permission to view this section.';

  @override
  String get cannotAssignAdminRole =>
      'Only an administrator can assign a system role.';

  @override
  String get navUsers => 'Users';

  @override
  String get account => 'Account';

  @override
  String get clientAccounts => 'Client accounts';

  @override
  String get supplierAccounts => 'Supplier accounts';

  @override
  String get searchProducts => 'Search products…';

  @override
  String get stockLog => 'Stock log';

  @override
  String get stockAdjusted => 'Stock adjusted.';

  @override
  String couldNotLoadProducts(Object error) {
    return 'Could not load products: $error';
  }

  @override
  String get adjustStock => 'Adjust stock';

  @override
  String get noProductsMatch => 'No products match your search.';

  @override
  String get createFirstProductHint =>
      'Create your first product to start selling.';

  @override
  String get settingsDatabase => 'Database';

  @override
  String get settingsDatabaseSubtitle =>
      'Local PostgreSQL connection used by this workstation.';

  @override
  String get settingsSource => 'Source';

  @override
  String get settingsDemoData => 'Demo data';

  @override
  String get settingsTarget => 'Target';

  @override
  String get settingsConfigured => 'Configured';

  @override
  String get settingsYes => 'Yes';

  @override
  String get settingsNo => 'No';

  @override
  String get settingsSslMode => 'SSL mode';

  @override
  String get settingsLicense => 'License';

  @override
  String get settingsLicenseSubtitle => 'Offline workstation activation.';

  @override
  String get settingsInstallationId => 'Installation id';

  @override
  String get settingsLoading => 'Loading…';

  @override
  String get settingsStatus => 'Status';

  @override
  String get settingsLicensedBusiness => 'Licensed business';

  @override
  String get settingsExpires => 'Expires';

  @override
  String get currencyEgp => 'EGP';

  @override
  String get dashOverviewTitle => 'Business performance overview';

  @override
  String get dashQuickActions => 'Quick actions';

  @override
  String get dashVsPreviousPeriod => 'vs previous period';

  @override
  String get dashPeriodToday => 'Today';

  @override
  String get dashPeriodLast7 => 'Last 7 days';

  @override
  String get dashPeriodThisMonth => 'This month';

  @override
  String get dashPeriodCustom => 'Custom';

  @override
  String get dashFrom => 'From';

  @override
  String get dashTo => 'To';

  @override
  String get dashPickDate => 'Pick a date';

  @override
  String get dashContactSales => 'Contact sales';

  @override
  String get dashContactSalesBody =>
      'To renew your license or upgrade your plan, contact the Operix sales team:\n\nsales@operixhq.com';

  @override
  String get dashCopyEmail => 'Copy email';

  @override
  String get dashSalesEmailCopied => 'Sales email copied';

  @override
  String get dashOk => 'OK';

  @override
  String get dashLicenseExpiryAlert => 'License expiry alert';

  @override
  String dashLicenseExpiryHeadline(int days, String business) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left on $business\'s license.',
      two: '2 days left on $business\'s license.',
      one: '1 day left on $business\'s license.',
      zero: '$business\'s license expires today.',
    );
    return '$_temp0';
  }

  @override
  String dashLicenseExpiryFooter(String date) {
    return 'Expiry date: $date — renew the license to avoid service interruption.';
  }

  @override
  String get dashManageLicense => 'Manage license';

  @override
  String get dashActionNewSalesInvoice => 'New sales invoice';

  @override
  String get dashActionNewExpense => 'New expense';

  @override
  String get dashActionPurchaseInvoice => 'Purchase invoice';

  @override
  String get dashActionSalesReturns => 'Sales returns';

  @override
  String get dashKpiRevenue => 'Revenue';

  @override
  String get dashKpiExpenses => 'Expenses';

  @override
  String get dashKpiExpensesSubtitle => 'Cost of goods & expenses';

  @override
  String get dashKpiNetProfit => 'Net profit';

  @override
  String get dashKpiNetProfitSubtitle => 'After costs';

  @override
  String get dashKpiCashBalance => 'Cash balance';

  @override
  String get dashKpiCashBalanceSubtitle => 'All accounts';

  @override
  String get dashSalesTrend => 'Sales trend';

  @override
  String get dashSalesTrendSubtitle => 'Net sales over the selected period';

  @override
  String get dashRevenueDistribution => 'Revenue distribution';

  @override
  String get dashRevenueDistributionSubtitle => 'How revenue is distributed';

  @override
  String get dashCogs => 'Cost of goods';

  @override
  String get dashNoSalesData => 'No sales data for this period';

  @override
  String get dashTotalProfit => 'Total profit';

  @override
  String dashMarginLabel(String value) {
    return 'Margin $value%';
  }

  @override
  String get dashGrossMargin => 'Gross profit margin';

  @override
  String get dashInventoryValue => 'Inventory value';

  @override
  String get dashAtCost => 'At cost';

  @override
  String get dashOrders => 'Orders';

  @override
  String dashAverageLabel(String value) {
    return 'Average: $value';
  }

  @override
  String get dashNewCustomers => 'New customers';

  @override
  String get dashThisPeriod => 'This period';

  @override
  String get dashSupplierDue => 'Supplier payables';

  @override
  String get dashTotalDueAmount => 'Total amount due';

  @override
  String get dashTopProducts => 'Top selling products';

  @override
  String dashPiecesLabel(int count) {
    return '$count pcs';
  }

  @override
  String get dashInventoryHealthy => 'All items are well stocked';

  @override
  String dashInventoryLowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items reached reorder level',
      one: '1 item reached reorder level',
    );
    return '$_temp0';
  }

  @override
  String get dashInventoryHealthyBody =>
      'Inventory is in good shape across all stock-tracked items';

  @override
  String get dashInventoryLowBody =>
      'Review the inventory screen to reorder low-stock items';

  @override
  String get dashSalesInvoicesTitle => 'Sales invoices';

  @override
  String get dashCreateInvoice => 'Create invoice';

  @override
  String get dashFilters => 'Filters';

  @override
  String get dashSearchInvoiceHint => 'Search by invoice number or customer…';

  @override
  String get dashChooseCustomer => 'Choose customer';

  @override
  String get dashCashCustomer => 'Cash customer';

  @override
  String get dashAddAtLeastOneItem => 'Add at least one item to the invoice.';

  @override
  String dashInvoiceCreated(String number) {
    return 'Invoice $number created';
  }

  @override
  String dashCouldNotSaveInvoice(Object error) {
    return 'Could not save the invoice: $error';
  }

  @override
  String get dashNewSalesInvoiceTitle => 'New sales invoice';

  @override
  String get dashNewSalesInvoiceSubtitle =>
      'Create an official invoice for wholesalers or businesses.';

  @override
  String get dashBack => 'Back';

  @override
  String get dashInvoiceDateLabel => 'Invoice date *';

  @override
  String get dashDueDateLabel => 'Due date';

  @override
  String get dashSelectDate => 'Select a date';

  @override
  String get dashInvoiceNumberLabel => 'Invoice number';

  @override
  String get dashAutoGenerated => '# Auto-generated';

  @override
  String get dashInvoiceItems => 'Invoice items';

  @override
  String get dashAddItem => 'Add item';

  @override
  String get dashColItem => 'Item';

  @override
  String get dashColPrice => 'Price';

  @override
  String get dashColQty => 'Quantity';

  @override
  String get dashColTotal => 'Total';

  @override
  String dashVatLabel(String rate) {
    return 'VAT ($rate%)';
  }

  @override
  String get dashAddItems => 'Add items';

  @override
  String get dashClose => 'Close';

  @override
  String get dashSearchByNameOrSku => 'Search by name or SKU…';

  @override
  String get dashNoItemsFound => 'No items found';

  @override
  String dashStockLabel(int count) {
    return 'Stock: $count';
  }

  @override
  String get dashNoItemsAddedYet => 'No items added yet';

  @override
  String get dashNoItemsAddedYetBody =>
      'Start building your invoice by adding items from your inventory.';

  @override
  String get dashNotes => 'Notes';

  @override
  String get dashNotesHint => 'Add any notes or terms for the customer…';

  @override
  String get dashChooseSupplier => 'Choose supplier';

  @override
  String get dashNoSupplier => 'No supplier';

  @override
  String get dashCashSupplier => 'Cash supplier';

  @override
  String dashPurchaseInvoiceCreated(String number) {
    return 'Purchase invoice $number created';
  }

  @override
  String get dashNewPurchaseInvoiceTitle => 'New purchase invoice';

  @override
  String get dashNewPurchaseInvoiceSubtitle =>
      'Create an invoice for items or services received from the supplier.';

  @override
  String get dashSupplierLabel => 'Supplier';

  @override
  String get dashColPurchasePrice => 'Purchase price';

  @override
  String get dashColSalePrice => 'Sales price';

  @override
  String get dashNoItemsAdded =>
      'No items added. Use the search above to add items.';

  @override
  String get dashNoItemsAddedBody =>
      'Use the \"Add item\" button above to add items.';
}
