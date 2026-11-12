import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'notification_model.dart';

class NotificationsRepository {
  NotificationsRepository({required this._client});

  final ApiClient _client;

  Future<List<AppNotification>> listMine() async {
    final response = await _client.get(ApiConstants.notifications);
    return (response['data'] as List<dynamic>)
        .map((row) => AppNotification.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(int id) =>
      _client.patch('${ApiConstants.notifications}/$id/read');
  Future<void> markAllAsRead() =>
      _client.patch('${ApiConstants.notifications}/read-all');

  Future<Map<String, dynamic>> sendConvocation({
    required String targetType,
    required int targetId,
    String? title,
    String? message,
    required List<String> channels,
  }) async {
    final response = await _client.post(
      '${ApiConstants.notifications}/convocations',
      data: {
        'targetType': targetType,
        'targetId': targetId,
        'channels': channels,
        'title': ?title,
        'message': ?message,
      },
    );
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> registerPushToken(String token, {String? platform}) {
    return _client.post(
      '${ApiConstants.notifications}/push-token',
      data: {'token': token, 'platform': ?platform},
    );
  }
}
