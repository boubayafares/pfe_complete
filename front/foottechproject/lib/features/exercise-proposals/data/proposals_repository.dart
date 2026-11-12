import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'proposal_model.dart';

class ProposalsRepository {
  ProposalsRepository({required this._client});

  final ApiClient _client;

  Future<List<ExerciseProposal>> list({String? status}) async {
    final response = await _client.get(
      ApiConstants.exerciseProposals,
      queryParameters: {'status': ?status},
    );
    return (response['data'] as List<dynamic>)
        .map((row) => ExerciseProposal.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExerciseProposal>> library() async {
    final response = await _client.get(
      '${ApiConstants.exerciseProposals}/library',
    );
    return (response['data'] as List<dynamic>)
        .map((row) => ExerciseProposal.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String titre,
    String? description,
    String? category,
    String? objectif,
    String difficulty = 'MEDIUM',
    int? durationMinutes,
    String visibility = 'TEAM',
    List<String> tags = const [],
  }) {
    return _client.post(
      ApiConstants.exerciseProposals,
      data: {
        'titre': titre,
        'description': ?description,
        'category': ?category,
        'objectif': ?objectif,
        'difficulty': difficulty,
        'durationMinutes': ?durationMinutes,
        'visibility': visibility,
        'tags': tags,
        'canvasData': {
          'pitch': 'football_2d',
          'players': [
            {'id': 6, 'role': 'Relayeur', 'x': 0.35, 'y': 0.52},
            {'id': 8, 'role': 'Createur', 'x': 0.58, 'y': 0.42},
            {'id': 9, 'role': 'Finisseur', 'x': 0.50, 'y': 0.18},
          ],
          'arrows': [
            {
              'from': {'x': 0.35, 'y': 0.52},
              'to': {'x': 0.58, 'y': 0.42},
            },
            {
              'from': {'x': 0.58, 'y': 0.42},
              'to': {'x': 0.50, 'y': 0.18},
            },
          ],
        },
        'animationData': {
          'mode': '2D_TIMELINE',
          'threeDReady': true,
          'keyframes': [
            {'t': 0, 'label': 'Placement'},
            {'t': 4, 'label': 'Appel et decalage'},
            {'t': 8, 'label': 'Finition'},
          ],
        },
      },
    );
  }

  Future<void> review(int id, {required String status, String? comment}) {
    return _client.patch(
      '${ApiConstants.exerciseProposals}/$id/review',
      data: {'status': status, 'reviewComment': ?comment},
    );
  }
}
