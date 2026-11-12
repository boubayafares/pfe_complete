
/// Points at the FootTech v2 backend (Coach/Staff/Player).
/// Override at build/run time, e.g.:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
///   flutter run -d windows --dart-define=API_BASE_URL=http://192.168.1.50:4000
/// Android emulator: use http://10.0.2.2:4000 (loopback alias to the host).
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: "http://localhost:4000",
  );

  static const String apiPrefix = '/api/v1';
  static final String socketUrl = baseUrl;

  static const String auth = '$apiPrefix/auth';
  static const String users = '$apiPrefix/users';
  static const String teams = '$apiPrefix/teams';
  static const String players = '$apiPrefix/players';
  static const String seasons = '$apiPrefix/seasons';
  static const String weeklyPlannings = '$apiPrefix/weekly-plannings';
  static const String trainings = '$apiPrefix/trainings';
  static const String exerciseProposals = '$apiPrefix/exercise-proposals';
  static const String attendance = '$apiPrefix/attendance';
  static const String matches = '$apiPrefix/matches';
  static const String notifications = '$apiPrefix/notifications';
  static const String dashboard = '$apiPrefix/dashboard';
  static const String calendarEvents = '$apiPrefix/calendar-events';
  static const String aiInsights = '$apiPrefix/ai-insights';
}
