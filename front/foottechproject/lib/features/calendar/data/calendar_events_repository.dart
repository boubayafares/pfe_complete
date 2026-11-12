import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'calendar_event_model.dart';

class CalendarEventsRepository {
  CalendarEventsRepository({required this._client});

  final ApiClient _client;

  /// Liste les évènements du calendrier partagé de l'équipe de l'utilisateur
  /// (le backend se résout côté serveur, aucun teamId à passer).
  Future<List<CalendarEvent>> list({DateTime? from, DateTime? to}) async {
    final query = <String, dynamic>{};
    if (from != null) query['from'] = from.toUtc().toIso8601String();
    if (to != null) query['to'] = to.toUtc().toIso8601String();
    final response = await _client.get(
      ApiConstants.calendarEvents,
      queryParameters: query,
    );
    final data = response['data'] as List<dynamic>? ?? const [];
    return data
        .map((row) => CalendarEvent.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Crée un évènement (réservé au coach et à l'adjoint).
  Future<CalendarEvent> create({
    required String title,
    required DateTime startTime,
    String? description,
    DateTime? endTime,
    bool? allDay,
    String? location,
    String? color,
  }) async {
    final response = await _client.post(
      ApiConstants.calendarEvents,
      data: {
        'title': title,
        'startTime': startTime.toUtc().toIso8601String(),
        'description': ?description,
        if (endTime != null) 'endTime': endTime.toUtc().toIso8601String(),
        'allDay': ?allDay,
        'location': ?location,
        'color': ?color,
      },
    );
    return CalendarEvent.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Met à jour un évènement (coach + adjoint ; suppression réservée au coach).
  Future<CalendarEvent> update(
    int id, {
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? allDay,
    String? location,
    String? color,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (startTime != null) {
      body['startTime'] = startTime.toUtc().toIso8601String();
    }
    if (endTime != null) body['endTime'] = endTime.toUtc().toIso8601String();
    if (allDay != null) body['allDay'] = allDay;
    if (location != null) body['location'] = location;
    if (color != null) body['color'] = color;
    final response = await _client.patch(
      '${ApiConstants.calendarEvents}/$id',
      data: body,
    );
    return CalendarEvent.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Supprime un évènement (réservé au coach).
  Future<void> delete(int id) =>
      _client.delete('${ApiConstants.calendarEvents}/$id');
}
