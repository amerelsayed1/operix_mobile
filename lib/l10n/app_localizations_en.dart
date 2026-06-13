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
  String get passwordMinChars => 'At least 6 characters';

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
}
