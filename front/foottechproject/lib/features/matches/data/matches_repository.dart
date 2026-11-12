import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'match_model.dart';

class MatchesRepository {
  MatchesRepository({required this._client});

  final ApiClient _client;

  Future<List<MatchInfo>> list() async {
    final response = await _client.get(ApiConstants.matches);
    return (response['data'] as List<dynamic>)
        .map((row) => MatchInfo.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<MatchInfo> getById(int id) async {
    final response = await _client.get('${ApiConstants.matches}/$id');
    return MatchInfo.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<MatchInfo> create({
    required String adversaire,
    required DateTime dateHeure,
    bool isHome = true,
  }) async {
    final response = await _client.post(
      ApiConstants.matches,
      data: {
        'adversaire': adversaire,
        'dateHeure': dateHeure.toIso8601String(),
        'isHome': isHome,
      },
    );
    return MatchInfo.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<MatchInfo> updateStatus(int id, String status) async {
    final response = await _client.patch(
      '${ApiConstants.matches}/$id/status',
      data: {'matchStatus': status},
    );
    return MatchInfo.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<LineupEntry>> getLineup(int matchId) async {
    final response = await _client.get(
      '${ApiConstants.matches}/$matchId/lineup',
    );
    return (response['data'] as List<dynamic>)
        .map((row) => LineupEntry.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> setLineupEntry(
    int matchId, {
    required int playerId,
    required String status,
    String? positionTerrain,
  }) {
    return _client.put(
      '${ApiConstants.matches}/$matchId/lineup',
      data: {
        'entries': [
          {
            'playerId': playerId,
            'status': status,
            'positionTerrain': ?positionTerrain,
          },
        ],
      },
    );
  }

  Future<List<AiRecommendation>> generateRecommendations(int matchId) async {
    final response = await _client.post(
      '${ApiConstants.matches}/$matchId/ai-recommendations',
      data: {},
    );
    return (response['data'] as List<dynamic>)
        .map((row) => AiRecommendation.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<AiRecommendation>> getRecommendations(int matchId) async {
    final response = await _client.get(
      '${ApiConstants.matches}/$matchId/ai-recommendations',
    );
    return (response['data'] as List<dynamic>)
        .map((row) => AiRecommendation.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<MatchEvent>> getEvents(int matchId) async {
    final response = await _client.get(
      '${ApiConstants.matches}/$matchId/events',
    );
    return (response['data'] as List<dynamic>)
        .map((row) => MatchEvent.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> recordEvent(
    int matchId, {
    required String eventType,
    required int minute,
    int? playerId,
  }) {
    return _client.post(
      '${ApiConstants.matches}/$matchId/events',
      data: {'eventType': eventType, 'minute': minute, 'playerId': ?playerId},
    );
  }

  Future<void> upsertEvaluation(
    int matchId, {
    required int playerId,
    double? note,
    String? commentaire,
  }) {
    return _client.put(
      '${ApiConstants.matches}/$matchId/evaluations',
      data: {'playerId': playerId, 'note': ?note, 'commentaire': ?commentaire},
    );
  }
}
