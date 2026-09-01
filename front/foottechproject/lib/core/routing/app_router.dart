import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/adaptive_shell.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_coach_screen.dart';
import '../../features/auth/presentation/coach_otp_screen.dart';
import '../../features/auth/presentation/activate_adjoint_screen.dart';
import '../../features/auth/presentation/player_login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/season_bilan_screen.dart';
import '../../features/teams/presentation/team_screen.dart';
import '../../features/players/presentation/create_player_screen.dart';
import '../../features/players/presentation/player_profile_screen.dart';
import '../../features/trainings/presentation/trainings_list_screen.dart';
import '../../features/trainings/presentation/training_detail_screen.dart';
import '../../features/trainings/presentation/tactical_drawing_screen.dart';
import '../../features/attendance/presentation/attendance_screen.dart';
import '../../features/matches/presentation/matches_list_screen.dart';
import '../../features/matches/presentation/match_detail_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/exercise-proposals/presentation/proposals_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/seasons/presentation/seasons_screen.dart';
import '../../features/seasons/presentation/seasons_details.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/onboarding',
    refreshListenable: _AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.value != null;
      final isCheckingSession = authState.isLoading;
      final path = state.matchedLocation;

      final publicPaths = ['/onboarding', '/login', '/register-coach', '/coach-verify-otp', '/activate-adjoint', '/player-login'];
      final isPublicPath = publicPaths.any((p) => path.startsWith(p));

      if (isCheckingSession) return null;
      if (!isLoggedIn && !isPublicPath) return '/onboarding';
      if (isLoggedIn && isPublicPath) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register-coach', builder: (context, state) => const RegisterCoachScreen()),
      GoRoute(
        path: '/coach-verify-otp',
        builder: (context, state) => CoachOtpScreen(email: (state.extra as String?) ?? ''),
      ),
      GoRoute(path: '/activate-adjoint', builder: (context, state) => const ActivateAdjointScreen()),
      GoRoute(path: '/player-login', builder: (context, state) => const PlayerLoginScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AdaptiveShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/team', builder: (context, state) => const TeamScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/trainings', builder: (context, state) => const TrainingsListScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/matches', builder: (context, state) => const MatchesListScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
        ],
      ),

      // Pushed on top of the shell.
      GoRoute(
        path: '/players/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreatePlayerScreen(),
      ),
      GoRoute(
        path: '/players/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PlayerProfileScreen(playerId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/trainings/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TrainingDetailScreen(trainingId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/trainings/:id/attendance',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AttendanceScreen(trainingId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/trainings/:id/situations/:situationId/drawing',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TacticalDrawingScreen(
          trainingId: int.parse(state.pathParameters['id']!),
          situationId: int.parse(state.pathParameters['situationId']!),
        ),
      ),
      GoRoute(
        path: '/matches/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MatchDetailScreen(matchId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/season-bilan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SeasonBilanScreen(),
      ),
      GoRoute(
        path: '/exercise-proposals',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProposalsScreen(),
      ),
      GoRoute(
        path: '/seasons',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SeasonsScreen(),
      ),
      GoRoute(
        path: '/seasons/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SeasonDetailsScreen(seasonId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) => notifyListeners());
  }
}
