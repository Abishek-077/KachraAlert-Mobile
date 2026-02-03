import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('ne'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localization =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    return localization ?? AppLocalizations(const Locale('en'));
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'guestUser': 'Guest User',
      'notSignedIn': 'Not signed in',
      'topContributor': 'Top Contributor',
      'reports': 'Reports',
      'resolved': 'Resolved',
      'impact': 'Impact',
      'achievements': 'Achievements',
      'quickReporter': 'Quick Reporter',
      'reportsInWeek': '5 reports in a week',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'manageAlertPrefs': 'Manage alert preferences',
      'payments': 'Payments',
      'viewInvoices': 'View invoices and pay dues',
      'language': 'Language',
      'english': 'English',
      'nepali': 'Nepali',
      'privacy': 'Privacy',
      'dataPermissions': 'Data and permissions',
      'appearance': 'Appearance',
      'darkMode': 'Dark mode',
      'lightMode': 'Light mode',
      'helpSupport': 'Help & Support',
      'faqContact': 'FAQs and contact',
      'logout': 'Logout',
      'signOutDevice': 'Sign out of this device',
      'adminPanel': 'Admin Panel',
      'broadcastAnnouncements': 'Broadcast announcements',
      'languageSelectionTitle': 'Choose your language',
      'languageSelectionSubtitle': 'This updates the entire app experience.',
      'reportFiltersAll': 'All',
      'reportFiltersVerified': 'Verified',
      'reportFiltersInProgress': 'In Progress',
      'reportFiltersCleaned': 'Cleaned',
      'newReport': 'New Report',
      'failedLoadReports': 'Failed to load reports',
      'retry': 'Retry',
      'noReportsFound': 'No reports found',
      'createReportHint': 'Create a report to keep your neighborhood clean.',
      'reportWaste': 'Report Waste',
      'reportedBy': 'Reported by {name}',
      'communityMember': 'Community Member',
      'category': 'Category',
      'location': 'Location',
      'details': 'Details',
      'editReport': 'Edit Report',
      'newReportTitle': 'New Report',
      'close': 'Close',
      'chooseFromGallery': 'Choose from gallery',
      'takePhoto': 'Take a photo',
      'locationHint': 'e.g. Ward 10, Baneshwor',
      'detailsHint': 'Describe the issue (what, where, how urgent)',
      'addPhotoOptional': 'Add photo (optional)',
      'photoHelp': 'Attach an image to help the team verify the issue.',
      'attachedPhoto': 'Attached photo',
      'removeAttachment': 'Remove attachment',
      'saveChanges': 'Save Changes',
      'submitReport': 'Submit Report',
      'missedPickup': 'Missed Pickup',
      'overflowingBin': 'Overflowing Bin',
      'badSmell': 'Bad Smell',
      'other': 'Other',
      'reportId': 'RPT-{id}',
      'reportCreated': 'Report created successfully',
      'reportUpdated': 'Report updated successfully',
      'mustLoginReport': 'You must be logged in to create a report',
      'locationMessageRequired': 'Location and message are required',
      'reportSaveFailed': 'Failed to save report: {error}',
      'topContributorTitle': 'Top 10% this month',
      'reported': 'Reported',
      'signInToUpdatePhoto': 'Please sign in to update your photo.',
      'profilePhotoUpdated': 'Profile photo updated.',
      'profilePhotoUpdateFailed': 'Failed to update profile photo: {error}',
    },
    'ne': {
      'guestUser': 'अतिथि प्रयोगकर्ता',
      'notSignedIn': 'साइन इन गरिएको छैन',
      'topContributor': 'शीर्ष योगदानकर्ता',
      'reports': 'रिपोर्टहरू',
      'resolved': 'समाधान भएका',
      'impact': 'प्रभाव',
      'achievements': 'उपलब्धिहरू',
      'quickReporter': 'छिटो रिपोर्टर',
      'reportsInWeek': 'एक हप्तामा ५ रिपोर्ट',
      'settings': 'सेटिङहरू',
      'notifications': 'सूचनाहरू',
      'manageAlertPrefs': 'अलर्ट प्राथमिकता व्यवस्थापन गर्नुहोस्',
      'payments': 'भुक्तानीहरू',
      'viewInvoices': 'चलानी हेर्नुहोस् र तिर्नुहोस्',
      'language': 'भाषा',
      'english': 'अङ्ग्रेजी',
      'nepali': 'नेपाली',
      'privacy': 'गोपनीयता',
      'dataPermissions': 'डाटा र अनुमति',
      'appearance': 'रूप',
      'darkMode': 'डार्क मोड',
      'lightMode': 'लाइट मोड',
      'helpSupport': 'सहायता र समर्थन',
      'faqContact': 'प्रश्नोत्तर र सम्पर्क',
      'logout': 'लगआउट',
      'signOutDevice': 'यस उपकरणबाट साइन आउट',
      'adminPanel': 'प्रशासक प्यानल',
      'broadcastAnnouncements': 'घोषणाहरू प्रसारण गर्नुहोस्',
      'languageSelectionTitle': 'आफ्नो भाषा छान्नुहोस्',
      'languageSelectionSubtitle': 'यसले सम्पूर्ण एप अनुभव अपडेट गर्छ।',
      'reportFiltersAll': 'सबै',
      'reportFiltersVerified': 'प्रमाणित',
      'reportFiltersInProgress': 'प्रगति हुँदै',
      'reportFiltersCleaned': 'सफा गरिएको',
      'newReport': 'नयाँ रिपोर्ट',
      'failedLoadReports': 'रिपोर्टहरू लोड गर्न असफल',
      'retry': 'फेरि प्रयास गर्नुहोस्',
      'noReportsFound': 'कुनै रिपोर्ट भेटिएन',
      'createReportHint': 'आफ्नो छिमेक सफा राख्न रिपोर्ट गर्नुहोस्।',
      'reportWaste': 'फोहोर रिपोर्ट गर्नुहोस्',
      'reportedBy': '{name} द्वारा रिपोर्ट गरिएको',
      'communityMember': 'समुदाय सदस्य',
      'category': 'श्रेणी',
      'location': 'स्थान',
      'details': 'विवरण',
      'editReport': 'रिपोर्ट सम्पादन',
      'newReportTitle': 'नयाँ रिपोर्ट',
      'close': 'बन्द गर्नुहोस्',
      'chooseFromGallery': 'ग्यालेरीबाट छान्नुहोस्',
      'takePhoto': 'फोटो खिच्नुहोस्',
      'locationHint': 'उदाहरण: वडा १०, बानेश्वर',
      'detailsHint': 'समस्या वर्णन गर्नुहोस् (के, कहाँ, कति तत्काल)',
      'addPhotoOptional': 'फोटो थप्नुहोस् (ऐच्छिक)',
      'photoHelp': 'समस्या पुष्टि गर्न फोटो संलग्न गर्नुहोस्।',
      'attachedPhoto': 'संलग्न फोटो',
      'removeAttachment': 'संलग्न हटाउनुहोस्',
      'saveChanges': 'परिवर्तन सुरक्षित गर्नुहोस्',
      'submitReport': 'रिपोर्ट पठाउनुहोस्',
      'missedPickup': 'कुहिने सङ्कलन छुट्यो',
      'overflowingBin': 'भरिएको डस्टबिन',
      'badSmell': 'दुर्गन्ध',
      'other': 'अन्य',
      'reportId': 'आरपीटी-{id}',
      'reportCreated': 'रिपोर्ट सफलतापूर्वक बनाइयो',
      'reportUpdated': 'रिपोर्ट सफलतापूर्वक अपडेट भयो',
      'mustLoginReport': 'रिपोर्ट बनाउन पहिले लगइन गर्नुहोस्',
      'locationMessageRequired': 'स्थान र विवरण आवश्यक छन्',
      'reportSaveFailed': 'रिपोर्ट सुरक्षित गर्न असफल: {error}',
      'topContributorTitle': 'यस महिनाको शीर्ष १०%',
      'reported': 'रिपोर्ट गरिएको',
      'signInToUpdatePhoto': 'फोटो अपडेट गर्न कृपया लगइन गर्नुहोस्।',
      'profilePhotoUpdated': 'प्रोफाइल फोटो अपडेट भयो।',
      'profilePhotoUpdateFailed': 'प्रोफाइल फोटो अपडेट गर्न असफल: {error}',
    },
  };

  String _value(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }

  String get guestUser => _value('guestUser');
  String get notSignedIn => _value('notSignedIn');
  String get topContributor => _value('topContributor');
  String get reports => _value('reports');
  String get resolved => _value('resolved');
  String get impact => _value('impact');
  String get achievements => _value('achievements');
  String get quickReporter => _value('quickReporter');
  String get reportsInWeek => _value('reportsInWeek');
  String get settings => _value('settings');
  String get notifications => _value('notifications');
  String get manageAlertPrefs => _value('manageAlertPrefs');
  String get payments => _value('payments');
  String get viewInvoices => _value('viewInvoices');
  String get language => _value('language');
  String get english => _value('english');
  String get nepali => _value('nepali');
  String get privacy => _value('privacy');
  String get dataPermissions => _value('dataPermissions');
  String get appearance => _value('appearance');
  String get darkMode => _value('darkMode');
  String get lightMode => _value('lightMode');
  String get helpSupport => _value('helpSupport');
  String get faqContact => _value('faqContact');
  String get logout => _value('logout');
  String get signOutDevice => _value('signOutDevice');
  String get adminPanel => _value('adminPanel');
  String get broadcastAnnouncements => _value('broadcastAnnouncements');
  String get languageSelectionTitle => _value('languageSelectionTitle');
  String get languageSelectionSubtitle => _value('languageSelectionSubtitle');
  String get reportFiltersAll => _value('reportFiltersAll');
  String get reportFiltersVerified => _value('reportFiltersVerified');
  String get reportFiltersInProgress => _value('reportFiltersInProgress');
  String get reportFiltersCleaned => _value('reportFiltersCleaned');
  String get newReport => _value('newReport');
  String get failedLoadReports => _value('failedLoadReports');
  String get retry => _value('retry');
  String get noReportsFound => _value('noReportsFound');
  String get createReportHint => _value('createReportHint');
  String get reportWaste => _value('reportWaste');
  String get communityMember => _value('communityMember');
  String get category => _value('category');
  String get location => _value('location');
  String get details => _value('details');
  String get editReport => _value('editReport');
  String get newReportTitle => _value('newReportTitle');
  String get close => _value('close');
  String get chooseFromGallery => _value('chooseFromGallery');
  String get takePhoto => _value('takePhoto');
  String get locationHint => _value('locationHint');
  String get detailsHint => _value('detailsHint');
  String get addPhotoOptional => _value('addPhotoOptional');
  String get photoHelp => _value('photoHelp');
  String get attachedPhoto => _value('attachedPhoto');
  String get removeAttachment => _value('removeAttachment');
  String get saveChanges => _value('saveChanges');
  String get submitReport => _value('submitReport');
  String get missedPickup => _value('missedPickup');
  String get overflowingBin => _value('overflowingBin');
  String get badSmell => _value('badSmell');
  String get other => _value('other');
  String get reportCreated => _value('reportCreated');
  String get reportUpdated => _value('reportUpdated');
  String get mustLoginReport => _value('mustLoginReport');
  String get locationMessageRequired => _value('locationMessageRequired');
  String get topContributorTitle => _value('topContributorTitle');
  String get reported => _value('reported');
  String get signInToUpdatePhoto => _value('signInToUpdatePhoto');
  String get profilePhotoUpdated => _value('profilePhotoUpdated');

  String reportedBy(String name) =>
      _value('reportedBy').replaceAll('{name}', name);

  String reportId(String id) => _value('reportId').replaceAll('{id}', id);

  String reportSaveFailed(String error) =>
      _value('reportSaveFailed').replaceAll('{error}', error);

  String profilePhotoUpdateFailed(String error) =>
      _value('profilePhotoUpdateFailed').replaceAll('{error}', error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
