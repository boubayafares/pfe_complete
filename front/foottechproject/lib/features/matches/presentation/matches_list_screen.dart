import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import 'create_match_screen.dart';
import 'matches_provider.dart';

class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(teamMatchesProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navMatches)),
      floatingActionButton: user?.canManageTeam == true
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const CreateMatchScreen()),
                );
                if (created == true) ref.invalidate(teamMatchesProvider);
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (matches) => matches.isEmpty
            ? Center(
                child: Text(
                  context.l10n.noMatches,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      onTap: () => context.push('/matches/${match.id}'),
                      title: Text(
                        context.l10n.homeAwayVs(
                          match.isHome ? context.l10n.home : context.l10n.away,
                          match.adversaire,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat(
                          'EEEE d MMM - HH:mm',
                          'en_US',
                        ).format(match.dateHeure),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      trailing: match.matchStatus == 'SCHEDULED'
                          ? const Icon(
                              Icons.chevron_right,
                              color: AppColors.textMuted,
                            )
                          : Text(
                              match.scoreLabel,
                              style: TextStyle(
                                color: match.isLive
                                    ? AppColors.green
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
