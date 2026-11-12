/// Un évènement du calendrier partagé d'une équipe.
///
/// Les joueurs reçoivent une projection "titre seul" du backend (pas de
/// description / lieu) : [description] et [location] restent donc `null` pour
/// le rôle JOUEUR, tandis que le coach et l'adjoint obtiennent le détail
/// complet.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    this.endTime,
    this.allDay = false,
    this.description,
    this.location,
    this.color,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      // `id` est un BIGSERIAL côté backend, donc renvoyé sous forme de String.
      id: int.parse(json['id'].toString()),
      title: json['title'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
      allDay: json['all_day'] as bool? ?? false,
      description: json['description'] as String?,
      location: json['location'] as String?,
      color: json['color'] as String?,
    );
  }

  final int id;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final bool allDay;
  final String? description;
  final String? location;

  /// Couleur hexadécimale éventuelle (ex: "#ff0000").
  final String? color;
}
