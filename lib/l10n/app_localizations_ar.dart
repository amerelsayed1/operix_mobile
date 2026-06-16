// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'أوبريكس ديسكتوب';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get onbBusinessHeadline => 'إعداد نشاطك التجاري';

  @override
  String get onbBusinessSubtitle =>
      'أنشئ هوية الشركة المحلية المستخدمة في الشريط الجانبي والإيصالات ومستندات المبيعات والتقارير.';

  @override
  String get onbBusinessIdentity => 'هوية النشاط التجاري';

  @override
  String get onbBusinessIdentityHint =>
      'هذا هو الاسم والشعار اللذان سيراهما العملاء.';

  @override
  String get onbBusinessNameLabel => 'اسم النشاط التجاري';

  @override
  String get onbBusinessNameRequired => 'أدخل اسم النشاط التجاري';

  @override
  String get onbBranchNameLabel => 'اسم الفرع';

  @override
  String get onbBranchNameRequired => 'أدخل اسم الفرع';

  @override
  String get onbLogoPathLabel => 'مسار شعار النشاط';

  @override
  String get onbLogoPathOptional =>
      'اختياري. استخدم مسار صورة PNG أو JPG على هذا الجهاز.';

  @override
  String get onbSaving => 'جارٍ الحفظ…';

  @override
  String get onbSaveBusiness => 'حفظ هوية النشاط';

  @override
  String onbSaveError(Object error) {
    return 'تعذّر حفظ ملف النشاط التجاري: $error';
  }

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get done => 'تم';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get refresh => 'تحديث';

  @override
  String get enterFullScreen => 'ملء الشاشة';

  @override
  String get exitFullScreen => 'الخروج من ملء الشاشة';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get apply => 'تطبيق';

  @override
  String get clear => 'مسح';

  @override
  String get optional => 'اختياري';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get brandLocalFirst => 'محلي أولاً • PostgreSQL';

  @override
  String get loginHeadline => 'نقاط بيع أوبريكس';

  @override
  String get loginTagline =>
      'افتح الورديات، بِع بسرعة، وحافظ على تزامن المخزون والنقد — كل ذلك على قاعدة بيانات عملك المحلية.';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signInSubtitle => 'استخدم حساب محطة عمل أوبريكس المحلي.';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get show => 'إظهار';

  @override
  String get hide => 'إخفاء';

  @override
  String get enterUsername => 'أدخل اسم المستخدم';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get signingIn => 'جارٍ تسجيل الدخول…';

  @override
  String unexpectedError(Object error) {
    return 'خطأ غير متوقع: $error';
  }

  @override
  String get setupHeadline => 'مرحبًا بك في أوبريكس';

  @override
  String get setupSubtitle =>
      'أنشئ حساب المسؤول لمحطة العمل هذه. يمكنك إضافة مستخدمين آخرين لاحقًا.';

  @override
  String get setupTitle => 'إعداد المسؤول';

  @override
  String get setupHint => 'هذا أول حساب على قاعدة بيانات جديدة.';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get createAccountContinue => 'إنشاء الحساب والمتابعة';

  @override
  String get creating => 'جارٍ الإنشاء…';

  @override
  String get enterFullName => 'أدخل الاسم الكامل';

  @override
  String get chooseUsername => 'اختر اسم مستخدم';

  @override
  String get usernameMinChars => '3 أحرف على الأقل';

  @override
  String get choosePassword => 'اختر كلمة مرور';

  @override
  String get passwordMinChars => '8 أحرف على الأقل';

  @override
  String get passwordNeedsLetterNumber => 'استخدم أحرفًا وأرقامًا معًا';

  @override
  String get passwordsDontMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get cannotReachDatabase => 'تعذّر الوصول إلى قاعدة البيانات';

  @override
  String get navDashboard => 'لوحة المعلومات';

  @override
  String get navPos => 'نقاط البيع';

  @override
  String get navSales => 'المبيعات';

  @override
  String get navPurchases => 'المشتريات';

  @override
  String get navInventory => 'المخزون';

  @override
  String get navClients => 'العملاء';

  @override
  String get navSuppliers => 'الموردون';

  @override
  String get navReports => 'التقارير';

  @override
  String get navAccounting => 'المحاسبة';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get titlePointOfSale => 'نقاط البيع';

  @override
  String get desktopWorkspace => 'مساحة عمل سطح المكتب';

  @override
  String get businessFinanceDesktop => 'إدارة مالية للأعمال';

  @override
  String get connecting => 'جارٍ الاتصال…';

  @override
  String get postgresql => 'PostgreSQL';

  @override
  String get demoData => 'بيانات تجريبية';

  @override
  String get openCashierShift => 'افتح وردية الكاشير';

  @override
  String get openShiftSubtitle =>
      'ابدأ وردية لبدء البيع. ستتم تسوية النقد مقابل الرصيد الافتتاحي عند إغلاقها.';

  @override
  String cashierLabel(Object name) {
    return 'الكاشير: $name';
  }

  @override
  String get openingCashFloat => 'الرصيد النقدي الافتتاحي';

  @override
  String get openShift => 'فتح الوردية';

  @override
  String get opening => 'جارٍ الفتح…';

  @override
  String couldNotOpenShift(Object error) {
    return 'تعذّر فتح الوردية: $error';
  }

  @override
  String shiftLabel(Object number) {
    return 'وردية $number';
  }

  @override
  String openedAt(Object time) {
    return 'فُتحت $time';
  }

  @override
  String get terminal => 'نقطة البيع';

  @override
  String get history => 'السجل';

  @override
  String get closeShift => 'إغلاق الوردية';

  @override
  String closeShiftTitle(Object number) {
    return 'إغلاق الوردية $number';
  }

  @override
  String get openingFloat => 'الرصيد الافتتاحي';

  @override
  String get countedCashInDrawer => 'النقد المعدود في الدرج';

  @override
  String get notesOptional => 'ملاحظات (اختياري)';

  @override
  String get enterCountedCash => 'أدخل مبلغ النقد المعدود.';

  @override
  String couldNotCloseShift(Object error) {
    return 'تعذّر إغلاق الوردية: $error';
  }

  @override
  String shiftClosedTitle(Object number) {
    return 'أُغلقت الوردية $number';
  }

  @override
  String get expectedCash => 'النقد المتوقع';

  @override
  String get countedCash => 'النقد المعدود';

  @override
  String get balanced => 'متوازن';

  @override
  String overBy(Object amount) {
    return 'زيادة بمقدار $amount';
  }

  @override
  String shortBy(Object amount) {
    return 'عجز بمقدار $amount';
  }

  @override
  String get currentSale => 'البيع الحالي';

  @override
  String itemCount(Object count) {
    return '$count صنف';
  }

  @override
  String get clearCart => 'إفراغ السلة';

  @override
  String get customerOptional => 'العميل (اختياري)';

  @override
  String get cartEmpty => 'السلة فارغة';

  @override
  String get tapProductsToAdd => 'اضغط على المنتجات لإضافتها';

  @override
  String get searchProductsHint => 'ابحث عن المنتجات بالاسم أو الرمز…';

  @override
  String get noProductsMatchSearch => 'لا توجد منتجات مطابقة لبحثك.';

  @override
  String get outBadge => 'نفد';

  @override
  String get all => 'الكل';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get discount => 'الخصم';

  @override
  String get tax => 'الضريبة';

  @override
  String get total => 'الإجمالي';

  @override
  String chargeAmount(Object amount) {
    return 'ادفع $amount';
  }

  @override
  String get saving => 'جارٍ الحفظ…';

  @override
  String get addAction => 'إضافة';

  @override
  String get orderDiscount => 'خصم الطلب';

  @override
  String get discountAmount => 'قيمة الخصم';

  @override
  String noMoreStock(Object name) {
    return 'لا يوجد مزيد من \"$name\" في المخزون.';
  }

  @override
  String checkoutFailed(Object error) {
    return 'فشل الدفع: $error';
  }

  @override
  String get takePayment => 'تحصيل الدفع';

  @override
  String get totalDue => 'الإجمالي المستحق';

  @override
  String get paid => 'المدفوع';

  @override
  String get remaining => 'المتبقي';

  @override
  String get change => 'الباقي';

  @override
  String get cash => 'نقدًا';

  @override
  String get card => 'بطاقة';

  @override
  String get custom => 'مخصص';

  @override
  String get methodNameHint => 'اسم الطريقة (مثل محفظة، قسيمة)';

  @override
  String get amount => 'المبلغ';

  @override
  String get referenceOptional => 'مرجع (اختياري)';

  @override
  String get addPayment => 'إضافة دفعة';

  @override
  String get confirmPayment => 'تأكيد الدفع';

  @override
  String confirmChange(Object amount) {
    return 'تأكيد • الباقي $amount';
  }

  @override
  String get enterValidAmount => 'أدخل مبلغًا صالحًا.';

  @override
  String cannotExceedRemaining(Object method, Object amount) {
    return 'لا يمكن أن تتجاوز $method المبلغ المتبقي $amount.';
  }

  @override
  String get nameCustomMethod => 'سمِّ طريقة الدفع المخصصة.';

  @override
  String get salesReceipt => 'إيصال بيع';

  @override
  String get receiptLabel => 'إيصال';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String get cashierShort => 'الكاشير';

  @override
  String get customerLabel => 'العميل';

  @override
  String get thankYou => 'شكرًا لشرائك!';

  @override
  String get salesHistory => 'سجل المبيعات';

  @override
  String get thisShiftOnly => 'هذه الوردية فقط';

  @override
  String get noSalesYet => 'لا توجد مبيعات بعد';

  @override
  String couldNotLoadOrders(Object error) {
    return 'تعذّر تحميل الطلبات: $error';
  }

  @override
  String get noPayment => 'لا يوجد دفع';

  @override
  String get products => 'المنتجات';

  @override
  String get searchProductsShort => 'ابحث عن المنتجات…';

  @override
  String get newProduct => 'منتج جديد';

  @override
  String get noProductsYet => 'لا توجد منتجات بعد';

  @override
  String get createFirstProduct => 'أنشئ أول منتج لبدء البيع.';

  @override
  String get productCreated => 'تم إنشاء المنتج.';

  @override
  String get productUpdated => 'تم تحديث المنتج.';

  @override
  String get productDeleted => 'تم حذف المنتج.';

  @override
  String couldNotDelete(Object error) {
    return 'تعذّر الحذف: $error';
  }

  @override
  String get deleteProductTitle => 'حذف المنتج';

  @override
  String deleteProductConfirm(Object name) {
    return 'حذف \"$name\"؟ لا يمكن التراجع عن ذلك.';
  }

  @override
  String get colProduct => 'المنتج';

  @override
  String get colCategory => 'الفئة';

  @override
  String get colStock => 'المخزون';

  @override
  String get colPrice => 'السعر';

  @override
  String get tagInactive => 'غير نشط';

  @override
  String get tagLow => 'منخفض';

  @override
  String get newProductTitle => 'منتج جديد';

  @override
  String get editProductTitle => 'تعديل المنتج';

  @override
  String get sectionProductDetails => 'تفاصيل المنتج';

  @override
  String get productNameLabel => 'اسم المنتج *';

  @override
  String get productNameHint => 'مثل لوحة مفاتيح لاسلكية';

  @override
  String get skuLabel => 'الرمز (SKU) *';

  @override
  String get skuHint => 'وحدة حفظ المخزون';

  @override
  String get barcodeLabel => 'الباركود';

  @override
  String get categoryLabel => 'الفئة';

  @override
  String get categoryHint => 'مثل إلكترونيات';

  @override
  String get unitLabel => 'الوحدة';

  @override
  String get sectionPricing => 'التسعير';

  @override
  String get costPriceLabel => 'سعر التكلفة';

  @override
  String get sellingPriceLabel => 'سعر البيع *';

  @override
  String get sectionInventory => 'المخزون';

  @override
  String get stockOnHand => 'المخزون المتوفر';

  @override
  String get openingStock => 'المخزون الافتتاحي';

  @override
  String get minimumStockAlert => 'تنبيه الحد الأدنى للمخزون';

  @override
  String get activeLabel => 'نشط';

  @override
  String get activeSubtitle => 'المنتجات غير النشطة مخفية من نقاط البيع';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get createProductAction => 'إنشاء المنتج';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get skuRequired => 'الرمز مطلوب';

  @override
  String get enterValidPrice => 'أدخل سعرًا صالحًا';

  @override
  String get cannotBeNegative => 'لا يمكن أن يكون سالبًا';

  @override
  String couldNotSaveProduct(Object error) {
    return 'تعذّر حفظ المنتج: $error';
  }

  @override
  String get pickExisting => 'اختر موجودًا';

  @override
  String get phoneLabel => 'الهاتف';

  @override
  String get statusLabel => 'الحالة';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusInactive => 'غير نشط';

  @override
  String get statusBlocked => 'محظور';

  @override
  String get codeRequired => 'الرمز مطلوب';

  @override
  String deleteConfirmName(Object name) {
    return 'حذف \"$name\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get customersTitle => 'العملاء';

  @override
  String get searchCustomers => 'بحث عن العملاء…';

  @override
  String get newCustomer => 'عميل جديد';

  @override
  String get editCustomerTitle => 'تعديل العميل';

  @override
  String get noCustomersYet => 'لا يوجد عملاء بعد';

  @override
  String get noCustomersSubtitle => 'أضف أول عميل لتتبّع المبيعات والأرصدة.';

  @override
  String get noCustomersMatch => 'لا يوجد عملاء مطابقون لبحثك.';

  @override
  String get customerCreated => 'تم إنشاء العميل.';

  @override
  String get customerUpdated => 'تم تحديث العميل.';

  @override
  String get customerDeleted => 'تم حذف العميل.';

  @override
  String couldNotLoadCustomers(Object error) {
    return 'تعذّر تحميل العملاء: $error';
  }

  @override
  String get deleteCustomerTitle => 'حذف العميل';

  @override
  String get colCustomer => 'العميل';

  @override
  String get colPhone => 'الهاتف';

  @override
  String get colBalance => 'الرصيد';

  @override
  String get colStatus => 'الحالة';

  @override
  String get sectionCustomerDetails => 'بيانات العميل';

  @override
  String get customerNameLabel => 'الاسم';

  @override
  String get customerNameHint => 'مثل شركة القاهرة للتجارة';

  @override
  String get customerCodeLabel => 'رمز العميل';

  @override
  String get customerCodeHint => 'مثل CUST-0001';

  @override
  String get createCustomerAction => 'إنشاء العميل';

  @override
  String couldNotSaveCustomer(Object error) {
    return 'تعذّر حفظ العميل: $error';
  }

  @override
  String get suppliersTitle => 'الموردون';

  @override
  String get searchSuppliers => 'بحث عن الموردين…';

  @override
  String get newSupplier => 'مورد جديد';

  @override
  String get editSupplierTitle => 'تعديل المورد';

  @override
  String get noSuppliersYet => 'لا يوجد موردون بعد';

  @override
  String get noSuppliersSubtitle => 'أضف أول مورد لتتبّع المشتريات والمستحقات.';

  @override
  String get noSuppliersMatch => 'لا يوجد موردون مطابقون لبحثك.';

  @override
  String get supplierCreated => 'تم إنشاء المورد.';

  @override
  String get supplierUpdated => 'تم تحديث المورد.';

  @override
  String get supplierDeleted => 'تم حذف المورد.';

  @override
  String couldNotLoadSuppliers(Object error) {
    return 'تعذّر تحميل الموردين: $error';
  }

  @override
  String get deleteSupplierTitle => 'حذف المورد';

  @override
  String get colSupplier => 'المورد';

  @override
  String get colPayable => 'المستحق';

  @override
  String get sectionSupplierDetails => 'بيانات المورد';

  @override
  String get companyNameLabel => 'اسم الشركة';

  @override
  String get companyNameHint => 'مثل موزّعي النيل';

  @override
  String get companyNameRequired => 'اسم الشركة مطلوب';

  @override
  String get supplierCodeLabel => 'رمز المورد';

  @override
  String get supplierCodeHint => 'مثل SUP-0001';

  @override
  String get createSupplierAction => 'إنشاء المورد';

  @override
  String couldNotSaveSupplier(Object error) {
    return 'تعذّر حفظ المورد: $error';
  }

  @override
  String get usersTitle => 'المستخدمون';

  @override
  String get searchUsers => 'بحث عن المستخدمين…';

  @override
  String get newUser => 'مستخدم جديد';

  @override
  String get editUserTitle => 'تعديل المستخدم';

  @override
  String get noUsersYet => 'لا يوجد مستخدمون إضافيون';

  @override
  String get noUsersSubtitle =>
      'أضف الكاشيرين والمديرين لمنحهم تسجيل دخول خاص بهم.';

  @override
  String get noUsersMatch => 'لا يوجد مستخدمون مطابقون لبحثك.';

  @override
  String get userCreated => 'تم إنشاء المستخدم.';

  @override
  String get userUpdated => 'تم تحديث المستخدم.';

  @override
  String get userDeleted => 'تم حذف المستخدم.';

  @override
  String couldNotLoadUsers(Object error) {
    return 'تعذّر تحميل المستخدمين: $error';
  }

  @override
  String get deleteUserTitle => 'حذف المستخدم';

  @override
  String get colUser => 'المستخدم';

  @override
  String get colRole => 'الدور';

  @override
  String get colLastLogin => 'آخر دخول';

  @override
  String get youPill => 'أنت';

  @override
  String get neverLoggedIn => 'أبداً';

  @override
  String get sectionUserDetails => 'بيانات المستخدم';

  @override
  String get userFullNameHint => 'مثل سارة حسن';

  @override
  String get fullNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get usernameSignInHint => 'يُستخدم لتسجيل الدخول';

  @override
  String get usernameRequired => 'اسم المستخدم مطلوب';

  @override
  String get roleLabel => 'الدور';

  @override
  String get roleAdmin => 'مدير النظام';

  @override
  String get roleManager => 'مدير';

  @override
  String get roleCashier => 'كاشير';

  @override
  String get sectionAccess => 'الصلاحيات';

  @override
  String get newPasswordLabel => 'كلمة مرور جديدة';

  @override
  String get leaveBlankKeep => 'اتركها فارغة للإبقاء على الحالية';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get useAtLeast6 => 'استخدم 6 أحرف على الأقل';

  @override
  String get inactiveCannotSignIn =>
      'المستخدمون غير النشطين لا يمكنهم تسجيل الدخول.';

  @override
  String get createUserAction => 'إنشاء المستخدم';

  @override
  String couldNotSaveUser(Object error) {
    return 'تعذّر حفظ المستخدم: $error';
  }

  @override
  String get settingsGroupBusiness => 'الأعمال';

  @override
  String get settingsGroupDocuments => 'المستندات والطباعة';

  @override
  String get settingsGroupPos => 'نقطة البيع';

  @override
  String get settingsGroupProducts => 'المنتجات';

  @override
  String get navCompanyInfo => 'معلومات الشركة';

  @override
  String get navAccountingSettings => 'المحاسبة';

  @override
  String get navRolesPermissions => 'الأدوار والصلاحيات';

  @override
  String get navPaymentMethods => 'طرق الدفع';

  @override
  String get navCostCategories => 'تصنيفات التكاليف';

  @override
  String get navInvoiceSettings => 'إعدادات الفواتير';

  @override
  String get navPrintSettings => 'إعدادات الطباعة';

  @override
  String get navPrinters => 'الطابعات';

  @override
  String get navPosDevices => 'نقاط البيع';

  @override
  String get navItemCategories => 'تصنيفات الاصناف';

  @override
  String get navItemAttributes => 'خصائص الاصناف';

  @override
  String get navUnits => 'وحدات القياس';

  @override
  String get navTaxSettings => 'إعدادات الضرائب';

  @override
  String get comingSoonTitle => 'قريباً';

  @override
  String get comingSoonBody => 'سيتوفر هذا القسم من الإعدادات قريباً.';

  @override
  String get catSubtitle => 'نظّم منتجاتك في فئات.';

  @override
  String get catAdd => 'إضافة فئة';

  @override
  String get catEditTitle => 'تعديل الفئة';

  @override
  String get catSearchHint => 'ابحث في الفئات…';

  @override
  String get catColName => 'الاسم';

  @override
  String get catColProducts => 'المنتجات';

  @override
  String catProductCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منتجات',
      one: 'منتج واحد',
      zero: 'لا منتجات',
    );
    return '$_temp0';
  }

  @override
  String get catNameEn => 'الاسم (إنجليزي)';

  @override
  String get catNameAr => 'الاسم (عربي)';

  @override
  String get catNameHintEn => 'e.g. Beverages';

  @override
  String get catNameHintAr => 'مثال: مشروبات';

  @override
  String get catNameRequired => 'أدخل اسمًا بالإنجليزية أو العربية.';

  @override
  String get catEmpty => 'لا توجد فئات بعد. أضف أول فئة.';

  @override
  String get catCreated => 'تم إنشاء الفئة.';

  @override
  String get catUpdated => 'تم تحديث الفئة.';

  @override
  String get catDeleted => 'تم حذف الفئة.';

  @override
  String get catDeleteTitle => 'حذف الفئة';

  @override
  String catDeleteConfirm(Object name) {
    return 'هل تريد حذف الفئة \"$name\"؟';
  }

  @override
  String get unitSubtitle => 'حدّد وحدات بيع وتخزين المنتجات.';

  @override
  String get unitAdd => 'إضافة وحدة';

  @override
  String get unitEditTitle => 'تعديل الوحدة';

  @override
  String get unitColShortCode => 'الرمز المختصر';

  @override
  String get unitColDecimals => 'الكميات';

  @override
  String get unitColDefault => 'افتراضي';

  @override
  String get unitNameEn => 'الاسم (إنجليزي)';

  @override
  String get unitNameAr => 'الاسم (عربي)';

  @override
  String get unitNameHintEn => 'e.g. Piece, Box, Kilogram';

  @override
  String get unitNameHintAr => 'مثال: قطعة، صندوق، كيلوجرام';

  @override
  String get unitShortCodeLabel => 'الرمز المختصر';

  @override
  String get unitShortCodeHint => 'مثال: كجم، قطعة، صندوق';

  @override
  String get unitDescriptionLabel => 'الوصف';

  @override
  String get unitAllowDecimalLabel => 'الكميات';

  @override
  String get unitIntegerOnly => 'صحيحة (1، 2، 3)';

  @override
  String get unitDecimalAllowed => 'عشرية (1.5، 2.3)';

  @override
  String get unitNameRequired => 'أدخل اسمًا بالإنجليزية أو العربية.';

  @override
  String get unitEmpty => 'لا توجد وحدات بعد. أضف أول وحدة.';

  @override
  String get unitCreated => 'تم إنشاء الوحدة.';

  @override
  String get unitUpdated => 'تم تحديث الوحدة.';

  @override
  String get unitDeleted => 'تم حذف الوحدة.';

  @override
  String get unitSetDefault => 'تعيين كافتراضي';

  @override
  String get unitDefaultBadge => 'افتراضي';

  @override
  String unitDefaultSet(Object name) {
    return 'أصبحت \"$name\" الوحدة الافتراضية.';
  }

  @override
  String get unitDeleteTitle => 'حذف الوحدة';

  @override
  String unitDeleteConfirm(Object name) {
    return 'هل تريد حذف الوحدة \"$name\"؟';
  }

  @override
  String catalogLoadError(Object error) {
    return 'تعذّر تحميل القائمة: $error';
  }

  @override
  String catalogSaveError(Object error) {
    return 'تعذّر الحفظ: $error';
  }

  @override
  String get rolesSubtitle => 'إدارة الأدوار وصلاحياتها';

  @override
  String get addRole => 'إضافة دور';

  @override
  String get permissionsAction => 'الصلاحيات';

  @override
  String membersLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضو',
      one: 'عضو واحد',
      zero: 'لا أعضاء',
    );
    return '$_temp0';
  }

  @override
  String get roleDeleteTitle => 'حذف الدور';

  @override
  String roleDeleteConfirm(Object name) {
    return 'حذف الدور \"$name\"؟';
  }

  @override
  String get roleCreated => 'تم إنشاء الدور.';

  @override
  String get roleUpdated => 'تم تحديث الدور.';

  @override
  String get roleDeleted => 'تم حذف الدور.';

  @override
  String couldNotLoadRoles(Object error) {
    return 'تعذّر تحميل الأدوار: $error';
  }

  @override
  String couldNotSaveRole(Object error) {
    return 'تعذّر حفظ الدور: $error';
  }

  @override
  String permissionsForRole(Object name) {
    return 'صلاحيات — $name';
  }

  @override
  String get newRoleTitle => 'دور جديد';

  @override
  String get permissionsDialogSubtitle =>
      'حدد الإجراءات المسموح بها لهذا الدور';

  @override
  String get roleNameLabel => 'اسم الدور';

  @override
  String get roleNameHint => 'مثال: كاشير';

  @override
  String get roleNameRequired => 'اسم الدور مطلوب';

  @override
  String get descriptionLabel => 'الوصف';

  @override
  String get descriptionHint => 'الوصف';

  @override
  String get savePermissions => 'حفظ الصلاحيات';

  @override
  String actionsCount(int granted, int total) {
    return '$granted / $total إجراءات';
  }

  @override
  String modulesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وحدات',
      one: 'وحدة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get companyInfoSubtitle => 'مراجعة من إعدادات شركة Operix.';

  @override
  String get businessLogoLabel => 'شعار العمل';

  @override
  String get logoUploadHint =>
      'اضغط لتغيير الشعار. الصيغ المقبولة: JPG, PNG, GIF (أقصى حجم 2 ميجابايت)';

  @override
  String get companySettingsNameLabel => 'الاسم';

  @override
  String get companySettingsNameRequired => 'الاسم مطلوب';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get emailInvalid => 'أدخل بريدًا إلكترونيًا صالحًا';

  @override
  String get phoneFieldLabel => 'الهاتف';

  @override
  String get commercialRegLabel => 'رقم السجل التجاري';

  @override
  String get commercialRegHint => 'أدخل رقم السجل التجاري';

  @override
  String get cityLabel => 'المدينة';

  @override
  String get regionLabel => 'المنطقة / المحافظة';

  @override
  String get countryLabel => 'الدولة';

  @override
  String get postalCodeLabel => 'الرمز البريدي';

  @override
  String get postalCodeHint => 'أدخل الرمز البريدي';

  @override
  String get addressLabel => 'العنوان';

  @override
  String get companySettingsSaved => 'تم حفظ معلومات الشركة';

  @override
  String get logoPathDialogTitle => 'مسار صورة الشعار';

  @override
  String get accessDeniedTitle => 'غير مصرح بالوصول';

  @override
  String get accessDeniedBody => 'ليس لديك صلاحية لعرض هذا القسم.';

  @override
  String get cannotAssignAdminRole => 'يمكن لمسؤول النظام فقط إسناد دور نظامي.';

  @override
  String get navUsers => 'المستخدمون';

  @override
  String get account => 'الحساب';

  @override
  String get clientAccounts => 'حسابات العملاء';

  @override
  String get supplierAccounts => 'حسابات الموردين';

  @override
  String get searchProducts => 'ابحث عن المنتجات…';

  @override
  String get stockLog => 'سجل المخزون';

  @override
  String get stockAdjusted => 'تم تعديل المخزون.';

  @override
  String couldNotLoadProducts(Object error) {
    return 'تعذّر تحميل المنتجات: $error';
  }

  @override
  String get adjustStock => 'تعديل المخزون';

  @override
  String get noProductsMatch => 'لا توجد منتجات مطابقة لبحثك.';

  @override
  String get createFirstProductHint => 'أنشئ أول منتج لبدء البيع.';

  @override
  String get settingsDatabase => 'قاعدة البيانات';

  @override
  String get settingsDatabaseSubtitle =>
      'اتصال PostgreSQL المحلي المستخدم في هذه المحطة.';

  @override
  String get settingsSource => 'المصدر';

  @override
  String get settingsDemoData => 'بيانات تجريبية';

  @override
  String get settingsTarget => 'الوجهة';

  @override
  String get settingsConfigured => 'مُهيأ';

  @override
  String get settingsYes => 'نعم';

  @override
  String get settingsNo => 'لا';

  @override
  String get settingsSslMode => 'وضع SSL';

  @override
  String get settingsLicense => 'الترخيص';

  @override
  String get settingsLicenseSubtitle => 'تفعيل المحطة دون اتصال.';

  @override
  String get settingsInstallationId => 'معرّف التثبيت';

  @override
  String get settingsLoading => 'جارٍ التحميل…';

  @override
  String get settingsStatus => 'الحالة';

  @override
  String get settingsLicensedBusiness => 'النشاط المُرخّص';

  @override
  String get settingsExpires => 'تنتهي في';

  @override
  String get currencyEgp => 'ج.م';

  @override
  String get dashOverviewTitle => 'نظرة عامة على أداء الأعمال';

  @override
  String get dashQuickActions => 'إجراءات سريعة';

  @override
  String get dashVsPreviousPeriod => 'مقارنة بالفترة السابقة';

  @override
  String get dashPeriodToday => 'اليوم';

  @override
  String get dashPeriodLast7 => 'آخر 7 أيام';

  @override
  String get dashPeriodThisMonth => 'هذا الشهر';

  @override
  String get dashPeriodCustom => 'مخصص';

  @override
  String get dashFrom => 'من';

  @override
  String get dashTo => 'إلى';

  @override
  String get dashPickDate => 'اختر تاريخاً';

  @override
  String get dashContactSales => 'تواصل مع المبيعات';

  @override
  String get dashContactSalesBody =>
      'لتجديد الترخيص أو ترقية الباقة، تواصل مع فريق مبيعات Operix:\n\nsales@operixhq.com';

  @override
  String get dashCopyEmail => 'نسخ البريد';

  @override
  String get dashSalesEmailCopied => 'تم نسخ بريد المبيعات';

  @override
  String get dashOk => 'حسناً';

  @override
  String get dashLicenseExpiryAlert => 'تنبيه انتهاء الترخيص';

  @override
  String dashLicenseExpiryHeadline(int days, String business) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'متبقٍ $days يوماً على انتهاء ترخيص $business.',
      many: 'متبقٍ $days يوماً على انتهاء ترخيص $business.',
      few: 'متبقٍ $days أيام على انتهاء ترخيص $business.',
      two: 'متبقٍ يومان على انتهاء ترخيص $business.',
      one: 'متبقٍ يوم واحد على انتهاء ترخيص $business.',
      zero: 'ينتهي ترخيص $business اليوم.',
    );
    return '$_temp0';
  }

  @override
  String dashLicenseExpiryFooter(String date) {
    return 'تاريخ الانتهاء: $date — جدّد الترخيص لتفادي توقف الخدمة.';
  }

  @override
  String get dashManageLicense => 'إدارة الترخيص';

  @override
  String get dashActionNewSalesInvoice => 'فاتورة مبيعات جديدة';

  @override
  String get dashActionNewExpense => 'تكلفة جديدة';

  @override
  String get dashActionPurchaseInvoice => 'فاتورة شراء';

  @override
  String get dashActionSalesReturns => 'مرتجعات المبيعات';

  @override
  String get dashKpiRevenue => 'الإيرادات';

  @override
  String get dashKpiExpenses => 'التكاليف';

  @override
  String get dashKpiExpensesSubtitle => 'تكلفة البضاعة والمصروفات';

  @override
  String get dashKpiNetProfit => 'صافي الربح';

  @override
  String get dashKpiNetProfitSubtitle => 'بعد التكاليف';

  @override
  String get dashKpiCashBalance => 'الرصيد النقدي';

  @override
  String get dashKpiCashBalanceSubtitle => 'جميع الحسابات';

  @override
  String get dashSalesTrend => 'اتجاه المبيعات';

  @override
  String get dashSalesTrendSubtitle => 'صافي المبيعات خلال الفترة المحددة';

  @override
  String get dashRevenueDistribution => 'توزيع الإيرادات';

  @override
  String get dashRevenueDistributionSubtitle => 'كيف يتم توزيع الإيرادات';

  @override
  String get dashCogs => 'تكلفة البضاعة';

  @override
  String get dashNoSalesData => 'لا توجد بيانات مبيعات للفترة';

  @override
  String get dashTotalProfit => 'إجمالي الربح';

  @override
  String dashMarginLabel(String value) {
    return 'الهامش $value%';
  }

  @override
  String get dashGrossMargin => 'هامش الربح الإجمالي';

  @override
  String get dashInventoryValue => 'قيمة المخزون';

  @override
  String get dashAtCost => 'بالتكلفة';

  @override
  String get dashOrders => 'الطلبات';

  @override
  String dashAverageLabel(String value) {
    return 'المتوسط: $value';
  }

  @override
  String get dashNewCustomers => 'عملاء جدد';

  @override
  String get dashThisPeriod => 'هذه الفترة';

  @override
  String get dashSupplierDue => 'مستحقات الموردين';

  @override
  String get dashTotalDueAmount => 'إجمالي المبلغ المستحق';

  @override
  String get dashTopProducts => 'أعلى الأصناف مبيعاً';

  @override
  String dashPiecesLabel(int count) {
    return '$count قطعة';
  }

  @override
  String get dashInventoryHealthy => 'جميع الأصناف متوفرة بمخزون جيد';

  @override
  String dashInventoryLowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صنف وصل حد إعادة الطلب',
      many: '$count صنفاً وصل حد إعادة الطلب',
      few: '$count أصناف وصلت حد إعادة الطلب',
      two: 'صنفان وصلا حد إعادة الطلب',
      one: 'صنف واحد وصل حد إعادة الطلب',
    );
    return '$_temp0';
  }

  @override
  String get dashInventoryHealthyBody =>
      'المخزون بحالة جيدة في جميع الأصناف المرتبطة بالمخزون';

  @override
  String get dashInventoryLowBody =>
      'راجع شاشة المخزون لإعادة طلب الأصناف منخفضة الكمية';

  @override
  String get dashSalesInvoicesTitle => 'فواتير المبيعات';

  @override
  String get dashCreateInvoice => 'إنشاء فاتورة';

  @override
  String get dashFilters => 'الفلاتر';

  @override
  String get dashSearchInvoiceHint => 'بحث برقم الفاتورة أو العميل...';

  @override
  String get dashChooseCustomer => 'اختر العميل';

  @override
  String get dashCashCustomer => 'عميل نقدي';

  @override
  String get dashAddAtLeastOneItem =>
      'أضف صنفاً واحداً على الأقل إلى الفاتورة.';

  @override
  String dashInvoiceCreated(String number) {
    return 'تم إنشاء الفاتورة $number';
  }

  @override
  String dashCouldNotSaveInvoice(Object error) {
    return 'تعذّر حفظ الفاتورة: $error';
  }

  @override
  String get dashNewSalesInvoiceTitle => 'فاتورة مبيعات جديدة';

  @override
  String get dashNewSalesInvoiceSubtitle =>
      'إنشاء فاتورة رسمية لتجار الجملة أو الشركات.';

  @override
  String get dashBack => 'رجوع';

  @override
  String get dashInvoiceDateLabel => 'تاريخ الفاتورة *';

  @override
  String get dashDueDateLabel => 'تاريخ الاستحقاق';

  @override
  String get dashSelectDate => 'اختر تاريخاً';

  @override
  String get dashInvoiceNumberLabel => 'رقم الفاتورة';

  @override
  String get dashAutoGenerated => '# توليد تلقائي';

  @override
  String get dashInvoiceItems => 'عناصر الفاتورة';

  @override
  String get dashAddItem => 'إضافة صنف';

  @override
  String get dashColItem => 'الصنف';

  @override
  String get dashColPrice => 'السعر';

  @override
  String get dashColQty => 'الكمية';

  @override
  String get dashColTotal => 'الإجمالي';

  @override
  String dashVatLabel(String rate) {
    return 'ضريبة القيمة المضافة ($rate%)';
  }

  @override
  String get dashAddItems => 'إضافة أصناف';

  @override
  String get dashClose => 'إغلاق';

  @override
  String get dashSearchByNameOrSku => 'ابحث بالاسم أو رمز SKU...';

  @override
  String get dashNoItemsFound => 'لا توجد أصناف';

  @override
  String dashStockLabel(int count) {
    return 'مخزون: $count';
  }

  @override
  String get dashNoItemsAddedYet => 'لم تتم إضافة عناصر بعد';

  @override
  String get dashNoItemsAddedYetBody =>
      'ابدأ ببناء فاتورتك عن طريق إضافة أصناف من مخزونك.';

  @override
  String get dashNotes => 'الملاحظات';

  @override
  String get dashNotesHint => 'أضف أي ملاحظات أو شروط للعميل...';

  @override
  String get dashChooseSupplier => 'اختر المورد';

  @override
  String get dashNoSupplier => 'بدون مورد';

  @override
  String get dashCashSupplier => 'مورد نقدي';

  @override
  String dashPurchaseInvoiceCreated(String number) {
    return 'تم إنشاء فاتورة الشراء $number';
  }

  @override
  String get dashNewPurchaseInvoiceTitle => 'فاتورة شراء جديدة';

  @override
  String get dashNewPurchaseInvoiceSubtitle =>
      'إنشاء فاتورة للأصناف أو الخدمات المستلمة من المورد.';

  @override
  String get dashSupplierLabel => 'المورد';

  @override
  String get dashColPurchasePrice => 'سعر الشراء';

  @override
  String get dashColSalePrice => 'سعر البيع';

  @override
  String get dashNoItemsAdded =>
      'لم تتم إضافة عناصر. استخدم البحث أعلاه لإضافة الأصناف.';

  @override
  String get dashNoItemsAddedBody =>
      'استخدم زر \"إضافة عنصر\" أعلاه لإضافة الأصناف.';
}
