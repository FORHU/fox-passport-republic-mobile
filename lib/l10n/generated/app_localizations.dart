import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

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

  /// No description provided for @notificationsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t update your notifications. Try again.'**
  String get notificationsUpdateFailed;

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

  /// No description provided for @searchEventPlanLikeThis.
  ///
  /// In en, this message translates to:
  /// **'Plan something like this'**
  String get searchEventPlanLikeThis;

  /// No description provided for @searchEventPlanHint.
  ///
  /// In en, this message translates to:
  /// **'This event is already booked. Start your own and see what you can book.'**
  String get searchEventPlanHint;

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

  /// No description provided for @messageAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach a photo'**
  String get messageAttachPhoto;

  /// No description provided for @messageCancelReply.
  ///
  /// In en, this message translates to:
  /// **'Cancel reply'**
  String get messageCancelReply;

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

  /// No description provided for @whereYoullBe.
  ///
  /// In en, this message translates to:
  /// **'Where you\'ll be'**
  String get whereYoullBe;

  /// No description provided for @locationAfterBooking.
  ///
  /// In en, this message translates to:
  /// **'Exact location provided after booking'**
  String get locationAfterBooking;

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

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingLabel;

  /// No description provided for @authResetCodeSent.
  ///
  /// In en, this message translates to:
  /// **'If that email exists, a code has been sent.'**
  String get authResetCodeSent;

  /// No description provided for @authPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Please log in.'**
  String get authPasswordUpdated;

  /// No description provided for @authAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created! Check your email for a code.'**
  String get authAccountCreated;

  /// No description provided for @authEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified. You can now log in.'**
  String get authEmailVerified;

  /// No description provided for @authNewCodeSent.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way.'**
  String get authNewCodeSent;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

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

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get settingsEditProfile;

  /// No description provided for @settingsBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get settingsBlockedUsers;

  /// No description provided for @settingsBlockedUsersHint.
  ///
  /// In en, this message translates to:
  /// **'People who can\'t send you a follow request'**
  String get settingsBlockedUsersHint;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsChangePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Use a new password to keep your account safe'**
  String get settingsChangePasswordHint;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account'**
  String get settingsDeleteAccountHint;

  /// No description provided for @spaceCitizen.
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get spaceCitizen;

  /// No description provided for @spaceVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get spaceVenue;

  /// No description provided for @spaceEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get spaceEvent;

  /// No description provided for @spaceCitizenHint.
  ///
  /// In en, this message translates to:
  /// **'Browse, plan and book'**
  String get spaceCitizenHint;

  /// No description provided for @spaceVenueHint.
  ///
  /// In en, this message translates to:
  /// **'Your venues and the requests for them'**
  String get spaceVenueHint;

  /// No description provided for @spaceEventHint.
  ///
  /// In en, this message translates to:
  /// **'Your events and guest check-in'**
  String get spaceEventHint;

  /// No description provided for @spaceSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch space'**
  String get spaceSwitchTitle;

  /// No description provided for @spaceSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'You hold more than one role. Choose where to work.'**
  String get spaceSwitchHint;

  /// No description provided for @spaceNowIn.
  ///
  /// In en, this message translates to:
  /// **'Now in {space}'**
  String spaceNowIn(String space);

  /// No description provided for @spaceManageOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Manage on the web'**
  String get spaceManageOnWeb;

  /// No description provided for @spaceTabRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get spaceTabRequests;

  /// No description provided for @spaceTabVenues.
  ///
  /// In en, this message translates to:
  /// **'Venues'**
  String get spaceTabVenues;

  /// No description provided for @spaceTabEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get spaceTabEvents;

  /// No description provided for @spaceTabCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get spaceTabCheckIn;

  /// No description provided for @spaceTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get spaceTabOverview;

  /// No description provided for @spaceTabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get spaceTabCalendar;

  /// No description provided for @spaceTabEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get spaceTabEarnings;

  /// No description provided for @spaceTabMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get spaceTabMore;

  /// No description provided for @venueKpiLive.
  ///
  /// In en, this message translates to:
  /// **'Venues live'**
  String get venueKpiLive;

  /// No description provided for @venueKpiLiveValue.
  ///
  /// In en, this message translates to:
  /// **'{live} of {total}'**
  String venueKpiLiveValue(int live, int total);

  /// No description provided for @venueKpiUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Bookings, next 30 days'**
  String get venueKpiUpcoming;

  /// No description provided for @venueKpiPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid out'**
  String get venueKpiPaid;

  /// No description provided for @venueKpiPending.
  ///
  /// In en, this message translates to:
  /// **'Pending payouts'**
  String get venueKpiPending;

  /// No description provided for @venueNeedsReply.
  ///
  /// In en, this message translates to:
  /// **'Needs your reply'**
  String get venueNeedsReply;

  /// No description provided for @venueSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get venueSeeAll;

  /// No description provided for @venueNothingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting for you.'**
  String get venueNothingWaiting;

  /// No description provided for @venueComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up at your venues'**
  String get venueComingUp;

  /// No description provided for @venueNothingUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No bookings in the next 30 days.'**
  String get venueNothingUpcoming;

  /// No description provided for @venueQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get venueQuickActions;

  /// No description provided for @venueQuickCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check in a guest'**
  String get venueQuickCheckIn;

  /// No description provided for @venueQuickCloseDay.
  ///
  /// In en, this message translates to:
  /// **'Close a day'**
  String get venueQuickCloseDay;

  /// No description provided for @venueQuickAddVenue.
  ///
  /// In en, this message translates to:
  /// **'Add a venue'**
  String get venueQuickAddVenue;

  /// No description provided for @venueAddVenue.
  ///
  /// In en, this message translates to:
  /// **'Add venue'**
  String get venueAddVenue;

  /// No description provided for @esTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get esTitleNew;

  /// No description provided for @esTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get esTitleEdit;

  /// No description provided for @esStepBasics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get esStepBasics;

  /// No description provided for @esStepLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get esStepLocation;

  /// No description provided for @esStepPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get esStepPhotos;

  /// No description provided for @esStepPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get esStepPackage;

  /// No description provided for @esStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get esStepReview;

  /// No description provided for @esTitle.
  ///
  /// In en, this message translates to:
  /// **'Event title'**
  String get esTitle;

  /// No description provided for @esCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get esCategory;

  /// No description provided for @esCatCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get esCatCorporate;

  /// No description provided for @esCatBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get esCatBirthday;

  /// No description provided for @esCatWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get esCatWedding;

  /// No description provided for @esCatSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get esCatSocial;

  /// No description provided for @esCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get esCatOther;

  /// No description provided for @esCatOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Please specify the event category'**
  String get esCatOtherHint;

  /// No description provided for @esDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get esDescription;

  /// No description provided for @esWordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / 500 words'**
  String esWordCount(int count);

  /// No description provided for @esWordsToGo.
  ///
  /// In en, this message translates to:
  /// **'{count} more to reach 100'**
  String esWordsToGo(int count);

  /// No description provided for @esAttendees.
  ///
  /// In en, this message translates to:
  /// **'Max attendees'**
  String get esAttendees;

  /// No description provided for @esPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get esPolicy;

  /// No description provided for @esLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Where the event takes place. Choosing a venue fills this in for you.'**
  String get esLocationHint;

  /// No description provided for @esPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 photos. Five is recommended.'**
  String get esPhotosHint;

  /// No description provided for @esPackageTitle.
  ///
  /// In en, this message translates to:
  /// **'Core package'**
  String get esPackageTitle;

  /// No description provided for @esPackageHint.
  ///
  /// In en, this message translates to:
  /// **'The venue and everything your event includes.'**
  String get esPackageHint;

  /// No description provided for @esVenueSlot.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get esVenueSlot;

  /// No description provided for @esNoVenue.
  ///
  /// In en, this message translates to:
  /// **'No venue yet'**
  String get esNoVenue;

  /// No description provided for @esChooseVenue.
  ///
  /// In en, this message translates to:
  /// **'Choose a venue'**
  String get esChooseVenue;

  /// No description provided for @esAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to package'**
  String get esAdd;

  /// No description provided for @esPackageEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing else added yet.'**
  String get esPackageEmpty;

  /// No description provided for @esEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String esEditItem(String name);

  /// No description provided for @esAgreedPrice.
  ///
  /// In en, this message translates to:
  /// **'Agreed price'**
  String get esAgreedPrice;

  /// No description provided for @esListed.
  ///
  /// In en, this message translates to:
  /// **'Listed: {price}'**
  String esListed(String price);

  /// No description provided for @esOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get esOptional;

  /// No description provided for @esRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from package'**
  String get esRemove;

  /// No description provided for @esDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get esDone;

  /// No description provided for @esCostVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get esCostVenue;

  /// No description provided for @esCostTalent.
  ///
  /// In en, this message translates to:
  /// **'Talent'**
  String get esCostTalent;

  /// No description provided for @esCostServices.
  ///
  /// In en, this message translates to:
  /// **'Services and equipment'**
  String get esCostServices;

  /// No description provided for @esCostTotal.
  ///
  /// In en, this message translates to:
  /// **'Package cost'**
  String get esCostTotal;

  /// No description provided for @esMargin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get esMargin;

  /// No description provided for @esSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested price'**
  String get esSuggested;

  /// No description provided for @esPickVenues.
  ///
  /// In en, this message translates to:
  /// **'Venues'**
  String get esPickVenues;

  /// No description provided for @esPickTalent.
  ///
  /// In en, this message translates to:
  /// **'Talent'**
  String get esPickTalent;

  /// No description provided for @esPickServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get esPickServices;

  /// No description provided for @esPickEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get esPickEquipment;

  /// No description provided for @esPickSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get esPickSearch;

  /// No description provided for @esPickNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing found.'**
  String get esPickNone;

  /// No description provided for @esPickMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get esPickMore;

  /// No description provided for @esAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get esAdded;

  /// No description provided for @esAccessApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get esAccessApproved;

  /// No description provided for @esAccessPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get esAccessPending;

  /// No description provided for @esAccessApply.
  ///
  /// In en, this message translates to:
  /// **'Apply first'**
  String get esAccessApply;

  /// No description provided for @esToastAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {name} to your package'**
  String esToastAdded(String name);

  /// No description provided for @esToastDuplicate.
  ///
  /// In en, this message translates to:
  /// **'{name} is already in your package'**
  String esToastDuplicate(String name);

  /// No description provided for @esToastOneVenue.
  ///
  /// In en, this message translates to:
  /// **'Only one venue can be in the package. Remove the existing venue first.'**
  String get esToastOneVenue;

  /// No description provided for @esToastVenuePending.
  ///
  /// In en, this message translates to:
  /// **'Your affiliation with this venue is still pending approval.'**
  String get esToastVenuePending;

  /// No description provided for @esToastVenueApply.
  ///
  /// In en, this message translates to:
  /// **'Apply to this venue first. You need an approved affiliation to host here.'**
  String get esToastVenueApply;

  /// No description provided for @esReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Event title'**
  String get esReadyTitle;

  /// No description provided for @esReadyCategory.
  ///
  /// In en, this message translates to:
  /// **'Category selected'**
  String get esReadyCategory;

  /// No description provided for @esReadyOther.
  ///
  /// In en, this message translates to:
  /// **'Say what kind of event it is'**
  String get esReadyOther;

  /// No description provided for @esReadyVenue.
  ///
  /// In en, this message translates to:
  /// **'Approved venue attached'**
  String get esReadyVenue;

  /// No description provided for @esReadyGallery.
  ///
  /// In en, this message translates to:
  /// **'5 photos'**
  String get esReadyGallery;

  /// No description provided for @esReadyDescription.
  ///
  /// In en, this message translates to:
  /// **'100+ word description'**
  String get esReadyDescription;

  /// No description provided for @esRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get esRequired;

  /// No description provided for @esRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get esRecommended;

  /// No description provided for @esScore.
  ///
  /// In en, this message translates to:
  /// **'{pct}% ready'**
  String esScore(int pct);

  /// No description provided for @esNotDraft.
  ///
  /// In en, this message translates to:
  /// **'This event has already been sent for review, so you can only save changes.'**
  String get esNotDraft;

  /// No description provided for @esSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get esSaveDraft;

  /// No description provided for @esSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send for review'**
  String get esSubmit;

  /// No description provided for @esSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get esSaveChanges;

  /// No description provided for @esSavedDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft saved.'**
  String get esSavedDraft;

  /// No description provided for @esSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Sent for review.'**
  String get esSubmitted;

  /// No description provided for @esSavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes saved.'**
  String get esSavedChanges;

  /// No description provided for @esNeedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add an event title before saving.'**
  String get esNeedsTitle;

  /// No description provided for @esSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save that. Try again.'**
  String get esSaveFailed;

  /// No description provided for @esPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'That photo didn\'t upload. Try again.'**
  String get esPhotoFailed;

  /// No description provided for @esPartial.
  ///
  /// In en, this message translates to:
  /// **'Saved, but some items could not be added. Fix them and send it again.'**
  String get esPartial;

  /// No description provided for @esProblemLine.
  ///
  /// In en, this message translates to:
  /// **'{name}: {reason}'**
  String esProblemLine(String name, String reason);

  /// No description provided for @esEditEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get esEditEvent;

  /// No description provided for @esViewPublic.
  ///
  /// In en, this message translates to:
  /// **'View public page'**
  String get esViewPublic;

  /// No description provided for @eventsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your events'**
  String get eventsSearchHint;

  /// No description provided for @eventsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String eventsCount(int count);

  /// No description provided for @eventsCountOf.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} events'**
  String eventsCountOf(int shown, int total);

  /// No description provided for @eventsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No events match.'**
  String get eventsNoMatch;

  /// No description provided for @eventsInvitesWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 venue invitation is waiting} other{{count} venue invitations are waiting}}'**
  String eventsInvitesWaiting(int count);

  /// No description provided for @eventsInReview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event is in review} other{{count} events are in review}}'**
  String eventsInReview(int count);

  /// No description provided for @eventsDeclined.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event was declined} other{{count} events were declined}}'**
  String eventsDeclined(int count);

  /// No description provided for @eventsDrafts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 draft to finish} other{{count} drafts to finish}}'**
  String eventsDrafts(int count);

  /// No description provided for @eventsNewOnWeb.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get eventsNewOnWeb;

  /// No description provided for @overviewAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs your attention'**
  String get overviewAttention;

  /// No description provided for @overviewAllClear.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get overviewAllClear;

  /// No description provided for @overviewPartnersWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 partner application is waiting} other{{count} partner applications are waiting}}'**
  String overviewPartnersWaiting(int count);

  /// No description provided for @overviewVenuesInReview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 venue is in review} other{{count} venues are in review}}'**
  String overviewVenuesInReview(int count);

  /// No description provided for @overviewVenuesDeclined.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 venue was declined} other{{count} venues were declined}}'**
  String overviewVenuesDeclined(int count);

  /// No description provided for @overviewVenuesDrafts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 draft to finish} other{{count} drafts to finish}}'**
  String overviewVenuesDrafts(int count);

  /// No description provided for @overviewTodayAhead.
  ///
  /// In en, this message translates to:
  /// **'Today and coming up'**
  String get overviewTodayAhead;

  /// No description provided for @overviewToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get overviewToday;

  /// No description provided for @overviewNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get overviewNumbers;

  /// No description provided for @calendarAllVenuesCount.
  ///
  /// In en, this message translates to:
  /// **'All venues ({count})'**
  String calendarAllVenuesCount(int count);

  /// No description provided for @calendarShowAllVenues.
  ///
  /// In en, this message translates to:
  /// **'Show all venues'**
  String get calendarShowAllVenues;

  /// No description provided for @venuesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or city'**
  String get venuesSearchHint;

  /// No description provided for @venuesSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get venuesSearchClear;

  /// No description provided for @venuesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String venuesFilterAll(int count);

  /// No description provided for @venuesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 venue} other{{count} venues}}'**
  String venuesCount(int count);

  /// No description provided for @venuesCountOf.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} venues'**
  String venuesCountOf(int shown, int total);

  /// No description provided for @venuesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No venues match.'**
  String get venuesNoMatch;

  /// No description provided for @partnersTitle.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get partnersTitle;

  /// No description provided for @partnersIntroMayor.
  ///
  /// In en, this message translates to:
  /// **'Event Foxers who want to run events at your venues.'**
  String get partnersIntroMayor;

  /// No description provided for @partnersIntroEvent.
  ///
  /// In en, this message translates to:
  /// **'The venues you can run your events at.'**
  String get partnersIntroEvent;

  /// No description provided for @partnersNeedsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Needs your answer'**
  String get partnersNeedsAnswer;

  /// No description provided for @partnersWaitingForThem.
  ///
  /// In en, this message translates to:
  /// **'Waiting for them'**
  String get partnersWaitingForThem;

  /// No description provided for @partnersActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get partnersActive;

  /// No description provided for @partnersPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get partnersPast;

  /// No description provided for @partnersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No partners yet.'**
  String get partnersEmpty;

  /// No description provided for @partnersApplied.
  ///
  /// In en, this message translates to:
  /// **'{name} applied to host at {venue}'**
  String partnersApplied(String name, String venue);

  /// No description provided for @partnersYouInvited.
  ///
  /// In en, this message translates to:
  /// **'You invited {name} to host at {venue}'**
  String partnersYouInvited(String name, String venue);

  /// No description provided for @partnersInvitedYou.
  ///
  /// In en, this message translates to:
  /// **'{venue} invited you to host events there'**
  String partnersInvitedYou(String venue);

  /// No description provided for @partnersYouApplied.
  ///
  /// In en, this message translates to:
  /// **'You applied to host at {venue}'**
  String partnersYouApplied(String venue);

  /// No description provided for @partnersActiveAt.
  ///
  /// In en, this message translates to:
  /// **'{name} at {venue}'**
  String partnersActiveAt(String name, String venue);

  /// No description provided for @partnersAgreedPrice.
  ///
  /// In en, this message translates to:
  /// **'Agreed price: {price}'**
  String partnersAgreedPrice(String price);

  /// No description provided for @partnersApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get partnersApprove;

  /// No description provided for @partnersAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get partnersAccept;

  /// No description provided for @partnersReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get partnersReject;

  /// No description provided for @partnersDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get partnersDecline;

  /// No description provided for @partnersWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get partnersWithdraw;

  /// No description provided for @partnersRevoke.
  ///
  /// In en, this message translates to:
  /// **'End partnership'**
  String get partnersRevoke;

  /// No description provided for @partnersRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'End this partnership?'**
  String get partnersRevokeTitle;

  /// No description provided for @partnersRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer be partnered with {venue}.'**
  String partnersRevokeBody(String name, String venue);

  /// No description provided for @partnersRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Say no to this?'**
  String get partnersRejectTitle;

  /// No description provided for @partnersRejectBody.
  ///
  /// In en, this message translates to:
  /// **'They will be told you said no.'**
  String get partnersRejectBody;

  /// No description provided for @partnersApproved.
  ///
  /// In en, this message translates to:
  /// **'Done. They\'ve been told.'**
  String get partnersApproved;

  /// No description provided for @partnersRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined. They\'ve been told.'**
  String get partnersRejected;

  /// No description provided for @partnersWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn.'**
  String get partnersWithdrawn;

  /// No description provided for @partnersRevoked.
  ///
  /// In en, this message translates to:
  /// **'Partnership ended.'**
  String get partnersRevoked;

  /// No description provided for @partnersActionFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t go through. Try again.'**
  String get partnersActionFailed;

  /// No description provided for @partnersStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get partnersStatusRejected;

  /// No description provided for @partnersStatusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get partnersStatusRevoked;

  /// No description provided for @partnersOpenRow.
  ///
  /// In en, this message translates to:
  /// **'Venue partners'**
  String get partnersOpenRow;

  /// No description provided for @partnersInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite an Event Foxer'**
  String get partnersInvite;

  /// No description provided for @partnersInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an Event Foxer'**
  String get partnersInviteTitle;

  /// No description provided for @partnersInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Search Event Foxers'**
  String get partnersInviteHint;

  /// No description provided for @partnersInviteNone.
  ///
  /// In en, this message translates to:
  /// **'No Event Foxers found.'**
  String get partnersInviteNone;

  /// No description provided for @partnersChooseVenue.
  ///
  /// In en, this message translates to:
  /// **'Which venue?'**
  String get partnersChooseVenue;

  /// No description provided for @partnersInviteNoVenue.
  ///
  /// In en, this message translates to:
  /// **'You need a live venue to invite someone.'**
  String get partnersInviteNoVenue;

  /// No description provided for @partnersInviteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite {name}?'**
  String partnersInviteConfirmTitle(String name);

  /// No description provided for @partnersInviteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll be asked to host events at {venue}.'**
  String partnersInviteConfirmBody(String venue);

  /// No description provided for @partnersInviteAction.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get partnersInviteAction;

  /// No description provided for @partnersInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent.'**
  String get partnersInviteSent;

  /// No description provided for @partnersApply.
  ///
  /// In en, this message translates to:
  /// **'Apply to a venue'**
  String get partnersApply;

  /// No description provided for @partnersApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a venue'**
  String get partnersApplyTitle;

  /// No description provided for @partnersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search venues'**
  String get partnersSearchHint;

  /// No description provided for @partnersApplyNone.
  ///
  /// In en, this message translates to:
  /// **'No venues found.'**
  String get partnersApplyNone;

  /// No description provided for @partnersAlready.
  ///
  /// In en, this message translates to:
  /// **'Already on your list'**
  String get partnersAlready;

  /// No description provided for @partnersApplyConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply to {venue}?'**
  String partnersApplyConfirmTitle(String venue);

  /// No description provided for @partnersApplyConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The venue\'s Mayor will be asked to approve.'**
  String get partnersApplyConfirmBody;

  /// No description provided for @partnersApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get partnersApplyAction;

  /// No description provided for @partnersApplySent.
  ///
  /// In en, this message translates to:
  /// **'Applied. The Mayor has been told.'**
  String get partnersApplySent;

  /// No description provided for @studioTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New venue'**
  String get studioTitleNew;

  /// No description provided for @studioTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit venue'**
  String get studioTitleEdit;

  /// No description provided for @studioStepBasics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get studioStepBasics;

  /// No description provided for @studioStepLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get studioStepLocation;

  /// No description provided for @studioStepPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get studioStepPhotos;

  /// No description provided for @studioStepDetails.
  ///
  /// In en, this message translates to:
  /// **'What\'s included'**
  String get studioStepDetails;

  /// No description provided for @studioStepPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get studioStepPricing;

  /// No description provided for @studioStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get studioStepReview;

  /// No description provided for @studioName.
  ///
  /// In en, this message translates to:
  /// **'Venue name'**
  String get studioName;

  /// No description provided for @studioDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe your venue'**
  String get studioDescription;

  /// No description provided for @studioCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity (guests)'**
  String get studioCapacity;

  /// No description provided for @studioCategory.
  ///
  /// In en, this message translates to:
  /// **'Type of venue'**
  String get studioCategory;

  /// No description provided for @studioCategoryIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get studioCategoryIndoor;

  /// No description provided for @studioCategoryOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get studioCategoryOutdoor;

  /// No description provided for @studioCategoryHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get studioCategoryHotel;

  /// No description provided for @studioCategoryBeachResort.
  ///
  /// In en, this message translates to:
  /// **'Beach resort'**
  String get studioCategoryBeachResort;

  /// No description provided for @studioCategoryGarden.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get studioCategoryGarden;

  /// No description provided for @studioCategoryMix.
  ///
  /// In en, this message translates to:
  /// **'Indoor and outdoor'**
  String get studioCategoryMix;

  /// No description provided for @studioCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get studioCategoryOther;

  /// No description provided for @studioAddress.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get studioAddress;

  /// No description provided for @studioCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get studioCity;

  /// No description provided for @studioState.
  ///
  /// In en, this message translates to:
  /// **'State or province'**
  String get studioState;

  /// No description provided for @studioCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get studioCountry;

  /// No description provided for @studioServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Service area'**
  String get studioServiceArea;

  /// No description provided for @studioServiceAreaHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to drop a pin where your venue is, then set how far around it your area reaches.'**
  String get studioServiceAreaHint;

  /// No description provided for @studioRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get studioRadius;

  /// No description provided for @studioRadiusValue.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String studioRadiusValue(int meters);

  /// No description provided for @studioOverlap.
  ///
  /// In en, this message translates to:
  /// **'This area overlaps {names}. Move the pin or shrink the radius.'**
  String studioOverlap(String names);

  /// No description provided for @studioNoPin.
  ///
  /// In en, this message translates to:
  /// **'No pin yet'**
  String get studioNoPin;

  /// No description provided for @studioPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Add 1 to 5 photos. The first is the cover.'**
  String get studioPhotosHint;

  /// No description provided for @studioAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get studioAddPhoto;

  /// No description provided for @studioPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'That photo didn\'t upload. Try again.'**
  String get studioPhotoFailed;

  /// No description provided for @studioIncluded.
  ///
  /// In en, this message translates to:
  /// **'What guests get'**
  String get studioIncluded;

  /// No description provided for @studioSpaceType.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get studioSpaceType;

  /// No description provided for @studioAmenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get studioAmenities;

  /// No description provided for @studioTechAv.
  ///
  /// In en, this message translates to:
  /// **'Tech and AV'**
  String get studioTechAv;

  /// No description provided for @studioStaffing.
  ///
  /// In en, this message translates to:
  /// **'Staffing'**
  String get studioStaffing;

  /// No description provided for @studioPolicies.
  ///
  /// In en, this message translates to:
  /// **'House rules'**
  String get studioPolicies;

  /// No description provided for @studioAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Add your own'**
  String get studioAddCustom;

  /// No description provided for @studioPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get studioPrice;

  /// No description provided for @studioBillingRate.
  ///
  /// In en, this message translates to:
  /// **'Charged'**
  String get studioBillingRate;

  /// No description provided for @studioRateHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get studioRateHourly;

  /// No description provided for @studioRateDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get studioRateDaily;

  /// No description provided for @studioRateWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get studioRateWeekly;

  /// No description provided for @studioRateMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get studioRateMonthly;

  /// No description provided for @studioRateYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get studioRateYearly;

  /// No description provided for @studioRateOneTime.
  ///
  /// In en, this message translates to:
  /// **'One time'**
  String get studioRateOneTime;

  /// No description provided for @studioExtraGuest.
  ///
  /// In en, this message translates to:
  /// **'Extra guest fee (optional)'**
  String get studioExtraGuest;

  /// No description provided for @studioCancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get studioCancellation;

  /// No description provided for @studioReviewReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to send for review'**
  String get studioReviewReady;

  /// No description provided for @studioReviewMissing.
  ///
  /// In en, this message translates to:
  /// **'Still to fill in'**
  String get studioReviewMissing;

  /// No description provided for @studioMissingName.
  ///
  /// In en, this message translates to:
  /// **'Venue name'**
  String get studioMissingName;

  /// No description provided for @studioMissingCategory.
  ///
  /// In en, this message translates to:
  /// **'Type of venue'**
  String get studioMissingCategory;

  /// No description provided for @studioMissingDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get studioMissingDescription;

  /// No description provided for @studioMissingCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get studioMissingCapacity;

  /// No description provided for @studioMissingAddress.
  ///
  /// In en, this message translates to:
  /// **'Address, city and country'**
  String get studioMissingAddress;

  /// No description provided for @studioMissingLocation.
  ///
  /// In en, this message translates to:
  /// **'A pin on the map'**
  String get studioMissingLocation;

  /// No description provided for @studioMissingPhotos.
  ///
  /// In en, this message translates to:
  /// **'At least one photo'**
  String get studioMissingPhotos;

  /// No description provided for @studioMissingPrice.
  ///
  /// In en, this message translates to:
  /// **'A price'**
  String get studioMissingPrice;

  /// No description provided for @studioNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get studioNext;

  /// No description provided for @studioBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get studioBack;

  /// No description provided for @studioSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get studioSaveDraft;

  /// No description provided for @studioSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send for review'**
  String get studioSubmit;

  /// No description provided for @studioSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get studioSaveChanges;

  /// No description provided for @studioSavedDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft saved.'**
  String get studioSavedDraft;

  /// No description provided for @studioSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Sent for review. We\'ll tell you when it\'s live.'**
  String get studioSubmitted;

  /// No description provided for @studioSavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes saved.'**
  String get studioSavedChanges;

  /// No description provided for @studioSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save that. Try again.'**
  String get studioSaveFailed;

  /// No description provided for @studioOverlapRefused.
  ///
  /// In en, this message translates to:
  /// **'Another venue already covers part of this area. Move the pin.'**
  String get studioOverlapRefused;

  /// No description provided for @studioLiveNote.
  ///
  /// In en, this message translates to:
  /// **'This venue is live. Your changes show to guests as soon as you save.'**
  String get studioLiveNote;

  /// No description provided for @studioUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get studioUseMyLocation;

  /// No description provided for @studioLocateDenied.
  ///
  /// In en, this message translates to:
  /// **'Location is off for this app. Allow it in your phone\'s settings, or tap the map instead.'**
  String get studioLocateDenied;

  /// No description provided for @studioLocateOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on your phone\'s location, or tap the map instead.'**
  String get studioLocateOff;

  /// No description provided for @studioLocateFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find where you are. Tap the map instead.'**
  String get studioLocateFailed;

  /// No description provided for @studioPhotoFailedWhy.
  ///
  /// In en, this message translates to:
  /// **'That photo didn\'t upload: {reason}'**
  String studioPhotoFailedWhy(String reason);

  /// No description provided for @studioMapNeedsToken.
  ///
  /// In en, this message translates to:
  /// **'The map isn\'t available, so the pin can\'t be placed.'**
  String get studioMapNeedsToken;

  /// No description provided for @venueHubEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get venueHubEdit;

  /// No description provided for @venueHubEditHint.
  ///
  /// In en, this message translates to:
  /// **'Name, photos, location, pricing'**
  String get venueHubEditHint;

  /// No description provided for @venueHubAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get venueHubAvailability;

  /// No description provided for @venueHubAvailabilityHint.
  ///
  /// In en, this message translates to:
  /// **'See bookings and close days'**
  String get venueHubAvailabilityHint;

  /// No description provided for @venueHubPublic.
  ///
  /// In en, this message translates to:
  /// **'View public page'**
  String get venueHubPublic;

  /// No description provided for @venueHubPublicHint.
  ///
  /// In en, this message translates to:
  /// **'How guests see it'**
  String get venueHubPublicHint;

  /// No description provided for @earningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earningsTitle;

  /// No description provided for @earningsPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get earningsPending;

  /// No description provided for @earningsPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid out'**
  String get earningsPaid;

  /// No description provided for @earningsRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent payouts'**
  String get earningsRecent;

  /// No description provided for @earningsNone.
  ///
  /// In en, this message translates to:
  /// **'No payouts yet. They appear after a guest is checked in.'**
  String get earningsNone;

  /// No description provided for @earningsSetup.
  ///
  /// In en, this message translates to:
  /// **'Payout setup'**
  String get earningsSetup;

  /// No description provided for @earningsSetupReady.
  ///
  /// In en, this message translates to:
  /// **'Payouts are on'**
  String get earningsSetupReady;

  /// No description provided for @earningsSetupReadyHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be paid to your bank account.'**
  String get earningsSetupReadyHint;

  /// No description provided for @earningsSetupStart.
  ///
  /// In en, this message translates to:
  /// **'Set up payouts'**
  String get earningsSetupStart;

  /// No description provided for @earningsSetupFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish payout setup'**
  String get earningsSetupFinish;

  /// No description provided for @earningsSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Opens on the web. It asks for your bank and identity details.'**
  String get earningsSetupHint;

  /// No description provided for @payoutPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get payoutPending;

  /// No description provided for @payoutPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get payoutPaid;

  /// No description provided for @payoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get payoutFailed;

  /// No description provided for @payoutSourceVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue booking'**
  String get payoutSourceVenue;

  /// No description provided for @payoutSourceOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get payoutSourceOther;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requestsTitle;

  /// No description provided for @requestsIntro.
  ///
  /// In en, this message translates to:
  /// **'People adding your venue to their events. Confirm the ones you can host.'**
  String get requestsIntro;

  /// No description provided for @requestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No requests yet. When someone adds your venue to their event, it shows up here.'**
  String get requestsEmpty;

  /// No description provided for @requestFrom.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String requestFrom(String name);

  /// No description provided for @requestReplyBy.
  ///
  /// In en, this message translates to:
  /// **'Reply by {date}'**
  String requestReplyBy(String date);

  /// No description provided for @requestAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get requestAccept;

  /// No description provided for @requestDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get requestDecline;

  /// No description provided for @requestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted.'**
  String get requestAccepted;

  /// No description provided for @requestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined.'**
  String get requestDeclined;

  /// No description provided for @requestActionFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t update that request. Try again.'**
  String get requestActionFailed;

  /// No description provided for @requestDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline this request?'**
  String get requestDeclineTitle;

  /// No description provided for @requestDeclineBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll be told you can\'t host it.'**
  String get requestDeclineBody;

  /// No description provided for @requestStatusAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Needs your reply'**
  String get requestStatusAwaiting;

  /// No description provided for @requestStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get requestStatusPending;

  /// No description provided for @requestStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get requestStatusApproved;

  /// No description provided for @requestStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get requestStatusRejected;

  /// No description provided for @requestStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get requestStatusCancelled;

  /// No description provided for @listingsVenuesEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t listed a venue yet. Add one on the web.'**
  String get listingsVenuesEmpty;

  /// No description provided for @listingsEventsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created an event yet. Tap New event to start one.'**
  String get listingsEventsEmpty;

  /// No description provided for @listingStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get listingStatusDraft;

  /// No description provided for @listingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get listingStatusPending;

  /// No description provided for @listingStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get listingStatusLive;

  /// No description provided for @listingStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get listingStatusRejected;

  /// No description provided for @listingStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get listingStatusArchived;

  /// No description provided for @checkInTitle.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkInTitle;

  /// No description provided for @checkInIntro.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR on a guest\'s ticket, or type the code printed under it.'**
  String get checkInIntro;

  /// No description provided for @checkInScan.
  ///
  /// In en, this message translates to:
  /// **'Scan ticket'**
  String get checkInScan;

  /// No description provided for @checkInScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a ticket'**
  String get checkInScanTitle;

  /// No description provided for @checkInScanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR on the ticket.'**
  String get checkInScanHint;

  /// No description provided for @checkInTorch.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get checkInTorch;

  /// No description provided for @checkInCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off. Allow it in your phone\'s settings, or type the code instead.'**
  String get checkInCameraDenied;

  /// No description provided for @checkInCameraFailed.
  ///
  /// In en, this message translates to:
  /// **'The camera isn\'t available. Type the code instead.'**
  String get checkInCameraFailed;

  /// No description provided for @checkInTypeInstead.
  ///
  /// In en, this message translates to:
  /// **'Type the code'**
  String get checkInTypeInstead;

  /// No description provided for @checkInCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Ticket code'**
  String get checkInCodeLabel;

  /// No description provided for @checkInAction.
  ///
  /// In en, this message translates to:
  /// **'Check in guest'**
  String get checkInAction;

  /// No description provided for @checkInDone.
  ///
  /// In en, this message translates to:
  /// **'Guest checked in.'**
  String get checkInDone;

  /// No description provided for @checkInFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t check that guest in. Check the code and try again.'**
  String get checkInFailed;

  /// No description provided for @blockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedTitle;

  /// No description provided for @blockedBody.
  ///
  /// In en, this message translates to:
  /// **'Blocked people can\'t send you a new follow request. You can unblock anyone at any time.'**
  String get blockedBody;

  /// No description provided for @blockedEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t blocked anyone.'**
  String get blockedEmpty;

  /// No description provided for @blockedUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get blockedUnblock;

  /// No description provided for @blockedUnblocked.
  ///
  /// In en, this message translates to:
  /// **'{name} was unblocked.'**
  String blockedUnblocked(String name);

  /// No description provided for @blockedUnblockFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t unblock them. Try again.'**
  String get blockedUnblockFailed;

  /// No description provided for @passwordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get passwordTitle;

  /// No description provided for @passwordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get passwordCurrent;

  /// No description provided for @passwordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get passwordNew;

  /// No description provided for @passwordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get passwordConfirm;

  /// No description provided for @passwordSave.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get passwordSave;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Your password was changed.'**
  String get passwordChanged;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t change your password. Try again.'**
  String get passwordChangeFailed;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This is permanent. All your data, including bookings, badges, stamps and listings, will be erased. Cancel any active bookings first.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get deleteAccountPassword;

  /// No description provided for @deleteAccountType.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get deleteAccountType;

  /// No description provided for @deleteAccountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get deleteAccountMismatch;

  /// No description provided for @deleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountAction;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete your account. Try again.'**
  String get deleteAccountFailed;

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

  /// No description provided for @eventWaitlistFull.
  ///
  /// In en, this message translates to:
  /// **'This event is full. Join the waitlist and we\'ll tell you when a spot opens.'**
  String get eventWaitlistFull;

  /// No description provided for @eventWaitlistOn.
  ///
  /// In en, this message translates to:
  /// **'You\'re number {position} of {total} on the waitlist. We\'ll tell you when a spot opens.'**
  String eventWaitlistOn(int position, int total);

  /// No description provided for @eventWaitlistOnNoPlace.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the waitlist. We\'ll tell you when a spot opens.'**
  String get eventWaitlistOnNoPlace;

  /// No description provided for @eventWaitlistOpened.
  ///
  /// In en, this message translates to:
  /// **'A spot opened up. Book now before it fills again.'**
  String get eventWaitlistOpened;

  /// No description provided for @eventWaitlistJoin.
  ///
  /// In en, this message translates to:
  /// **'Join waitlist'**
  String get eventWaitlistJoin;

  /// No description provided for @eventWaitlistLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave waitlist'**
  String get eventWaitlistLeave;

  /// No description provided for @eventWaitlistJoined.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the waitlist.'**
  String get eventWaitlistJoined;

  /// No description provided for @eventWaitlistLeft.
  ///
  /// In en, this message translates to:
  /// **'You left the waitlist.'**
  String get eventWaitlistLeft;

  /// No description provided for @eventWaitlistFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Try again.'**
  String get eventWaitlistFailed;

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

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

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

  /// No description provided for @calendarHoldAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Needs your reply'**
  String get calendarHoldAwaiting;

  /// No description provided for @calendarHoldHeld.
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get calendarHoldHeld;

  /// No description provided for @calendarHoldConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get calendarHoldConfirmed;

  /// No description provided for @calendarBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get calendarBlocked;

  /// No description provided for @calendarAllVenues.
  ///
  /// In en, this message translates to:
  /// **'All venues'**
  String get calendarAllVenues;

  /// No description provided for @calendarDayManage.
  ///
  /// In en, this message translates to:
  /// **'Open or close this day'**
  String get calendarDayManage;

  /// No description provided for @calendarDayManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Open or close {date}'**
  String calendarDayManageTitle(String date);

  /// No description provided for @calendarDayOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get calendarDayOpen;

  /// No description provided for @calendarDayClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get calendarDayClosed;

  /// No description provided for @calendarDayBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked, so it can\'t be closed'**
  String get calendarDayBooked;

  /// No description provided for @calendarDayFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t update that day. Try again.'**
  String get calendarDayFailed;

  /// No description provided for @calendarOpenDay.
  ///
  /// In en, this message translates to:
  /// **'Open this day'**
  String get calendarOpenDay;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @bookingsNeedsYou.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get bookingsNeedsYou;

  /// No description provided for @searchList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get searchList;

  /// No description provided for @homePlanning.
  ///
  /// In en, this message translates to:
  /// **'What are you planning?'**
  String get homePlanning;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homePlanNew.
  ///
  /// In en, this message translates to:
  /// **'Plan something new'**
  String get homePlanNew;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search venues, Foxers and events'**
  String get homeSearchHint;

  /// No description provided for @homeStartPlanning.
  ///
  /// In en, this message translates to:
  /// **'Start planning'**
  String get homeStartPlanning;

  /// No description provided for @homePackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular {occasion} packages'**
  String homePackagesTitle(String occasion);

  /// No description provided for @homePackagesTitleIn.
  ///
  /// In en, this message translates to:
  /// **'Popular {occasion} packages in {city}'**
  String homePackagesTitleIn(String occasion, String city);

  /// No description provided for @packageFromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String packageFromPrice(String price);

  /// No description provided for @homeVenuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Venues to browse'**
  String get homeVenuesTitle;

  /// No description provided for @homeVenuesTitleIn.
  ///
  /// In en, this message translates to:
  /// **'Venues in {city}'**
  String homeVenuesTitleIn(String city);

  /// No description provided for @homeGearTitle.
  ///
  /// In en, this message translates to:
  /// **'Gear to rent'**
  String get homeGearTitle;

  /// No description provided for @homeServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services to add'**
  String get homeServicesTitle;

  /// No description provided for @homeFoxersTitle.
  ///
  /// In en, this message translates to:
  /// **'Foxers to plan with'**
  String get homeFoxersTitle;

  /// No description provided for @homeRepublicTitle.
  ///
  /// In en, this message translates to:
  /// **'From the Republic'**
  String get homeRepublicTitle;

  /// No description provided for @homeChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan your first event'**
  String get homeChecklistTitle;

  /// No description provided for @homeChecklistProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String homeChecklistProgress(int done, int total);

  /// No description provided for @homeChecklistStep1.
  ///
  /// In en, this message translates to:
  /// **'Pick what you\'re planning'**
  String get homeChecklistStep1;

  /// No description provided for @homeChecklistStep2.
  ///
  /// In en, this message translates to:
  /// **'Choose a package or venue'**
  String get homeChecklistStep2;

  /// No description provided for @homeChecklistStep3.
  ///
  /// In en, this message translates to:
  /// **'Book it and get your ticket'**
  String get homeChecklistStep3;

  /// No description provided for @homeChecklistStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get homeChecklistStart;

  /// No description provided for @homeChecklistContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeChecklistContinue;

  /// No description provided for @homeComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get homeComingUp;

  /// No description provided for @homeComingUpElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Nothing in {city} yet, so here is what is on elsewhere.'**
  String homeComingUpElsewhere(String city);

  /// No description provided for @homeContinuePlanning.
  ///
  /// In en, this message translates to:
  /// **'Continue planning'**
  String get homeContinuePlanning;

  /// No description provided for @homeBookOne.
  ///
  /// In en, this message translates to:
  /// **'Or book just one thing'**
  String get homeBookOne;

  /// No description provided for @homeHappeningSoon.
  ///
  /// In en, this message translates to:
  /// **'Happening soon near you'**
  String get homeHappeningSoon;

  /// No description provided for @homeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue: {occasion}'**
  String homeContinue(String occasion);

  /// No description provided for @homeIdeas.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 idea} other{{count} ideas}}'**
  String homeIdeas(int count);

  /// No description provided for @homeMoreCount.
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String homeMoreCount(int count);

  /// No description provided for @occasionBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get occasionBirthday;

  /// No description provided for @occasionWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get occasionWedding;

  /// No description provided for @occasionCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get occasionCorporate;

  /// No description provided for @occasionSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get occasionSocial;

  /// No description provided for @occasionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get occasionOther;

  /// No description provided for @occasionAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get occasionAll;

  /// No description provided for @categoryVenues.
  ///
  /// In en, this message translates to:
  /// **'Venues'**
  String get categoryVenues;

  /// No description provided for @categoryPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get categoryPhotography;

  /// No description provided for @categoryVideography.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get categoryVideography;

  /// No description provided for @categoryDj.
  ///
  /// In en, this message translates to:
  /// **'DJ'**
  String get categoryDj;

  /// No description provided for @categoryLiveBand.
  ///
  /// In en, this message translates to:
  /// **'Live band'**
  String get categoryLiveBand;

  /// No description provided for @categoryMc.
  ///
  /// In en, this message translates to:
  /// **'MC'**
  String get categoryMc;

  /// No description provided for @categoryCatering.
  ///
  /// In en, this message translates to:
  /// **'Catering'**
  String get categoryCatering;

  /// No description provided for @categoryDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get categoryDesign;

  /// No description provided for @categoryStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get categoryStaff;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categorySound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get categorySound;

  /// No description provided for @categoryDecor.
  ///
  /// In en, this message translates to:
  /// **'Decor'**
  String get categoryDecor;

  /// No description provided for @categoryFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get categoryFurniture;

  /// No description provided for @categoryEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get categoryEquipment;

  /// No description provided for @occasionTitle.
  ///
  /// In en, this message translates to:
  /// **'{occasion} ideas'**
  String occasionTitle(String occasion);

  /// No description provided for @occasionTitleIn.
  ///
  /// In en, this message translates to:
  /// **'{occasion} ideas in {city}'**
  String occasionTitleIn(String occasion, String city);

  /// No description provided for @occasionPackages.
  ///
  /// In en, this message translates to:
  /// **'Ready-made packages'**
  String get occasionPackages;

  /// No description provided for @occasionAskPrice.
  ///
  /// In en, this message translates to:
  /// **'Ask for a price'**
  String get occasionAskPrice;

  /// No description provided for @occasionNoPackages.
  ///
  /// In en, this message translates to:
  /// **'No ready-made {occasion} packages yet.'**
  String occasionNoPackages(String occasion);

  /// No description provided for @occasionNoPackagesIn.
  ///
  /// In en, this message translates to:
  /// **'No ready-made {occasion} packages in {city} yet.'**
  String occasionNoPackagesIn(String occasion, String city);

  /// No description provided for @occasionPlanner.
  ///
  /// In en, this message translates to:
  /// **'Have a Foxer plan it'**
  String get occasionPlanner;

  /// No description provided for @occasionPlannerBody.
  ///
  /// In en, this message translates to:
  /// **'Tell a planner what you want and they handle the rest.'**
  String get occasionPlannerBody;

  /// No description provided for @occasionFindPlanner.
  ///
  /// In en, this message translates to:
  /// **'Find a planner'**
  String get occasionFindPlanner;

  /// No description provided for @occasionYourself.
  ///
  /// In en, this message translates to:
  /// **'Plan it yourself'**
  String get occasionYourself;

  /// No description provided for @occasionNoneHere.
  ///
  /// In en, this message translates to:
  /// **'None here yet'**
  String get occasionNoneHere;

  /// No description provided for @planAddDate.
  ///
  /// In en, this message translates to:
  /// **'Add date'**
  String get planAddDate;

  /// No description provided for @planGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get planGuests;

  /// No description provided for @planWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get planWhen;

  /// No description provided for @planApply.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get planApply;

  /// No description provided for @guestsUpTo20.
  ///
  /// In en, this message translates to:
  /// **'Up to 20'**
  String get guestsUpTo20;

  /// No description provided for @guests20to50.
  ///
  /// In en, this message translates to:
  /// **'20–50'**
  String get guests20to50;

  /// No description provided for @guests50to100.
  ///
  /// In en, this message translates to:
  /// **'50–100'**
  String get guests50to100;

  /// No description provided for @guests100plus.
  ///
  /// In en, this message translates to:
  /// **'100+'**
  String get guests100plus;

  /// No description provided for @allCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything you can book'**
  String get allCategoriesTitle;

  /// No description provided for @allCategoriesFind.
  ///
  /// In en, this message translates to:
  /// **'Find a category'**
  String get allCategoriesFind;

  /// No description provided for @allCategoriesOccasions.
  ///
  /// In en, this message translates to:
  /// **'Occasions'**
  String get allCategoriesOccasions;

  /// No description provided for @allCategoriesPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get allCategoriesPeople;

  /// No description provided for @allCategoriesGear.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get allCategoriesGear;

  /// No description provided for @allCategoriesVenues.
  ///
  /// In en, this message translates to:
  /// **'Venues'**
  String get allCategoriesVenues;

  /// No description provided for @allCategoriesNone.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get allCategoriesNone;

  /// No description provided for @itemBookDays.
  ///
  /// In en, this message translates to:
  /// **'How many days?'**
  String get itemBookDays;

  /// No description provided for @itemBookQuantity.
  ///
  /// In en, this message translates to:
  /// **'How many?'**
  String get itemBookQuantity;

  /// No description provided for @itemBookPickup.
  ///
  /// In en, this message translates to:
  /// **'Pick up'**
  String get itemBookPickup;

  /// No description provided for @itemBookDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get itemBookDelivery;

  /// No description provided for @itemBookAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get itemBookAddress;

  /// No description provided for @itemBookLocation.
  ///
  /// In en, this message translates to:
  /// **'Where is the event?'**
  String get itemBookLocation;

  /// No description provided for @itemBookStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get itemBookStarts;

  /// No description provided for @itemBookNeedAddress.
  ///
  /// In en, this message translates to:
  /// **'Add a delivery address.'**
  String get itemBookNeedAddress;

  /// No description provided for @itemBookNeedLocation.
  ///
  /// In en, this message translates to:
  /// **'Add where the event is.'**
  String get itemBookNeedLocation;

  /// No description provided for @itemBookNeedDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date.'**
  String get itemBookNeedDate;

  /// No description provided for @itemBookBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get itemBookBook;

  /// No description provided for @itemBookedSub.
  ///
  /// In en, this message translates to:
  /// **'The owner has been told. Follow it in Messages.'**
  String get itemBookedSub;

  /// No description provided for @itemBookDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get itemBookDone;

  /// No description provided for @itemBookSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to book.'**
  String get itemBookSignIn;

  /// No description provided for @itemBookAbout.
  ///
  /// In en, this message translates to:
  /// **'About this'**
  String get itemBookAbout;

  /// No description provided for @itemBookPriceFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get itemBookPriceFrom;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String reviewsCount(int count);

  /// No description provided for @reviewsNone.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get reviewsNone;

  /// No description provided for @reviewsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all {count}'**
  String reviewsSeeAll(int count);

  /// No description provided for @reviewsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the reviews.'**
  String get reviewsLoadFailed;

  /// No description provided for @reviewWrite.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get reviewWrite;

  /// No description provided for @ticketBookAgain.
  ///
  /// In en, this message translates to:
  /// **'Book again'**
  String get ticketBookAgain;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'How was it?'**
  String get reviewTitle;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tell others what it was like (optional)'**
  String get reviewHint;

  /// No description provided for @reviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Post review'**
  String get reviewSubmit;

  /// No description provided for @reviewThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks, your review is posted.'**
  String get reviewThanks;

  /// No description provided for @reviewFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t post your review. Try again.'**
  String get reviewFailed;

  /// No description provided for @reviewPickStars.
  ///
  /// In en, this message translates to:
  /// **'Choose a star rating.'**
  String get reviewPickStars;

  /// No description provided for @republicTitle.
  ///
  /// In en, this message translates to:
  /// **'Republic'**
  String get republicTitle;

  /// No description provided for @republicRowBody.
  ///
  /// In en, this message translates to:
  /// **'What the community is posting'**
  String get republicRowBody;

  /// No description provided for @republicTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get republicTabAll;

  /// No description provided for @republicTabCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get republicTabCommunity;

  /// No description provided for @republicTabMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get republicTabMarketplace;

  /// No description provided for @republicEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing posted here yet. Be the first.'**
  String get republicEmpty;

  /// No description provided for @republicPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get republicPost;

  /// No description provided for @republicCompose.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get republicCompose;

  /// No description provided for @republicComposeHint.
  ///
  /// In en, this message translates to:
  /// **'Share something with the Republic'**
  String get republicComposeHint;

  /// No description provided for @republicPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted.'**
  String get republicPosted;

  /// No description provided for @republicPostFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t post that. Try again.'**
  String get republicPostFailed;

  /// No description provided for @republicLikeFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your like.'**
  String get republicLikeFailed;

  /// No description provided for @republicComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get republicComments;

  /// No description provided for @republicNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get republicNoComments;

  /// No description provided for @republicCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get republicCommentHint;

  /// No description provided for @republicSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get republicSend;

  /// No description provided for @republicCommentFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t post your comment.'**
  String get republicCommentFailed;

  /// No description provided for @republicEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get republicEdited;

  /// No description provided for @republicJustNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get republicJustNow;

  /// No description provided for @republicMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String republicMinutesAgo(int count);

  /// No description provided for @republicHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String republicHoursAgo(int count);

  /// No description provided for @republicMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get republicMore;

  /// No description provided for @republicSeeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get republicSeeMore;

  /// No description provided for @republicSeeLess.
  ///
  /// In en, this message translates to:
  /// **'See less'**
  String get republicSeeLess;

  /// No description provided for @republicMenuCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get republicMenuCopyLink;

  /// No description provided for @republicMenuSave.
  ///
  /// In en, this message translates to:
  /// **'Save post'**
  String get republicMenuSave;

  /// No description provided for @republicMenuUnsave.
  ///
  /// In en, this message translates to:
  /// **'Unsave'**
  String get republicMenuUnsave;

  /// No description provided for @republicMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get republicMenuEdit;

  /// No description provided for @republicMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get republicMenuDelete;

  /// No description provided for @republicMenuHide.
  ///
  /// In en, this message translates to:
  /// **'Hide post'**
  String get republicMenuHide;

  /// No description provided for @republicMenuReport.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get republicMenuReport;

  /// No description provided for @republicLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get republicLinkCopied;

  /// No description provided for @republicSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get republicSaved;

  /// No description provided for @republicUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get republicUnsaved;

  /// No description provided for @republicHidden.
  ///
  /// In en, this message translates to:
  /// **'Post hidden'**
  String get republicHidden;

  /// No description provided for @republicDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get republicDeleted;

  /// No description provided for @republicEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get republicEditTitle;

  /// No description provided for @republicEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get republicEditSave;

  /// No description provided for @republicUpdated.
  ///
  /// In en, this message translates to:
  /// **'Post updated'**
  String get republicUpdated;

  /// No description provided for @republicDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this post?'**
  String get republicDeleteTitle;

  /// No description provided for @republicDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get republicDeleteBody;

  /// No description provided for @republicDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get republicDeleteConfirm;

  /// No description provided for @republicCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get republicCancel;

  /// No description provided for @republicActionFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Try again.'**
  String get republicActionFailed;

  /// No description provided for @republicSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved posts'**
  String get republicSavedTitle;

  /// No description provided for @republicSavedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet. Save a post from its menu.'**
  String get republicSavedEmpty;

  /// No description provided for @republicReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this post'**
  String get republicReportTitle;

  /// No description provided for @republicReported.
  ///
  /// In en, this message translates to:
  /// **'Thanks, we\'ll take a look.'**
  String get republicReported;

  /// No description provided for @republicReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get republicReasonSpam;

  /// No description provided for @republicReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get republicReasonHarassment;

  /// No description provided for @republicReasonHate.
  ///
  /// In en, this message translates to:
  /// **'Hate speech'**
  String get republicReasonHate;

  /// No description provided for @republicReasonNudity.
  ///
  /// In en, this message translates to:
  /// **'Nudity or sexual content'**
  String get republicReasonNudity;

  /// No description provided for @republicReasonViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence or dangerous content'**
  String get republicReasonViolence;

  /// No description provided for @republicReasonMisinfo.
  ///
  /// In en, this message translates to:
  /// **'Misinformation'**
  String get republicReasonMisinfo;

  /// No description provided for @republicReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get republicReasonOther;

  /// No description provided for @republicComposePrompt.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get republicComposePrompt;

  /// No description provided for @republicLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get republicLike;

  /// No description provided for @republicReactLove.
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get republicReactLove;

  /// No description provided for @republicReactHaha.
  ///
  /// In en, this message translates to:
  /// **'Haha'**
  String get republicReactHaha;

  /// No description provided for @republicReactWow.
  ///
  /// In en, this message translates to:
  /// **'Wow'**
  String get republicReactWow;

  /// No description provided for @republicReactSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get republicReactSad;

  /// No description provided for @republicReactAngry.
  ///
  /// In en, this message translates to:
  /// **'Angry'**
  String get republicReactAngry;

  /// No description provided for @republicReactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get republicReactions;

  /// No description provided for @republicTabPartners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get republicTabPartners;

  /// No description provided for @republicSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get republicSortBy;

  /// No description provided for @republicSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get republicSortRecent;

  /// No description provided for @republicSortTop.
  ///
  /// In en, this message translates to:
  /// **'Top posts'**
  String get republicSortTop;

  /// No description provided for @republicSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search the Republic'**
  String get republicSearchHint;

  /// No description provided for @republicSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No posts match “{query}”.'**
  String republicSearchEmpty(String query);

  /// No description provided for @republicClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get republicClearSearch;

  /// No description provided for @republicShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get republicShare;

  /// No description provided for @republicRepost.
  ///
  /// In en, this message translates to:
  /// **'Repost'**
  String get republicRepost;

  /// No description provided for @republicRepostTitle.
  ///
  /// In en, this message translates to:
  /// **'Repost to your feed'**
  String get republicRepostTitle;

  /// No description provided for @republicRepostHint.
  ///
  /// In en, this message translates to:
  /// **'Say something about this…'**
  String get republicRepostHint;

  /// No description provided for @republicReposted.
  ///
  /// In en, this message translates to:
  /// **'Reposted to your feed.'**
  String get republicReposted;

  /// No description provided for @republicSendInMessage.
  ///
  /// In en, this message translates to:
  /// **'Send in message'**
  String get republicSendInMessage;

  /// No description provided for @republicSendPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Send post'**
  String get republicSendPostTitle;

  /// No description provided for @republicSendSearch.
  ///
  /// In en, this message translates to:
  /// **'Search your chats'**
  String get republicSendSearch;

  /// No description provided for @republicSendCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a message…'**
  String get republicSendCaptionHint;

  /// No description provided for @republicSendNoChats.
  ///
  /// In en, this message translates to:
  /// **'No chats to send to. Start a chat first.'**
  String get republicSendNoChats;

  /// No description provided for @republicPostSent.
  ///
  /// In en, this message translates to:
  /// **'Post sent.'**
  String get republicPostSent;

  /// No description provided for @republicPostSentMany.
  ///
  /// In en, this message translates to:
  /// **'Post sent to {count} chats.'**
  String republicPostSentMany(int count);

  /// No description provided for @republicSendPostFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send that post. Try again.'**
  String get republicSendPostFailed;

  /// No description provided for @republicVerifiedStamp.
  ///
  /// In en, this message translates to:
  /// **'Verified Venue Stamp'**
  String get republicVerifiedStamp;

  /// No description provided for @republicVerifiedBooking.
  ///
  /// In en, this message translates to:
  /// **'Verified booking'**
  String get republicVerifiedBooking;

  /// No description provided for @republicVotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 vote} other{{count} votes}}'**
  String republicVotesCount(int count);

  /// No description provided for @republicVoteFailed.
  ///
  /// In en, this message translates to:
  /// **'Your vote didn\'t go through.'**
  String get republicVoteFailed;

  /// No description provided for @republicPinned.
  ///
  /// In en, this message translates to:
  /// **'Featured in Republic'**
  String get republicPinned;

  /// No description provided for @republicBookVenue.
  ///
  /// In en, this message translates to:
  /// **'Book venue'**
  String get republicBookVenue;

  /// No description provided for @republicRentGear.
  ///
  /// In en, this message translates to:
  /// **'Rent gear'**
  String get republicRentGear;

  /// No description provided for @republicBookService.
  ///
  /// In en, this message translates to:
  /// **'Book service'**
  String get republicBookService;

  /// No description provided for @republicGetTickets.
  ///
  /// In en, this message translates to:
  /// **'Get tickets'**
  String get republicGetTickets;

  /// No description provided for @republicMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get republicMessage;

  /// No description provided for @republicPartnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Official Partner Foxer opportunity'**
  String get republicPartnerTitle;

  /// No description provided for @republicPartnerBody.
  ///
  /// In en, this message translates to:
  /// **'Available for funding, package allocations and co-host production.'**
  String get republicPartnerBody;

  /// No description provided for @republicContactPartner.
  ///
  /// In en, this message translates to:
  /// **'Contact partner'**
  String get republicContactPartner;

  /// No description provided for @republicSharedPost.
  ///
  /// In en, this message translates to:
  /// **'Shared a post'**
  String get republicSharedPost;

  /// No description provided for @republicTypeStory.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get republicTypeStory;

  /// No description provided for @republicTypePoll.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get republicTypePoll;

  /// No description provided for @republicTypeVenue.
  ///
  /// In en, this message translates to:
  /// **'Spotlight venue'**
  String get republicTypeVenue;

  /// No description provided for @republicVisibility.
  ///
  /// In en, this message translates to:
  /// **'Who can see this'**
  String get republicVisibility;

  /// No description provided for @republicVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get republicVisibilityPublic;

  /// No description provided for @republicVisibilityFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get republicVisibilityFollowers;

  /// No description provided for @republicVisibilityOnlyMe.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get republicVisibilityOnlyMe;

  /// No description provided for @republicPosting.
  ///
  /// In en, this message translates to:
  /// **'Posting…'**
  String get republicPosting;

  /// No description provided for @republicPollHint.
  ///
  /// In en, this message translates to:
  /// **'Ask the Republic a question…'**
  String get republicPollHint;

  /// No description provided for @republicPollOption.
  ///
  /// In en, this message translates to:
  /// **'Option {n}'**
  String republicPollOption(int n);

  /// No description provided for @republicAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get republicAddOption;

  /// No description provided for @republicAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get republicAddPhotos;

  /// No description provided for @republicPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} photos'**
  String republicPhotoCount(int count, int max);

  /// No description provided for @republicChooseVenue.
  ///
  /// In en, this message translates to:
  /// **'Choose a venue'**
  String get republicChooseVenue;

  /// No description provided for @republicNoVenues.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have a venue to spotlight yet.'**
  String get republicNoVenues;

  /// No description provided for @republicReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get republicReply;

  /// No description provided for @republicReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String republicReplyingTo(String name);

  /// No description provided for @republicEditingComment.
  ///
  /// In en, this message translates to:
  /// **'Editing your comment'**
  String get republicEditingComment;

  /// No description provided for @republicEditComment.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get republicEditComment;

  /// No description provided for @republicDeleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get republicDeleteComment;

  /// No description provided for @republicDeleteCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment?'**
  String get republicDeleteCommentTitle;

  /// No description provided for @republicNoReactions.
  ///
  /// In en, this message translates to:
  /// **'No reactions yet.'**
  String get republicNoReactions;

  /// No description provided for @republicCommentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String republicCommentsCount(int count);

  /// No description provided for @republicDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String republicDaysAgo(int count);

  /// No description provided for @passportTabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get passportTabProgress;

  /// No description provided for @passportTabStamps.
  ///
  /// In en, this message translates to:
  /// **'Stamps'**
  String get passportTabStamps;

  /// No description provided for @passportTabMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get passportTabMatches;

  /// No description provided for @passportTabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get passportTabSaved;

  /// No description provided for @passportTabEarn.
  ///
  /// In en, this message translates to:
  /// **'Earn'**
  String get passportTabEarn;

  /// No description provided for @passportSavedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved posts yet.'**
  String get passportSavedEmpty;

  /// No description provided for @passportSavedAction.
  ///
  /// In en, this message translates to:
  /// **'Browse Republic'**
  String get passportSavedAction;

  /// No description provided for @passportEarnIntro.
  ///
  /// In en, this message translates to:
  /// **'Apply to become a Foxer — hosts, venues, gear and talent keep FoxPassport running.'**
  String get passportEarnIntro;

  /// No description provided for @passportEarnApply.
  ///
  /// In en, this message translates to:
  /// **'Apply on web'**
  String get passportEarnApply;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to log in again to use FoxPassport.'**
  String get signOutConfirmBody;

  /// No description provided for @signOutStay.
  ///
  /// In en, this message translates to:
  /// **'Stay signed in'**
  String get signOutStay;

  /// No description provided for @signOutFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t sign you out. Try again.'**
  String get signOutFailed;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileNameLabel;

  /// No description provided for @profileUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profileUsernameLabel;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get profilePhoneLabel;

  /// No description provided for @profilePrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Private profile'**
  String get profilePrivateTitle;

  /// No description provided for @profilePrivateBody.
  ///
  /// In en, this message translates to:
  /// **'New followers must be approved by you. Your followers and following lists are hidden from everyone else.'**
  String get profilePrivateBody;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileChangePhoto;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your photo was updated.'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t update your photo. Try again.'**
  String get profilePhotoFailed;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSave;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your profile was updated.'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t update your profile. Try again.'**
  String get profileUpdateFailed;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your full profile, so this shows what we have.'**
  String get profileLoadFailed;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String profileMemberSince(String date);

  /// No description provided for @a11yDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease {thing}'**
  String a11yDecrease(String thing);

  /// No description provided for @a11yIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase {thing}'**
  String a11yIncrease(String thing);

  /// No description provided for @teamTitle.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get teamTitle;

  /// No description provided for @teamIntro.
  ///
  /// In en, this message translates to:
  /// **'Add Organizers and Check-in Helpers to what you run. Prices, payouts, refunds and the team itself stay with you.'**
  String get teamIntro;

  /// No description provided for @teamYourVenues.
  ///
  /// In en, this message translates to:
  /// **'Your venues'**
  String get teamYourVenues;

  /// No description provided for @teamYourEvents.
  ///
  /// In en, this message translates to:
  /// **'Your upcoming events'**
  String get teamYourEvents;

  /// No description provided for @teamNoVenues.
  ///
  /// In en, this message translates to:
  /// **'You have no venues yet.'**
  String get teamNoVenues;

  /// No description provided for @teamNoEvents.
  ///
  /// In en, this message translates to:
  /// **'You have no upcoming events.'**
  String get teamNoEvents;

  /// No description provided for @teamAcceptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept requests from Organizers'**
  String get teamAcceptsTitle;

  /// No description provided for @teamAcceptsBody.
  ///
  /// In en, this message translates to:
  /// **'Approved Organizers can ask to join. You decide on every request.'**
  String get teamAcceptsBody;

  /// No description provided for @teamRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests to join'**
  String get teamRequests;

  /// No description provided for @teamAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get teamAccept;

  /// No description provided for @teamDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get teamDecline;

  /// No description provided for @teamKindOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get teamKindOrganizer;

  /// No description provided for @teamKindHelper.
  ///
  /// In en, this message translates to:
  /// **'Check-in Helper'**
  String get teamKindHelper;

  /// No description provided for @teamHintOrganizer.
  ///
  /// In en, this message translates to:
  /// **'An approved Organizer who helps you run this. Find them by name or city, or type their email. They must accept, and the invitation expires after 14 days.'**
  String get teamHintOrganizer;

  /// No description provided for @teamHintHelper.
  ///
  /// In en, this message translates to:
  /// **'Anyone, added straight away, who can only check guests in at the door.'**
  String get teamHintHelper;

  /// No description provided for @teamFieldOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Search by name or city, or type an email'**
  String get teamFieldOrganizer;

  /// No description provided for @teamFieldHelper.
  ///
  /// In en, this message translates to:
  /// **'Their email address'**
  String get teamFieldHelper;

  /// No description provided for @teamSendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send invitation'**
  String get teamSendInvite;

  /// No description provided for @teamAddHelper.
  ///
  /// In en, this message translates to:
  /// **'Add helper'**
  String get teamAddHelper;

  /// No description provided for @teamSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching Organizers…'**
  String get teamSearching;

  /// No description provided for @teamNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No approved Organizers match. You can still invite someone by email.'**
  String get teamNoMatches;

  /// No description provided for @teamInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get teamInvite;

  /// No description provided for @teamOnTeamAlready.
  ///
  /// In en, this message translates to:
  /// **'On the team'**
  String get teamOnTeamAlready;

  /// No description provided for @teamLevel.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String teamLevel(int level);

  /// No description provided for @teamOnTheTeam.
  ///
  /// In en, this message translates to:
  /// **'On the team'**
  String get teamOnTheTeam;

  /// No description provided for @teamWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an answer'**
  String get teamWaiting;

  /// No description provided for @teamSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String teamSince(String date);

  /// No description provided for @teamExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String teamExpires(String date);

  /// No description provided for @teamEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one else yet. Only you can run this.'**
  String get teamEmpty;

  /// No description provided for @teamLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your team.'**
  String get teamLoadFailed;

  /// No description provided for @teamRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get teamRemove;

  /// No description provided for @teamWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get teamWithdraw;

  /// No description provided for @teamRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String teamRemoveTitle(String name);

  /// No description provided for @teamRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be on this team.'**
  String get teamRemoveBody;

  /// No description provided for @teamWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw the invitation to {name}?'**
  String teamWithdrawTitle(String name);

  /// No description provided for @teamWithdrawBody.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to accept it.'**
  String get teamWithdrawBody;

  /// No description provided for @teamPast.
  ///
  /// In en, this message translates to:
  /// **'Past ({count})'**
  String teamPast(int count);

  /// No description provided for @teamPastExpired.
  ///
  /// In en, this message translates to:
  /// **'Invitation expired'**
  String get teamPastExpired;

  /// No description provided for @teamPastDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get teamPastDeclined;

  /// No description provided for @teamPastFinished.
  ///
  /// In en, this message translates to:
  /// **'Event over'**
  String get teamPastFinished;

  /// No description provided for @teamPastLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get teamPastLeft;

  /// No description provided for @teamPastRevoked.
  ///
  /// In en, this message translates to:
  /// **'Organizer role removed'**
  String get teamPastRevoked;

  /// No description provided for @teamPastRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get teamPastRemoved;

  /// No description provided for @teamInvited.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get teamInvited;

  /// No description provided for @teamHelperAdded.
  ///
  /// In en, this message translates to:
  /// **'Helper added'**
  String get teamHelperAdded;

  /// No description provided for @teamRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from the team'**
  String get teamRemoved;

  /// No description provided for @teamWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Invitation withdrawn'**
  String get teamWithdrawn;

  /// No description provided for @teamRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted'**
  String get teamRequestAccepted;

  /// No description provided for @teamRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get teamRequestDeclined;

  /// No description provided for @teamActionFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t go through. Try again.'**
  String get teamActionFailed;

  /// No description provided for @studioStepOf.
  ///
  /// In en, this message translates to:
  /// **'STEP {n} OF {total}'**
  String studioStepOf(int n, int total);

  /// No description provided for @studioCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get studioCover;

  /// No description provided for @studioPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{n} of {max} photos'**
  String studioPhotoCount(int n, int max);

  /// No description provided for @esCardDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get esCardDetails;

  /// No description provided for @esCardGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests and policy'**
  String get esCardGuests;

  /// No description provided for @esAddTalent.
  ///
  /// In en, this message translates to:
  /// **'Talent'**
  String get esAddTalent;

  /// No description provided for @esAddServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get esAddServices;

  /// No description provided for @esAddEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get esAddEquipment;

  /// No description provided for @esAddHint.
  ///
  /// In en, this message translates to:
  /// **'Add to your package'**
  String get esAddHint;

  /// No description provided for @esYourPrice.
  ///
  /// In en, this message translates to:
  /// **'Price to sell at'**
  String get esYourPrice;

  /// No description provided for @esPackageItems.
  ///
  /// In en, this message translates to:
  /// **'What is included'**
  String get esPackageItems;

  /// No description provided for @spaceWorkingAs.
  ///
  /// In en, this message translates to:
  /// **'Working as'**
  String get spaceWorkingAs;

  /// No description provided for @spaceCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get spaceCurrent;

  /// No description provided for @spaceSwitched.
  ///
  /// In en, this message translates to:
  /// **'Now in the {space} space'**
  String spaceSwitched(String space);

  /// No description provided for @spaceGear.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get spaceGear;

  /// No description provided for @spaceGearHint.
  ///
  /// In en, this message translates to:
  /// **'Your gear and the requests for it'**
  String get spaceGearHint;

  /// No description provided for @spaceServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get spaceServices;

  /// No description provided for @spaceServicesHint.
  ///
  /// In en, this message translates to:
  /// **'Your services and the requests for them'**
  String get spaceServicesHint;

  /// No description provided for @spacePerformer.
  ///
  /// In en, this message translates to:
  /// **'Performer'**
  String get spacePerformer;

  /// No description provided for @spacePerformerHint.
  ///
  /// In en, this message translates to:
  /// **'Your performances and the requests for them'**
  String get spacePerformerHint;

  /// No description provided for @spaceTabPerformances.
  ///
  /// In en, this message translates to:
  /// **'Performances'**
  String get spaceTabPerformances;

  /// No description provided for @requestsIntroGear.
  ///
  /// In en, this message translates to:
  /// **'People adding your gear to their events. Confirm the ones you can supply.'**
  String get requestsIntroGear;

  /// No description provided for @requestsEmptyGear.
  ///
  /// In en, this message translates to:
  /// **'No requests yet. When someone adds your gear to their event, it shows up here.'**
  String get requestsEmptyGear;

  /// No description provided for @requestsIntroServices.
  ///
  /// In en, this message translates to:
  /// **'People adding your services to their events. Confirm the ones you can do.'**
  String get requestsIntroServices;

  /// No description provided for @requestsEmptyServices.
  ///
  /// In en, this message translates to:
  /// **'No requests yet. When someone adds your service to their event, it shows up here.'**
  String get requestsEmptyServices;

  /// No description provided for @providerGear.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get providerGear;

  /// No description provided for @providerServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get providerServices;

  /// No description provided for @providerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your listings'**
  String get providerSearchHint;

  /// No description provided for @providerEmptyGear.
  ///
  /// In en, this message translates to:
  /// **'You have no gear listed yet.'**
  String get providerEmptyGear;

  /// No description provided for @providerEmptyServices.
  ///
  /// In en, this message translates to:
  /// **'You have no services listed yet.'**
  String get providerEmptyServices;

  /// No description provided for @providerAddOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Add on web'**
  String get providerAddOnWeb;

  /// No description provided for @providerListingEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit on the web'**
  String get providerListingEdit;

  /// No description provided for @providerListingView.
  ///
  /// In en, this message translates to:
  /// **'View public page'**
  String get providerListingView;

  /// No description provided for @providerStatLive.
  ///
  /// In en, this message translates to:
  /// **'Listings live'**
  String get providerStatLive;

  /// No description provided for @providerStatJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs, next 30 days'**
  String get providerStatJobs;

  /// No description provided for @providerComingUp.
  ///
  /// In en, this message translates to:
  /// **'Confirmed and coming up'**
  String get providerComingUp;

  /// No description provided for @providerNothingComing.
  ///
  /// In en, this message translates to:
  /// **'Nothing confirmed yet.'**
  String get providerNothingComing;

  /// No description provided for @providerRequestsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 request needs your reply} other{{count} requests need your reply}}'**
  String providerRequestsWaiting(int count);

  /// No description provided for @ticketsOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'No connection. Showing the tickets saved {when}.'**
  String ticketsOfflineNote(String when);
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
