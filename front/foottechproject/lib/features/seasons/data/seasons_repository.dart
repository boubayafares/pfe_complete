import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'seasons_model.dart';

/// HTTP-backed season management against the FootTech v2 backend.
class SeasonsRepository {
  SeasonsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<Season>> list() async {
    final body = await _api.get(ApiConstants.seasons);
    final data = body['data'] as List<dynamic>;
    return data.map((e) => Season.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Season> getById(int id) async {
    final body = await _api.get('${ApiConstants.seasons}/$id');
    return Season.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Season> create({
    required String name,
    required String startDate,
    required String endDate,
    bool isCurrent = false,
  }) async {
    final body = await _api.post(
      ApiConstants.seasons,
      data: {
        'name': name,
        'startDate': startDate,
        'endDate': endDate,
        'isCurrent': isCurrent,
      },
    );
    return Season.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Season> update(
    int id, {
    String? name,
    String? startDate,
    String? endDate,
    bool? isCurrent,
  }) async {
    final body = await _api.patch(
      '${ApiConstants.seasons}/$id',
      data: {
        'name': ?name,
        'startDate': ?startDate,
        'endDate': ?endDate,
        'isCurrent': ?isCurrent,
      },
    );
    return Season.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> remove(int id) async {
    await _api.delete('${ApiConstants.seasons}/$id');
  }
}
