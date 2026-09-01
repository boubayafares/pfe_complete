import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'notification_model.dart';

class NotificationsRepository {
  NotificationsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<AppNotification>> listMine() async {
    final response = await _client.get(ApiConstants.notifications);
    return (response['data'] as List<dynamic>).map((row) => AppNotification.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<void> markAsRead(int id) => _client.patch('${ApiConstants.notifications}/$id/read');
  Future<void> markAllAsRead() => _client.patch('${ApiConstants.notifications}/read-all');

  Future<void> registerPushToken(String token, {String? platform}) {
    return _client.post('${ApiConstants.notifications}/push-token', data: {
      'token': token,
      if (platform != null) 'platform': platform,
    });
  }
}
