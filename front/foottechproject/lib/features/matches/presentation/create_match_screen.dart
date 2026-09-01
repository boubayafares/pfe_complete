import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import 'matches_provider.dart';

class CreateMatchScreen extends ConsumerStatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  final _adversaireController = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  bool _isHome = true;
  bool _submitting = false;

  Future<void> _submit() async {
    final teamId = ref.read(authControllerProvider).value?.teamId;
    if (teamId == null || _adversaireController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      final dateHeure = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
      await ref.read(matchesRepositoryProvider).create(teamId: teamId, adversaire: _adversaireController.text.trim(), dateHeure: dateHeure, isHome: _isHome);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.newMatch)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _adversaireController, decoration: InputDecoration(labelText: context.l10n.opponent)),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  title: Text(context.l10n.date),
                  subtitle: Text(DateFormat('EEEE d MMMM yyyy', 'en_US').format(_date)),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                ListTile(
                  title: Text(context.l10n.time),
                  subtitle: Text(_time.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _time);
                    if (picked != null) setState(() => _time = picked);
                  },
                ),
                SwitchListTile(
                  title: Text(context.l10n.homeGame),
                  value: _isHome,
                  onChanged: (value) => setState(() => _isHome = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.greenTextOnFill))
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
