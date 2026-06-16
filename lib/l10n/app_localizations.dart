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

  /// No description provided for @onbBusinessHeadline.
  ///
  /// In en, this message translates to:
  /// **'Set up your business'**
  String get onbBusinessHeadline;

  /// No description provided for @onbBusinessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create the local company identity used in the sidebar, receipts, sales documents, and reports.'**
  String get onbBusinessSubtitle;

  /// No description provided for @onbBusinessIdentity.
  ///
  /// In en, this message translates to:
  /// **'Business identity'**
  String get onbBusinessIdentity;

  /// No description provided for @onbBusinessIdentityHint.
  ///
  /// In en, this message translates to:
  /// **'This is the name and logo customers will see.'**
  String get onbBusinessIdentityHint;

  /// No description provided for @onbBusinessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get onbBusinessNameLabel;

  /// No description provided for @onbBusinessNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the business name'**
  String get onbBusinessNameRequired;

  /// No description provided for @onbBranchNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get onbBranchNameLabel;

  /// No description provided for @onbBranchNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the branch name'**
  String get onbBranchNameRequired;

  /// No description provided for @onbLogoPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Business logo path'**
  String get onbLogoPathLabel;

  /// No description provided for @onbLogoPathOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional. Use a PNG or JPG path on this workstation.'**
  String get onbLogoPathOptional;

  /// No description provided for @onbSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get onbSaving;

  /// No description provided for @onbSaveBusiness.
  ///
  /// In en, this message translates to:
  /// **'Save business identity'**
  String get onbSaveBusiness;

  /// No description provided for @onbSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save business profile: {error}'**
  String onbSaveError(Object error);

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
  /// **'At least 8 characters'**
  String get passwordMinChars;

  /// No description provided for @passwordNeedsLetterNumber.
  ///
  /// In en, this message translates to:
  /// **'Use both letters and numbers'**
  String get passwordNeedsLetterNumber;

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

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

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

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @statusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get statusBlocked;

  /// No description provided for @codeRequired.
  ///
  /// In en, this message translates to:
  /// **'Code is required'**
  String get codeRequired;

  /// No description provided for @deleteConfirmName.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String deleteConfirmName(Object name);

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers…'**
  String get searchCustomers;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get newCustomer;

  /// No description provided for @editCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomerTitle;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomersYet;

  /// No description provided for @noCustomersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first customer to track sales and balances.'**
  String get noCustomersSubtitle;

  /// No description provided for @noCustomersMatch.
  ///
  /// In en, this message translates to:
  /// **'No customers match your search.'**
  String get noCustomersMatch;

  /// No description provided for @customerCreated.
  ///
  /// In en, this message translates to:
  /// **'Customer created.'**
  String get customerCreated;

  /// No description provided for @customerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Customer updated.'**
  String get customerUpdated;

  /// No description provided for @customerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Customer deleted.'**
  String get customerDeleted;

  /// No description provided for @couldNotLoadCustomers.
  ///
  /// In en, this message translates to:
  /// **'Could not load customers: {error}'**
  String couldNotLoadCustomers(Object error);

  /// No description provided for @deleteCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete customer'**
  String get deleteCustomerTitle;

  /// No description provided for @colCustomer.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER'**
  String get colCustomer;

  /// No description provided for @colPhone.
  ///
  /// In en, this message translates to:
  /// **'PHONE'**
  String get colPhone;

  /// No description provided for @colBalance.
  ///
  /// In en, this message translates to:
  /// **'BALANCE'**
  String get colBalance;

  /// No description provided for @colStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get colStatus;

  /// No description provided for @sectionCustomerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer details'**
  String get sectionCustomerDetails;

  /// No description provided for @customerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customerNameLabel;

  /// No description provided for @customerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cairo Trading Co.'**
  String get customerNameHint;

  /// No description provided for @customerCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer code'**
  String get customerCodeLabel;

  /// No description provided for @customerCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. CUST-0001'**
  String get customerCodeHint;

  /// No description provided for @createCustomerAction.
  ///
  /// In en, this message translates to:
  /// **'Create customer'**
  String get createCustomerAction;

  /// No description provided for @couldNotSaveCustomer.
  ///
  /// In en, this message translates to:
  /// **'Could not save the customer: {error}'**
  String couldNotSaveCustomer(Object error);

  /// No description provided for @suppliersTitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliersTitle;

  /// No description provided for @searchSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Search suppliers…'**
  String get searchSuppliers;

  /// No description provided for @newSupplier.
  ///
  /// In en, this message translates to:
  /// **'New supplier'**
  String get newSupplier;

  /// No description provided for @editSupplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit supplier'**
  String get editSupplierTitle;

  /// No description provided for @noSuppliersYet.
  ///
  /// In en, this message translates to:
  /// **'No suppliers yet'**
  String get noSuppliersYet;

  /// No description provided for @noSuppliersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first supplier to track purchases and payables.'**
  String get noSuppliersSubtitle;

  /// No description provided for @noSuppliersMatch.
  ///
  /// In en, this message translates to:
  /// **'No suppliers match your search.'**
  String get noSuppliersMatch;

  /// No description provided for @supplierCreated.
  ///
  /// In en, this message translates to:
  /// **'Supplier created.'**
  String get supplierCreated;

  /// No description provided for @supplierUpdated.
  ///
  /// In en, this message translates to:
  /// **'Supplier updated.'**
  String get supplierUpdated;

  /// No description provided for @supplierDeleted.
  ///
  /// In en, this message translates to:
  /// **'Supplier deleted.'**
  String get supplierDeleted;

  /// No description provided for @couldNotLoadSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Could not load suppliers: {error}'**
  String couldNotLoadSuppliers(Object error);

  /// No description provided for @deleteSupplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete supplier'**
  String get deleteSupplierTitle;

  /// No description provided for @colSupplier.
  ///
  /// In en, this message translates to:
  /// **'SUPPLIER'**
  String get colSupplier;

  /// No description provided for @colPayable.
  ///
  /// In en, this message translates to:
  /// **'PAYABLE'**
  String get colPayable;

  /// No description provided for @sectionSupplierDetails.
  ///
  /// In en, this message translates to:
  /// **'Supplier details'**
  String get sectionSupplierDetails;

  /// No description provided for @companyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get companyNameLabel;

  /// No description provided for @companyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Nile Distributors'**
  String get companyNameHint;

  /// No description provided for @companyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required'**
  String get companyNameRequired;

  /// No description provided for @supplierCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier code'**
  String get supplierCodeLabel;

  /// No description provided for @supplierCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. SUP-0001'**
  String get supplierCodeHint;

  /// No description provided for @createSupplierAction.
  ///
  /// In en, this message translates to:
  /// **'Create supplier'**
  String get createSupplierAction;

  /// No description provided for @couldNotSaveSupplier.
  ///
  /// In en, this message translates to:
  /// **'Could not save the supplier: {error}'**
  String couldNotSaveSupplier(Object error);

  /// No description provided for @usersTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersTitle;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users…'**
  String get searchUsers;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New user'**
  String get newUser;

  /// No description provided for @editUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get editUserTitle;

  /// No description provided for @noUsersYet.
  ///
  /// In en, this message translates to:
  /// **'No additional users'**
  String get noUsersYet;

  /// No description provided for @noUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add cashiers and managers to give them their own sign-in.'**
  String get noUsersSubtitle;

  /// No description provided for @noUsersMatch.
  ///
  /// In en, this message translates to:
  /// **'No users match your search.'**
  String get noUsersMatch;

  /// No description provided for @userCreated.
  ///
  /// In en, this message translates to:
  /// **'User created.'**
  String get userCreated;

  /// No description provided for @userUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated.'**
  String get userUpdated;

  /// No description provided for @userDeleted.
  ///
  /// In en, this message translates to:
  /// **'User deleted.'**
  String get userDeleted;

  /// No description provided for @couldNotLoadUsers.
  ///
  /// In en, this message translates to:
  /// **'Could not load users: {error}'**
  String couldNotLoadUsers(Object error);

  /// No description provided for @deleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get deleteUserTitle;

  /// No description provided for @colUser.
  ///
  /// In en, this message translates to:
  /// **'USER'**
  String get colUser;

  /// No description provided for @colRole.
  ///
  /// In en, this message translates to:
  /// **'ROLE'**
  String get colRole;

  /// No description provided for @colLastLogin.
  ///
  /// In en, this message translates to:
  /// **'LAST LOGIN'**
  String get colLastLogin;

  /// No description provided for @youPill.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youPill;

  /// No description provided for @neverLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get neverLoggedIn;

  /// No description provided for @sectionUserDetails.
  ///
  /// In en, this message translates to:
  /// **'User details'**
  String get sectionUserDetails;

  /// No description provided for @userFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sara Hassan'**
  String get userFullNameHint;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @usernameSignInHint.
  ///
  /// In en, this message translates to:
  /// **'used to sign in'**
  String get usernameSignInHint;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get roleCashier;

  /// No description provided for @sectionAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get sectionAccess;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @leaveBlankKeep.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep current'**
  String get leaveBlankKeep;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'A password is required'**
  String get passwordRequired;

  /// No description provided for @useAtLeast6.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get useAtLeast6;

  /// No description provided for @inactiveCannotSignIn.
  ///
  /// In en, this message translates to:
  /// **'Inactive users cannot sign in.'**
  String get inactiveCannotSignIn;

  /// No description provided for @createUserAction.
  ///
  /// In en, this message translates to:
  /// **'Create user'**
  String get createUserAction;

  /// No description provided for @couldNotSaveUser.
  ///
  /// In en, this message translates to:
  /// **'Could not save the user: {error}'**
  String couldNotSaveUser(Object error);

  /// No description provided for @settingsGroupBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get settingsGroupBusiness;

  /// No description provided for @settingsGroupDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents & printing'**
  String get settingsGroupDocuments;

  /// No description provided for @settingsGroupPos.
  ///
  /// In en, this message translates to:
  /// **'Point of sale'**
  String get settingsGroupPos;

  /// No description provided for @settingsGroupProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get settingsGroupProducts;

  /// No description provided for @navCompanyInfo.
  ///
  /// In en, this message translates to:
  /// **'Company information'**
  String get navCompanyInfo;

  /// No description provided for @navAccountingSettings.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get navAccountingSettings;

  /// No description provided for @navRolesPermissions.
  ///
  /// In en, this message translates to:
  /// **'Roles & permissions'**
  String get navRolesPermissions;

  /// No description provided for @navPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get navPaymentMethods;

  /// No description provided for @navCostCategories.
  ///
  /// In en, this message translates to:
  /// **'Cost categories'**
  String get navCostCategories;

  /// No description provided for @navInvoiceSettings.
  ///
  /// In en, this message translates to:
  /// **'Invoice settings'**
  String get navInvoiceSettings;

  /// No description provided for @navPrintSettings.
  ///
  /// In en, this message translates to:
  /// **'Print settings'**
  String get navPrintSettings;

  /// No description provided for @navPrinters.
  ///
  /// In en, this message translates to:
  /// **'Printers'**
  String get navPrinters;

  /// No description provided for @navPosDevices.
  ///
  /// In en, this message translates to:
  /// **'Points of sale'**
  String get navPosDevices;

  /// No description provided for @navItemCategories.
  ///
  /// In en, this message translates to:
  /// **'Item categories'**
  String get navItemCategories;

  /// No description provided for @navItemAttributes.
  ///
  /// In en, this message translates to:
  /// **'Item attributes'**
  String get navItemAttributes;

  /// No description provided for @navUnits.
  ///
  /// In en, this message translates to:
  /// **'Units of measure'**
  String get navUnits;

  /// No description provided for @navTaxSettings.
  ///
  /// In en, this message translates to:
  /// **'Tax settings'**
  String get navTaxSettings;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This settings section will be available soon.'**
  String get comingSoonBody;

  /// No description provided for @catSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize your products into categories.'**
  String get catSubtitle;

  /// No description provided for @catAdd.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get catAdd;

  /// No description provided for @catEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get catEditTitle;

  /// No description provided for @catSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search categories…'**
  String get catSearchHint;

  /// No description provided for @catColName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get catColName;

  /// No description provided for @catColProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get catColProducts;

  /// No description provided for @catProductCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No products} =1{1 product} other{{count} products}}'**
  String catProductCount(int count);

  /// No description provided for @catNameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get catNameEn;

  /// No description provided for @catNameAr.
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get catNameAr;

  /// No description provided for @catNameHintEn.
  ///
  /// In en, this message translates to:
  /// **'e.g. Beverages'**
  String get catNameHintEn;

  /// No description provided for @catNameHintAr.
  ///
  /// In en, this message translates to:
  /// **'مثال: مشروبات'**
  String get catNameHintAr;

  /// No description provided for @catNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name in English or Arabic.'**
  String get catNameRequired;

  /// No description provided for @catEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Add your first one.'**
  String get catEmpty;

  /// No description provided for @catCreated.
  ///
  /// In en, this message translates to:
  /// **'Category created.'**
  String get catCreated;

  /// No description provided for @catUpdated.
  ///
  /// In en, this message translates to:
  /// **'Category updated.'**
  String get catUpdated;

  /// No description provided for @catDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted.'**
  String get catDeleted;

  /// No description provided for @catDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get catDeleteTitle;

  /// No description provided for @catDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the category \"{name}\"?'**
  String catDeleteConfirm(Object name);

  /// No description provided for @unitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Define the units products are sold and stocked in.'**
  String get unitSubtitle;

  /// No description provided for @unitAdd.
  ///
  /// In en, this message translates to:
  /// **'Add unit'**
  String get unitAdd;

  /// No description provided for @unitEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit unit'**
  String get unitEditTitle;

  /// No description provided for @unitColShortCode.
  ///
  /// In en, this message translates to:
  /// **'Short code'**
  String get unitColShortCode;

  /// No description provided for @unitColDecimals.
  ///
  /// In en, this message translates to:
  /// **'Quantities'**
  String get unitColDecimals;

  /// No description provided for @unitColDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get unitColDefault;

  /// No description provided for @unitNameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get unitNameEn;

  /// No description provided for @unitNameAr.
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get unitNameAr;

  /// No description provided for @unitNameHintEn.
  ///
  /// In en, this message translates to:
  /// **'e.g. Piece, Box, Kilogram'**
  String get unitNameHintEn;

  /// No description provided for @unitNameHintAr.
  ///
  /// In en, this message translates to:
  /// **'مثال: قطعة، صندوق، كيلوجرام'**
  String get unitNameHintAr;

  /// No description provided for @unitShortCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Short code'**
  String get unitShortCodeLabel;

  /// No description provided for @unitShortCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. kg, pcs, box'**
  String get unitShortCodeHint;

  /// No description provided for @unitDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get unitDescriptionLabel;

  /// No description provided for @unitAllowDecimalLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantities'**
  String get unitAllowDecimalLabel;

  /// No description provided for @unitIntegerOnly.
  ///
  /// In en, this message translates to:
  /// **'Whole (1, 2, 3)'**
  String get unitIntegerOnly;

  /// No description provided for @unitDecimalAllowed.
  ///
  /// In en, this message translates to:
  /// **'Decimal (1.5, 2.3)'**
  String get unitDecimalAllowed;

  /// No description provided for @unitNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name in English or Arabic.'**
  String get unitNameRequired;

  /// No description provided for @unitEmpty.
  ///
  /// In en, this message translates to:
  /// **'No units yet. Add your first one.'**
  String get unitEmpty;

  /// No description provided for @unitCreated.
  ///
  /// In en, this message translates to:
  /// **'Unit created.'**
  String get unitCreated;

  /// No description provided for @unitUpdated.
  ///
  /// In en, this message translates to:
  /// **'Unit updated.'**
  String get unitUpdated;

  /// No description provided for @unitDeleted.
  ///
  /// In en, this message translates to:
  /// **'Unit deleted.'**
  String get unitDeleted;

  /// No description provided for @unitSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get unitSetDefault;

  /// No description provided for @unitDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get unitDefaultBadge;

  /// No description provided for @unitDefaultSet.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is now the default unit.'**
  String unitDefaultSet(Object name);

  /// No description provided for @unitDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete unit'**
  String get unitDeleteTitle;

  /// No description provided for @unitDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the unit \"{name}\"?'**
  String unitDeleteConfirm(Object name);

  /// No description provided for @catalogLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the list: {error}'**
  String catalogLoadError(Object error);

  /// No description provided for @catalogSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String catalogSaveError(Object error);

  /// No description provided for @rolesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage roles and their permissions'**
  String get rolesSubtitle;

  /// No description provided for @addRole.
  ///
  /// In en, this message translates to:
  /// **'Add role'**
  String get addRole;

  /// No description provided for @permissionsAction.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsAction;

  /// No description provided for @membersLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No members} =1{1 member} other{{count} members}}'**
  String membersLabel(int count);

  /// No description provided for @roleDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete role'**
  String get roleDeleteTitle;

  /// No description provided for @roleDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the role \"{name}\"?'**
  String roleDeleteConfirm(Object name);

  /// No description provided for @roleCreated.
  ///
  /// In en, this message translates to:
  /// **'Role created.'**
  String get roleCreated;

  /// No description provided for @roleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role updated.'**
  String get roleUpdated;

  /// No description provided for @roleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Role deleted.'**
  String get roleDeleted;

  /// No description provided for @couldNotLoadRoles.
  ///
  /// In en, this message translates to:
  /// **'Could not load roles: {error}'**
  String couldNotLoadRoles(Object error);

  /// No description provided for @couldNotSaveRole.
  ///
  /// In en, this message translates to:
  /// **'Could not save the role: {error}'**
  String couldNotSaveRole(Object error);

  /// No description provided for @permissionsForRole.
  ///
  /// In en, this message translates to:
  /// **'Permissions — {name}'**
  String permissionsForRole(Object name);

  /// No description provided for @newRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'New role'**
  String get newRoleTitle;

  /// No description provided for @permissionsDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the actions allowed for this role'**
  String get permissionsDialogSubtitle;

  /// No description provided for @roleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Role name'**
  String get roleNameLabel;

  /// No description provided for @roleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cashier'**
  String get roleNameHint;

  /// No description provided for @roleNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Role name is required'**
  String get roleNameRequired;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionHint;

  /// No description provided for @savePermissions.
  ///
  /// In en, this message translates to:
  /// **'Save permissions'**
  String get savePermissions;

  /// No description provided for @actionsCount.
  ///
  /// In en, this message translates to:
  /// **'{granted} / {total} actions'**
  String actionsCount(int granted, int total);

  /// No description provided for @modulesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 module} other{{count} modules}}'**
  String modulesCount(int count);

  /// No description provided for @companyInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reviewed from Operix Company Settings.'**
  String get companyInfoSubtitle;

  /// No description provided for @businessLogoLabel.
  ///
  /// In en, this message translates to:
  /// **'Business logo'**
  String get businessLogoLabel;

  /// No description provided for @logoUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Click to change the logo. Accepted formats: JPG, PNG, GIF (max 2 MB)'**
  String get logoUploadHint;

  /// No description provided for @companySettingsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get companySettingsNameLabel;

  /// No description provided for @companySettingsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get companySettingsNameRequired;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @phoneFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneFieldLabel;

  /// No description provided for @commercialRegLabel.
  ///
  /// In en, this message translates to:
  /// **'Commercial registration number'**
  String get commercialRegLabel;

  /// No description provided for @commercialRegHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the commercial registration number'**
  String get commercialRegHint;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @regionLabel.
  ///
  /// In en, this message translates to:
  /// **'Region / Governorate'**
  String get regionLabel;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @postalCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get postalCodeLabel;

  /// No description provided for @postalCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the postal code'**
  String get postalCodeHint;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @companySettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Company information saved'**
  String get companySettingsSaved;

  /// No description provided for @logoPathDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Logo image path'**
  String get logoPathDialogTitle;

  /// No description provided for @accessDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get accessDeniedTitle;

  /// No description provided for @accessDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to view this section.'**
  String get accessDeniedBody;

  /// No description provided for @cannotAssignAdminRole.
  ///
  /// In en, this message translates to:
  /// **'Only an administrator can assign a system role.'**
  String get cannotAssignAdminRole;

  /// No description provided for @navUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get navUsers;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @clientAccounts.
  ///
  /// In en, this message translates to:
  /// **'Client accounts'**
  String get clientAccounts;

  /// No description provided for @supplierAccounts.
  ///
  /// In en, this message translates to:
  /// **'Supplier accounts'**
  String get supplierAccounts;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products…'**
  String get searchProducts;

  /// No description provided for @stockLog.
  ///
  /// In en, this message translates to:
  /// **'Stock log'**
  String get stockLog;

  /// No description provided for @stockAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Stock adjusted.'**
  String get stockAdjusted;

  /// No description provided for @couldNotLoadProducts.
  ///
  /// In en, this message translates to:
  /// **'Could not load products: {error}'**
  String couldNotLoadProducts(Object error);

  /// No description provided for @adjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get adjustStock;

  /// No description provided for @noProductsMatch.
  ///
  /// In en, this message translates to:
  /// **'No products match your search.'**
  String get noProductsMatch;

  /// No description provided for @createFirstProductHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first product to start selling.'**
  String get createFirstProductHint;

  /// No description provided for @settingsDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get settingsDatabase;

  /// No description provided for @settingsDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local PostgreSQL connection used by this workstation.'**
  String get settingsDatabaseSubtitle;

  /// No description provided for @settingsSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get settingsSource;

  /// No description provided for @settingsDemoData.
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get settingsDemoData;

  /// No description provided for @settingsTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get settingsTarget;

  /// No description provided for @settingsConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get settingsConfigured;

  /// No description provided for @settingsYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get settingsYes;

  /// No description provided for @settingsNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get settingsNo;

  /// No description provided for @settingsSslMode.
  ///
  /// In en, this message translates to:
  /// **'SSL mode'**
  String get settingsSslMode;

  /// No description provided for @settingsLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get settingsLicense;

  /// No description provided for @settingsLicenseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline workstation activation.'**
  String get settingsLicenseSubtitle;

  /// No description provided for @settingsInstallationId.
  ///
  /// In en, this message translates to:
  /// **'Installation id'**
  String get settingsInstallationId;

  /// No description provided for @settingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get settingsLoading;

  /// No description provided for @settingsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get settingsStatus;

  /// No description provided for @settingsLicensedBusiness.
  ///
  /// In en, this message translates to:
  /// **'Licensed business'**
  String get settingsLicensedBusiness;

  /// No description provided for @settingsExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get settingsExpires;

  /// No description provided for @currencyEgp.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get currencyEgp;

  /// No description provided for @dashOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Business performance overview'**
  String get dashOverviewTitle;

  /// No description provided for @dashQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashQuickActions;

  /// No description provided for @dashVsPreviousPeriod.
  ///
  /// In en, this message translates to:
  /// **'vs previous period'**
  String get dashVsPreviousPeriod;

  /// No description provided for @dashPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashPeriodToday;

  /// No description provided for @dashPeriodLast7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get dashPeriodLast7;

  /// No description provided for @dashPeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get dashPeriodThisMonth;

  /// No description provided for @dashPeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get dashPeriodCustom;

  /// No description provided for @dashFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get dashFrom;

  /// No description provided for @dashTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get dashTo;

  /// No description provided for @dashPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get dashPickDate;

  /// No description provided for @dashContactSales.
  ///
  /// In en, this message translates to:
  /// **'Contact sales'**
  String get dashContactSales;

  /// No description provided for @dashContactSalesBody.
  ///
  /// In en, this message translates to:
  /// **'To renew your license or upgrade your plan, contact the Operix sales team:\n\nsales@operixhq.com'**
  String get dashContactSalesBody;

  /// No description provided for @dashCopyEmail.
  ///
  /// In en, this message translates to:
  /// **'Copy email'**
  String get dashCopyEmail;

  /// No description provided for @dashSalesEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'Sales email copied'**
  String get dashSalesEmailCopied;

  /// No description provided for @dashOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dashOk;

  /// No description provided for @dashLicenseExpiryAlert.
  ///
  /// In en, this message translates to:
  /// **'License expiry alert'**
  String get dashLicenseExpiryAlert;

  /// No description provided for @dashLicenseExpiryHeadline.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{{business}\'s license expires today.} =1{1 day left on {business}\'s license.} =2{2 days left on {business}\'s license.} other{{days} days left on {business}\'s license.}}'**
  String dashLicenseExpiryHeadline(int days, String business);

  /// No description provided for @dashLicenseExpiryFooter.
  ///
  /// In en, this message translates to:
  /// **'Expiry date: {date} — renew the license to avoid service interruption.'**
  String dashLicenseExpiryFooter(String date);

  /// No description provided for @dashManageLicense.
  ///
  /// In en, this message translates to:
  /// **'Manage license'**
  String get dashManageLicense;

  /// No description provided for @dashActionNewSalesInvoice.
  ///
  /// In en, this message translates to:
  /// **'New sales invoice'**
  String get dashActionNewSalesInvoice;

  /// No description provided for @dashActionNewExpense.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get dashActionNewExpense;

  /// No description provided for @dashActionPurchaseInvoice.
  ///
  /// In en, this message translates to:
  /// **'Purchase invoice'**
  String get dashActionPurchaseInvoice;

  /// No description provided for @dashActionSalesReturns.
  ///
  /// In en, this message translates to:
  /// **'Sales returns'**
  String get dashActionSalesReturns;

  /// No description provided for @dashKpiRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get dashKpiRevenue;

  /// No description provided for @dashKpiExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get dashKpiExpenses;

  /// No description provided for @dashKpiExpensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cost of goods & expenses'**
  String get dashKpiExpensesSubtitle;

  /// No description provided for @dashKpiNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get dashKpiNetProfit;

  /// No description provided for @dashKpiNetProfitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After costs'**
  String get dashKpiNetProfitSubtitle;

  /// No description provided for @dashKpiCashBalance.
  ///
  /// In en, this message translates to:
  /// **'Cash balance'**
  String get dashKpiCashBalance;

  /// No description provided for @dashKpiCashBalanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All accounts'**
  String get dashKpiCashBalanceSubtitle;

  /// No description provided for @dashSalesTrend.
  ///
  /// In en, this message translates to:
  /// **'Sales trend'**
  String get dashSalesTrend;

  /// No description provided for @dashSalesTrendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Net sales over the selected period'**
  String get dashSalesTrendSubtitle;

  /// No description provided for @dashRevenueDistribution.
  ///
  /// In en, this message translates to:
  /// **'Revenue distribution'**
  String get dashRevenueDistribution;

  /// No description provided for @dashRevenueDistributionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How revenue is distributed'**
  String get dashRevenueDistributionSubtitle;

  /// No description provided for @dashCogs.
  ///
  /// In en, this message translates to:
  /// **'Cost of goods'**
  String get dashCogs;

  /// No description provided for @dashNoSalesData.
  ///
  /// In en, this message translates to:
  /// **'No sales data for this period'**
  String get dashNoSalesData;

  /// No description provided for @dashTotalProfit.
  ///
  /// In en, this message translates to:
  /// **'Total profit'**
  String get dashTotalProfit;

  /// No description provided for @dashMarginLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin {value}%'**
  String dashMarginLabel(String value);

  /// No description provided for @dashGrossMargin.
  ///
  /// In en, this message translates to:
  /// **'Gross profit margin'**
  String get dashGrossMargin;

  /// No description provided for @dashInventoryValue.
  ///
  /// In en, this message translates to:
  /// **'Inventory value'**
  String get dashInventoryValue;

  /// No description provided for @dashAtCost.
  ///
  /// In en, this message translates to:
  /// **'At cost'**
  String get dashAtCost;

  /// No description provided for @dashOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get dashOrders;

  /// No description provided for @dashAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average: {value}'**
  String dashAverageLabel(String value);

  /// No description provided for @dashNewCustomers.
  ///
  /// In en, this message translates to:
  /// **'New customers'**
  String get dashNewCustomers;

  /// No description provided for @dashThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get dashThisPeriod;

  /// No description provided for @dashSupplierDue.
  ///
  /// In en, this message translates to:
  /// **'Supplier payables'**
  String get dashSupplierDue;

  /// No description provided for @dashTotalDueAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount due'**
  String get dashTotalDueAmount;

  /// No description provided for @dashTopProducts.
  ///
  /// In en, this message translates to:
  /// **'Top selling products'**
  String get dashTopProducts;

  /// No description provided for @dashPiecesLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} pcs'**
  String dashPiecesLabel(int count);

  /// No description provided for @dashInventoryHealthy.
  ///
  /// In en, this message translates to:
  /// **'All items are well stocked'**
  String get dashInventoryHealthy;

  /// No description provided for @dashInventoryLowCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item reached reorder level} other{{count} items reached reorder level}}'**
  String dashInventoryLowCount(int count);

  /// No description provided for @dashInventoryHealthyBody.
  ///
  /// In en, this message translates to:
  /// **'Inventory is in good shape across all stock-tracked items'**
  String get dashInventoryHealthyBody;

  /// No description provided for @dashInventoryLowBody.
  ///
  /// In en, this message translates to:
  /// **'Review the inventory screen to reorder low-stock items'**
  String get dashInventoryLowBody;

  /// No description provided for @dashSalesInvoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales invoices'**
  String get dashSalesInvoicesTitle;

  /// No description provided for @dashCreateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create invoice'**
  String get dashCreateInvoice;

  /// No description provided for @dashFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get dashFilters;

  /// No description provided for @dashSearchInvoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Search by invoice number or customer…'**
  String get dashSearchInvoiceHint;

  /// No description provided for @dashChooseCustomer.
  ///
  /// In en, this message translates to:
  /// **'Choose customer'**
  String get dashChooseCustomer;

  /// No description provided for @dashCashCustomer.
  ///
  /// In en, this message translates to:
  /// **'Cash customer'**
  String get dashCashCustomer;

  /// No description provided for @dashAddAtLeastOneItem.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item to the invoice.'**
  String get dashAddAtLeastOneItem;

  /// No description provided for @dashInvoiceCreated.
  ///
  /// In en, this message translates to:
  /// **'Invoice {number} created'**
  String dashInvoiceCreated(String number);

  /// No description provided for @dashCouldNotSaveInvoice.
  ///
  /// In en, this message translates to:
  /// **'Could not save the invoice: {error}'**
  String dashCouldNotSaveInvoice(Object error);

  /// No description provided for @dashNewSalesInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'New sales invoice'**
  String get dashNewSalesInvoiceTitle;

  /// No description provided for @dashNewSalesInvoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an official invoice for wholesalers or businesses.'**
  String get dashNewSalesInvoiceSubtitle;

  /// No description provided for @dashBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get dashBack;

  /// No description provided for @dashInvoiceDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice date *'**
  String get dashInvoiceDateLabel;

  /// No description provided for @dashDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dashDueDateLabel;

  /// No description provided for @dashSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get dashSelectDate;

  /// No description provided for @dashInvoiceNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice number'**
  String get dashInvoiceNumberLabel;

  /// No description provided for @dashAutoGenerated.
  ///
  /// In en, this message translates to:
  /// **'# Auto-generated'**
  String get dashAutoGenerated;

  /// No description provided for @dashInvoiceItems.
  ///
  /// In en, this message translates to:
  /// **'Invoice items'**
  String get dashInvoiceItems;

  /// No description provided for @dashAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get dashAddItem;

  /// No description provided for @dashColItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get dashColItem;

  /// No description provided for @dashColPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get dashColPrice;

  /// No description provided for @dashColQty.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get dashColQty;

  /// No description provided for @dashColTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get dashColTotal;

  /// No description provided for @dashVatLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT ({rate}%)'**
  String dashVatLabel(String rate);

  /// No description provided for @dashAddItems.
  ///
  /// In en, this message translates to:
  /// **'Add items'**
  String get dashAddItems;

  /// No description provided for @dashClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dashClose;

  /// No description provided for @dashSearchByNameOrSku.
  ///
  /// In en, this message translates to:
  /// **'Search by name or SKU…'**
  String get dashSearchByNameOrSku;

  /// No description provided for @dashNoItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get dashNoItemsFound;

  /// No description provided for @dashStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String dashStockLabel(int count);

  /// No description provided for @dashNoItemsAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No items added yet'**
  String get dashNoItemsAddedYet;

  /// No description provided for @dashNoItemsAddedYetBody.
  ///
  /// In en, this message translates to:
  /// **'Start building your invoice by adding items from your inventory.'**
  String get dashNoItemsAddedYetBody;

  /// No description provided for @dashNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get dashNotes;

  /// No description provided for @dashNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add any notes or terms for the customer…'**
  String get dashNotesHint;

  /// No description provided for @dashChooseSupplier.
  ///
  /// In en, this message translates to:
  /// **'Choose supplier'**
  String get dashChooseSupplier;

  /// No description provided for @dashNoSupplier.
  ///
  /// In en, this message translates to:
  /// **'No supplier'**
  String get dashNoSupplier;

  /// No description provided for @dashCashSupplier.
  ///
  /// In en, this message translates to:
  /// **'Cash supplier'**
  String get dashCashSupplier;

  /// No description provided for @dashPurchaseInvoiceCreated.
  ///
  /// In en, this message translates to:
  /// **'Purchase invoice {number} created'**
  String dashPurchaseInvoiceCreated(String number);

  /// No description provided for @dashNewPurchaseInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'New purchase invoice'**
  String get dashNewPurchaseInvoiceTitle;

  /// No description provided for @dashNewPurchaseInvoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an invoice for items or services received from the supplier.'**
  String get dashNewPurchaseInvoiceSubtitle;

  /// No description provided for @dashSupplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get dashSupplierLabel;

  /// No description provided for @dashColPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase price'**
  String get dashColPurchasePrice;

  /// No description provided for @dashColSalePrice.
  ///
  /// In en, this message translates to:
  /// **'Sales price'**
  String get dashColSalePrice;

  /// No description provided for @dashNoItemsAdded.
  ///
  /// In en, this message translates to:
  /// **'No items added. Use the search above to add items.'**
  String get dashNoItemsAdded;

  /// No description provided for @dashNoItemsAddedBody.
  ///
  /// In en, this message translates to:
  /// **'Use the \"Add item\" button above to add items.'**
  String get dashNoItemsAddedBody;
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
