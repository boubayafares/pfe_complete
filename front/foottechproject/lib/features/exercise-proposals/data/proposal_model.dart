class ExerciseProposal {
  const ExerciseProposal({
    required this.id,
    required this.titre,
    this.description,
    required this.status,
    required this.proposedBy,
  });

  factory ExerciseProposal.fromJson(Map<String, dynamic> json) {
    return ExerciseProposal(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      proposedBy: json['proposed_by'] as int,
    );
  }

  final int id;
  final String titre;
  final String? description;
  final String status; // PENDING | VALIDATED | REJECTED
  final int proposedBy;
}
