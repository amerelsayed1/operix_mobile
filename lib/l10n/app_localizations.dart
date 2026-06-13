import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Operix Desktop'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @enterFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Enter full screen'**
  String get enterFullScreen;

  /// No description provided for @exitFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get exitFullScreen;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @brandLocalFirst.
  ///
  /// In en, this message translates to:
  /// **'Local-first • PostgreSQL'**
  String get brandLocalFirst;

  /// No description provided for @loginHeadline.
  ///
  /// In en, this message translates to:
  /// **'Operix Point of Sale'**
  String get loginHeadline;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Run shifts, sell fast, and keep inventory and cash in sync — all on your local business database.'**
  String get loginTagline;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your local Operix workstation account.'**
  String get signInSubtitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterUsername;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpectedError(Object error);

  /// No description provided for @setupHeadline.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Operix'**
  String get setupHeadline;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create the administrator account for this workstation. You can add more users later.'**
  String get setupSubtitle;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up administrator'**
  String get setupTitle;

  /// No description provided for @setupHint.
  ///
  /// In en, this message translates to:
  /// **'This is the first account on a fresh database.'**
  String get setupHint;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @createAccountContinue.
  ///
  /// In en, this message translates to:
  /// **'Create account & continue'**
  String get createAccountContinue;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creating;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter a full name'**
  String get enterFullName;

  /// No description provided for @chooseUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get chooseUsername;

  /// No description provided for @usernameMinChars.
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters'**
  String get usernameMinChars;

  /// No description provided for @choosePassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a password'**
  String get choosePassword;

  /// No description provided for @passwordMinChars.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordMinChars;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @cannotReachDatabase.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the database'**
  String get cannotReachDatabase;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navPos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get navPos;

  /// No description provided for @navSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get navSales;

  /// No description provided for @navPurchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get navPurchases;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get navClients;

  /// No description provided for @navSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get navSuppliers;

  /// No description provided for @navAccounting.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get navAccounting;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @titlePointOfSale.
  ///
  /// In en, this message translates to:
  /// **'Point of Sale'**
  String get titlePointOfSale;

  /// No description provided for @desktopWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Desktop workspace'**
  String get desktopWorkspace;

  /// No description provided for @businessFinanceDesktop.
  ///
  /// In en, this message translates to:
  /// **'Business Finance Desktop'**
  String get businessFinanceDesktop;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @postgresql.
  ///
  /// In en, this message translates to:
  /// **'PostgreSQL'**
  String get postgresql;

  /// No description provided for @demoData.
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get demoData;

  /// No description provided for @openCashierShift.
  ///
  /// In en, this message translates to:
  /// **'Open a cashier shift'**
  String get openCashierShift;

  /// No description provided for @openShiftSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a shift to begin selling. Cash will be reconciled against the opening float when you close it.'**
  String get openShiftSubtitle;

  /// No description provided for @cashierLabel.
  ///
  /// In en, this message translates to:
  /// **'Cashier: {name}'**
  String cashierLabel(Object name);

  /// No description provided for @openingCashFloat.
  ///
  /// In en, this message translates to:
  /// **'Opening cash float'**
  String get openingCashFloat;

  /// No description provided for @openShift.
  ///
  /// In en, this message translates to:
  /// **'Open shift'**
  String get openShift;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get opening;

  /// No description provided for @couldNotOpenShift.
  ///
  /// In en, this message translates to:
  /// **'Could not open shift: {error}'**
  String couldNotOpenShift(Object error);

  /// No description provided for @shiftLabel.
  ///
  /// In en, this message translates to:
  /// **'Shift {number}'**
  String shiftLabel(Object number);

  /// No description provided for @openedAt.
  ///
  /// In en, this message translates to:
  /// **'Opened {time}'**
  String openedAt(Object time);

  /// No description provided for @terminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminal;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @closeShift.
  ///
  /// In en, this message translates to:
  /// **'Close shift'**
  String get closeShift;

  /// No description provided for @closeShiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Close shift {number}'**
  String closeShiftTitle(Object number);

  /// No description provided for @openingFloat.
  ///
  /// In en, this message translates to:
  /// **'Opening float'**
  String get openingFloat;

  /// No description provided for @countedCashInDrawer.
  ///
  /// In en, this message translates to:
  /// **'Counted cash in drawer'**
  String get countedCashInDrawer;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @enterCountedCash.
  ///
  /// In en, this message translates to:
  /// **'Enter the counted cash amount.'**
  String get enterCountedCash;

  /// No description provided for @couldNotCloseShift.
  ///
  /// In en, this message translates to:
  /// **'Could not close shift: {error}'**
  String couldNotCloseShift(Object error);

  /// No description provided for @shiftClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'Shift {number} closed'**
  String shiftClosedTitle(Object number);

  /// No description provided for @expectedCash.
  ///
  /// In en, this message translates to:
  /// **'Expected cash'**
  String get expectedCash;

  /// No description provided for @countedCash.
  ///
  /// In en, this message translates to:
  /// **'Counted cash'**
  String get countedCash;

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balanced;

  /// No description provided for @overBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String overBy(Object amount);

  /// No description provided for @shortBy.
  ///
  /// In en, this message translates to:
  /// **'Short by {amount}'**
  String shortBy(Object amount);

  /// No description provided for @currentSale.
  ///
  /// In en, this message translates to:
  /// **'Current sale'**
  String get currentSale;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s)'**
  String itemCount(Object count);

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get clearCart;

  /// No description provided for @customerOptional.
  ///
  /// In en, this message translates to:
  /// **'Customer (optional)'**
  String get customerOptional;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartEmpty;

  /// No description provided for @tapProductsToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap products to add them'**
  String get tapProductsToAdd;

  /// No description provided for @searchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search products by name or SKU…'**
  String get searchProductsHint;

  /// No description provided for @noProductsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No products match your search.'**
  String get noProductsMatchSearch;

  /// No description provided for @outBadge.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outBadge;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @chargeAmount.
  ///
  /// In en, this message translates to:
  /// **'Charge {amount}'**
  String chargeAmount(Object amount);

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @addAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addAction;

  /// No description provided for @orderDiscount.
  ///
  /// In en, this message translates to:
  /// **'Order discount'**
  String get orderDiscount;

  /// No description provided for @discountAmount.
  ///
  /// In en, this message translates to:
  /// **'Discount amount'**
  String get discountAmount;

  /// No description provided for @noMoreStock.
  ///
  /// In en, this message translates to:
  /// **'No more \"{name}\" in stock.'**
  String noMoreStock(Object name);

  /// No description provided for @checkoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Checkout failed: {error}'**
  String checkoutFailed(Object error);

  /// No description provided for @takePayment.
  ///
  /// In en, this message translates to:
  /// **'Take payment'**
  String get takePayment;

  /// No description provided for @totalDue.
  ///
  /// In en, this message translates to:
  /// **'Total due'**
  String get totalDue;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @methodNameHint.
  ///
  /// In en, this message translates to:
  /// **'Method name (e.g. Wallet, Voucher)'**
  String get methodNameHint;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @referenceOptional.
  ///
  /// In en, this message translates to:
  /// **'Reference (optional)'**
  String get referenceOptional;

  /// No description provided for @addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add payment'**
  String get addPayment;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get confirmPayment;

  /// No description provided for @confirmChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm • change {amount}'**
  String confirmChange(Object amount);

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get enterValidAmount;

  /// No description provided for @cannotExceedRemaining.
  ///
  /// In en, this message translates to:
  /// **'{method} cannot exceed the remaining {amount}.'**
  String cannotExceedRemaining(Object method, Object amount);

  /// No description provided for @nameCustomMethod.
  ///
  /// In en, this message translates to:
  /// **'Name the custom payment method.'**
  String get nameCustomMethod;

  /// No description provided for @salesReceipt.
  ///
  /// In en, this message translates to:
  /// **'Sales Receipt'**
  String get salesReceipt;

  /// No description provided for @receiptLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @cashierShort.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get cashierShort;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerLabel;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your purchase!'**
  String get thankYou;

  /// No description provided for @salesHistory.
  ///
  /// In en, this message translates to:
  /// **'Sales history'**
  String get salesHistory;

  /// No description provided for @thisShiftOnly.
  ///
  /// In en, this message translates to:
  /// **'This shift only'**
  String get thisShiftOnly;

  /// No description provided for @noSalesYet.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get noSalesYet;

  /// No description provided for @couldNotLoadOrders.
  ///
  /// In en, this message translates to:
  /// **'Could not load orders: {error}'**
  String couldNotLoadOrders(Object error);

  /// No description provided for @noPayment.
  ///
  /// In en, this message translates to:
  /// **'No payment'**
  String get noPayment;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @searchProductsShort.
  ///
  /// In en, this message translates to:
  /// **'Search products…'**
  String get searchProductsShort;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get newProduct;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYet;

  /// No description provided for @createFirstProduct.
  ///
  /// In en, this message translates to:
  /// **'Create your first product to start selling.'**
  String get createFirstProduct;

  /// No description provided for @productCreated.
  ///
  /// In en, this message translates to:
  /// **'Product created.'**
  String get productCreated;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated.'**
  String get productUpdated;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted.'**
  String get productDeleted;

  /// No description provided for @couldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {error}'**
  String couldNotDelete(Object error);

  /// No description provided for @deleteProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete product'**
  String get deleteProductTitle;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String deleteProductConfirm(Object name);

  /// No description provided for @colProduct.
  ///
  /// In en, this message translates to:
  /// **'PRODUCT'**
  String get colProduct;

  /// No description provided for @colCategory.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get colCategory;

  /// No description provided for @colStock.
  ///
  /// In en, this message translates to:
  /// **'STOCK'**
  String get colStock;

  /// No description provided for @colPrice.
  ///
  /// In en, this message translates to:
  /// **'PRICE'**
  String get colPrice;

  /// No description provided for @tagInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get tagInactive;

  /// No description provided for @tagLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get tagLow;

  /// No description provided for @newProductTitle.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get newProductTitle;

  /// No description provided for @editProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProductTitle;

  /// No description provided for @sectionProductDetails.
  ///
  /// In en, this message translates to:
  /// **'Product details'**
  String get sectionProductDetails;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product name *'**
  String get productNameLabel;

  /// No description provided for @productNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Wireless Keyboard'**
  String get productNameHint;

  /// No description provided for @skuLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU *'**
  String get skuLabel;

  /// No description provided for @skuHint.
  ///
  /// In en, this message translates to:
  /// **'Stock keeping unit'**
  String get skuHint;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Electronics'**
  String get categoryHint;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @sectionPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get sectionPricing;

  /// No description provided for @costPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost price'**
  String get costPriceLabel;

  /// No description provided for @sellingPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Selling price *'**
  String get sellingPriceLabel;

  /// No description provided for @sectionInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get sectionInventory;

  /// No description provided for @stockOnHand.
  ///
  /// In en, this message translates to:
  /// **'Stock on hand'**
  String get stockOnHand;

  /// No description provided for @openingStock.
  ///
  /// In en, this message translates to:
  /// **'Opening stock'**
  String get openingStock;

  /// No description provided for @minimumStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Minimum stock alert'**
  String get minimumStockAlert;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @activeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inactive products are hidden from the POS'**
  String get activeSubtitle;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @createProductAction.
  ///
  /// In en, this message translates to:
  /// **'Create product'**
  String get createProductAction;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @skuRequired.
  ///
  /// In en, this message translates to:
  /// **'SKU is required'**
  String get skuRequired;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get enterValidPrice;

  /// No description provided for @cannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Cannot be negative'**
  String get cannotBeNegative;

  /// No description provided for @couldNotSaveProduct.
  ///
  /// In en, this message translates to:
  /// **'Could not save product: {error}'**
  String couldNotSaveProduct(Object error);

  /// No description provided for @pickExisting.
  ///
  /// In en, this message translates to:
  /// **'Pick existing'**
  String get pickExisting;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
