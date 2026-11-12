import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import 'season_form_dialog.dart';
import 'seasons_provider.dart';

class SeasonDetailsScreen extends ConsumerWidget {
  const SeasonDetailsScreen({super.key, required this.seasonId});

  final int seasonId;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final season = ref.read(seasonProvider(seasonId)).value;
    if (season == null) return;
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => SeasonFormDialog(season: season),
    );
    if (updated == true) {
      ref.invalidate(seasonProvider(seasonId));
      ref.invalidate(seasonsListProvider);
    }
  }

  Future<void> _setCurrent(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(seasonsRepositoryProvider)
          .update(seasonId, isCurrent: true);
      ref.invalidate(seasonProvider(seasonId));
      ref.invalidate(seasonsListProvider);
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteTitle),
        content: Text(l10n.deleteConfirm(l10n.navSeasons)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.coralDanger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(seasonsRepositoryProvider).remove(seasonId);
      ref.invalidate(seasonsListProvider);
      if (context.mounted) context.pop();
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync = ref.watch(seasonProvider(seasonId));
    final user = ref.watch(authControllerProvider).value;
    final canManage = user?.canManageTeam == true;
    final dateFormat = DateFormat('EEEE d MMMM yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.seasonDetails)),
      body: seasonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (season) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              season.isCurrent
                                  ? Icons.calendar_month
                                  : Icons.calendar_today_outlined,
                              color: season.isCurrent
                                  ? AppColors.green
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                season.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          context.l10n.fromTo(
                            dateFormat.format(season.startDate),
                            dateFormat.format(season.endDate),
                          ),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (season.isCurrent)
                          Text(
                            context.l10n.current,
                            style: const TextStyle(
                              color: AppColors.greenSoftText,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (canManage && season.teamId != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  if (!season.isCurrent)
                    OutlinedButton.icon(
                      onPressed: () => _setCurrent(context, ref),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(context.l10n.current),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => _edit(context, ref),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(context.l10n.edit),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => _delete(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.coralDanger,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(context.l10n.deleteSeason),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
