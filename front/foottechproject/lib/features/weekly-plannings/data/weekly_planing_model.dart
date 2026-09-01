// Enum pour les moments de la journée
enum PlanningMoment {
  matin,
  apresMidi,
  soir;

  String get jsonValue {
    switch (this) {
      case PlanningMoment.matin:
        return 'MATIN';
      case PlanningMoment.apresMidi:
        return 'APRES_MIDI';
      case PlanningMoment.soir:
        return 'SOIR';
    }
  }

  static PlanningMoment fromJson(String value) {
    switch (value) {
      case 'MATIN':
        return PlanningMoment.matin;
      case 'APRES_MIDI':
        return PlanningMoment.apresMidi;
      case 'SOIR':
        return PlanningMoment.soir;
      default:
        throw ArgumentError('Unknown PlanningMoment: $value');
    }
  }
}

// Modèle pour un créneau du planning (une ligne du tableau)
class WeeklyPlanningSlot {
  const WeeklyPlanningSlot({
    required this.id,
    required this.weeklyPlanningId,
    required this.jour,
    required this.moment,
    this.trainingId,
    this.description,
  });

  factory WeeklyPlanningSlot.fromJson(Map<String, dynamic> json) {
    return WeeklyPlanningSlot(
      id: json['id'] as int,
      weeklyPlanningId: json['weekly_planning_id'] as int,
      jour: DateTime.parse(json['jour'] as String),
      moment: PlanningMoment.fromJson(json['moment'] as String),
      trainingId: json['training_id'] as int?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekly_planning_id': weeklyPlanningId,
      'jour': jour.toIso8601String().split('T').first, // format YYYY-MM-DD
      'moment': moment.jsonValue,
      'training_id': trainingId,
      'description': description,
    };
  }

  final int id;
  final int weeklyPlanningId;
  final DateTime jour;
  final PlanningMoment moment;
  final int? trainingId; // peut être null si l'entraînement n'est pas encore créé
  final String? description;
}

// Modèle principal du planning hebdomadaire
class WeeklyPlanning {
  const WeeklyPlanning({
    required this.id,
    required this.teamId,
    this.seasonId,
    this.semaineNumero,
    required this.dateDebut,
    required this.dateFin,
    this.nombreSeances,
    this.intensite,
    this.volume,
    required this.matchPrevu,
    this.slots = const [], // optionnel, pour charger les créneaux associés
  });

  factory WeeklyPlanning.fromJson(Map<String, dynamic> json) {
    return WeeklyPlanning(
      id: json['id'] as int,
      teamId: json['team_id'] as int,
      seasonId: json['season_id'] as int?,
      semaineNumero: json['semaine_numero'] as int?,
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateFin: DateTime.parse(json['date_fin'] as String),
      nombreSeances: json['nombre_seances'] as int?,
      intensite: json['intensite'] as String?,
      volume: json['volume'] as String?,
      matchPrevu: json['match_prevu'] as bool,
      slots: (json['slots'] as List<dynamic>?)
          ?.map((e) => WeeklyPlanningSlot.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'season_id': seasonId,
      'semaine_numero': semaineNumero,
      'date_debut': dateDebut.toIso8601String().split('T').first,
      'date_fin': dateFin.toIso8601String().split('T').first,
      'nombre_seances': nombreSeances,
      'intensite': intensite,
      'volume': volume,
      'match_prevu': matchPrevu,
      'slots': slots.map((s) => s.toJson()).toList(),
    };
  }

  final int id;
  final int teamId;
  final int? seasonId;
  final int? semaineNumero;
  final DateTime dateDebut;
  final DateTime dateFin;
  final int? nombreSeances;
  final String? intensite;
  final String? volume;
  final bool matchPrevu;
  final List<WeeklyPlanningSlot> slots; // peut être vide
}