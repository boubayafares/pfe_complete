import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'dashboard_models.dart';

class DashboardRepository {
  DashboardRepository({required this._client});

  final ApiClient _client;

  Future<DashboardData> getMyDashboard() async {
    final response = await _client.get('${ApiConstants.dashboard}/me');
    return DashboardData.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<SeasonBilanEntry>> getSeasonBilan({int? seasonId}) async {
    final response = await _client.get(
      '${ApiConstants.dashboard}/season-bilan',
      queryParameters: {'seasonId': ?seasonId},
    );
    return (response['data'] as List<dynamic>)
        .map((row) => SeasonBilanEntry.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
