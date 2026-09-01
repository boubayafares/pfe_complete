import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../localization/localization.dart';
import '../theme/app_theme.dart';

class _Destination {
  const _Destination({required this.icon, required this.selectedIcon});
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination(icon: Icons.home_outlined, selectedIcon: Icons.home),
  _Destination(icon: Icons.groups_outlined, selectedIcon: Icons.groups),
  _Destination(icon: Icons.fitness_center_outlined, selectedIcon: Icons.fitness_center),
  _Destination(icon: Icons.sports_soccer_outlined, selectedIcon: Icons.sports_soccer),
  _Destination(icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month),
  _Destination(icon: Icons.person_outline, selectedIcon: Icons.person),
];

String _label(BuildContext context, int index) {
  switch (index) {
    case 0:
      return context.l10n.navHome;
    case 1:
      return context.l10n.navTeam;
    case 2:
      return context.l10n.navTrainings;
    case 3:
      return context.l10n.navMatches;
    case 4:
      return context.l10n.navCalendar;
    default:
      return context.l10n.navProfile;
  }
}

/// Wraps go_router's StatefulShellRoute branches. Below [AppBreakpoints.desktop]
/// (phones, narrow windows) this renders a bottom nav bar; at/above it
/// (tablets landscape, desktop, web on a normal window) it renders a
/// NavigationRail down the left side instead — same branches, same state,
/// just a different chrome per form factor.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= AppBreakpoints.desktop;

    if (!isWide) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
          items: _destinations
              .asMap()
              .entries
              .map((e) => BottomNavigationBarItem(icon: Icon(e.value.icon), activeIcon: Icon(e.value.selectedIcon), label: _label(context, e.key)))
              .toList(),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.navyBgAlt,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.sports_soccer, color: AppColors.greenTextOnFill, size: 18),
              ),
            ),
            destinations: _destinations
                .asMap()
                .entries
                .map((e) => NavigationRailDestination(icon: Icon(e.value.icon), selectedIcon: Icon(e.value.selectedIcon), label: Text(_label(context, e.key))))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
