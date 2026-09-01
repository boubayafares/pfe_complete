import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'attendance_model.dart';

class AttendanceRepository {
  AttendanceRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<AttendanceRecord>> listByTraining(int trainingId) async {
    final response = await _client.get('${ApiConstants.attendance}/trainings/$trainingId');
    return (response['data'] as List<dynamic>).map((row) => AttendanceRecord.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<void> mark(int trainingId, {required int playerId, required String status}) {
    return _client.post('${ApiConstants.attendance}/trainings/$trainingId', data: {'playerId': playerId, 'status': status});
  }

  /// INCOMPLET (corrigé): le backend expose POST /attendance/trainings/:id/bulk
  /// pour marquer les présences de tout un effectif en un seul appel —
  /// cette méthode n'existait pas côté app, ce qui obligeait à appeler
  /// mark() une fois par joueur (une requête HTTP par joueur pour "marquer
  /// tout le monde présent" sur un effectif de 20+ joueurs).
  Future<void> bulkMark(int trainingId, {required List<AttendanceEntry> entries}) {
    return _client.post('${ApiConstants.attendance}/trainings/$trainingId/bulk', data: {
      'entries': entries.map((e) => {'playerId': e.playerId, 'status': e.status}).toList(),
    });
  }

  /// Retrieves a player's attendance history across trainings — backend
  /// route existed (GET /attendance/players/:playerId/history) but had no
  /// client-side counterpart either.
  Future<List<AttendanceRecord>> listByPlayer(int playerId) async {
    final response = await _client.get('${ApiConstants.attendance}/players/$playerId/history');
    return (response['data'] as List<dynamic>).map((row) => AttendanceRecord.fromJson(row as Map<String, dynamic>)).toList();
  }
}

class AttendanceEntry {
  const AttendanceEntry({required this.playerId, required this.status});
  final int playerId;
  final String status; // PRESENT | ABSENT | LATE | INJURED
}
