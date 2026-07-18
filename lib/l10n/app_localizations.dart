import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @loginTitleWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitleWelcomeBack;

  /// No description provided for @loginTitleCreatePin.
  ///
  /// In en, this message translates to:
  /// **'Create Security PIN'**
  String get loginTitleCreatePin;

  /// No description provided for @loginSubWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to access your workshop'**
  String get loginSubWelcomeBack;

  /// No description provided for @loginSubCreatePin.
  ///
  /// In en, this message translates to:
  /// **'Set a 4-digit PIN to protect your database'**
  String get loginSubCreatePin;

  /// No description provided for @loginLabelPin.
  ///
  /// In en, this message translates to:
  /// **'Security PIN'**
  String get loginLabelPin;

  /// No description provided for @loginLabelEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter 4-digit PIN'**
  String get loginLabelEnterPin;

  /// No description provided for @loginLabelConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm 4-digit PIN'**
  String get loginLabelConfirmPin;

  /// No description provided for @loginErrorLength.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 4 digits'**
  String get loginErrorLength;

  /// No description provided for @loginErrorMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get loginErrorMismatch;

  /// No description provided for @loginErrorIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get loginErrorIncorrect;

  /// No description provided for @loginButtonUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock Dashboard'**
  String get loginButtonUnlock;

  /// No description provided for @loginButtonSetPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN & Login'**
  String get loginButtonSetPin;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search customer or vehicle...'**
  String get dashboardSearchHint;

  /// No description provided for @dashboardStatTodaysSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get dashboardStatTodaysSales;

  /// No description provided for @dashboardStatBillsGenerated.
  ///
  /// In en, this message translates to:
  /// **'{count} bills generated'**
  String dashboardStatBillsGenerated(int count);

  /// No description provided for @dashboardStatPendingJobs.
  ///
  /// In en, this message translates to:
  /// **'Pending Jobs'**
  String get dashboardStatPendingJobs;

  /// No description provided for @dashboardStatInProgressCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in progress'**
  String dashboardStatInProgressCount(int count);

  /// No description provided for @dashboardStatCompletedJobs.
  ///
  /// In en, this message translates to:
  /// **'Completed Jobs'**
  String get dashboardStatCompletedJobs;

  /// No description provided for @dashboardStatCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dashboardStatCompleted;

  /// No description provided for @dashboardStatCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardStatCompletedToday;

  /// No description provided for @dashboardStatTotalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get dashboardStatTotalCustomers;

  /// No description provided for @dashboardStatRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get dashboardStatRegistered;

  /// No description provided for @dashboardSectionActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'Active Job Cards'**
  String get dashboardSectionActiveJobs;

  /// No description provided for @dashboardSectionLowStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Items'**
  String get dashboardSectionLowStockAlert;

  /// No description provided for @dashboardNoActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'No active job cards'**
  String get dashboardNoActiveJobs;

  /// No description provided for @dashboardNoLowStock.
  ///
  /// In en, this message translates to:
  /// **'All items are in stock'**
  String get dashboardNoLowStock;

  /// No description provided for @dashboardViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get dashboardViewAll;

  /// No description provided for @dashboardLowStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Low stock alert'**
  String get dashboardLowStockAlert;

  /// No description provided for @dashboardItemsNeedRestocking.
  ///
  /// In en, this message translates to:
  /// **'{count} items need restocking'**
  String dashboardItemsNeedRestocking(int count);

  /// No description provided for @dashboardActionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get dashboardActionView;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboardQuickActions;

  /// No description provided for @billingTitle.
  ///
  /// In en, this message translates to:
  /// **'New Invoice'**
  String get billingTitle;

  /// No description provided for @billingCustomerSection.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get billingCustomerSection;

  /// No description provided for @billingVehicleSection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details'**
  String get billingVehicleSection;

  /// No description provided for @billingItemsSection.
  ///
  /// In en, this message translates to:
  /// **'Items & Services'**
  String get billingItemsSection;

  /// No description provided for @billingSummarySection.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get billingSummarySection;

  /// No description provided for @billingButtonSave.
  ///
  /// In en, this message translates to:
  /// **'Save Invoice'**
  String get billingButtonSave;

  /// No description provided for @billingErrorCustomerRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer is required'**
  String get billingErrorCustomerRequired;

  /// No description provided for @billingErrorItemRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item'**
  String get billingErrorItemRequired;

  /// No description provided for @billingHintSavedVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select saved vehicle or add new below'**
  String get billingHintSavedVehicle;

  /// No description provided for @billingLabelSavedVehicles.
  ///
  /// In en, this message translates to:
  /// **'Saved Vehicles'**
  String get billingLabelSavedVehicles;

  /// No description provided for @billingLabelNewVehicle.
  ///
  /// In en, this message translates to:
  /// **'+ New vehicle'**
  String get billingLabelNewVehicle;

  /// No description provided for @billingLabelCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get billingLabelCustomerName;

  /// No description provided for @billingLabelMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get billingLabelMobileNumber;

  /// No description provided for @billingLabelVehicleNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number'**
  String get billingLabelVehicleNumber;

  /// No description provided for @billingLabelVehicleModel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Model'**
  String get billingLabelVehicleModel;

  /// No description provided for @billingLabelFuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel Type'**
  String get billingLabelFuelType;

  /// No description provided for @billingStatusExistingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Existing customer'**
  String get billingStatusExistingCustomer;

  /// No description provided for @billingActionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get billingActionClear;

  /// No description provided for @billingItemsHeader.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get billingItemsHeader;

  /// No description provided for @billingActionAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get billingActionAddItem;

  /// No description provided for @billingNoItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'No items added'**
  String get billingNoItemsTitle;

  /// No description provided for @billingNoItemsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to add parts or services'**
  String get billingNoItemsSubtitle;

  /// No description provided for @billingHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get billingHistory;

  /// No description provided for @billingInvoiceDate.
  ///
  /// In en, this message translates to:
  /// **'Invoice Date'**
  String get billingInvoiceDate;

  /// No description provided for @billingPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get billingPayment;

  /// No description provided for @billingStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get billingStatus;

  /// No description provided for @billingMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get billingMethod;

  /// No description provided for @billingNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Notes or remarks (optional)…'**
  String get billingNotesHint;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get statusPartial;

  /// No description provided for @methodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get methodCash;

  /// No description provided for @methodUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get methodUpi;

  /// No description provided for @methodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get methodCard;

  /// No description provided for @methodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get methodBank;

  /// No description provided for @methodPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get methodPending;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileLanguageSetting.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get profileLanguageSetting;

  /// No description provided for @profileLanguageSelect.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get profileLanguageSelect;

  /// No description provided for @jobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Cards'**
  String get jobsTitle;

  /// No description provided for @jobsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get jobsFilterAll;

  /// No description provided for @jobsNewJobCard.
  ///
  /// In en, this message translates to:
  /// **'New Job Card'**
  String get jobsNewJobCard;

  /// No description provided for @jobsNoJobCards.
  ///
  /// In en, this message translates to:
  /// **'No job cards found matching this filter.'**
  String get jobsNoJobCards;

  /// No description provided for @jobsColJobId.
  ///
  /// In en, this message translates to:
  /// **'Job ID'**
  String get jobsColJobId;

  /// No description provided for @jobsColCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get jobsColCustomer;

  /// No description provided for @jobsColVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get jobsColVehicle;

  /// No description provided for @jobsColComplaint.
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get jobsColComplaint;

  /// No description provided for @jobsColMechanic.
  ///
  /// In en, this message translates to:
  /// **'Mechanic'**
  String get jobsColMechanic;

  /// No description provided for @jobsColAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get jobsColAmount;

  /// No description provided for @jobsColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get jobsColStatus;

  /// No description provided for @jobsColActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get jobsColActions;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @customersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get customersAdd;

  /// No description provided for @customersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone...'**
  String get customersSearchHint;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory Management'**
  String get inventoryTitle;

  /// No description provided for @inventoryAddPart.
  ///
  /// In en, this message translates to:
  /// **'Add Part'**
  String get inventoryAddPart;

  /// No description provided for @inventoryTabAll.
  ///
  /// In en, this message translates to:
  /// **'All Parts'**
  String get inventoryTabAll;

  /// No description provided for @inventoryTabLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get inventoryTabLowStock;

  /// No description provided for @inventorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search parts by name, category, or SKU...'**
  String get inventorySearchHint;

  /// No description provided for @inventoryColName.
  ///
  /// In en, this message translates to:
  /// **'Part Name'**
  String get inventoryColName;

  /// No description provided for @inventoryColSku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get inventoryColSku;

  /// No description provided for @inventoryColCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get inventoryColCategory;

  /// No description provided for @inventoryColPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get inventoryColPurchase;

  /// No description provided for @inventoryColSelling.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get inventoryColSelling;

  /// No description provided for @inventoryColStock.
  ///
  /// In en, this message translates to:
  /// **'Stock Qty'**
  String get inventoryColStock;

  /// No description provided for @inventoryColMinStock.
  ///
  /// In en, this message translates to:
  /// **'Min Stock'**
  String get inventoryColMinStock;

  /// No description provided for @inventoryColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get inventoryColStatus;

  /// No description provided for @inventoryColActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get inventoryColActions;

  /// No description provided for @inventoryDeletePart.
  ///
  /// In en, this message translates to:
  /// **'Delete Part'**
  String get inventoryDeletePart;

  /// No description provided for @inventoryDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Part?'**
  String get inventoryDeleteConfirmTitle;

  /// No description provided for @inventoryDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \'{name}\'? This action cannot be undone.'**
  String inventoryDeleteConfirmBody(String name);

  /// No description provided for @inventoryDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Part deleted successfully'**
  String get inventoryDeleteSuccess;

  /// No description provided for @inventoryDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete part'**
  String get inventoryDeleteError;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportsPeriodDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get reportsPeriodDaily;

  /// No description provided for @reportsPeriodWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get reportsPeriodWeekly;

  /// No description provided for @reportsPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get reportsPeriodMonthly;

  /// No description provided for @tabVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get tabVehicles;

  /// No description provided for @tabInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get tabInvoices;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
