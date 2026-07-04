// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitleWelcomeBack => 'Welcome Back';

  @override
  String get loginTitleCreatePin => 'Create Security PIN';

  @override
  String get loginSubWelcomeBack => 'Enter your PIN to access your workshop';

  @override
  String get loginSubCreatePin => 'Set a 4-digit PIN to protect your database';

  @override
  String get loginLabelPin => 'Security PIN';

  @override
  String get loginLabelEnterPin => 'Enter 4-digit PIN';

  @override
  String get loginLabelConfirmPin => 'Confirm 4-digit PIN';

  @override
  String get loginErrorLength => 'PIN must be 4 digits';

  @override
  String get loginErrorMismatch => 'PINs do not match';

  @override
  String get loginErrorIncorrect => 'Incorrect PIN';

  @override
  String get loginButtonUnlock => 'Unlock Dashboard';

  @override
  String get loginButtonSetPin => 'Set PIN & Login';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardSearchHint => 'Search customer or vehicle...';

  @override
  String get dashboardStatTodaysSales => 'Today\'s Sales';

  @override
  String dashboardStatBillsGenerated(int count) {
    return '$count bills generated';
  }

  @override
  String get dashboardStatPendingJobs => 'Pending Jobs';

  @override
  String dashboardStatInProgressCount(int count) {
    return '$count in progress';
  }

  @override
  String get dashboardStatCompletedJobs => 'Completed Jobs';

  @override
  String get dashboardStatCompleted => 'Completed';

  @override
  String get dashboardStatCompletedToday => 'Today';

  @override
  String get dashboardStatTotalCustomers => 'Total Customers';

  @override
  String get dashboardStatRegistered => 'Registered';

  @override
  String get dashboardSectionActiveJobs => 'Active Job Cards';

  @override
  String get dashboardSectionLowStockAlert => 'Low Stock Items';

  @override
  String get dashboardNoActiveJobs => 'No active job cards';

  @override
  String get dashboardNoLowStock => 'All items are in stock';

  @override
  String get dashboardViewAll => 'View All';

  @override
  String get dashboardLowStockAlert => 'Low stock alert';

  @override
  String dashboardItemsNeedRestocking(int count) {
    return '$count items need restocking';
  }

  @override
  String get dashboardActionView => 'View';

  @override
  String get dashboardQuickActions => 'Quick actions';

  @override
  String get billingTitle => 'New Invoice';

  @override
  String get billingCustomerSection => 'Customer Details';

  @override
  String get billingVehicleSection => 'Vehicle Details';

  @override
  String get billingItemsSection => 'Items & Services';

  @override
  String get billingSummarySection => 'Payment Summary';

  @override
  String get billingButtonSave => 'Save Invoice';

  @override
  String get billingErrorCustomerRequired => 'Customer is required';

  @override
  String get billingErrorItemRequired => 'Add at least one item';

  @override
  String get billingHintSavedVehicle => 'Select saved vehicle or add new below';

  @override
  String get billingLabelSavedVehicles => 'Saved Vehicles';

  @override
  String get billingLabelNewVehicle => '+ New vehicle';

  @override
  String get billingLabelCustomerName => 'Customer Name';

  @override
  String get billingLabelMobileNumber => 'Mobile Number';

  @override
  String get billingLabelVehicleNumber => 'Vehicle Number';

  @override
  String get billingLabelVehicleModel => 'Vehicle Model';

  @override
  String get billingLabelFuelType => 'Fuel Type';

  @override
  String get billingStatusExistingCustomer => 'Existing customer';

  @override
  String get billingActionClear => 'Clear';

  @override
  String get billingItemsHeader => 'Items';

  @override
  String get billingActionAddItem => 'Add Item';

  @override
  String get billingNoItemsTitle => 'No items added';

  @override
  String get billingNoItemsSubtitle => 'Tap to add parts or services';

  @override
  String get billingHistory => 'History';

  @override
  String get billingInvoiceDate => 'Invoice Date';

  @override
  String get billingPayment => 'Payment';

  @override
  String get billingStatus => 'Status';

  @override
  String get billingMethod => 'Method';

  @override
  String get billingNotesHint => 'Notes or remarks (optional)…';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusPartial => 'Partial';

  @override
  String get methodCash => 'Cash';

  @override
  String get methodUpi => 'UPI';

  @override
  String get methodCard => 'Card';

  @override
  String get methodBank => 'Bank Transfer';

  @override
  String get methodPending => 'Pending';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLanguageSetting => 'App Language';

  @override
  String get profileLanguageSelect => 'Choose Language';

  @override
  String get jobsTitle => 'Job Cards';

  @override
  String get jobsFilterAll => 'All';

  @override
  String get jobsNewJobCard => 'New Job Card';

  @override
  String get jobsNoJobCards => 'No job cards found matching this filter.';

  @override
  String get jobsColJobId => 'Job ID';

  @override
  String get jobsColCustomer => 'Customer';

  @override
  String get jobsColVehicle => 'Vehicle';

  @override
  String get jobsColComplaint => 'Complaint';

  @override
  String get jobsColMechanic => 'Mechanic';

  @override
  String get jobsColAmount => 'Amount';

  @override
  String get jobsColStatus => 'Status';

  @override
  String get jobsColActions => 'Actions';

  @override
  String get customersTitle => 'Customers';

  @override
  String get customersAdd => 'Add';

  @override
  String get customersSearchHint => 'Search by name or phone...';

  @override
  String get inventoryTitle => 'Inventory Management';

  @override
  String get inventoryAddPart => 'Add Part';

  @override
  String get inventoryTabAll => 'All Parts';

  @override
  String get inventoryTabLowStock => 'Low Stock';

  @override
  String get inventorySearchHint => 'Search parts by name, category, or SKU...';

  @override
  String get inventoryColName => 'Part Name';

  @override
  String get inventoryColSku => 'SKU';

  @override
  String get inventoryColCategory => 'Category';

  @override
  String get inventoryColPurchase => 'Purchase Price';

  @override
  String get inventoryColSelling => 'Selling Price';

  @override
  String get inventoryColStock => 'Stock Qty';

  @override
  String get inventoryColMinStock => 'Min Stock';

  @override
  String get inventoryColStatus => 'Status';

  @override
  String get inventoryColActions => 'Actions';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsPeriodDaily => 'Daily';

  @override
  String get reportsPeriodWeekly => 'Weekly';

  @override
  String get reportsPeriodMonthly => 'Monthly';

  @override
  String get tabVehicles => 'Vehicles';

  @override
  String get tabInvoices => 'Invoices';

  @override
  String get tabHistory => 'History';
}
