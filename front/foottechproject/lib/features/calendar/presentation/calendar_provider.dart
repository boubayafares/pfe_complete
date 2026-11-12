import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/calendar_event_model.dart';
import '../data/calendar_events_repository.dart';

final calendarRepositoryProvider = Provider<CalendarEventsRepository>((ref) {
  return CalendarEventsRepository(client: ref.watch(apiClientProvider));
});

/// Évènements du calendrier partagé de l'équipe de l'utilisateur connecté.
final calendarEventsProvider = FutureProvider.autoDispose<List<CalendarEvent>>((
  ref,
) {
  // Attend que la session soit restaurée (teamId résolu côté serveur).
  ref.watch(authControllerProvider);
  return ref.watch(calendarRepositoryProvider).list();
});
