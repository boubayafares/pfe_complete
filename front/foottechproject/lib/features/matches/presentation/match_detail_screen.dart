import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/match_model.dart';
import 'matches_provider.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.matchId});
  final int matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchLiveControllerProvider(matchId));
    final user = ref.watch(authControllerProvider).value;
    final canManage = user?.canManageTeam == true;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: matchAsync.maybeWhen(
            data: (m) => Text(
              context.l10n.homeAwayVs(
                m.isHome ? context.l10n.home : context.l10n.away,
                m.adversaire,
              ),
            ),
            orElse: () => const Text('Match'),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.green,
            tabs: [
              Tab(text: context.l10n.lineup),
              Tab(text: context.l10n.live),
              Tab(text: context.l10n.ai),
            ],
          ),
        ),
        body: matchAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (match) => TabBarView(
            children: [
              _LineupTab(matchId: matchId, canManage: canManage),
              _LiveTab(matchId: matchId, match: match, canManage: canManage),
              _AiTab(matchId: matchId, canManage: canManage),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineupTab extends ConsumerWidget {
  const _LineupTab({required this.matchId, required this.canManage});
  final int matchId;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineupAsync = ref.watch(matchLineupProvider(matchId));

    return lineupAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (lineup) {
        final starters = lineup.where((e) => e.status == 'STARTER').toList();
        final subs = lineup.where((e) => e.status == 'SUBSTITUTE').toList();
        final notSelected = lineup
            .where((e) => e.status == 'NOT_SELECTED')
            .toList();
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              context.l10n.starters,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            ...starters.map(
              (e) =>
                  _LineupTile(entry: e, canManage: canManage, matchId: matchId),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.substitutes,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            ...subs.map(
              (e) =>
                  _LineupTile(entry: e, canManage: canManage, matchId: matchId),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.notSelected,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            ...notSelected.map(
              (e) =>
                  _LineupTile(entry: e, canManage: canManage, matchId: matchId),
            ),
            if (lineup.isEmpty)
              Text(
                context.l10n.lineupNotSet,
                style: const TextStyle(color: AppColors.textMuted),
              ),
          ],
        );
      },
    );
  }
}

class _LineupTile extends ConsumerWidget {
  const _LineupTile({
    required this.entry,
    required this.canManage,
    required this.matchId,
  });
  final LineupEntry entry;
  final bool canManage;
  final int matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.navyBorder,
        child: Text(
          '${entry.numeroMaillot ?? '-'}',
          style: const TextStyle(fontSize: 11),
        ),
      ),
      title: Text(entry.fullName, style: const TextStyle(fontSize: 13)),
      subtitle: entry.positionTerrain != null
          ? Text(
              entry.positionTerrain!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            )
          : null,
      trailing: canManage
          ? DropdownButton<String>(
              value: entry.status,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(
                  value: 'STARTER',
                  child: Text(context.l10n.starter),
                ),
                DropdownMenuItem(
                  value: 'SUBSTITUTE',
                  child: Text(context.l10n.substitute),
                ),
                DropdownMenuItem(
                  value: 'NOT_SELECTED',
                  child: Text(context.l10n.notSelected),
                ),
              ],
              onChanged: (status) async {
                if (status == null || status == entry.status) return;
                try {
                  await ref
                      .read(matchesRepositoryProvider)
                      .setLineupEntry(
                        matchId,
                        playerId: entry.playerId,
                        status: status,
                        positionTerrain: entry.positionTerrain,
                      );
                  ref.invalidate(matchLineupProvider(matchId));
                } on ApiException catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.message)));
                  }
                }
              },
            )
          : null,
    );
  }
}

class _LiveTab extends ConsumerWidget {
  const _LiveTab({
    required this.matchId,
    required this.match,
    required this.canManage,
  });
  final int matchId;
  final MatchInfo match;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(matchEventsProvider(matchId));
    final lineupAsync = ref.watch(matchLineupProvider(matchId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(
                match.matchStatus,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                match.scoreLabel,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (canManage) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (match.matchStatus == 'SCHEDULED')
                      ElevatedButton(
                        onPressed: () async {
                          await ref
                              .read(matchesRepositoryProvider)
                              .updateStatus(matchId, 'LIVE');
                          ref.invalidate(matchLiveControllerProvider(matchId));
                        },
                        child: Text(context.l10n.start),
                      ),
                    if (match.matchStatus == 'LIVE') ...[
                      ElevatedButton(
                        onPressed: () => _showRecordEventSheet(
                          context,
                          ref,
                          lineupAsync.value ?? [],
                        ),
                        child: Text(context.l10n.addEvent),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () async {
                          await ref
                              .read(matchesRepositoryProvider)
                              .updateStatus(matchId, 'FINISHED');
                          ref.invalidate(matchLiveControllerProvider(matchId));
                        },
                        child: Text(context.l10n.finish),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: eventsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (events) => events.isEmpty
                ? Center(
                    child: Text(
                      context.l10n.noEvents,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return ListTile(
                        leading: Text(
                          "${event.minute}'",
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        title: Text(
                          _eventLabel(context, event.eventType),
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String _eventLabel(BuildContext context, String type) => switch (type) {
    'GOAL' => context.l10n.eventGoal,
    'ASSIST' => context.l10n.eventAssist,
    'YELLOW_CARD' => context.l10n.yellowCard,
    'RED_CARD' => context.l10n.redCard,
    'SUBSTITUTION_IN' => context.l10n.eventSubOn,
    'SUBSTITUTION_OUT' => context.l10n.eventSubOff,
    'INJURY' => context.l10n.eventInjury,
    _ => type,
  };

  void _showRecordEventSheet(
    BuildContext context,
    WidgetRef ref,
    List<LineupEntry> lineup,
  ) {
    String eventType = 'GOAL';
    int? playerId = lineup.isNotEmpty ? lineup.first.playerId : null;
    final minuteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyCard,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: eventType,
                decoration: InputDecoration(labelText: context.l10n.type),
                items: [
                  DropdownMenuItem(
                    value: 'GOAL',
                    child: Text(context.l10n.eventGoal),
                  ),
                  DropdownMenuItem(
                    value: 'YELLOW_CARD',
                    child: Text(context.l10n.yellowCard),
                  ),
                  DropdownMenuItem(
                    value: 'RED_CARD',
                    child: Text(context.l10n.redCard),
                  ),
                  DropdownMenuItem(
                    value: 'INJURY',
                    child: Text(context.l10n.eventInjury),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => eventType = value ?? 'GOAL'),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<int>(
                initialValue: playerId,
                decoration: InputDecoration(labelText: context.l10n.player),
                items: lineup
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.playerId,
                        child: Text(e.fullName),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => playerId = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: minuteController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.l10n.minute),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ref
                        .read(matchesRepositoryProvider)
                        .recordEvent(
                          matchId,
                          eventType: eventType,
                          minute: int.tryParse(minuteController.text) ?? 0,
                          playerId: playerId,
                        );
                    ref.invalidate(matchEventsProvider(matchId));
                    if (context.mounted) Navigator.of(context).pop();
                  } on ApiException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.message)));
                    }
                  }
                },
                child: Text(context.l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiTab extends ConsumerWidget {
  const _AiTab({required this.matchId, required this.canManage});
  final int matchId;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(
      matchRecommendationsProvider(matchId),
    );

    return Column(
      children: [
        if (canManage)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await ref
                      .read(matchesRepositoryProvider)
                      .generateRecommendations(matchId);
                  ref.invalidate(matchRecommendationsProvider(matchId));
                } on ApiException catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.message)));
                  }
                }
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(context.l10n.generateAiRecommendations),
            ),
          ),
        Expanded(
          child: recommendationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (recommendations) => recommendations.isEmpty
                ? Center(
                    child: Text(
                      context.l10n.noRecommendation,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: recommendations.length,
                    itemBuilder: (context, index) {
                      final rec = recommendations[index];
                      final label = switch (rec.recommendedStatus) {
                        'STARTER' => context.l10n.starter,
                        'SUBSTITUTE' => context.l10n.substitute,
                        _ => context.l10n.notSelected,
                      };
                      final color = rec.recommendedStatus == 'STARTER'
                          ? AppColors.green
                          : AppColors.textMuted;
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          title: Text(
                            context.l10n.playerId(rec.playerId),
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            'Score: ${((rec.finalScore ?? 0) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(color: color, fontSize: 10),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
