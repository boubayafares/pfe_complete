class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.profileImage,
    required this.accountStatus,
    this.dateNaissance,
    this.tailleCm,
    this.poidsKg,
    this.postePrincipal,
    this.posteSecondaire,
    this.piedFort,
    this.numeroMaillot,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String,
      profileImage: json['profile_image'] as String?,
      accountStatus: json['account_status'] as String,
      dateNaissance: json['date_naissance'] != null ? DateTime.parse(json['date_naissance'] as String) : null,
      tailleCm: (json['taille_cm'] as num?)?.toDouble(),
      poidsKg: (json['poids_kg'] as num?)?.toDouble(),
      postePrincipal: json['poste_principal'] as String?,
      posteSecondaire: json['poste_secondaire'] as String?,
      piedFort: json['pied_fort'] as String?,
      numeroMaillot: json['numero_maillot'] as int?,
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? profileImage;
  final String accountStatus;
  final DateTime? dateNaissance;
  final double? tailleCm;
  final double? poidsKg;
  final String? postePrincipal;
  final String? posteSecondaire;
  final String? piedFort;
  final int? numeroMaillot;

  String get fullName => '$firstName $lastName';
}

class Guardian {
  const Guardian({required this.relation, this.nom, this.prenom, this.tel1, this.tel2, this.email});

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      relation: json['relation'] as String,
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      tel1: json['tel1'] as String?,
      tel2: json['tel2'] as String?,
      email: json['email'] as String?,
    );
  }

  final String relation; // PERE | MERE | TUTEUR
  final String? nom;
  final String? prenom;
  final String? tel1;
  final String? tel2;
  final String? email;
}

class PlayerAddress {
  const PlayerAddress({this.adresseComplete, this.distanceClubKm, this.moyenTransport, this.dureeTrajetMin});

  factory PlayerAddress.fromJson(Map<String, dynamic> json) {
    return PlayerAddress(
      adresseComplete: json['adresse_complete'] as String?,
      distanceClubKm: (json['distance_club_km'] as num?)?.toDouble(),
      moyenTransport: json['moyen_transport'] as String?,
      dureeTrajetMin: json['duree_trajet_min'] as int?,
    );
  }

  final String? adresseComplete;
  final double? distanceClubKm;
  final String? moyenTransport;
  final int? dureeTrajetMin;
}

class SchoolInfo {
  const SchoolInfo({this.etablissement, this.classe, this.niveauScolaire});

  factory SchoolInfo.fromJson(Map<String, dynamic> json) {
    return SchoolInfo(
      etablissement: json['etablissement'] as String?,
      classe: json['classe'] as String?,
      niveauScolaire: json['niveau_scolaire'] as String?,
    );
  }

  final String? etablissement;
  final String? classe;
  final String? niveauScolaire;
}

class SeasonProfile {
  const SeasonProfile({
    required this.season,
    this.poidsKg,
    this.tailleCm,
    this.poste1,
    this.poste2,
    this.pointsForts,
    this.pointsAAmeliorer,
  });

  factory SeasonProfile.fromJson(Map<String, dynamic> json) {
    return SeasonProfile(
      season: json['season'] as String,
      poidsKg: (json['poids_kg'] as num?)?.toDouble(),
      tailleCm: (json['taille_cm'] as num?)?.toDouble(),
      poste1: json['poste1'] as String?,
      poste2: json['poste2'] as String?,
      pointsForts: json['points_forts'] as String?,
      pointsAAmeliorer: json['points_a_ameliorer'] as String?,
    );
  }

  final String season;
  final double? poidsKg;
  final double? tailleCm;
  final String? poste1;
  final String? poste2;
  final String? pointsForts;
  final String? pointsAAmeliorer;
}

class PlayerInjury {
  const PlayerInjury({
    required this.id,
    required this.dateBlessure,
    this.description,
    this.dureeIndisponibiliteJours,
    this.dateRetour,
  });

  factory PlayerInjury.fromJson(Map<String, dynamic> json) {
    return PlayerInjury(
      id: json['id'] as int,
      dateBlessure: DateTime.parse(json['date_blessure'] as String),
      description: json['description'] as String?,
      dureeIndisponibiliteJours: json['duree_indisponibilite_jours'] as int?,
      dateRetour: json['date_retour'] != null ? DateTime.parse(json['date_retour'] as String) : null,
    );
  }

  final int id;
  final DateTime dateBlessure;
  final String? description;
  final int? dureeIndisponibiliteJours;
  final DateTime? dateRetour;

  bool get isActive => dateRetour == null;
}
