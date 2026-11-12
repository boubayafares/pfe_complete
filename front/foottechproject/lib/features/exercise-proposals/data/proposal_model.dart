class ExerciseProposal {
  const ExerciseProposal({
    required this.id,
    required this.titre,
    this.description,
    this.category,
    this.objectif,
    this.difficulty,
    this.durationMinutes,
    this.visibility,
    this.tags = const [],
    this.canvasData,
    this.animationData,
    this.aiModel,
    required this.status,
    required this.proposedBy,
  });

  factory ExerciseProposal.fromJson(Map<String, dynamic> json) {
    return ExerciseProposal(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      objectif: json['objectif'] as String?,
      difficulty: json['difficulty'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      visibility: json['visibility'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      canvasData: json['canvas_data'] as Map<String, dynamic>?,
      animationData: json['animation_data'] as Map<String, dynamic>?,
      aiModel: json['ai_model'] as Map<String, dynamic>?,
      status: json['status'] as String,
      proposedBy: json['proposed_by'] as int,
    );
  }

  final int id;
  final String titre;
  final String? description;
  final String? category;
  final String? objectif;
  final String? difficulty;
  final int? durationMinutes;
  final String? visibility;
  final List<String> tags;
  final Map<String, dynamic>? canvasData;
  final Map<String, dynamic>? animationData;
  final Map<String, dynamic>? aiModel;
  final String status; // PENDING | VALIDATED | REJECTED
  final int proposedBy;

  String get difficultyLabel => switch (difficulty) {
    'EASY' => 'Facile',
    'HARD' => 'Difficile',
    'ELITE' => 'Elite',
    _ => 'Moyen',
  };
}
