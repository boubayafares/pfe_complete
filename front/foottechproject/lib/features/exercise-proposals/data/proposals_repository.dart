import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'proposal_model.dart';

class ProposalsRepository {
  ProposalsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<ExerciseProposal>> list({String? status}) async {
    final response = await _client.get(ApiConstants.exerciseProposals, queryParameters: {if (status != null) 'status': status});
    return (response['data'] as List<dynamic>).map((row) => ExerciseProposal.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<void> create({required String titre, String? description}) {
    return _client.post(ApiConstants.exerciseProposals, data: {'titre': titre, if (description != null) 'description': description});
  }

  Future<void> review(int id, {required String status, String? comment}) {
    return _client.patch('${ApiConstants.exerciseProposals}/$id/review', data: {'status': status, if (comment != null) 'reviewComment': comment});
  }
}
