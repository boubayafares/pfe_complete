import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import 'trainings_provider.dart';

class CreateTrainingScreen extends ConsumerStatefulWidget {
  const CreateTrainingScreen({super.key});

  @override
  ConsumerState<CreateTrainingScreen> createState() =>
      _CreateTrainingScreenState();
}

class _CreateTrainingScreenState extends ConsumerState<CreateTrainingScreen> {
  final _locationController = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 30);
  bool _submitting = false;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    final teamId = ref.read(authControllerProvider).value?.teamId;
    if (teamId == null) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(trainingsRepositoryProvider)
          .create(
            date: _date,
            startTime: _fmt(_startTime),
            endTime: _fmt(_endTime),
            location: _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.newTraining)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Text(context.l10n.date),
                  subtitle: Text(
                    DateFormat('EEEE d MMMM yyyy', 'en_US').format(_date),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                ListTile(
                  title: Text(context.l10n.startTime),
                  subtitle: Text(_fmt(_startTime)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (picked != null) setState(() => _startTime = picked);
                  },
                ),
                ListTile(
                  title: Text(context.l10n.endTime),
                  subtitle: Text(_fmt(_endTime)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (picked != null) setState(() => _endTime = picked);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(labelText: context.l10n.location),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.greenTextOnFill,
                          ),
                        )
                      : Text(context.l10n.create),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
