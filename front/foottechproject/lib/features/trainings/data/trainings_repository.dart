import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'training_model.dart';

class TrainingsRepository {
  TrainingsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<Training>> list({int? teamId}) async {
    final response = await _client.get(ApiConstants.trainings, queryParameters: {if (teamId != null) 'teamId': teamId});
    return (response['data'] as List<dynamic>).map((row) => Training.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<Training> getById(int id) async {
    final response = await _client.get('${ApiConstants.trainings}/$id');
    return Training.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Training> create({required int teamId, required DateTime date, required String startTime, required String endTime, String? location}) async {
    final response = await _client.post(ApiConstants.trainings, data: {
      'teamId': teamId,
      'date': date.toIso8601String().split('T').first,
      'startTime': startTime,
      'endTime': endTime,
      if (location != null) 'location': location,
    });
    return Training.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<TrainingSheet?> getSheet(int trainingId) async {
    try {
      final response = await _client.get('${ApiConstants.trainings}/$trainingId/sheet');
      return TrainingSheet.fromJson(response['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  Future<TrainingSheet> upsertSheet(int trainingId, {String? objectifs, String? effectif}) async {
    final response = await _client.put('${ApiConstants.trainings}/$trainingId/sheet', data: {
      if (objectifs != null) 'objectifs': objectifs,
      if (effectif != null) 'effectif': effectif,
    });
    return TrainingSheet.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<TrainingSituation>> listSituations(int trainingId) async {
    final response = await _client.get('${ApiConstants.trainings}/$trainingId/situations');
    return (response['data'] as List<dynamic>).map((row) => TrainingSituation.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<TrainingSituation> createSituation(int trainingId, Map<String, dynamic> body) async {
    final response = await _client.post('${ApiConstants.trainings}/$trainingId/situations', data: body);
    return TrainingSituation.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>?> getDrawing(int trainingId, int situationId) async {
    final response = await _client.get('${ApiConstants.trainings}/$trainingId/situations/$situationId/drawing');
    final data = response['data'];
    return data == null ? null : (data as Map<String, dynamic>)['canvas_data'] as Map<String, dynamic>?;
  }

  Future<void> saveDrawing(int trainingId, int situationId, Map<String, dynamic> canvasData) {
    return _client.post('${ApiConstants.trainings}/$trainingId/situations/$situationId/drawing', data: {'canvasData': canvasData});
  }
}
