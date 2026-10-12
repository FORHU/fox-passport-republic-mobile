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

  /// No description provided for @passport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

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
