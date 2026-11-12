import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/attendance_model.dart';
import '../data/attendance_repository.dart';
import 'attendance_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key, required this.trainingId});
  final int trainingId;

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _bulkSubmitting = false;
  Color _statusColor(String status) => switch (status) {
    'PRESENT' => AppColors.green,
    'ABSENT' => const Color(0xFFE24B4A),
    'LATE' => AppColors.amberWarning,
    'INJURED' => AppColors.coralDanger,
    _ => AppColors.navyBorder,
  };

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      final socketService = ref.read(socketServiceProvider);
      final socket = await socketService.connect();
      if (!mounted) return;
      socketService.joinTrainingAttendance(widget.trainingId);
      socket.on('attendance:update', _handleAttendanceUpdate);
    });
  }

  void _handleAttendanceUpdate(dynamic payload) {
    if (payload is Map && payload['trainingId'] == widget.trainingId) {
      ref.invalidate(attendanceListProvider(widget.trainingId));
    }
  }

  @override
  void dispose() {
    final socketService = ref.read(socketServiceProvider);
    socketService.socket?.off('attendance:update', _handleAttendanceUpdate);
    socketService.leaveTrainingAttendance(widget.trainingId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(
      attendanceListProvider(widget.trainingId),
    );
    final canManage =
        ref.watch(authControllerProvider).value?.canManageTeam == true;

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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.presentCount(present, records.length),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (canManage && records.isNotEmpty)
                      TextButton.icon(
                        onPressed: _bulkSubmitting
                            ? null
                            : () => _markAllPresent(records),
                        icon: _bulkSubmitting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.done_all, size: 16),
                        label: const Text('Tous présents'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView.separated(
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${record.numeroMaillot ?? '-'} - ${record.fullName}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            for (final status in [
                              'PRESENT',
                              'ABSENT',
                              'LATE',
                              'INJURED',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: InkWell(
                                  onTap: canManage
                                      ? () async {
                                          try {
                                            await ref
                                                .read(
                                                  attendanceRepositoryProvider,
                                                )
                                                .mark(
                                                  widget.trainingId,
                                                  playerId: record.playerId,
                                                  status: status,
                                                );
                                            ref.invalidate(
                                              attendanceListProvider(
                                                widget.trainingId,
                                              ),
                                            );
                                          } on ApiException catch (error) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(error.message),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      : null,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: record.status == status
                                          ? _statusColor(status)
                                          : AppColors.navyBorder,
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

  Future<void> _markAllPresent(List<AttendanceRecord> records) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer les présences'),
        content: Text('${records.length} joueurs seront marqués présents.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _bulkSubmitting = true);
    try {
      await ref
          .read(attendanceRepositoryProvider)
          .bulkMark(
            widget.trainingId,
            entries: records
                .map(
                  (record) => AttendanceEntry(
                    playerId: record.playerId,
                    status: 'PRESENT',
                  ),
                )
                .toList(),
          );
      ref.invalidate(attendanceListProvider(widget.trainingId));
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _bulkSubmitting = false);
    }
  }
}
