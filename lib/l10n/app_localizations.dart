import 'package:flutter/material.dart';
import 'app_en.dart';
import 'app_sw.dart';

abstract class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Common
  String get appName;
  String get ok;
  String get cancel;
  String get yes;
  String get no;
  String get save;
  String get delete;
  String get edit;
  String get search;
  String get loading;
  String get error;
  String get success;
  
  // Login Screen
  String get welcomeBack;
  String get username;
  String get password;
  String get forgotPassword;
  String get login;
  String get dontHaveAccount;
  String get signUp;
  String get pleaseEnterCredentials;
  String get loginSuccess;
  
  // Registration
  String get createAccount;
  String get firstName;
  String get lastName;
  String get email;
  String get phoneNumber;
  String get confirmPassword;
  String get register;
  String get alreadyHaveAccount;
  
  // Profile Screen
  String get profile;
  String get myProfile;
  String get customerBooking;
  String get myBooking;
  String get changePassword;
  String get termsAndUse;
  String get privacyPolicy;
  String get aboutApp;
  String get helpSupport;
  String get logout;
  String get deleteAccount;
  String get subscriptionPayments;
  String get paymentHistory;
  String get myPostedProperties;
  String get language;
  String get selectLanguage;
  
  // Logout Dialog
  String get logoutTitle;
  String get logoutMessage;
  
  // Delete Account Dialog
  String get deleteAccountTitle;
  String get deleteAccountMessage;
  
  // Home Screen
  String get home;
  String get properties;
  String get favorites;
  String get bookings;
  String get notifications;
  
  // Property
  String get propertyDetails;
  String get location;
  String get price;
  String get bedrooms;
  String get bathrooms;
  String get area;
  String get description;
  String get amenities;
  String get bookNow;
  String get contactOwner;
  
  // Booking
  String get bookingDetails;
  String get checkIn;
  String get checkOut;
  String get guests;
  String get totalPrice;
  String get confirmBooking;
  String get bookingConfirmed;
  
  // Search
  String get searchProperties;
  String get filters;
  String get priceRange;
  String get propertyType;
  String get apply;
  String get reset;
  
  // Messages
  String get noPropertiesFound;
  String get noBookingsFound;
  String get noFavoritesFound;
  String get addedToFavorites;
  String get removedFromFavorites;
  
  // Change Password
  String get currentPassword;
  String get newPassword;
  String get confirmNewPassword;
  String get passwordChanged;
  
  // Validation
  String get fieldRequired;
  String get invalidEmail;
  String get passwordTooShort;
  String get passwordsDoNotMatch;
  
  // Registration Screen
  String get createAccountTitle;
  String get customer;
  String get broker;
  String get propertyOwner;
  String get serviceCharge;
  String get mobileNumber;
  String get gender;
  String get male;
  String get female;
  String get other;
  String get dateOfBirth;
  String get locationHint;
  String get acceptTerms;
  String get pleaseSelectUserType;
  String get passwordMustMatch;
  String get accountCreatedSuccess;
  
  // Home Screen
  String get shortStay;
  String get normalUpload;
  
  // Properties Screen
  String get allProperties;
  String get availableProperties;
  String get noPropertiesAvailable;
  String get forRent;
  String get forSale;
  String get airbnb;
  
  // Booking Screen
  String get myBookings;
  String get browseProperties;
  String get bookedOn;
  String get rented;
  String get sold;
  String get tryAgain;
  
  // Search Screen
  String get searchResults;
  String get searchHere;
  String get justNow;
  String get minutesAgo;
  String get hoursAgo;
  String get yesterday;
  String get daysAgo;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'sw'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'sw':
        return AppLocalizationsSw();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
