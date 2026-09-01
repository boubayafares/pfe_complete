import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import 'trainings_provider.dart';

class TrainingDetailScreen extends ConsumerWidget {
  const TrainingDetailScreen({super.key, required this.trainingId});
  final int trainingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetAsync = ref.watch(trainingSheetProvider(trainingId));
    final situationsAsync = ref.watch(trainingSituationsProvider(trainingId));
    final user = ref.watch(authControllerProvider).value;
    final canManage = user?.canManageTeam == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.technicalSheet),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: context.l10n.attendance,
            onPressed: () => context.push('/trainings/$trainingId/attendance'),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => _showAddSituationSheet(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          sheetAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
            data: (sheet) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.objectives, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(sheet?.objectifs ?? context.l10n.notProvided, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: AppSpacing.sm),
                Text(context.l10n.players, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(sheet?.effectif ?? context.l10n.notProvided, style: const TextStyle(fontSize: 13)),
                if (canManage) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => _showEditSheetDialog(context, ref, sheet?.objectifs, sheet?.effectif),
                    child: Text(context.l10n.edit),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(context.l10n.situations, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          situationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('$error'),
            data: (situations) => situations.isEmpty
                ? Text(context.l10n.noSituationAdded, style: const TextStyle(color: AppColors.textMuted))
                : Column(
                    children: situations.map((s) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          onTap: () => context.push('/trainings/$trainingId/situations/${s.id}/drawing'),
                          leading: CircleAvatar(radius: 14, backgroundColor: AppColors.navyBorder, child: Text('${s.ordre}', style: const TextStyle(fontSize: 11))),
                          title: Text(s.titre ?? 'Situation ${s.ordre}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            [
                              if (s.dureeTravail != null) context.l10n.work(s.dureeTravail!),
                              if (s.dureeRecuperation != null) context.l10n.recovery(s.dureeRecuperation!),
                            ].join(' · '),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                          trailing: const Icon(Icons.gesture, size: 18, color: AppColors.green),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditSheetDialog(BuildContext context, WidgetRef ref, String? objectifs, String? effectif) {
    final objectifsController = TextEditingController(text: objectifs);
    final effectifController = TextEditingController(text: effectif);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.navyCard,
        title: Text(context.l10n.technicalSheet),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: objectifsController, maxLines: 3, decoration: InputDecoration(labelText: context.l10n.objectives)),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: effectifController, decoration: InputDecoration(labelText: context.l10n.players)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(trainingsRepositoryProvider).upsertSheet(trainingId, objectifs: objectifsController.text, effectif: effectifController.text);
                ref.invalidate(trainingSheetProvider(trainingId));
                if (context.mounted) Navigator.of(context).pop();
              } on ApiException catch (error) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
  }

  void _showAddSituationSheet(BuildContext context, WidgetRef ref) {
    final titreController = TextEditingController();
    final travailController = TextEditingController();
    final recupController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyCard,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.newSituation, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: titreController, decoration: InputDecoration(labelText: context.l10n.title)),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: travailController, decoration: InputDecoration(labelText: context.l10n.workDuration)),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: recupController, decoration: InputDecoration(labelText: context.l10n.recoveryDuration)),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(trainingsRepositoryProvider).createSituation(trainingId, {
                    'titre': titreController.text,
                    'dureeTravail': travailController.text,
                    'dureeRecuperation': recupController.text,
                  });
                  ref.invalidate(trainingSituationsProvider(trainingId));
                  if (context.mounted) Navigator.of(context).pop();
                } on ApiException catch (error) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
                }
              },
              child: Text(context.l10n.add),
            ),
          ],
        ),
      ),
    );
  }
}
