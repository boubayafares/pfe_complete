import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FootTech'**
  String get appTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Coach, Assistant or Player — your club, in your pocket.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingCoachBtn.
  ///
  /// In en, this message translates to:
  /// **'I am a Coach or Assistant'**
  String get onboardingCoachBtn;

  /// No description provided for @onboardingPlayerBtn.
  ///
  /// In en, this message translates to:
  /// **'I am a Player (SMS login)'**
  String get onboardingPlayerBtn;

  /// No description provided for @onboardingCreateCoach.
  ///
  /// In en, this message translates to:
  /// **'New club? Create a Coach account'**
  String get onboardingCreateCoach;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Coach / Assistant Login'**
  String get loginTitle;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @firstTimeAssistant.
  ///
  /// In en, this message translates to:
  /// **'First-time Assistant login?'**
  String get firstTimeAssistant;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @unableToLogin.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect'**
  String get unableToLogin;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a Coach account'**
  String get registerTitle;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @min8Chars.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get min8Chars;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get createAccount;

  /// No description provided for @unableToRegister.
  ///
  /// In en, this message translates to:
  /// **'Unable to register'**
  String get unableToRegister;

  /// No description provided for @activateTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant Activation'**
  String get activateTitle;

  /// No description provided for @activateIntro.
  ///
  /// In en, this message translates to:
  /// **'Your coach has added you as an assistant. A code was sent by SMS to the number provided — enter it below with a password of your choice to activate your account.'**
  String get activateIntro;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @codeReceivedSms.
  ///
  /// In en, this message translates to:
  /// **'Code received by SMS'**
  String get codeReceivedSms;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @activateButton.
  ///
  /// In en, this message translates to:
  /// **'Activate my account'**
  String get activateButton;

  /// No description provided for @codeExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired or never received? Ask your coach to re-add you to the team to receive a new code.'**
  String get codeExpired;

  /// No description provided for @accountActivatedLogin.
  ///
  /// In en, this message translates to:
  /// **'Account activated — you can now log in'**
  String get accountActivatedLogin;

  /// No description provided for @playerLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Player Login'**
  String get playerLoginTitle;

  /// No description provided for @codeSentToPhone.
  ///
  /// In en, this message translates to:
  /// **'A code has been sent to {phone}. Enter it below.'**
  String codeSentToPhone(Object phone);

  /// No description provided for @enterCoachPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter the phone number you gave your coach.'**
  String get enterCoachPhone;

  /// No description provided for @validate.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get validate;

  /// No description provided for @receiveCode.
  ///
  /// In en, this message translates to:
  /// **'Receive the code'**
  String get receiveCode;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Account verification'**
  String get otpTitle;

  /// No description provided for @otpCodeSentEmail.
  ///
  /// In en, this message translates to:
  /// **'A code has been sent to {email}. Enter it below to activate your account.'**
  String otpCodeSentEmail(Object email);

  /// No description provided for @otpWillSendEmail.
  ///
  /// In en, this message translates to:
  /// **'A verification code will be sent by SMS to the number associated with {email} to activate your account.'**
  String otpWillSendEmail(Object email);

  /// No description provided for @verifyAndActivate.
  ///
  /// In en, this message translates to:
  /// **'Verify and activate'**
  String get verifyAndActivate;

  /// No description provided for @receiveNewCode.
  ///
  /// In en, this message translates to:
  /// **'Receive a new code'**
  String get receiveNewCode;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get navTeam;

  /// No description provided for @navTrainings.
  ///
  /// In en, this message translates to:
  /// **'Trainings'**
  String get navTrainings;

  /// No description provided for @navMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get navMatches;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @biometricLocked.
  ///
  /// In en, this message translates to:
  /// **'FootTech is locked'**
  String get biometricLocked;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @biometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock FootTech'**
  String get biometricReason;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server'**
  String get errorNetwork;

  /// No description provided for @sessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Session not found.'**
  String get sessionNotFound;

  /// No description provided for @nextTraining.
  ///
  /// In en, this message translates to:
  /// **'Next training'**
  String get nextTraining;

  /// No description provided for @nextMatch.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get nextMatch;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get players;

  /// No description provided for @proposals.
  ///
  /// In en, this message translates to:
  /// **'Proposals'**
  String get proposals;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @seasonSummary.
  ///
  /// In en, this message translates to:
  /// **'Season summary'**
  String get seasonSummary;

  /// No description provided for @starter.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get starter;

  /// No description provided for @substitute.
  ///
  /// In en, this message translates to:
  /// **'Substitute'**
  String get substitute;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data for now'**
  String get noData;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @played.
  ///
  /// In en, this message translates to:
  /// **'Pld'**
  String get played;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @assists.
  ///
  /// In en, this message translates to:
  /// **'Assists'**
  String get assists;

  /// No description provided for @goalsConceded.
  ///
  /// In en, this message translates to:
  /// **'Goals conc.'**
  String get goalsConceded;

  /// No description provided for @noTeamLinked.
  ///
  /// In en, this message translates to:
  /// **'No team linked to your account yet.'**
  String get noTeamLinked;

  /// No description provided for @createFirstTeam.
  ///
  /// In en, this message translates to:
  /// **'Create your first team'**
  String get createFirstTeam;

  /// No description provided for @canAddPlayersAssistants.
  ///
  /// In en, this message translates to:
  /// **'You can then add your players and assistants.'**
  String get canAddPlayersAssistants;

  /// No description provided for @teamName.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get teamName;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category ({example})'**
  String category(Object example);

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @addPlayer.
  ///
  /// In en, this message translates to:
  /// **'Add a player'**
  String get addPlayer;

  /// No description provided for @addAssistant.
  ///
  /// In en, this message translates to:
  /// **'Add an assistant'**
  String get addAssistant;

  /// No description provided for @noPlayersYet.
  ///
  /// In en, this message translates to:
  /// **'No players yet'**
  String get noPlayersYet;

  /// No description provided for @noAssistantsYet.
  ///
  /// In en, this message translates to:
  /// **'No assistants yet'**
  String get noAssistantsYet;

  /// No description provided for @awaitingActivation.
  ///
  /// In en, this message translates to:
  /// **'{phone} - awaiting activation'**
  String awaitingActivation(Object phone);

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @newPlayer.
  ///
  /// In en, this message translates to:
  /// **'New player'**
  String get newPlayer;

  /// No description provided for @phoneSmsActivation.
  ///
  /// In en, this message translates to:
  /// **'Phone (SMS activation)'**
  String get phoneSmsActivation;

  /// No description provided for @primaryPosition.
  ///
  /// In en, this message translates to:
  /// **'Primary position'**
  String get primaryPosition;

  /// No description provided for @strongFoot.
  ///
  /// In en, this message translates to:
  /// **'Strong foot'**
  String get strongFoot;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @ambidextrous.
  ///
  /// In en, this message translates to:
  /// **'Ambidextrous'**
  String get ambidextrous;

  /// No description provided for @jerseyNumber.
  ///
  /// In en, this message translates to:
  /// **'Jersey number'**
  String get jerseyNumber;

  /// No description provided for @createPlayer.
  ///
  /// In en, this message translates to:
  /// **'Create player'**
  String get createPlayer;

  /// No description provided for @tabIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get tabIdentity;

  /// No description provided for @tabFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get tabFamily;

  /// No description provided for @tabSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get tabSchool;

  /// No description provided for @tabInjuries.
  ///
  /// In en, this message translates to:
  /// **'Injuries'**
  String get tabInjuries;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @foot.
  ///
  /// In en, this message translates to:
  /// **'Foot'**
  String get foot;

  /// No description provided for @evolutionBySeason.
  ///
  /// In en, this message translates to:
  /// **'Evolution by season'**
  String get evolutionBySeason;

  /// No description provided for @noDataRecorded.
  ///
  /// In en, this message translates to:
  /// **'No data recorded'**
  String get noDataRecorded;

  /// No description provided for @parentsGuardian.
  ///
  /// In en, this message translates to:
  /// **'Parents / guardian'**
  String get parentsGuardian;

  /// No description provided for @father.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get father;

  /// No description provided for @mother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get mother;

  /// No description provided for @guardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get guardian;

  /// No description provided for @noContactRecorded.
  ///
  /// In en, this message translates to:
  /// **'No contact recorded'**
  String get noContactRecorded;

  /// No description provided for @addressCommute.
  ///
  /// In en, this message translates to:
  /// **'Address and commute'**
  String get addressCommute;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @kmFromClub.
  ///
  /// In en, this message translates to:
  /// **'{distance} km from the club'**
  String kmFromClub(Object distance);

  /// No description provided for @school.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get school;

  /// No description provided for @classLevel.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classLevel;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @noInjuries.
  ///
  /// In en, this message translates to:
  /// **'No injuries recorded'**
  String get noInjuries;

  /// No description provided for @injury.
  ///
  /// In en, this message translates to:
  /// **'Injury'**
  String get injury;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'· {days} days'**
  String days(Object days);

  /// No description provided for @noTrainingPlanned.
  ///
  /// In en, this message translates to:
  /// **'No training planned'**
  String get noTrainingPlanned;

  /// No description provided for @technicalSheet.
  ///
  /// In en, this message translates to:
  /// **'Technical sheet'**
  String get technicalSheet;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @objectives.
  ///
  /// In en, this message translates to:
  /// **'Objectives'**
  String get objectives;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @situations.
  ///
  /// In en, this message translates to:
  /// **'Situations'**
  String get situations;

  /// No description provided for @noSituationAdded.
  ///
  /// In en, this message translates to:
  /// **'No situation added'**
  String get noSituationAdded;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work: {value}'**
  String work(Object value);

  /// No description provided for @recovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery: {value}'**
  String recovery(Object value);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @newSituation.
  ///
  /// In en, this message translates to:
  /// **'New situation'**
  String get newSituation;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @workDuration.
  ///
  /// In en, this message translates to:
  /// **'Work duration (e.g., 2*4)'**
  String get workDuration;

  /// No description provided for @recoveryDuration.
  ///
  /// In en, this message translates to:
  /// **'Recovery duration'**
  String get recoveryDuration;

  /// No description provided for @diagramSaved.
  ///
  /// In en, this message translates to:
  /// **'Diagram saved'**
  String get diagramSaved;

  /// No description provided for @tacticalDiagram.
  ///
  /// In en, this message translates to:
  /// **'Tactical diagram'**
  String get tacticalDiagram;

  /// No description provided for @newTraining.
  ///
  /// In en, this message translates to:
  /// **'New training'**
  String get newTraining;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTime;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @homeAwayVs.
  ///
  /// In en, this message translates to:
  /// **'{homeAway} vs {opponent}'**
  String homeAwayVs(Object homeAway, Object opponent);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get away;

  /// No description provided for @lineup.
  ///
  /// In en, this message translates to:
  /// **'Lineup'**
  String get lineup;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @starters.
  ///
  /// In en, this message translates to:
  /// **'Starters'**
  String get starters;

  /// No description provided for @substitutes.
  ///
  /// In en, this message translates to:
  /// **'Substitutes'**
  String get substitutes;

  /// No description provided for @lineupNotSet.
  ///
  /// In en, this message translates to:
  /// **'Lineup not set'**
  String get lineupNotSet;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'+ Event'**
  String get addEvent;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @noEvents.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get noEvents;

  /// No description provided for @eventGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get eventGoal;

  /// No description provided for @eventAssist.
  ///
  /// In en, this message translates to:
  /// **'Assist'**
  String get eventAssist;

  /// No description provided for @yellowCard.
  ///
  /// In en, this message translates to:
  /// **'Yellow card'**
  String get yellowCard;

  /// No description provided for @redCard.
  ///
  /// In en, this message translates to:
  /// **'Red card'**
  String get redCard;

  /// No description provided for @eventSubOn.
  ///
  /// In en, this message translates to:
  /// **'Substituted on'**
  String get eventSubOn;

  /// No description provided for @eventSubOff.
  ///
  /// In en, this message translates to:
  /// **'Substituted off'**
  String get eventSubOff;

  /// No description provided for @eventInjury.
  ///
  /// In en, this message translates to:
  /// **'Injury'**
  String get eventInjury;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minute;

  /// No description provided for @generateAiRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Generate AI recommendations'**
  String get generateAiRecommendations;

  /// No description provided for @noRecommendation.
  ///
  /// In en, this message translates to:
  /// **'No recommendation generated'**
  String get noRecommendation;

  /// No description provided for @playerId.
  ///
  /// In en, this message translates to:
  /// **'Player #{id}'**
  String playerId(Object id);

  /// No description provided for @opponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get opponent;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @homeGame.
  ///
  /// In en, this message translates to:
  /// **'Home game'**
  String get homeGame;

  /// No description provided for @newMatch.
  ///
  /// In en, this message translates to:
  /// **'New match'**
  String get newMatch;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noEventsDay.
  ///
  /// In en, this message translates to:
  /// **'No events this day.'**
  String get noEventsDay;

  /// No description provided for @noEventsDayTap.
  ///
  /// In en, this message translates to:
  /// **'No events this day. Tap + to add one.'**
  String get noEventsDayTap;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get readOnly;

  /// No description provided for @eventAdded.
  ///
  /// In en, this message translates to:
  /// **'Event added'**
  String get eventAdded;

  /// No description provided for @eventModified.
  ///
  /// In en, this message translates to:
  /// **'Event modified'**
  String get eventModified;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTitle;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteConfirm(Object title);

  /// No description provided for @eventDeleted.
  ///
  /// In en, this message translates to:
  /// **'Event deleted'**
  String get eventDeleted;

  /// No description provided for @newEvent.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get newEvent;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleRequired;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color: '**
  String get color;

  /// No description provided for @titleRequiredMsg.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequiredMsg;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @coachRole.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coachRole;

  /// No description provided for @assistantRole.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistantRole;

  /// No description provided for @playerRole.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get playerRole;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @exerciseProposals.
  ///
  /// In en, this message translates to:
  /// **'Exercise proposals'**
  String get exerciseProposals;

  /// No description provided for @noPendingProposal.
  ///
  /// In en, this message translates to:
  /// **'No pending proposal'**
  String get noPendingProposal;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @proposeExercise.
  ///
  /// In en, this message translates to:
  /// **'Propose an exercise'**
  String get proposeExercise;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @presentCount.
  ///
  /// In en, this message translates to:
  /// **'{present}/{total} present'**
  String presentCount(Object present, Object total);

  /// No description provided for @vsOpponent.
  ///
  /// In en, this message translates to:
  /// **'vs {opponent}'**
  String vsOpponent(Object opponent);

  /// No description provided for @minutesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minutesPlayed;

  /// No description provided for @heightValue.
  ///
  /// In en, this message translates to:
  /// **'{cm} cm'**
  String heightValue(Object cm);

  /// No description provided for @weightValue.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg'**
  String weightValue(Object kg);

  /// No description provided for @match.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get match;

  /// No description provided for @aiScorePercent.
  ///
  /// In en, this message translates to:
  /// **'Score: {value}%'**
  String aiScorePercent(Object value);

  /// No description provided for @situationNumber.
  ///
  /// In en, this message translates to:
  /// **'Situation {value}'**
  String situationNumber(Object value);

  /// No description provided for @navSeasons.
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get navSeasons;

  /// No description provided for @newSeason.
  ///
  /// In en, this message translates to:
  /// **'New season'**
  String get newSeason;

  /// No description provided for @seasonName.
  ///
  /// In en, this message translates to:
  /// **'Season name'**
  String get seasonName;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endDate;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current season'**
  String get current;

  /// No description provided for @createSeason.
  ///
  /// In en, this message translates to:
  /// **'Create season'**
  String get createSeason;

  /// No description provided for @noSeasons.
  ///
  /// In en, this message translates to:
  /// **'No seasons'**
  String get noSeasons;

  /// No description provided for @seasonDetails.
  ///
  /// In en, this message translates to:
  /// **'Season details'**
  String get seasonDetails;

  /// No description provided for @fromTo.
  ///
  /// In en, this message translates to:
  /// **'From {start} to {end}'**
  String fromTo(Object end, Object start);

  /// No description provided for @deleteSeason.
  ///
  /// In en, this message translates to:
  /// **'Delete season'**
  String get deleteSeason;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
