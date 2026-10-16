import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('es')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Fox Passport'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @loginHint.
  ///
  /// In en, this message translates to:
  /// **'Hint: any email + password of 6+ chars'**
  String get loginHint;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @tickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get tickets;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @passport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @authWordmark.
  ///
  /// In en, this message translates to:
  /// **'FoxPassport'**
  String get authWordmark;

  /// No description provided for @authEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmailAddress;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullName;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get authContinueWithFacebook;

  /// No description provided for @homeHeroKickerUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String homeHeroKickerUser(String name);

  /// No description provided for @homeHeroKickerGuest.
  ///
  /// In en, this message translates to:
  /// **'FoxPassport · Book any event'**
  String get homeHeroKickerGuest;

  /// No description provided for @homeHeroBookThe.
  ///
  /// In en, this message translates to:
  /// **'Book the'**
  String get homeHeroBookThe;

  /// No description provided for @homeHeroNight.
  ///
  /// In en, this message translates to:
  /// **'night'**
  String get homeHeroNight;

  /// No description provided for @homeHeroAnywhere.
  ///
  /// In en, this message translates to:
  /// **'anywhere.'**
  String get homeHeroAnywhere;

  /// No description provided for @homeHeroBody.
  ///
  /// In en, this message translates to:
  /// **'The venue, the gear and the crew for any night, in one booking.'**
  String get homeHeroBody;

  /// No description provided for @homeSearchWhat.
  ///
  /// In en, this message translates to:
  /// **'What'**
  String get homeSearchWhat;

  /// No description provided for @homeSearchWhere.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get homeSearchWhere;

  /// No description provided for @homeSearchWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get homeSearchWhen;

  /// No description provided for @homeSearchAnyEvent.
  ///
  /// In en, this message translates to:
  /// **'Any event'**
  String get homeSearchAnyEvent;

  /// No description provided for @homeSearchAnyCity.
  ///
  /// In en, this message translates to:
  /// **'Any city'**
  String get homeSearchAnyCity;

  /// No description provided for @homeSearchAnyDate.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get homeSearchAnyDate;

  /// No description provided for @homeSearchFind.
  ///
  /// In en, this message translates to:
  /// **'Find events'**
  String get homeSearchFind;

  /// No description provided for @homeSearchCityHint.
  ///
  /// In en, this message translates to:
  /// **'Type a city'**
  String get homeSearchCityHint;

  /// No description provided for @homeEventWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get homeEventWedding;

  /// No description provided for @homeEventBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get homeEventBirthday;

  /// No description provided for @homeEventCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get homeEventCorporate;

  /// No description provided for @homeEventSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get homeEventSocial;

  /// No description provided for @homeEventOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get homeEventOther;

  /// No description provided for @welcomeSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get welcomeSkip;

  /// No description provided for @welcomeBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get welcomeBackAction;

  /// No description provided for @welcomeHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get welcomeHaveAccount;

  /// No description provided for @welcomeRoleEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get welcomeRoleEvent;

  /// No description provided for @welcomeRoleVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get welcomeRoleVenue;

  /// No description provided for @welcomeRoleGear.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get welcomeRoleGear;

  /// No description provided for @welcomeRoleTalent.
  ///
  /// In en, this message translates to:
  /// **'Talent'**
  String get welcomeRoleTalent;

  /// No description provided for @welcomeRolePerformer.
  ///
  /// In en, this message translates to:
  /// **'Performer'**
  String get welcomeRolePerformer;

  /// No description provided for @welcome1Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'FoxPassport'**
  String get welcome1Eyebrow;

  /// No description provided for @welcome1Headline.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FoxPassport'**
  String get welcome1Headline;

  /// No description provided for @welcome1Body.
  ///
  /// In en, this message translates to:
  /// **'Plan, book and live unforgettable events — and meet the people who make them happen.'**
  String get welcome1Body;

  /// No description provided for @welcome1Button.
  ///
  /// In en, this message translates to:
  /// **'Show me around'**
  String get welcome1Button;

  /// No description provided for @welcome2Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get welcome2Eyebrow;

  /// No description provided for @welcome2Headline.
  ///
  /// In en, this message translates to:
  /// **'Discover experiences'**
  String get welcome2Headline;

  /// No description provided for @welcome2Body.
  ///
  /// In en, this message translates to:
  /// **'Browse trending events, venues, gear and talent near you. Filter by vibe — birthdays, weddings, corporate nights and more.'**
  String get welcome2Body;

  /// No description provided for @welcome2Button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get welcome2Button;

  /// No description provided for @welcome3Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Foxers'**
  String get welcome3Eyebrow;

  /// No description provided for @welcome3Headline.
  ///
  /// In en, this message translates to:
  /// **'Book Foxers in one place'**
  String get welcome3Headline;

  /// No description provided for @welcome3Body.
  ///
  /// In en, this message translates to:
  /// **'Foxers are the verified pros behind every event. See their real availability, book them directly and pay securely.'**
  String get welcome3Body;

  /// No description provided for @welcome3Button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get welcome3Button;

  /// No description provided for @welcome4Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get welcome4Eyebrow;

  /// No description provided for @welcome4Headline.
  ///
  /// In en, this message translates to:
  /// **'Stamp your passport'**
  String get welcome4Headline;

  /// No description provided for @welcome4Body.
  ///
  /// In en, this message translates to:
  /// **'Every event you attend earns stamps, badges and levels on your digital FoxPassport.'**
  String get welcome4Body;

  /// No description provided for @welcome4Button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get welcome4Button;

  /// No description provided for @welcome5Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Republic'**
  String get welcome5Eyebrow;

  /// No description provided for @welcome5Headline.
  ///
  /// In en, this message translates to:
  /// **'Join the Republic'**
  String get welcome5Headline;

  /// No description provided for @welcome5Body.
  ///
  /// In en, this message translates to:
  /// **'Follow friends, post to the feed, chat with hosts and match with Foxers who fit your plans.'**
  String get welcome5Body;

  /// No description provided for @welcome5Button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get welcome5Button;

  /// No description provided for @welcome6Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcome6Eyebrow;

  /// No description provided for @welcome6Headline.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are'**
  String get welcome6Headline;

  /// No description provided for @welcome6Body.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to book and earn stamps. Want to earn instead? Apply as a Foxer once you\'re signed up.'**
  String get welcome6Body;

  /// No description provided for @welcome6Button.
  ///
  /// In en, this message translates to:
  /// **'Create a free account'**
  String get welcome6Button;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authAppleSoon.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple is coming soon.'**
  String get authAppleSoon;

  /// No description provided for @authSocialUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google and Facebook sign-in are available in the mobile app.'**
  String get authSocialUnavailable;

  /// No description provided for @authUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsername;

  /// No description provided for @registerTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the'**
  String get registerTermsPrefix;

  /// No description provided for @registerTermsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get registerTermsLink;

  /// No description provided for @registerTermsAnd.
  ///
  /// In en, this message translates to:
  /// **'&'**
  String get registerTermsAnd;

  /// No description provided for @registerPrivacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get registerPrivacyLink;

  /// No description provided for @registerTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms of Service and Privacy Policy to continue'**
  String get registerTermsRequired;

  /// No description provided for @registerLegalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The Terms and Privacy Policy open on the FoxPassport web app, which is not configured yet.'**
  String get registerLegalUnavailable;

  /// No description provided for @loginEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginEyebrow;

  /// No description provided for @loginHeadline.
  ///
  /// In en, this message translates to:
  /// **'Log in to your account'**
  String get loginHeadline;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginNewHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get loginNewHere;

  /// No description provided for @loginCreateAccountLink.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get loginCreateAccountLink;

  /// No description provided for @registerEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Free to join'**
  String get registerEyebrow;

  /// No description provided for @registerHeadline.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerHeadline;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerButton;

  /// No description provided for @registerConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get registerConfirmPassword;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerHaveAccount;

  /// No description provided for @registerLoginLink.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get registerLoginLink;

  /// No description provided for @verifyEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get verifyEyebrow;

  /// No description provided for @verifyHeadline.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyHeadline;

  /// No description provided for @verifyBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {email}'**
  String verifyBody(String email);

  /// No description provided for @verifyBodyNoEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we emailed you'**
  String get verifyBodyNoEmail;

  /// No description provided for @verifyCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verifyCodeHint;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @verifyResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get verifyResend;

  /// No description provided for @verifyResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String verifyResendIn(int seconds);

  /// No description provided for @forgotEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Account recovery'**
  String get forgotEyebrow;

  /// No description provided for @forgotHeadline.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotHeadline;

  /// No description provided for @forgotBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a reset code'**
  String get forgotBody;

  /// No description provided for @forgotButton.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get forgotButton;

  /// No description provided for @resetEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Almost done'**
  String get resetEyebrow;

  /// No description provided for @resetHeadline.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetHeadline;

  /// No description provided for @resetBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your email and choose a new password'**
  String get resetBody;

  /// No description provided for @resetCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Reset code'**
  String get resetCodeHint;

  /// No description provided for @resetNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetNewPassword;

  /// No description provided for @resetConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get resetConfirmPassword;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get resetButton;

  /// No description provided for @onboardingWebNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'This opens on the FoxPassport web app, which is not configured yet.'**
  String get onboardingWebNotConfigured;

  /// No description provided for @onboardingFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get onboardingFriend;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, '**
  String get onboardingWelcome;

  /// No description provided for @onboardingBackAgain.
  ///
  /// In en, this message translates to:
  /// **'Back again, '**
  String get onboardingBackAgain;

  /// No description provided for @onboardingProfileSubtitleReturning.
  ///
  /// In en, this message translates to:
  /// **'Update your profile or continue to manage your roles.'**
  String get onboardingProfileSubtitleReturning;

  /// No description provided for @onboardingProfileSubtitleNew.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your profile first.'**
  String get onboardingProfileSubtitleNew;

  /// No description provided for @onboardingDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get onboardingDisplayName;

  /// No description provided for @onboardingDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'How others will see you'**
  String get onboardingDisplayNameHint;

  /// No description provided for @onboardingYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Your address'**
  String get onboardingYourAddress;

  /// No description provided for @onboardingAddressHelp.
  ///
  /// In en, this message translates to:
  /// **'Used to show you events, venues and Foxers near you.'**
  String get onboardingAddressHelp;

  /// No description provided for @onboardingCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get onboardingCountry;

  /// No description provided for @onboardingStateProvince.
  ///
  /// In en, this message translates to:
  /// **'State / Province'**
  String get onboardingStateProvince;

  /// No description provided for @onboardingCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get onboardingCity;

  /// No description provided for @onboardingLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get onboardingLoading;

  /// No description provided for @onboardingSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select country…'**
  String get onboardingSelectCountry;

  /// No description provided for @onboardingSearchCountries.
  ///
  /// In en, this message translates to:
  /// **'Search countries…'**
  String get onboardingSearchCountries;

  /// No description provided for @onboardingSelectCountryFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a country first'**
  String get onboardingSelectCountryFirst;

  /// No description provided for @onboardingSelectState.
  ///
  /// In en, this message translates to:
  /// **'Select state…'**
  String get onboardingSelectState;

  /// No description provided for @onboardingNoStates.
  ///
  /// In en, this message translates to:
  /// **'No states here'**
  String get onboardingNoStates;

  /// No description provided for @onboardingSearchStates.
  ///
  /// In en, this message translates to:
  /// **'Search states…'**
  String get onboardingSearchStates;

  /// No description provided for @onboardingSelectStateFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a state first'**
  String get onboardingSelectStateFirst;

  /// No description provided for @onboardingSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Select city…'**
  String get onboardingSelectCity;

  /// No description provided for @onboardingSearchCities.
  ///
  /// In en, this message translates to:
  /// **'Search cities…'**
  String get onboardingSearchCities;

  /// No description provided for @onboardingSelectCityFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a city first'**
  String get onboardingSelectCityFirst;

  /// No description provided for @onboardingDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get onboardingDistrict;

  /// No description provided for @onboardingBarangay.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get onboardingBarangay;

  /// No description provided for @onboardingOptional.
  ///
  /// In en, this message translates to:
  /// **'— optional'**
  String get onboardingOptional;

  /// No description provided for @onboardingYourDistrict.
  ///
  /// In en, this message translates to:
  /// **'Your {label}'**
  String onboardingYourDistrict(String label);

  /// No description provided for @onboardingAddMissing.
  ///
  /// In en, this message translates to:
  /// **'Add your {fields} to continue.'**
  String onboardingAddMissing(String fields);

  /// No description provided for @onboardingFieldName.
  ///
  /// In en, this message translates to:
  /// **'display name'**
  String get onboardingFieldName;

  /// No description provided for @onboardingFieldCountry.
  ///
  /// In en, this message translates to:
  /// **'country'**
  String get onboardingFieldCountry;

  /// No description provided for @onboardingFieldCity.
  ///
  /// In en, this message translates to:
  /// **'city'**
  String get onboardingFieldCity;

  /// No description provided for @onboardingSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get onboardingSaving;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingIntentTitle.
  ///
  /// In en, this message translates to:
  /// **'What brings you here?'**
  String get onboardingIntentTitle;

  /// No description provided for @onboardingIntentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you plan to use FoxPassport.'**
  String get onboardingIntentSubtitle;

  /// No description provided for @onboardingIntentBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Events'**
  String get onboardingIntentBookTitle;

  /// No description provided for @onboardingIntentBookBody.
  ///
  /// In en, this message translates to:
  /// **'Browse foxers, venues, and services to create your perfect event.'**
  String get onboardingIntentBookBody;

  /// No description provided for @onboardingIntentFoxerTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a Foxer'**
  String get onboardingIntentFoxerTitle;

  /// No description provided for @onboardingIntentFoxerBody.
  ///
  /// In en, this message translates to:
  /// **'Offer services, rent gear, list venues, or create events professionally.'**
  String get onboardingIntentFoxerBody;

  /// No description provided for @onboardingIntentBothTitle.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get onboardingIntentBothTitle;

  /// No description provided for @onboardingIntentBothBody.
  ///
  /// In en, this message translates to:
  /// **'Book events and apply to become a Foxer in the ecosystem.'**
  String get onboardingIntentBothBody;

  /// No description provided for @onboardingRolesTitleHeld.
  ///
  /// In en, this message translates to:
  /// **'Your roles'**
  String get onboardingRolesTitleHeld;

  /// No description provided for @onboardingRolesTitlePending.
  ///
  /// In en, this message translates to:
  /// **'Application submitted'**
  String get onboardingRolesTitlePending;

  /// No description provided for @onboardingRolesTitleChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose your role'**
  String get onboardingRolesTitleChoose;

  /// No description provided for @onboardingRolesSubtitleHeld.
  ///
  /// In en, this message translates to:
  /// **'Active roles are shown below. Apply for additional roles anytime.'**
  String get onboardingRolesSubtitleHeld;

  /// No description provided for @onboardingRolesSubtitlePending.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing your application. You\'ll be notified once approved.'**
  String get onboardingRolesSubtitlePending;

  /// No description provided for @onboardingRolesSubtitleChoose.
  ///
  /// In en, this message translates to:
  /// **'Select how you want to contribute. You can hold multiple roles over time.'**
  String get onboardingRolesSubtitleChoose;

  /// No description provided for @onboardingFinishDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get onboardingFinishDashboard;

  /// No description provided for @onboardingFinishHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get onboardingFinishHome;

  /// No description provided for @onboardingFinishSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboardingFinishSkip;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingStepProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get onboardingStepProfile;

  /// No description provided for @onboardingStepInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get onboardingStepInterests;

  /// No description provided for @onboardingStepRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get onboardingStepRoles;

  /// No description provided for @onboardingStepSemantic.
  ///
  /// In en, this message translates to:
  /// **'Step {number}: {label}'**
  String onboardingStepSemantic(int number, String label);

  /// No description provided for @onboardingStatusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get onboardingStatusActive;

  /// No description provided for @onboardingStatusReview.
  ///
  /// In en, this message translates to:
  /// **'UNDER REVIEW'**
  String get onboardingStatusReview;

  /// No description provided for @onboardingStatusRevision.
  ///
  /// In en, this message translates to:
  /// **'NEEDS REVISION'**
  String get onboardingStatusRevision;

  /// No description provided for @onboardingRevisionCaption.
  ///
  /// In en, this message translates to:
  /// **'One or more documents were flagged — tap to fix and resubmit.'**
  String get onboardingRevisionCaption;

  /// No description provided for @onboardingLearnApply.
  ///
  /// In en, this message translates to:
  /// **'Learn more & apply'**
  String get onboardingLearnApply;

  /// No description provided for @onboardingUseQuery.
  ///
  /// In en, this message translates to:
  /// **'Use \"{query}\"'**
  String onboardingUseQuery(String query);

  /// No description provided for @onboardingNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get onboardingNoMatches;

  /// No description provided for @onboardingWhatYoullDo.
  ///
  /// In en, this message translates to:
  /// **'What you\'ll do'**
  String get onboardingWhatYoullDo;

  /// No description provided for @onboardingWhatYoullNeed.
  ///
  /// In en, this message translates to:
  /// **'What you\'ll need to apply'**
  String get onboardingWhatYoullNeed;

  /// No description provided for @onboardingReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Our team reviews every application. If a document needs fixing, we\'ll flag just that one so you can resubmit it.'**
  String get onboardingReviewNote;

  /// No description provided for @onboardingNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingNotNow;

  /// No description provided for @onboardingContinueApplication.
  ///
  /// In en, this message translates to:
  /// **'Continue to application'**
  String get onboardingContinueApplication;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @sampleTag.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get sampleTag;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @homeYourNextNight.
  ///
  /// In en, this message translates to:
  /// **'Your next night'**
  String get homeYourNextNight;

  /// No description provided for @homeOpenTicket.
  ///
  /// In en, this message translates to:
  /// **'Open ticket'**
  String get homeOpenTicket;

  /// No description provided for @homeTileVenues.
  ///
  /// In en, this message translates to:
  /// **'Venues'**
  String get homeTileVenues;

  /// No description provided for @homeTileFoxers.
  ///
  /// In en, this message translates to:
  /// **'Foxers'**
  String get homeTileFoxers;

  /// No description provided for @homeTileGear.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get homeTileGear;

  /// No description provided for @homeTileMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get homeTileMap;

  /// No description provided for @homePickedForYou.
  ///
  /// In en, this message translates to:
  /// **'Picked for you'**
  String get homePickedForYou;

  /// No description provided for @homeLocationChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose location'**
  String get homeLocationChoose;

  /// No description provided for @homeLocationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Location selection is coming soon.'**
  String get homeLocationComingSoon;

  /// No description provided for @homeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No listings found yet.'**
  String get homeNoResults;

  /// No description provided for @homeSearchPlanning.
  ///
  /// In en, this message translates to:
  /// **'What are you planning?'**
  String get homeSearchPlanning;

  /// No description provided for @homeVenuesNear.
  ///
  /// In en, this message translates to:
  /// **'Venues near you'**
  String get homeVenuesNear;

  /// No description provided for @homeFoxersForNight.
  ///
  /// In en, this message translates to:
  /// **'Foxers for your night'**
  String get homeFoxersForNight;

  /// No description provided for @ticketToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get ticketToday;

  /// No description provided for @ticketTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get ticketTomorrow;

  /// No description provided for @ticketInDays.
  ///
  /// In en, this message translates to:
  /// **'In {count, plural, =1{1 day} other{{count} days}}'**
  String ticketInDays(int count);

  /// No description provided for @priceUnitHour.
  ///
  /// In en, this message translates to:
  /// **'hr'**
  String get priceUnitHour;

  /// No description provided for @priceUnitNight.
  ///
  /// In en, this message translates to:
  /// **'night'**
  String get priceUnitNight;

  /// No description provided for @priceUnitWeek.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get priceUnitWeek;

  /// No description provided for @priceUnitMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get priceUnitMonth;

  /// No description provided for @priceUnitYear.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get priceUnitYear;

  /// No description provided for @guestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 guest} other{{count} guests}}'**
  String guestsCount(int count);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search FoxPassport'**
  String get searchHint;

  /// No description provided for @searchEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get searchEvents;

  /// No description provided for @searchVenues.
  ///
  /// In en, this message translates to:
  /// **'Venues'**
  String get searchVenues;

  /// No description provided for @searchFoxers.
  ///
  /// In en, this message translates to:
  /// **'Foxers'**
  String get searchFoxers;

  /// No description provided for @searchGear.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get searchGear;

  /// No description provided for @searchServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get searchServices;

  /// No description provided for @searchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches “{query}”'**
  String searchNoMatches(String query);

  /// No description provided for @searchMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get searchMap;

  /// No description provided for @searchFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get searchFilters;

  /// No description provided for @searchFilterCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get searchFilterCity;

  /// No description provided for @searchFilterMinPrice.
  ///
  /// In en, this message translates to:
  /// **'Minimum price'**
  String get searchFilterMinPrice;

  /// No description provided for @searchFilterMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Maximum price'**
  String get searchFilterMaxPrice;

  /// No description provided for @searchFilterMinCapacity.
  ///
  /// In en, this message translates to:
  /// **'Minimum guests'**
  String get searchFilterMinCapacity;

  /// No description provided for @searchChooseDates.
  ///
  /// In en, this message translates to:
  /// **'Choose date range'**
  String get searchChooseDates;

  /// No description provided for @searchSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get searchSortBy;

  /// No description provided for @searchSortRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get searchSortRecommended;

  /// No description provided for @searchSortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get searchSortPriceLow;

  /// No description provided for @searchSortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get searchSortPriceHigh;

  /// No description provided for @searchSortDateSoonest.
  ///
  /// In en, this message translates to:
  /// **'Date: soonest'**
  String get searchSortDateSoonest;

  /// No description provided for @searchSortDateLatest.
  ///
  /// In en, this message translates to:
  /// **'Date: latest'**
  String get searchSortDateLatest;

  /// No description provided for @searchClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get searchClearFilters;

  /// No description provided for @searchApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get searchApplyFilters;

  /// No description provided for @searchInvalidFilter.
  ///
  /// In en, this message translates to:
  /// **'Check the price and guest filters.'**
  String get searchInvalidFilter;

  /// No description provided for @searchEventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event details'**
  String get searchEventDetails;

  /// No description provided for @searchEventDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get searchEventDate;

  /// No description provided for @searchEventLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get searchEventLocation;

  /// No description provided for @searchEventGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get searchEventGuests;

  /// No description provided for @searchEventPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get searchEventPrice;

  /// No description provided for @searchNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get searchNew;

  /// No description provided for @searchSaveItem.
  ///
  /// In en, this message translates to:
  /// **'Save item'**
  String get searchSaveItem;

  /// No description provided for @searchRemoveSavedItem.
  ///
  /// In en, this message translates to:
  /// **'Remove saved item'**
  String get searchRemoveSavedItem;

  /// No description provided for @messageFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get messageFilterAll;

  /// No description provided for @messageFilterBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get messageFilterBookings;

  /// No description provided for @messageFilterGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get messageFilterGroups;

  /// No description provided for @messageFilterRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get messageFilterRequests;

  /// No description provided for @messagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your conversations will show up here.'**
  String get messagesEmpty;

  /// No description provided for @messagesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load messages.'**
  String get messagesLoadFailed;

  /// No description provided for @messageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get messageSearchHint;

  /// No description provided for @messageNew.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get messageNew;

  /// No description provided for @messageRequestAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get messageRequestAccept;

  /// No description provided for @messageRequestDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get messageRequestDecline;

  /// No description provided for @messageTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get messageTypeHint;

  /// No description provided for @messageViewTicket.
  ///
  /// In en, this message translates to:
  /// **'View ticket'**
  String get messageViewTicket;

  /// No description provided for @messageBookingAbout.
  ///
  /// In en, this message translates to:
  /// **'About this booking'**
  String get messageBookingAbout;

  /// No description provided for @messageSend.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get messageSend;

  /// No description provided for @messageRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Message request accepted.'**
  String get messageRequestAccepted;

  /// No description provided for @messageRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Message request declined.'**
  String get messageRequestDeclined;

  /// No description provided for @messageActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation from a Foxer or venue profile.'**
  String get messageActionUnavailable;

  /// No description provided for @messageVenueInbox.
  ///
  /// In en, this message translates to:
  /// **'Venue inbox'**
  String get messageVenueInbox;

  /// No description provided for @messageEventInbox.
  ///
  /// In en, this message translates to:
  /// **'Event inbox'**
  String get messageEventInbox;

  /// No description provided for @messageRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Message request'**
  String get messageRequestPending;

  /// No description provided for @messageSearchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Search within conversations is not available yet.'**
  String get messageSearchUnavailable;

  /// No description provided for @messageOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get messageOnline;

  /// No description provided for @messageSeen.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get messageSeen;

  /// No description provided for @messageRoleEventFoxer.
  ///
  /// In en, this message translates to:
  /// **'Event Foxer'**
  String get messageRoleEventFoxer;

  /// No description provided for @messageRoleVenueFoxer.
  ///
  /// In en, this message translates to:
  /// **'Venue Foxer'**
  String get messageRoleVenueFoxer;

  /// No description provided for @messageRoleGearFoxer.
  ///
  /// In en, this message translates to:
  /// **'Gear Foxer'**
  String get messageRoleGearFoxer;

  /// No description provided for @messageRoleServiceFoxer.
  ///
  /// In en, this message translates to:
  /// **'Service Foxer'**
  String get messageRoleServiceFoxer;

  /// No description provided for @messageRolePerformer.
  ///
  /// In en, this message translates to:
  /// **'Performer'**
  String get messageRolePerformer;

  /// No description provided for @priceUnitDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get priceUnitDay;

  /// No description provided for @comingSoonFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters are coming soon'**
  String get comingSoonFilters;

  /// No description provided for @comingSoonDetails.
  ///
  /// In en, this message translates to:
  /// **'Details are coming soon'**
  String get comingSoonDetails;

  /// No description provided for @comingSoonMap.
  ///
  /// In en, this message translates to:
  /// **'The map is coming soon'**
  String get comingSoonMap;

  /// No description provided for @comingSoonWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet passes are coming soon'**
  String get comingSoonWallet;

  /// No description provided for @comingSoonLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'The leaderboard is coming soon'**
  String get comingSoonLeaderboard;

  /// No description provided for @ticketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get ticketsTitle;

  /// No description provided for @ticketsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get ticketsUpcoming;

  /// No description provided for @ticketsPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get ticketsPast;

  /// No description provided for @ticketsEmptyUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming tickets yet'**
  String get ticketsEmptyUpcoming;

  /// No description provided for @ticketsEmptyPast.
  ///
  /// In en, this message translates to:
  /// **'No past tickets yet'**
  String get ticketsEmptyPast;

  /// No description provided for @apiLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this right now.'**
  String get apiLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @ticketDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get ticketDate;

  /// No description provided for @ticketDoors.
  ///
  /// In en, this message translates to:
  /// **'Doors'**
  String get ticketDoors;

  /// No description provided for @ticketGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get ticketGuests;

  /// No description provided for @ticketAddToWallet.
  ///
  /// In en, this message translates to:
  /// **'Add to wallet'**
  String get ticketAddToWallet;

  /// No description provided for @ticketDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get ticketDirections;

  /// No description provided for @ticketStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get ticketStatusConfirmed;

  /// No description provided for @ticketStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get ticketStatusPending;

  /// No description provided for @ticketStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ticketStatusCompleted;

  /// No description provided for @ticketStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ticketStatusCancelled;

  /// No description provided for @passportTitle.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passportTitle;

  /// No description provided for @passportRepublic.
  ///
  /// In en, this message translates to:
  /// **'Republic of Foxers'**
  String get passportRepublic;

  /// No description provided for @passportCitizenLevel.
  ///
  /// In en, this message translates to:
  /// **'Citizen · Level {level}'**
  String passportCitizenLevel(int level);

  /// No description provided for @passportXp.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String passportXp(int xp);

  /// No description provided for @passportNextLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level} at {xp}'**
  String passportNextLevel(int level, int xp);

  /// No description provided for @passportStamps.
  ///
  /// In en, this message translates to:
  /// **'Stamps'**
  String get passportStamps;

  /// No description provided for @passportStampsCount.
  ///
  /// In en, this message translates to:
  /// **'{have} of {total}'**
  String passportStampsCount(int have, int total);

  /// No description provided for @passportBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get passportBadges;

  /// No description provided for @passportLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get passportLeaderboard;

  /// No description provided for @passportLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get passportLocked;

  /// No description provided for @bookStepCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String bookStepCounter(int current, int total);

  /// No description provided for @spaceIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get spaceIndoor;

  /// No description provided for @spaceOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get spaceOutdoor;

  /// No description provided for @homeMessageFoxer.
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String homeMessageFoxer(String name);

  /// No description provided for @messageSampleFoxer.
  ///
  /// In en, this message translates to:
  /// **'This is a sample Foxer. Real Foxers show up here once there are some.'**
  String get messageSampleFoxer;

  /// No description provided for @messageStartFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open the chat. Try again.'**
  String get messageStartFailed;

  /// No description provided for @messageYou.
  ///
  /// In en, this message translates to:
  /// **'You: '**
  String get messageYou;

  /// No description provided for @messageNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get messageNow;

  /// No description provided for @messageEditedSuffix.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get messageEditedSuffix;

  /// No description provided for @messageReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get messageReply;

  /// No description provided for @messageEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get messageEdit;

  /// No description provided for @messageDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get messageDelete;

  /// No description provided for @messageReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to'**
  String get messageReplyingTo;

  /// No description provided for @messageEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing message'**
  String get messageEditing;

  /// No description provided for @messageCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get messageCancel;

  /// No description provided for @messageMute.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get messageMute;

  /// No description provided for @messageUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute notifications'**
  String get messageUnmute;

  /// No description provided for @messagePinChat.
  ///
  /// In en, this message translates to:
  /// **'Pin chat'**
  String get messagePinChat;

  /// No description provided for @messageUnpinChat.
  ///
  /// In en, this message translates to:
  /// **'Unpin chat'**
  String get messageUnpinChat;

  /// No description provided for @messageMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get messageMore;

  /// No description provided for @messageAttachSoon.
  ///
  /// In en, this message translates to:
  /// **'Sharing photos is coming soon'**
  String get messageAttachSoon;

  /// No description provided for @messageOwnerSample.
  ///
  /// In en, this message translates to:
  /// **'This is a sample venue, so there is no owner to message.'**
  String get messageOwnerSample;

  /// No description provided for @messageDeletedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this message?'**
  String get messageDeletedConfirm;

  /// No description provided for @messageTyping.
  ///
  /// In en, this message translates to:
  /// **'typing…'**
  String get messageTyping;

  /// No description provided for @messageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send the photo. Try again.'**
  String get messageUploadFailed;

  /// No description provided for @messageNewChatTitle.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get messageNewChatTitle;

  /// No description provided for @messageNewChatSearch.
  ///
  /// In en, this message translates to:
  /// **'Search Foxers'**
  String get messageNewChatSearch;

  /// No description provided for @messageNewChatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Foxers found.'**
  String get messageNewChatEmpty;

  /// No description provided for @homeNearYou.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get homeNearYou;

  /// No description provided for @areaTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you?'**
  String get areaTitle;

  /// No description provided for @areaUseDevice.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get areaUseDevice;

  /// No description provided for @areaUseDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'Only while the app is open.'**
  String get areaUseDeviceHint;

  /// No description provided for @areaUseProfile.
  ///
  /// In en, this message translates to:
  /// **'My city: {city}'**
  String areaUseProfile(String city);

  /// No description provided for @areaOtherCity.
  ///
  /// In en, this message translates to:
  /// **'Another city'**
  String get areaOtherCity;

  /// No description provided for @areaOtherCityHint.
  ///
  /// In en, this message translates to:
  /// **'Type a city'**
  String get areaOtherCityHint;

  /// No description provided for @areaGo.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get areaGo;

  /// No description provided for @areaLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location is off for this app. Turn it on in Settings to use it.'**
  String get areaLocationDenied;

  /// No description provided for @areaLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to use this.'**
  String get areaLocationOff;

  /// No description provided for @areaLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find your location. Try again.'**
  String get areaLocationFailed;

  /// No description provided for @locGateTitle.
  ///
  /// In en, this message translates to:
  /// **'See what is near you'**
  String get locGateTitle;

  /// No description provided for @locGateBody.
  ///
  /// In en, this message translates to:
  /// **'Share your location and Fox Passport shows the venues and Foxers around you. We only use it while the app is open, and you can change it any time in Settings.'**
  String get locGateBody;

  /// No description provided for @locGateAllow.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get locGateAllow;

  /// No description provided for @locGateSkip.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get locGateSkip;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get settingsLocation;

  /// No description provided for @settingsLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where you are'**
  String get settingsLocationTitle;

  /// No description provided for @settingsLocationDevice.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get settingsLocationDevice;

  /// No description provided for @settingsLocationNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsLocationNone;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @currencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Show prices in'**
  String get currencyTitle;

  /// No description provided for @currencyAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get currencyAuto;

  /// No description provided for @currencyAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Based on where you are'**
  String get currencyAutoHint;

  /// No description provided for @currencyBasedOnLocation.
  ///
  /// In en, this message translates to:
  /// **'Based on your location'**
  String get currencyBasedOnLocation;

  /// No description provided for @currencyChargedIn.
  ///
  /// In en, this message translates to:
  /// **'You are charged {amount}.'**
  String currencyChargedIn(String amount);

  /// No description provided for @currencyApprox.
  ///
  /// In en, this message translates to:
  /// **'≈ {amount}'**
  String currencyApprox(String amount);

  /// No description provided for @searchPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get searchPeople;

  /// No description provided for @searchHostedBy.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String searchHostedBy(String name);

  /// No description provided for @eventBook.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get eventBook;

  /// No description provided for @eventIncluded.
  ///
  /// In en, this message translates to:
  /// **'What\'s included'**
  String get eventIncluded;

  /// No description provided for @eventIncludedLabel.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get eventIncludedLabel;

  /// No description provided for @eventOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Switch off what you do not need.'**
  String get eventOptionalHint;

  /// No description provided for @eventPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get eventPackage;

  /// No description provided for @eventHostedBy.
  ///
  /// In en, this message translates to:
  /// **'Hosted by {name}'**
  String eventHostedBy(String name);

  /// No description provided for @eventSpotsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} spots left'**
  String eventSpotsLeft(int count);

  /// No description provided for @eventFull.
  ///
  /// In en, this message translates to:
  /// **'This event is full.'**
  String get eventFull;

  /// No description provided for @eventNotPriced.
  ///
  /// In en, this message translates to:
  /// **'This event has no price yet, so it cannot be booked.'**
  String get eventNotPriced;

  /// No description provided for @eventLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this event.'**
  String get eventLoadFailed;

  /// No description provided for @eventRemoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item left out} other{{count} items left out}}'**
  String eventRemoved(int count);

  /// No description provided for @eventSampleNote.
  ///
  /// In en, this message translates to:
  /// **'Sample event'**
  String get eventSampleNote;

  /// No description provided for @bookPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get bookPackage;

  /// No description provided for @ticketCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get ticketCancel;

  /// No description provided for @cancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking?'**
  String get cancelTitle;

  /// No description provided for @cancelPaid.
  ///
  /// In en, this message translates to:
  /// **'You paid'**
  String get cancelPaid;

  /// No description provided for @cancelRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get cancelRefund;

  /// No description provided for @cancelNoRefund.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get cancelNoRefund;

  /// No description provided for @cancelNotEligible.
  ///
  /// In en, this message translates to:
  /// **'This booking can no longer be cancelled.'**
  String get cancelNotEligible;

  /// No description provided for @cancelKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep booking'**
  String get cancelKeep;

  /// No description provided for @cancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelConfirm;

  /// No description provided for @cancelDone.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get cancelDone;

  /// No description provided for @cancelFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t cancel the booking. Try again.'**
  String get cancelFailed;

  /// No description provided for @rolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a Foxer'**
  String get rolesTitle;

  /// No description provided for @rolesIntro.
  ///
  /// In en, this message translates to:
  /// **'Hosts, venues, gear and talent keep FoxPassport running. Pick a role to see what it involves and apply.'**
  String get rolesIntro;

  /// No description provided for @rolesSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Host events, list a venue, offer gear or talent'**
  String get rolesSettingsHint;

  /// No description provided for @rolesContinueOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Continue on the web'**
  String get rolesContinueOnWeb;

  /// No description provided for @venueBookNow.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get venueBookNow;

  /// No description provided for @venueLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this venue.'**
  String get venueLoadFailed;

  /// No description provided for @venueUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} guests'**
  String venueUpTo(int count);

  /// No description provided for @venueSampleNote.
  ///
  /// In en, this message translates to:
  /// **'Sample venue'**
  String get venueSampleNote;

  /// No description provided for @venueIncluded.
  ///
  /// In en, this message translates to:
  /// **'What\'s included'**
  String get venueIncluded;

  /// No description provided for @venueAmenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get venueAmenities;

  /// No description provided for @venueFacilities.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get venueFacilities;

  /// No description provided for @venueRules.
  ///
  /// In en, this message translates to:
  /// **'House rules'**
  String get venueRules;

  /// No description provided for @venueGoodToKnow.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get venueGoodToKnow;

  /// No description provided for @venueParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get venueParking;

  /// No description provided for @venueAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get venueAccessibility;

  /// No description provided for @venueEntrance.
  ///
  /// In en, this message translates to:
  /// **'Getting in'**
  String get venueEntrance;

  /// No description provided for @foxerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this Foxer.'**
  String get foxerLoadFailed;

  /// No description provided for @foxerMatchMe.
  ///
  /// In en, this message translates to:
  /// **'Match me'**
  String get foxerMatchMe;

  /// No description provided for @foxerMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get foxerMessage;

  /// No description provided for @foxerOffers.
  ///
  /// In en, this message translates to:
  /// **'What they offer'**
  String get foxerOffers;

  /// No description provided for @foxerNoOffers.
  ///
  /// In en, this message translates to:
  /// **'Nothing listed yet. Send a request and tell them what you need.'**
  String get foxerNoOffers;

  /// No description provided for @foxerSampleNote.
  ///
  /// In en, this message translates to:
  /// **'Sample Foxer'**
  String get foxerSampleNote;

  /// No description provided for @foxerReviews.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reviews yet} =1{1 review} other{{count} reviews}}'**
  String foxerReviews(int count);

  /// No description provided for @matchTitle.
  ///
  /// In en, this message translates to:
  /// **'Match me'**
  String get matchTitle;

  /// No description provided for @matchIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell {name} what you have in mind. They will accept or decline, and nothing is charged until they accept.'**
  String matchIntro(String name);

  /// No description provided for @matchWhat.
  ///
  /// In en, this message translates to:
  /// **'What would you like?'**
  String get matchWhat;

  /// No description provided for @matchOwnIdea.
  ///
  /// In en, this message translates to:
  /// **'My own idea'**
  String get matchOwnIdea;

  /// No description provided for @matchWhen.
  ///
  /// In en, this message translates to:
  /// **'Which day?'**
  String get matchWhen;

  /// No description provided for @matchGuests.
  ///
  /// In en, this message translates to:
  /// **'How many guests?'**
  String get matchGuests;

  /// No description provided for @matchMessage.
  ///
  /// In en, this message translates to:
  /// **'Anything they should know?'**
  String get matchMessage;

  /// No description provided for @matchMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. The mood, the place, your budget'**
  String get matchMessageHint;

  /// No description provided for @matchNoCharge.
  ///
  /// In en, this message translates to:
  /// **'You will not be charged to send a request.'**
  String get matchNoCharge;

  /// No description provided for @matchSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get matchSend;

  /// No description provided for @matchFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your request. Try again.'**
  String get matchFailed;

  /// No description provided for @matchSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get matchSentTitle;

  /// No description provided for @matchSentBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will get back to you. You will be notified when they respond.'**
  String matchSentBody(String name);

  /// No description provided for @ticketsRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get ticketsRequests;

  /// No description provided for @ticketsEmptyRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests yet. Ask a Foxer to match you from their profile.'**
  String get ticketsEmptyRequests;

  /// No description provided for @matchViewRequests.
  ///
  /// In en, this message translates to:
  /// **'View my requests'**
  String get matchViewRequests;

  /// No description provided for @matchStateWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for reply'**
  String get matchStateWaiting;

  /// No description provided for @matchStateAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get matchStateAccepted;

  /// No description provided for @matchStateConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get matchStateConfirmed;

  /// No description provided for @matchStateDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get matchStateDeclined;

  /// No description provided for @matchTheFoxer.
  ///
  /// In en, this message translates to:
  /// **'the Foxer'**
  String get matchTheFoxer;

  /// No description provided for @matchWaitingNote.
  ///
  /// In en, this message translates to:
  /// **'{name} has your request and will reply soon.'**
  String matchWaitingNote(String name);

  /// No description provided for @matchPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get matchPayNow;

  /// No description provided for @matchWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get matchWithdraw;

  /// No description provided for @bookClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get bookClose;

  /// No description provided for @bookBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get bookBack;

  /// No description provided for @bookWhenTitle.
  ///
  /// In en, this message translates to:
  /// **'When is it?'**
  String get bookWhenTitle;

  /// No description provided for @bookSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get bookSelected;

  /// No description provided for @bookBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get bookBooked;

  /// No description provided for @bookDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String bookDayCount(int count);

  /// No description provided for @bookNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get bookNext;

  /// No description provided for @bookPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get bookPickDate;

  /// No description provided for @bookGuestsTitle.
  ///
  /// In en, this message translates to:
  /// **'How many guests?'**
  String get bookGuestsTitle;

  /// No description provided for @bookFitsUpTo.
  ///
  /// In en, this message translates to:
  /// **'Fits up to {count}'**
  String bookFitsUpTo(int count);

  /// No description provided for @bookOverCapacity.
  ///
  /// In en, this message translates to:
  /// **'{count} over capacity. The owner has to approve before you pay.'**
  String bookOverCapacity(int count);

  /// No description provided for @bookNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Anything the owner should know?'**
  String get bookNotesTitle;

  /// No description provided for @bookNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Setup time, catering, access needs'**
  String get bookNotesHint;

  /// No description provided for @bookReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get bookReviewTitle;

  /// No description provided for @bookDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get bookDate;

  /// No description provided for @bookGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get bookGuests;

  /// No description provided for @bookRateLine.
  ///
  /// In en, this message translates to:
  /// **'{rate} x {days}'**
  String bookRateLine(String rate, String days);

  /// No description provided for @bookServiceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get bookServiceFee;

  /// No description provided for @bookVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get bookVoucher;

  /// No description provided for @bookAddCode.
  ///
  /// In en, this message translates to:
  /// **'Add code'**
  String get bookAddCode;

  /// No description provided for @bookDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get bookDiscount;

  /// No description provided for @bookTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bookTotal;

  /// No description provided for @bookCancelPolicy.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation for 48 hours.'**
  String get bookCancelPolicy;

  /// No description provided for @bookSampleAmounts.
  ///
  /// In en, this message translates to:
  /// **'Sample amounts'**
  String get bookSampleAmounts;

  /// No description provided for @bookSampleTag.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get bookSampleTag;

  /// No description provided for @bookContinuePay.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get bookContinuePay;

  /// No description provided for @bookRequestToBook.
  ///
  /// In en, this message translates to:
  /// **'Request to book'**
  String get bookRequestToBook;

  /// No description provided for @bookPriceFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t price this booking.'**
  String get bookPriceFailed;

  /// No description provided for @bookPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get bookPayTitle;

  /// No description provided for @bookOrPayByCard.
  ///
  /// In en, this message translates to:
  /// **'Or pay by card'**
  String get bookOrPayByCard;

  /// No description provided for @bookCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get bookCardNumber;

  /// No description provided for @bookExpiry.
  ///
  /// In en, this message translates to:
  /// **'MM / YY'**
  String get bookExpiry;

  /// No description provided for @bookCvc.
  ///
  /// In en, this message translates to:
  /// **'CVC'**
  String get bookCvc;

  /// No description provided for @bookStripeNote.
  ///
  /// In en, this message translates to:
  /// **'Payment handled by Stripe.'**
  String get bookStripeNote;

  /// No description provided for @bookPayAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String bookPayAmount(String amount);

  /// No description provided for @bookPaymentsSoon.
  ///
  /// In en, this message translates to:
  /// **'Card payments in the app are coming soon.'**
  String get bookPaymentsSoon;

  /// No description provided for @bookFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t complete the booking. Try again.'**
  String get bookFailed;

  /// No description provided for @bookBookedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re booked'**
  String get bookBookedTitle;

  /// No description provided for @bookBookedSub.
  ///
  /// In en, this message translates to:
  /// **'Your ticket is in the Tickets tab.'**
  String get bookBookedSub;

  /// No description provided for @bookConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookConfirmed;

  /// No description provided for @bookReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get bookReference;

  /// No description provided for @bookTotalCharged.
  ///
  /// In en, this message translates to:
  /// **'Total charged'**
  String get bookTotalCharged;

  /// No description provided for @bookAttendHint.
  ///
  /// In en, this message translates to:
  /// **'Attend to earn a passport stamp.'**
  String get bookAttendHint;

  /// No description provided for @bookViewTicket.
  ///
  /// In en, this message translates to:
  /// **'View ticket'**
  String get bookViewTicket;

  /// No description provided for @bookMessageOwner.
  ///
  /// In en, this message translates to:
  /// **'Message the owner'**
  String get bookMessageOwner;

  /// No description provided for @bookRequestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get bookRequestSentTitle;

  /// No description provided for @bookRequestSentSub.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the owner to confirm.'**
  String get bookRequestSentSub;

  /// No description provided for @bookReqDelivered.
  ///
  /// In en, this message translates to:
  /// **'Request delivered'**
  String get bookReqDelivered;

  /// No description provided for @bookReqDeliveredBody.
  ///
  /// In en, this message translates to:
  /// **'The owner can accept or decline {count} guests.'**
  String bookReqDeliveredBody(int count);

  /// No description provided for @bookNotified.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be notified'**
  String get bookNotified;

  /// No description provided for @bookNotifiedBody.
  ///
  /// In en, this message translates to:
  /// **'By push notification and email.'**
  String get bookNotifiedBody;

  /// No description provided for @bookPayAfter.
  ///
  /// In en, this message translates to:
  /// **'Pay only after approval'**
  String get bookPayAfter;

  /// No description provided for @bookPayAfterBody.
  ///
  /// In en, this message translates to:
  /// **'If they decline, nothing is charged.'**
  String get bookPayAfterBody;

  /// No description provided for @bookAmountIfApproved.
  ///
  /// In en, this message translates to:
  /// **'Amount if approved'**
  String get bookAmountIfApproved;

  /// No description provided for @bookBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get bookBackHome;

  /// No description provided for @comingSoonMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages are coming soon'**
  String get comingSoonMessages;

  /// No description provided for @comingSoonVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher codes are coming soon'**
  String get comingSoonVoucher;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Events around the world'**
  String get mapTitle;

  /// No description provided for @mapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events on the map yet'**
  String get mapEmpty;

  /// No description provided for @mapViewEvents.
  ///
  /// In en, this message translates to:
  /// **'View events'**
  String get mapViewEvents;

  /// No description provided for @passportTicketsHint.
  ///
  /// In en, this message translates to:
  /// **'Upcoming, past and your requests'**
  String get passportTicketsHint;

  /// No description provided for @mapEventCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String mapEventCount(int count);

  /// No description provided for @homeEmptyVenues.
  ///
  /// In en, this message translates to:
  /// **'No venues here yet.'**
  String get homeEmptyVenues;

  /// No description provided for @homeEmptyVenuesAction.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get homeEmptyVenuesAction;

  /// No description provided for @homeEmptyFoxers.
  ///
  /// In en, this message translates to:
  /// **'No Foxers here yet. Be the first.'**
  String get homeEmptyFoxers;

  /// No description provided for @homeEmptyFoxersAction.
  ///
  /// In en, this message translates to:
  /// **'Become one'**
  String get homeEmptyFoxersAction;

  /// No description provided for @searchNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get searchNothingHere;

  /// No description provided for @searchTryFewerFilters.
  ///
  /// In en, this message translates to:
  /// **'Try removing a filter or a word.'**
  String get searchTryFewerFilters;

  /// No description provided for @mapEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Explore events'**
  String get mapEmptyAction;

  /// No description provided for @passportEmptyStamps.
  ///
  /// In en, this message translates to:
  /// **'Attend an event to earn your first stamp.'**
  String get passportEmptyStamps;

  /// No description provided for @passportEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Find events'**
  String get passportEmptyAction;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarHint.
  ///
  /// In en, this message translates to:
  /// **'Everything you book, host or supply'**
  String get calendarHint;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarNothingToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day.'**
  String get calendarNothingToday;

  /// No description provided for @calendarPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPreviousMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// No description provided for @calendarRoleGuest.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get calendarRoleGuest;

  /// No description provided for @calendarRoleHost.
  ///
  /// In en, this message translates to:
  /// **'Events I host'**
  String get calendarRoleHost;

  /// No description provided for @calendarRoleOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Organizing'**
  String get calendarRoleOrganizer;

  /// No description provided for @calendarRoleVenue.
  ///
  /// In en, this message translates to:
  /// **'At my venues'**
  String get calendarRoleVenue;

  /// No description provided for @calendarRoleSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplying'**
  String get calendarRoleSupplier;

  /// No description provided for @calendarOpenTickets.
  ///
  /// In en, this message translates to:
  /// **'Open tickets'**
  String get calendarOpenTickets;

  /// No description provided for @calendarManageOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Manage this on the web.'**
  String get calendarManageOnWeb;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
