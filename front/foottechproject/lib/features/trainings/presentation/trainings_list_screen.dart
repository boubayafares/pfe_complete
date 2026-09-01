import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import 'create_training_screen.dart';
import 'trainings_provider.dart';

class TrainingsListScreen extends ConsumerWidget {
  const TrainingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainingsAsync = ref.watch(teamTrainingsProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navTrainings)),
      floatingActionButton: user?.canManageTeam == true
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const CreateTrainingScreen()));
                if (created == true) ref.invalidate(teamTrainingsProvider);
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: trainingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (trainings) => trainings.isEmpty
            ? Center(child: Text(context.l10n.noTrainingPlanned, style: const TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: trainings.length,
                itemBuilder: (context, index) {
                  final training = trainings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      onTap: () => context.push('/trainings/${training.id}'),
                      title: Text(DateFormat('EEEE d MMM', 'en_US').format(training.date), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${training.startTime.substring(0, 5)} - ${training.endTime.substring(0, 5)}${training.location != null ? " · ${training.location}" : ""}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
