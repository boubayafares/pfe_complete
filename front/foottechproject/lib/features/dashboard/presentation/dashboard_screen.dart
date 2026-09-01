import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncValueX, ConsumerWidget, WidgetRef;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/media_url.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../profile/presentation/profile_provider.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final dashboardAsync = ref.watch(dashboardProvider);
    final avatarUrl = MediaUrl.resolve(ref.watch(myProfileProvider).value?.profileImage);
    final isWide = MediaQuery.of(context).size.width >= AppBreakpoints.desktop;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.green,
              backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
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
            children: [const SizedBox(height: 80), Center(child: Text('$error', textAlign: TextAlign.center))],
          ),
          data: (data) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 700 : double.infinity),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (data.upcomingTrainingDate != null)
                    _InfoCard(
                      label: context.l10n.nextTraining,
                      title: DateFormat('EEEE d MMMM - HH:mm', 'en_US').format(DateTime.parse(data.upcomingTrainingDate!)),
                      subtitle: data.upcomingTrainingLocation,
                      onTap: () => context.push('/trainings/${data.upcomingTrainingId}'),
                    ),
                  if (data.upcomingMatchAdversaire != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _InfoCard(
                      label: context.l10n.nextMatch,
                      title: 'vs ${data.upcomingMatchAdversaire}',
                      subtitle: data.upcomingMatchDate != null
                          ? DateFormat('EEEE d MMMM - HH:mm', 'en_US').format(DateTime.parse(data.upcomingMatchDate!))
                          : null,
                      trailing: data.nextMatchSelectionStatus != null
                          ? _SelectionBadge(status: data.nextMatchSelectionStatus!)
                          : null,
                      onTap: () => context.push('/matches/${data.upcomingMatchId}'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (data.playerCount != null)
                        Expanded(child: _StatTile(label: context.l10n.players, value: '${data.playerCount}')),
                      if (data.pendingProposals != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: _StatTile(label: context.l10n.proposals, value: '${data.pendingProposals}')),
                      ],
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _StatTile(label: context.l10n.notifications, value: '${data.unreadNotifications}')),
                    ],
                  ),
                  if (user?.canManageTeam == true) ...[
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/season-bilan'),
                      icon: const Icon(Icons.bar_chart, size: 18),
                      label: Text(context.l10n.seasonSummary),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.title, this.subtitle, this.trailing, this.onTap});

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
                  Text(label, style: const TextStyle(color: AppColors.greenSoftText, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10)),
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
      decoration: BoxDecoration(color: AppColors.navyCardAlt, borderRadius: BorderRadius.circular(AppRadii.card)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
