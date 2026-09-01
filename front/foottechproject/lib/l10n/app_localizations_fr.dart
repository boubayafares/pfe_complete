// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'FootTech';

  @override
  String get onboardingSubtitle =>
      'Coach, Adjoint ou Joueur — votre club, dans la poche.';

  @override
  String get onboardingCoachBtn => 'Je suis Coach ou Adjoint';

  @override
  String get onboardingPlayerBtn => 'Je suis Joueur (connexion par SMS)';

  @override
  String get onboardingCreateCoach => 'Nouveau club ? Créer un compte Coach';

  @override
  String get loginTitle => 'Connexion Coach / Adjoint';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get invalidEmail => 'Email invalide';

  @override
  String get required => 'Requis';

  @override
  String get firstTimeAssistant => 'Première connexion Adjoint ?';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get unableToLogin => 'Connexion impossible';

  @override
  String get registerTitle => 'Créer un compte Coach';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get phone => 'Téléphone';

  @override
  String get invalidNumber => 'Numéro invalide';

  @override
  String get min8Chars => 'Minimum 8 caractères';

  @override
  String get createAccount => 'Créer mon compte';

  @override
  String get unableToRegister => 'Inscription impossible';

  @override
  String get activateTitle => 'Activation Adjoint';

  @override
  String get activateIntro =>
      'Votre coach vous a ajouté comme adjoint. Un code vous a été envoyé par SMS au numéro renseigné — saisissez-le ci-dessous avec le mot de passe de votre choix pour activer votre compte.';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get codeReceivedSms => 'Code reçu par SMS';

  @override
  String get invalidCode => 'Code invalide';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get passwordsDontMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get activateButton => 'Activer mon compte';

  @override
  String get codeExpired =>
      'Code expiré ou jamais reçu ? Demandez à votre coach de vous ré-ajouter à l\'équipe pour recevoir un nouveau code.';

  @override
  String get accountActivatedLogin =>
      'Compte activé — vous pouvez vous connecter';

  @override
  String get playerLoginTitle => 'Connexion Joueur';

  @override
  String codeSentToPhone(Object phone) {
    return 'Un code a été envoyé au $phone. Saisissez-le ci-dessous.';
  }

  @override
  String get enterCoachPhone =>
      'Entrez le numéro de téléphone communiqué à votre coach.';

  @override
  String get validate => 'Valider';

  @override
  String get receiveCode => 'Recevoir le code';

  @override
  String get changeNumber => 'Changer de numéro';

  @override
  String get otpTitle => 'Vérification du compte';

  @override
  String otpCodeSentEmail(Object email) {
    return 'Un code a été envoyé au $email. Saisissez-le ci-dessous pour activer votre compte.';
  }

  @override
  String otpWillSendEmail(Object email) {
    return 'Un code de vérification va être envoyé par SMS au numéro associé à $email pour activer votre compte.';
  }

  @override
  String get verifyAndActivate => 'Vérifier et activer';

  @override
  String get receiveNewCode => 'Recevoir un nouveau code';

  @override
  String get navHome => 'Accueil';

  @override
  String get navTeam => 'Équipe';

  @override
  String get navTrainings => 'Entraînements';

  @override
  String get navMatches => 'Matchs';

  @override
  String get navCalendar => 'Calendrier';

  @override
  String get navProfile => 'Profil';

  @override
  String get biometricLocked => 'FootTech verrouillé';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get biometricReason => 'Déverrouillez FootTech';

  @override
  String get errorGeneric => 'Une erreur est survenue';

  @override
  String get errorNetwork => 'Impossible de contacter le serveur';

  @override
  String get sessionNotFound => 'Session introuvable.';

  @override
  String get nextTraining => 'Prochain entraînement';

  @override
  String get nextMatch => 'Prochain match';

  @override
  String get players => 'Effectif';

  @override
  String get proposals => 'Propositions';

  @override
  String get notifications => 'Notifications';

  @override
  String get seasonSummary => 'Bilan de saison';

  @override
  String get starter => 'Titulaire';

  @override
  String get substitute => 'Remplaçant';

  @override
  String get notSelected => 'Non retenu';

  @override
  String get noData => 'Aucune donnée pour le moment';

  @override
  String get player => 'Joueur';

  @override
  String get position => 'Poste';

  @override
  String get played => 'MJ';

  @override
  String get rating => 'Note';

  @override
  String get goals => 'Buts';

  @override
  String get assists => 'Passes D.';

  @override
  String get goalsConceded => 'Buts enc.';

  @override
  String get noTeamLinked =>
      'Aucune équipe associée à votre compte pour le moment.';

  @override
  String get createFirstTeam => 'Créez votre première équipe';

  @override
  String get canAddPlayersAssistants =>
      'Vous pourrez ensuite ajouter vos joueurs et adjoints.';

  @override
  String get teamName => 'Nom de l\'équipe';

  @override
  String category(Object example) {
    return 'Catégorie ($example)';
  }

  @override
  String get create => 'Créer';

  @override
  String get addPlayer => 'Ajouter un joueur';

  @override
  String get addAssistant => 'Ajouter un adjoint';

  @override
  String get noPlayersYet => 'Aucun joueur pour le moment';

  @override
  String get noAssistantsYet => 'Aucun adjoint pour le moment';

  @override
  String awaitingActivation(Object phone) {
    return '$phone - en attente d\'activation';
  }

  @override
  String get staff => 'Staff';

  @override
  String get add => 'Ajouter';

  @override
  String get newPlayer => 'Nouveau joueur';

  @override
  String get phoneSmsActivation => 'Téléphone (activation par SMS)';

  @override
  String get primaryPosition => 'Poste principal';

  @override
  String get strongFoot => 'Pied fort';

  @override
  String get right => 'Droit';

  @override
  String get left => 'Gauche';

  @override
  String get ambidextrous => 'Ambidextre';

  @override
  String get jerseyNumber => 'Numéro de maillot';

  @override
  String get createPlayer => 'Créer le joueur';

  @override
  String get tabIdentity => 'Identité';

  @override
  String get tabFamily => 'Famille';

  @override
  String get tabSchool => 'Scolarité';

  @override
  String get tabInjuries => 'Blessures';

  @override
  String get height => 'Taille';

  @override
  String get weight => 'Poids';

  @override
  String get foot => 'Pied';

  @override
  String get evolutionBySeason => 'Évolution par saison';

  @override
  String get noDataRecorded => 'Aucune donnée enregistrée';

  @override
  String get parentsGuardian => 'Parents / tuteur';

  @override
  String get father => 'Père';

  @override
  String get mother => 'Mère';

  @override
  String get guardian => 'Tuteur';

  @override
  String get noContactRecorded => 'Aucun contact enregistré';

  @override
  String get addressCommute => 'Adresse et trajet';

  @override
  String get notProvided => 'Non renseigné';

  @override
  String kmFromClub(Object distance) {
    return '$distance km du club';
  }

  @override
  String get school => 'Établissement';

  @override
  String get classLevel => 'Classe';

  @override
  String get level => 'Niveau';

  @override
  String get noInjuries => 'Aucune blessure enregistrée';

  @override
  String get injury => 'Blessure';

  @override
  String days(Object days) {
    return '· $days jours';
  }

  @override
  String get noTrainingPlanned => 'Aucun entraînement planifié';

  @override
  String get technicalSheet => 'Fiche technique';

  @override
  String get attendance => 'Présence';

  @override
  String get objectives => 'Objectifs';

  @override
  String get edit => 'Modifier';

  @override
  String get situations => 'Situations';

  @override
  String get noSituationAdded => 'Aucune situation ajoutée';

  @override
  String work(Object value) {
    return 'Travail: $value';
  }

  @override
  String recovery(Object value) {
    return 'Récup: $value';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get newSituation => 'Nouvelle situation';

  @override
  String get title => 'Titre';

  @override
  String get workDuration => 'Durée travail (ex: 2*4)';

  @override
  String get recoveryDuration => 'Durée récupération';

  @override
  String get diagramSaved => 'Schéma enregistré';

  @override
  String get tacticalDiagram => 'Schéma tactique';

  @override
  String get newTraining => 'Nouvel entraînement';

  @override
  String get date => 'Date';

  @override
  String get startTime => 'Heure de début';

  @override
  String get endTime => 'Heure de fin';

  @override
  String get location => 'Lieu';

  @override
  String get noMatches => 'Aucun match';

  @override
  String homeAwayVs(Object homeAway, Object opponent) {
    return '$homeAway vs $opponent';
  }

  @override
  String get home => 'Domicile';

  @override
  String get away => 'Extérieur';

  @override
  String get lineup => 'Composition';

  @override
  String get ai => 'IA';

  @override
  String get live => 'Live';

  @override
  String get starters => 'Titulaires';

  @override
  String get substitutes => 'Remplaçants';

  @override
  String get lineupNotSet => 'Composition non définie';

  @override
  String get start => 'Démarrer';

  @override
  String get addEvent => '+ Événement';

  @override
  String get finish => 'Terminer';

  @override
  String get noEvents => 'Aucun événement';

  @override
  String get eventGoal => 'But';

  @override
  String get eventAssist => 'Passe décisive';

  @override
  String get yellowCard => 'Carton jaune';

  @override
  String get redCard => 'Carton rouge';

  @override
  String get eventSubOn => 'Entrée en jeu';

  @override
  String get eventSubOff => 'Sortie';

  @override
  String get eventInjury => 'Blessure';

  @override
  String get type => 'Type';

  @override
  String get minute => 'Minute';

  @override
  String get generateAiRecommendations => 'Générer les recommandations IA';

  @override
  String get noRecommendation => 'Aucune recommandation générée';

  @override
  String playerId(Object id) {
    return 'Joueur #$id';
  }

  @override
  String get opponent => 'Adversaire';

  @override
  String get time => 'Heure';

  @override
  String get homeGame => 'À domicile';

  @override
  String get newMatch => 'Nouveau match';

  @override
  String get refresh => 'Actualiser';

  @override
  String get noEventsDay => 'Aucun événement ce jour.';

  @override
  String get noEventsDayTap =>
      'Aucun événement ce jour. Touchez + pour en ajouter.';

  @override
  String get description => 'Description';

  @override
  String get delete => 'Supprimer';

  @override
  String get readOnly => 'Lecture seule';

  @override
  String get eventAdded => 'Événement ajouté';

  @override
  String get eventModified => 'Événement modifié';

  @override
  String get deleteTitle => 'Supprimer';

  @override
  String deleteConfirm(Object title) {
    return 'Supprimer « $title » ?';
  }

  @override
  String get eventDeleted => 'Événement supprimé';

  @override
  String get newEvent => 'Nouvel événement';

  @override
  String get titleRequired => 'Titre *';

  @override
  String get allDay => 'Journée entière';

  @override
  String get color => 'Couleur : ';

  @override
  String get titleRequiredMsg => 'Le titre est requis';

  @override
  String get profile => 'Profil';

  @override
  String get logOut => 'Se déconnecter';

  @override
  String get coachRole => 'Coach';

  @override
  String get assistantRole => 'Adjoint';

  @override
  String get playerRole => 'Joueur';

  @override
  String get noNotifications => 'Aucune notification';

  @override
  String get exerciseProposals => 'Propositions d\'exercices';

  @override
  String get noPendingProposal => 'Aucune proposition en attente';

  @override
  String get pending => 'En attente';

  @override
  String get proposeExercise => 'Proposer un exercice';

  @override
  String get submit => 'Proposer';

  @override
  String presentCount(Object present, Object total) {
    return '$present/$total présents';
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
    return 'Score : $value%';
  }

  @override
  String situationNumber(Object value) {
    return 'Situation $value';
  }

  @override
  String get navSeasons => 'Saisons';

  @override
  String get newSeason => 'Nouvelle saison';

  @override
  String get seasonName => 'Nom de la saison';

  @override
  String get startDate => 'Début';

  @override
  String get endDate => 'Fin';

  @override
  String get current => 'Saison actuelle';

  @override
  String get createSeason => 'Créer la saison';

  @override
  String get noSeasons => 'Aucune saison';

  @override
  String get seasonDetails => 'Détails de la saison';

  @override
  String fromTo(Object end, Object start) {
    return 'Du $start au $end';
  }

  @override
  String get deleteSeason => 'Supprimer la saison';
}
