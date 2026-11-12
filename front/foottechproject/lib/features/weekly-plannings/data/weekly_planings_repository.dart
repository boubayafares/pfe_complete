import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'weekly_planing_model.dart'; // suppose que vos modèles sont dans ce fichier

class WeeklyPlanningRepository {
  WeeklyPlanningRepository({required this._client});

  final ApiClient _client;

  // --------------------------------------------------------------------------
  // Planning hebdomadaire
  // --------------------------------------------------------------------------

  /// Récupère les plannings de l'équipe authentifiée, éventuellement par saison.
  Future<List<WeeklyPlanning>> list({int? seasonId}) async {
    final queryParams = <String, dynamic>{};
    if (seasonId != null) queryParams['seasonId'] = seasonId;

    final response = await _client.get(
      ApiConstants.weeklyPlannings,
      queryParameters: queryParams,
    );
    final data = response['data'] as List<dynamic>;
    return data
        .map((row) => WeeklyPlanning.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Récupère un planning par son ID.
  Future<WeeklyPlanning> getById(int id) async {
    final response = await _client.get('${ApiConstants.weeklyPlannings}/$id');
    return WeeklyPlanning.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Crée un nouveau planning.
  /// L'équipe est toujours dérivée de la session authentifiée.
  Future<WeeklyPlanning> create({
    required DateTime dateDebut,
    required DateTime dateFin,
    required bool matchPrevu,
    int? seasonId,
    int? semaineNumero,
    int? nombreSeances,
    String? intensite,
    String? volume,
  }) async {
    final response = await _client.post(
      ApiConstants.weeklyPlannings,
      data: {
        'seasonId': seasonId,
        'semaineNumero': semaineNumero,
        'dateDebut': dateDebut.toIso8601String().split('T').first,
        'dateFin': dateFin.toIso8601String().split('T').first,
        'nombreSeances': nombreSeances,
        'intensite': intensite,
        'volume': volume,
        'matchPrevu': matchPrevu,
      },
    );
    return WeeklyPlanning.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Met à jour un planning existant.
  Future<WeeklyPlanning> update({
    required int id,
    int? seasonId,
    int? semaineNumero,
    DateTime? dateDebut,
    DateTime? dateFin,
    int? nombreSeances,
    String? intensite,
    String? volume,
    bool? matchPrevu,
  }) async {
    final body = <String, dynamic>{};
    if (seasonId != null) body['seasonId'] = seasonId;
    if (semaineNumero != null) body['semaineNumero'] = semaineNumero;
    if (dateDebut != null) {
      body['dateDebut'] = dateDebut.toIso8601String().split('T').first;
    }
    if (dateFin != null) {
      body['dateFin'] = dateFin.toIso8601String().split('T').first;
    }
    if (nombreSeances != null) body['nombreSeances'] = nombreSeances;
    if (intensite != null) body['intensite'] = intensite;
    if (volume != null) body['volume'] = volume;
    if (matchPrevu != null) body['matchPrevu'] = matchPrevu;

    final response = await _client.patch(
      '${ApiConstants.weeklyPlannings}/$id',
      data: body,
    );
    return WeeklyPlanning.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Supprime un planning (et ses créneaux par cascade).
  Future<void> delete(int id) async {
    await _client.delete('${ApiConstants.weeklyPlannings}/$id');
  }

  // --------------------------------------------------------------------------
  // Créneaux (slots) d'un planning
  // --------------------------------------------------------------------------

  /// Récupère tous les créneaux d'un planning donné.
  Future<List<WeeklyPlanningSlot>> listSlots(int planningId) async {
    final response = await _client.get(
      '${ApiConstants.weeklyPlannings}/$planningId/slots',
    );
    final data = response['data'] as List<dynamic>;
    return data
        .map((row) => WeeklyPlanningSlot.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Crée ou met à jour (upsert) un créneau pour un planning.
  /// Le backend utilise PUT /weekly-plannings/:id/slots.
  Future<WeeklyPlanningSlot> upsertSlot({
    required int planningId,
    required DateTime jour,
    required PlanningMoment moment,
    int? trainingId,
    String? description,
  }) async {
    final response = await _client.put(
      '${ApiConstants.weeklyPlannings}/$planningId/slots',
      data: {
        'jour': jour.toIso8601String().split('T').first,
        'moment': moment.jsonValue,
        'trainingId': ?trainingId,
        'description': ?description,
      },
    );
    return WeeklyPlanningSlot.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }
}
