// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get loginTitleWelcomeBack => 'स्वागत है';

  @override
  String get loginTitleCreatePin => 'सुरक्षा पिन बनाएं';

  @override
  String get loginSubWelcomeBack =>
      'अपनी कार्यशाला तक पहुँचने के लिए अपना पिन दर्ज करें';

  @override
  String get loginSubCreatePin =>
      'अपने डेटाबेस की सुरक्षा के लिए 4-अंकीय पिन सेट करें';

  @override
  String get loginLabelPin => 'सुरक्षा पिन';

  @override
  String get loginLabelEnterPin => '4-अंकीय पिन दर्ज करें';

  @override
  String get loginLabelConfirmPin => '4-अंकीय पिन की पुष्टि करें';

  @override
  String get loginErrorLength => 'पिन 4 अंकों का होना चाहिए';

  @override
  String get loginErrorMismatch => 'पिन मेल नहीं खाते';

  @override
  String get loginErrorIncorrect => 'गलत पिन';

  @override
  String get loginButtonUnlock => 'डैशबोर्ड अनलॉक करें';

  @override
  String get loginButtonSetPin => 'पिन सेट करें और लॉगिन करें';

  @override
  String get dashboardTitle => 'डैशबोर्ड';

  @override
  String get dashboardSearchHint => 'ग्राहक या वाहन खोजें...';

  @override
  String get dashboardStatTodaysSales => 'आज की बिक्री';

  @override
  String dashboardStatBillsGenerated(int count) {
    return '$count बिल बनाए गए';
  }

  @override
  String get dashboardStatPendingJobs => 'लंबित जॉब';

  @override
  String dashboardStatInProgressCount(int count) {
    return '$count प्रगति पर';
  }

  @override
  String get dashboardStatCompletedJobs => 'पूर्ण जॉब';

  @override
  String get dashboardStatCompleted => 'पूर्ण';

  @override
  String get dashboardStatCompletedToday => 'आज';

  @override
  String get dashboardStatTotalCustomers => 'कुल ग्राहक';

  @override
  String get dashboardStatRegistered => 'पंजीकृत';

  @override
  String get dashboardSectionActiveJobs => 'सक्रिय जॉब कार्ड';

  @override
  String get dashboardSectionLowStockAlert => 'कम स्टॉक आइटम';

  @override
  String get dashboardNoActiveJobs => 'कोई सक्रिय जॉब कार्ड नहीं है';

  @override
  String get dashboardNoLowStock => 'सभी सामग्री स्टॉक में हैं';

  @override
  String get dashboardViewAll => 'सभी देखें';

  @override
  String get dashboardLowStockAlert => 'कम स्टॉक चेतावनी';

  @override
  String dashboardItemsNeedRestocking(int count) {
    return '$count सामग्री को दोबारा भरने की आवश्यकता है';
  }

  @override
  String get dashboardActionView => 'देखें';

  @override
  String get dashboardQuickActions => 'त्वरित कार्रवाई';

  @override
  String get billingTitle => 'नया इनवॉइस';

  @override
  String get billingCustomerSection => 'ग्राहक का विवरण';

  @override
  String get billingVehicleSection => 'वाहन का विवरण';

  @override
  String get billingItemsSection => 'सामग्री और सेवाएं';

  @override
  String get billingSummarySection => 'भुगतान सारांश';

  @override
  String get billingButtonSave => 'इनवॉइस सहेजें';

  @override
  String get billingErrorCustomerRequired => 'ग्राहक आवश्यक है';

  @override
  String get billingErrorItemRequired => 'कम से कम एक सामग्री जोड़ें';

  @override
  String get billingHintSavedVehicle =>
      'सहेजे गए वाहन का चयन करें या नीचे नया जोड़ें';

  @override
  String get billingLabelSavedVehicles => 'सहेजे गए वाहन';

  @override
  String get billingLabelNewVehicle => '+ नया वाहन';

  @override
  String get billingLabelCustomerName => 'ग्राहक का नाम';

  @override
  String get billingLabelMobileNumber => 'मोबाइल नंबर';

  @override
  String get billingLabelVehicleNumber => 'वाहन संख्या';

  @override
  String get billingLabelVehicleModel => 'वाहन का मॉडल';

  @override
  String get billingLabelFuelType => 'ईंधन का प्रकार';

  @override
  String get billingStatusExistingCustomer => 'मौजूदा ग्राहक';

  @override
  String get billingActionClear => 'साफ़ करें';

  @override
  String get billingItemsHeader => 'सामग्री';

  @override
  String get billingActionAddItem => 'सामग्री जोड़ें';

  @override
  String get billingNoItemsTitle => 'कोई सामग्री नहीं जोड़ी गई';

  @override
  String get billingNoItemsSubtitle =>
      'पुर्जे या सेवाएं जोड़ने के लिए टैप करें';

  @override
  String get billingHistory => 'इतिहास';

  @override
  String get billingInvoiceDate => 'इनवॉइस की तारीख';

  @override
  String get billingPayment => 'भुगतान';

  @override
  String get billingStatus => 'स्थिति';

  @override
  String get billingMethod => 'तरीका';

  @override
  String get billingNotesHint => 'टिप्पणियां या रिमार्क्स (वैकल्पिक)...';

  @override
  String get statusPending => 'लंबित';

  @override
  String get statusInProgress => 'प्रगति पर';

  @override
  String get statusCompleted => 'पूर्ण';

  @override
  String get statusPaid => 'भुगतान किया गया';

  @override
  String get statusPartial => 'आंशिक';

  @override
  String get methodCash => 'नकद';

  @override
  String get methodUpi => 'यूपीआई (UPI)';

  @override
  String get methodCard => 'कार्ड';

  @override
  String get methodBank => 'बैंक ट्रांसफर';

  @override
  String get methodPending => 'लंबित';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get profileLanguageSetting => 'ऐप की भाषा';

  @override
  String get profileLanguageSelect => 'भाषा चुनें';

  @override
  String get jobsTitle => 'जॉब कार्ड';

  @override
  String get jobsFilterAll => 'सभी';

  @override
  String get jobsNewJobCard => 'नया जॉब कार्ड';

  @override
  String get jobsNoJobCards =>
      'इस फ़िल्टर से मेल खाने वाला कोई जॉब कार्ड नहीं मिला।';

  @override
  String get jobsColJobId => 'जॉब आईडी';

  @override
  String get jobsColCustomer => 'ग्राहक';

  @override
  String get jobsColVehicle => 'वाहन';

  @override
  String get jobsColComplaint => 'शिकायत';

  @override
  String get jobsColMechanic => 'मैकेनिक';

  @override
  String get jobsColAmount => 'राशि';

  @override
  String get jobsColStatus => 'स्थिति';

  @override
  String get jobsColActions => 'कार्रवाई';

  @override
  String get customersTitle => 'ग्राहक';

  @override
  String get customersAdd => 'जोड़ें';

  @override
  String get customersSearchHint => 'नाम या फ़ोन से खोजें...';

  @override
  String get inventoryTitle => 'स्टॉक प्रबंधन';

  @override
  String get inventoryAddPart => 'पुर्जा जोड़ें';

  @override
  String get inventoryTabAll => 'सभी पुर्जे';

  @override
  String get inventoryTabLowStock => 'कम स्टॉक';

  @override
  String get inventorySearchHint => 'नाम, श्रेणी या SKU द्वारा पुर्जे खोजें...';

  @override
  String get inventoryColName => 'पुर्जे का नाम';

  @override
  String get inventoryColSku => 'एसकेयू (SKU)';

  @override
  String get inventoryColCategory => 'श्रेणी';

  @override
  String get inventoryColPurchase => 'क्रय मूल्य';

  @override
  String get inventoryColSelling => 'बिक्री मूल्य';

  @override
  String get inventoryColStock => 'स्टॉक मात्रा';

  @override
  String get inventoryColMinStock => 'न्यूनतम स्टॉक';

  @override
  String get inventoryColStatus => 'स्थिति';

  @override
  String get inventoryColActions => 'कार्रवाई';

  @override
  String get reportsTitle => 'रिपोर्ट';

  @override
  String get reportsPeriodDaily => 'दैनिक';

  @override
  String get reportsPeriodWeekly => 'साप्ताहिक';

  @override
  String get reportsPeriodMonthly => 'मासिक';

  @override
  String get tabVehicles => 'वाहन';

  @override
  String get tabInvoices => 'इनवॉइस';

  @override
  String get tabHistory => 'इतिहास';
}
