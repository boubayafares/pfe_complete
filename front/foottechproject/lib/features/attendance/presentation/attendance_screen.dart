import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import 'attendance_provider.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key, required this.trainingId});
  final int trainingId;

  Color _statusColor(String status) => switch (status) {
        'PRESENT' => AppColors.green,
        'ABSENT' => const Color(0xFFE24B4A),
        'LATE' => AppColors.amberWarning,
        'INJURED' => AppColors.coralDanger,
        _ => AppColors.navyBorder,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceListProvider(trainingId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.attendance)),
      body: attendanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (records) {
          final present = records.where((r) => r.status == 'PRESENT').length;
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: records.isEmpty ? 0 : present / records.length,
                    minHeight: 6,
                    backgroundColor: AppColors.navyBorder,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(height: 6),
                Text(context.l10n.presentCount(present, records.length), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView.separated(
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(child: Text('${record.numeroMaillot ?? '-'} - ${record.fullName}', style: const TextStyle(fontSize: 13))),
                            for (final status in ['PRESENT', 'ABSENT', 'LATE', 'INJURED'])
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: InkWell(
                                  onTap: () async {
                                    await ref.read(attendanceRepositoryProvider).mark(trainingId, playerId: record.playerId, status: status);
                                    ref.invalidate(attendanceListProvider(trainingId));
                                  },
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: record.status == status ? _statusColor(status) : AppColors.navyBorder,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
