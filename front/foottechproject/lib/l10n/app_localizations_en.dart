// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FootTech';

  @override
  String get onboardingSubtitle =>
      'Coach, Assistant or Player — your club, in your pocket.';

  @override
  String get onboardingCoachBtn => 'I am a Coach or Assistant';

  @override
  String get onboardingPlayerBtn => 'I am a Player (SMS login)';

  @override
  String get onboardingCreateCoach => 'New club? Create a Coach account';

  @override
  String get loginTitle => 'Coach / Assistant Login';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get required => 'Required';

  @override
  String get firstTimeAssistant => 'First-time Assistant login?';

  @override
  String get loginButton => 'Log in';

  @override
  String get unableToLogin => 'Unable to connect';

  @override
  String get registerTitle => 'Create a Coach account';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get phone => 'Phone';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get min8Chars => 'Minimum 8 characters';

  @override
  String get createAccount => 'Create my account';

  @override
  String get unableToRegister => 'Unable to register';

  @override
  String get activateTitle => 'Assistant Activation';

  @override
  String get activateIntro =>
      'Your coach has added you as an assistant. A code was sent by SMS to the number provided — enter it below with a password of your choice to activate your account.';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get codeReceivedSms => 'Code received by SMS';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDontMatch => 'Passwords do not match';

  @override
  String get activateButton => 'Activate my account';

  @override
  String get codeExpired =>
      'Code expired or never received? Ask your coach to re-add you to the team to receive a new code.';

  @override
  String get accountActivatedLogin => 'Account activated — you can now log in';

  @override
  String get playerLoginTitle => 'Player Login';

  @override
  String codeSentToPhone(Object phone) {
    return 'A code has been sent to $phone. Enter it below.';
  }

  @override
  String get enterCoachPhone => 'Enter the phone number you gave your coach.';

  @override
  String get validate => 'Validate';

  @override
  String get receiveCode => 'Receive the code';

  @override
  String get changeNumber => 'Change number';

  @override
  String get otpTitle => 'Account verification';

  @override
  String otpCodeSentEmail(Object email) {
    return 'A code has been sent to $email. Enter it below to activate your account.';
  }

  @override
  String otpWillSendEmail(Object email) {
    return 'A verification code will be sent by SMS to the number associated with $email to activate your account.';
  }

  @override
  String get verifyAndActivate => 'Verify and activate';

  @override
  String get receiveNewCode => 'Receive a new code';

  @override
  String get navHome => 'Home';

  @override
  String get navTeam => 'Team';

  @override
  String get navTrainings => 'Trainings';

  @override
  String get navMatches => 'Matches';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navProfile => 'Profile';

  @override
  String get biometricLocked => 'FootTech is locked';

  @override
  String get unlock => 'Unlock';

  @override
  String get biometricReason => 'Unlock FootTech';

  @override
  String get errorGeneric => 'An error occurred';

  @override
  String get errorNetwork => 'Unable to reach the server';

  @override
  String get sessionNotFound => 'Session not found.';

  @override
  String get nextTraining => 'Next training';

  @override
  String get nextMatch => 'Next match';

  @override
  String get players => 'Players';

  @override
  String get proposals => 'Proposals';

  @override
  String get notifications => 'Notifications';

  @override
  String get seasonSummary => 'Season summary';

  @override
  String get starter => 'Starter';

  @override
  String get substitute => 'Substitute';

  @override
  String get notSelected => 'Not selected';

  @override
  String get noData => 'No data for now';

  @override
  String get player => 'Player';

  @override
  String get position => 'Position';

  @override
  String get played => 'Pld';

  @override
  String get rating => 'Rating';

  @override
  String get goals => 'Goals';

  @override
  String get assists => 'Assists';

  @override
  String get goalsConceded => 'Goals conc.';

  @override
  String get noTeamLinked => 'No team linked to your account yet.';

  @override
  String get createFirstTeam => 'Create your first team';

  @override
  String get canAddPlayersAssistants =>
      'You can then add your players and assistants.';

  @override
  String get teamName => 'Team name';

  @override
  String category(Object example) {
    return 'Category ($example)';
  }

  @override
  String get create => 'Create';

  @override
  String get addPlayer => 'Add a player';

  @override
  String get addAssistant => 'Add an assistant';

  @override
  String get noPlayersYet => 'No players yet';

  @override
  String get noAssistantsYet => 'No assistants yet';

  @override
  String awaitingActivation(Object phone) {
    return '$phone - awaiting activation';
  }

  @override
  String get staff => 'Staff';

  @override
  String get add => 'Add';

  @override
  String get newPlayer => 'New player';

  @override
  String get phoneSmsActivation => 'Phone (SMS activation)';

  @override
  String get primaryPosition => 'Primary position';

  @override
  String get strongFoot => 'Strong foot';

  @override
  String get right => 'Right';

  @override
  String get left => 'Left';

  @override
  String get ambidextrous => 'Ambidextrous';

  @override
  String get jerseyNumber => 'Jersey number';

  @override
  String get createPlayer => 'Create player';

  @override
  String get tabIdentity => 'Identity';

  @override
  String get tabFamily => 'Family';

  @override
  String get tabSchool => 'School';

  @override
  String get tabInjuries => 'Injuries';

  @override
  String get height => 'Height';

  @override
  String get weight => 'Weight';

  @override
  String get foot => 'Foot';

  @override
  String get evolutionBySeason => 'Evolution by season';

  @override
  String get noDataRecorded => 'No data recorded';

  @override
  String get parentsGuardian => 'Parents / guardian';

  @override
  String get father => 'Father';

  @override
  String get mother => 'Mother';

  @override
  String get guardian => 'Guardian';

  @override
  String get noContactRecorded => 'No contact recorded';

  @override
  String get addressCommute => 'Address and commute';

  @override
  String get notProvided => 'Not provided';

  @override
  String kmFromClub(Object distance) {
    return '$distance km from the club';
  }

  @override
  String get school => 'School';

  @override
  String get classLevel => 'Class';

  @override
  String get level => 'Level';

  @override
  String get noInjuries => 'No injuries recorded';

  @override
  String get injury => 'Injury';

  @override
  String days(Object days) {
    return '· $days days';
  }

  @override
  String get noTrainingPlanned => 'No training planned';

  @override
  String get technicalSheet => 'Technical sheet';

  @override
  String get attendance => 'Attendance';

  @override
  String get objectives => 'Objectives';

  @override
  String get edit => 'Edit';

  @override
  String get situations => 'Situations';

  @override
  String get noSituationAdded => 'No situation added';

  @override
  String work(Object value) {
    return 'Work: $value';
  }

  @override
  String recovery(Object value) {
    return 'Recovery: $value';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get newSituation => 'New situation';

  @override
  String get title => 'Title';

  @override
  String get workDuration => 'Work duration (e.g., 2*4)';

  @override
  String get recoveryDuration => 'Recovery duration';

  @override
  String get diagramSaved => 'Diagram saved';

  @override
  String get tacticalDiagram => 'Tactical diagram';

  @override
  String get newTraining => 'New training';

  @override
  String get date => 'Date';

  @override
  String get startTime => 'Start time';

  @override
  String get endTime => 'End time';

  @override
  String get location => 'Location';

  @override
  String get noMatches => 'No matches';

  @override
  String homeAwayVs(Object homeAway, Object opponent) {
    return '$homeAway vs $opponent';
  }

  @override
  String get home => 'Home';

  @override
  String get away => 'Away';

  @override
  String get lineup => 'Lineup';

  @override
  String get ai => 'AI';

  @override
  String get live => 'Live';

  @override
  String get starters => 'Starters';

  @override
  String get substitutes => 'Substitutes';

  @override
  String get lineupNotSet => 'Lineup not set';

  @override
  String get start => 'Start';

  @override
  String get addEvent => '+ Event';

  @override
  String get finish => 'Finish';

  @override
  String get noEvents => 'No events';

  @override
  String get eventGoal => 'Goal';

  @override
  String get eventAssist => 'Assist';

  @override
  String get yellowCard => 'Yellow card';

  @override
  String get redCard => 'Red card';

  @override
  String get eventSubOn => 'Substituted on';

  @override
  String get eventSubOff => 'Substituted off';

  @override
  String get eventInjury => 'Injury';

  @override
  String get type => 'Type';

  @override
  String get minute => 'Minute';

  @override
  String get generateAiRecommendations => 'Generate AI recommendations';

  @override
  String get noRecommendation => 'No recommendation generated';

  @override
  String playerId(Object id) {
    return 'Player #$id';
  }

  @override
  String get opponent => 'Opponent';

  @override
  String get time => 'Time';

  @override
  String get homeGame => 'Home game';

  @override
  String get newMatch => 'New match';

  @override
  String get refresh => 'Refresh';

  @override
  String get noEventsDay => 'No events this day.';

  @override
  String get noEventsDayTap => 'No events this day. Tap + to add one.';

  @override
  String get description => 'Description';

  @override
  String get delete => 'Delete';

  @override
  String get readOnly => 'Read only';

  @override
  String get eventAdded => 'Event added';

  @override
  String get eventModified => 'Event modified';

  @override
  String get deleteTitle => 'Delete';

  @override
  String deleteConfirm(Object title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get eventDeleted => 'Event deleted';

  @override
  String get newEvent => 'New event';

  @override
  String get titleRequired => 'Title *';

  @override
  String get allDay => 'All day';

  @override
  String get color => 'Color: ';

  @override
  String get titleRequiredMsg => 'Title is required';

  @override
  String get profile => 'Profile';

  @override
  String get logOut => 'Log out';

  @override
  String get coachRole => 'Coach';

  @override
  String get assistantRole => 'Assistant';

  @override
  String get playerRole => 'Player';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get exerciseProposals => 'Exercise proposals';

  @override
  String get noPendingProposal => 'No pending proposal';

  @override
  String get pending => 'Pending';

  @override
  String get proposeExercise => 'Propose an exercise';

  @override
  String get submit => 'Submit';

  @override
  String presentCount(Object present, Object total) {
    return '$present/$total present';
  }

  @override
  String vsOpponent(Object opponent) {
    return 'vs $opponent';
  }

  @override
  String get minutesPlayed => 'Min';

  @override
  String heightValue(Object cm) {
    return '$cm cm';
  }

  @override
  String weightValue(Object kg) {
    return '$kg kg';
  }

  @override
  String get match => 'Match';

  @override
  String aiScorePercent(Object value) {
    return 'Score: $value%';
  }

  @override
  String situationNumber(Object value) {
    return 'Situation $value';
  }

  @override
  String get navSeasons => 'Seasons';

  @override
  String get newSeason => 'New season';

  @override
  String get seasonName => 'Season name';

  @override
  String get startDate => 'Start';

  @override
  String get endDate => 'End';

  @override
  String get current => 'Current season';

  @override
  String get createSeason => 'Create season';

  @override
  String get noSeasons => 'No seasons';

  @override
  String get seasonDetails => 'Season details';

  @override
  String fromTo(Object end, Object start) {
    return 'From $start to $end';
  }

  @override
  String get deleteSeason => 'Delete season';
}
