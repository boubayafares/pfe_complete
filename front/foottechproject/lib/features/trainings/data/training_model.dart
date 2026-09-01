class Training {
  const Training({
    required this.id,
    required this.teamId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.status,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: json['id'] as int,
      teamId: json['team_id'] as int,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      location: json['location'] as String?,
      status: json['status'] as String,
    );
  }

  final int id;
  final int teamId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String? location;
  final String status;
}

class TrainingSheet {
  const TrainingSheet({required this.id, required this.trainingId, this.objectifs, this.effectif});

  factory TrainingSheet.fromJson(Map<String, dynamic> json) {
    return TrainingSheet(
      id: json['id'] as int,
      trainingId: json['training_id'] as int,
      objectifs: json['objectifs'] as String?,
      effectif: json['effectif'] as String?,
    );
  }

  final int id;
  final int trainingId;
  final String? objectifs;
  final String? effectif;
}

class TrainingSituation {
  const TrainingSituation({
    required this.id,
    required this.ordre,
    this.titre,
    this.description,
    this.dureeTravail,
    this.dureeRecuperation,
    this.criteresReussite,
  });

  factory TrainingSituation.fromJson(Map<String, dynamic> json) {
    return TrainingSituation(
      id: json['id'] as int,
      ordre: json['ordre'] as int,
      titre: json['titre'] as String?,
      description: json['description'] as String?,
      dureeTravail: json['duree_travail'] as String?,
      dureeRecuperation: json['duree_recuperation'] as String?,
      criteresReussite: (json['criteres_reussite'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  final int id;
  final int ordre;
  final String? titre;
  final String? description;
  final String? dureeTravail;
  final String? dureeRecuperation;
  final List<String>? criteresReussite;
}
