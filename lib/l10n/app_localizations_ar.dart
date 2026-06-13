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
  String get passwordMinChars => '6 أحرف على الأقل';

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
}
