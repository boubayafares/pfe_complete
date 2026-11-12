import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../ai_insights/data/ai_insights_repository.dart';
import '../../ai_insights/presentation/ai_insights_provider.dart';
import '../data/dashboard_models.dart';
import '../../../core/utils/media_url.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../profile/presentation/profile_provider.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      final socketService = ref.read(socketServiceProvider);
      final socket = await socketService.connect();
      if (!mounted) return;
      socket.on('attendance:update', _handleAttendanceUpdate);
    });
  }

  void _handleAttendanceUpdate(dynamic payload) {
    if (payload is Map && payload['type'] == 'ATTENDANCE') {
      ref.invalidate(dashboardProvider);
    }
  }

  @override
  void dispose() {
    ref
        .read(socketServiceProvider)
        .socket
        ?.off('attendance:update', _handleAttendanceUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final dashboardAsync = ref.watch(dashboardProvider);
    final expertModelAsync = user?.canManageTeam == true
        ? ref.watch(expertProjectModelProvider)
        : null;
    final avatarUrl = MediaUrl.resolve(
      ref.watch(myProfileProvider).value?.profileImage,
    );
    final isWide = MediaQuery.of(context).size.width >= AppBreakpoints.desktop;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.green,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(user?.fullName ?? '', style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(dashboardProvider.future),
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 80),
              Center(child: Text('$error', textAlign: TextAlign.center)),
            ],
          ),
          data: (data) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 700 : double.infinity,
              ),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (data.upcomingTrainingDate != null)
                    _InfoCard(
                      label: context.l10n.nextTraining,
                      title: DateFormat(
                        'EEEE d MMMM - HH:mm',
                        'en_US',
                      ).format(DateTime.parse(data.upcomingTrainingDate!)),
                      subtitle: data.upcomingTrainingLocation,
                      trailing: _AttendanceBadge(data: data),
                      onTap: () =>
                          context.push('/trainings/${data.upcomingTrainingId}'),
                    ),
                  if (data.upcomingMatchAdversaire != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _InfoCard(
                      label: context.l10n.nextMatch,
                      title: 'vs ${data.upcomingMatchAdversaire}',
                      subtitle: data.upcomingMatchDate != null
                          ? DateFormat(
                              'EEEE d MMMM - HH:mm',
                              'en_US',
                            ).format(DateTime.parse(data.upcomingMatchDate!))
                          : null,
                      trailing: data.nextMatchSelectionStatus != null
                          ? _SelectionBadge(
                              status: data.nextMatchSelectionStatus!,
                            )
                          : null,
                      onTap: () =>
                          context.push('/matches/${data.upcomingMatchId}'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (data.playerCount != null)
                        Expanded(
                          child: _StatTile(
                            label: context.l10n.players,
                            value: '${data.playerCount}',
                          ),
                        ),
                      if (data.pendingProposals != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _StatTile(
                            label: context.l10n.proposals,
                            value: '${data.pendingProposals}',
                          ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatTile(
                          label: context.l10n.notifications,
                          value: '${data.unreadNotifications}',
                        ),
                      ),
                    ],
                  ),
                  if (user?.canManageTeam == true) ...[
                    const SizedBox(height: AppSpacing.lg),
                    if (expertModelAsync != null)
                      _ExpertAiCard(modelAsync: expertModelAsync),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.push('/exercise-proposals'),
                          icon: const Icon(Icons.sports_soccer, size: 18),
                          label: const Text('Bibliothèque tactique'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/notifications'),
                          icon: const Icon(Icons.outgoing_mail, size: 18),
                          label: const Text('Convocations'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/season-bilan'),
                          icon: const Icon(Icons.bar_chart, size: 18),
                          label: Text(context.l10n.seasonSummary),
                        ),
                      ],
                    ),
                  ],
                  if (user != null && user.canManageTeam != true) ...[
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/exercise-proposals'),
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: const Text('Bibliothèque tactique'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpertAiCard extends StatelessWidget {
  const _ExpertAiCard({required this.modelAsync});

  final AsyncValue<ExpertProjectModel> modelAsync;

  @override
  Widget build(BuildContext context) {
    return modelAsync.when(
      loading: () =>
          const _AiCardFrame(child: Center(child: CircularProgressIndicator())),
      error: (error, _) => _AiCardFrame(
        child: Text(
          'IA expert indisponible: $error',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
      data: (model) {
        final activeCapabilities = model.capabilities
            .where((item) => item['status'] == 'ACTIVE')
            .toList();
        final firstRecommendation = model.recommendations.isNotEmpty
            ? model.recommendations.first
            : 'Le modèle IA est prêt à exploiter les données du projet.';
        return _AiCardFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_alt, color: AppColors.green),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      model.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${model.maturityPercent}%',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(value: model.maturityProgress),
              const SizedBox(height: AppSpacing.sm),
              Text(
                firstRecommendation,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _CapabilityChip(
                    label:
                        '${activeCapabilities.length}/${model.capabilities.length} modules actifs',
                    highlighted: true,
                  ),
                  for (final capability in model.capabilities.take(3))
                    _CapabilityChip(
                      label: capability['label']?.toString() ?? 'Module IA',
                      highlighted: capability['status'] == 'ACTIVE',
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AiCardFrame extends StatelessWidget {
  const _AiCardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navyCardAlt,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.green : AppColors.textMuted;
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.14),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.greenBgSoft,
          border: Border.all(color: AppColors.green, width: 0.5),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.greenSoftText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'STARTER' => context.l10n.starter,
      'SUBSTITUTE' => context.l10n.substitute,
      _ => context.l10n.notSelected,
    };
    final color = status == 'STARTER' ? AppColors.green : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10)),
    );
  }
}

class _AttendanceBadge extends StatelessWidget {
  const _AttendanceBadge({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final total = data.upcomingTrainingRosterCount;
    final present = data.upcomingTrainingPresentCount;
    final progress = total == 0
        ? 0.0
        : (present / total).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 86,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$present/$total présents',
            style: const TextStyle(color: AppColors.green, fontSize: 10),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: progress),
          Text(
            '${data.upcomingTrainingMarkedCount} marqués',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navyCardAlt,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
