import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import 'proposals_provider.dart';

/// Adjoint proposes exercise ideas; Coach validates or rejects them here.
class ProposalsScreen extends ConsumerWidget {
  const ProposalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(pendingProposalsProvider);
    final user = ref.watch(authControllerProvider).value;
    final isCoach = user?.isCoach == true;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.exerciseProposals)),
      floatingActionButton: user?.isAdjoint == true
          ? FloatingActionButton(onPressed: () => _showProposeSheet(context, ref), child: const Icon(Icons.add))
          : null,
      body: proposalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (proposals) => proposals.isEmpty
            ? Center(child: Text(context.l10n.noPendingProposal, style: const TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: proposals.length,
                itemBuilder: (context, index) {
                  final proposal = proposals[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      title: Text(proposal.titre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: proposal.description != null ? Text(proposal.description!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)) : null,
                      trailing: isCoach
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline, color: AppColors.green, size: 20),
                                  onPressed: () async {
                                    await ref.read(proposalsRepositoryProvider).review(proposal.id, status: 'VALIDATED');
                                    ref.invalidate(pendingProposalsProvider);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel_outlined, color: AppColors.coralDanger, size: 20),
                                  onPressed: () async {
                                    await ref.read(proposalsRepositoryProvider).review(proposal.id, status: 'REJECTED');
                                    ref.invalidate(pendingProposalsProvider);
                                  },
                                ),
                              ],
                            )
                          : Text(context.l10n.pending, style: const TextStyle(color: AppColors.amberWarning, fontSize: 11)),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showProposeSheet(BuildContext context, WidgetRef ref) {
    final titreController = TextEditingController();
    final descriptionController = TextEditingController();
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
            Text(context.l10n.proposeExercise, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: titreController, decoration: InputDecoration(labelText: context.l10n.title)),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: descriptionController, maxLines: 3, decoration: InputDecoration(labelText: context.l10n.description)),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(proposalsRepositoryProvider).create(titre: titreController.text, description: descriptionController.text);
                  ref.invalidate(pendingProposalsProvider);
                  if (context.mounted) Navigator.of(context).pop();
                } on ApiException catch (error) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
                }
              },
              child: Text(context.l10n.submit),
            ),
          ],
        ),
      ),
    );
  }
}
