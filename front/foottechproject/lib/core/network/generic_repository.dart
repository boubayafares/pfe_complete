import '../network/api_client.dart';
import '../utils/pagination.dart';

/// Generic repository over a single REST resource, mirroring the backend's
/// BaseRepository. Used directly by the lighter modules (seasons,
/// weekly-plannings, exercise-proposals) and as a base pattern the richer
/// modules' hand-written repositories follow.
class GenericRepository<T> {
  GenericRepository({
    required this._client,
    required this._basePath,
    required this._fromJson,
  });

  final ApiClient _client;
  final String _basePath;
  final T Function(Map<String, dynamic> json) _fromJson;

  Future<List<T>> list({Map<String, dynamic>? filters}) async {
    final response = await _client.get(_basePath, queryParameters: filters);
    final data = response['data'];
    if (data is! List) return [];
    return data.map((row) => _fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<Paginated<T>> listPaginated({Map<String, dynamic>? filters}) async {
    final response = await _client.get(_basePath, queryParameters: filters);
    final data = response['data'];
    final items = data is List
        ? data.map((row) => _fromJson(row as Map<String, dynamic>)).toList()
        : <T>[];
    final paginationJson = response['pagination'];
    final meta = paginationJson is Map<String, dynamic>
        ? PaginationMeta.fromJson(paginationJson)
        : null;
    return Paginated(items: items, meta: meta);
  }

  Future<T> getById(int id) async {
    final response = await _client.get('$_basePath/$id');
    return _fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<T> create(Map<String, dynamic> body) async {
    final response = await _client.post(_basePath, data: body);
    return _fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<T> update(int id, Map<String, dynamic> body) async {
    final response = await _client.patch('$_basePath/$id', data: body);
    return _fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> remove(int id) => _client.delete('$_basePath/$id');
}
