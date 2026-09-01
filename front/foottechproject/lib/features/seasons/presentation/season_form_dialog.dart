import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/seasons_model.dart';
import 'seasons_provider.dart';

class SeasonFormDialog extends ConsumerStatefulWidget {
  const SeasonFormDialog({super.key, this.season});

  final Season? season;

  @override
  ConsumerState<SeasonFormDialog> createState() => _SeasonFormDialogState();
}

class _SeasonFormDialogState extends ConsumerState<SeasonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late bool _isCurrent;
  bool _submitting = false;

  static const _dateFormat = 'yyyy-MM-dd';

  bool get _isEdit => widget.season != null;

  @override
  void initState() {
    super.initState();
    final season = widget.season;
    _nameController = TextEditingController(text: season?.name ?? '');
    _startDate = season?.startDate;
    _endDate = season?.endDate;
    _isCurrent = season?.isCurrent ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    final startDate = _startDate, endDate = _endDate;
    if (!_formKey.currentState!.validate()) return;
    if (startDate == null || endDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.required)));
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = ref.read(seasonsRepositoryProvider);
      final season = widget.season;
      if (season == null) {
        await repo.create(
          name: _nameController.text.trim(),
          startDate: DateFormat(_dateFormat).format(startDate),
          endDate: DateFormat(_dateFormat).format(endDate),
          isCurrent: _isCurrent,
        );
      } else {
        await repo.update(
          season.id,
          name: _nameController.text.trim(),
          startDate: DateFormat(_dateFormat).format(startDate),
          endDate: DateFormat(_dateFormat).format(endDate),
          isCurrent: _isCurrent,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFormat = DateFormat('d MMM yyyy');

    return AlertDialog(
      title: Text(_isEdit ? l10n.edit : l10n.newSeason),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.seasonName),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().length < 4) ? l10n.required : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _DateField(
                  label: l10n.startDate,
                  value: _startDate,
                  formatter: dateFormat,
                  onTap: () => _pickDate(isStart: true),
                ),
                const SizedBox(height: AppSpacing.md),
                _DateField(
                  label: l10n.endDate,
                  value: _endDate,
                  formatter: dateFormat,
                  onTap: () => _pickDate(isStart: false),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.current, style: const TextStyle(fontSize: 13)),
                  value: _isCurrent,
                  onChanged: (value) => setState(() => _isCurrent = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.greenTextOnFill))
              : Text(_isEdit ? l10n.save : l10n.createSeason),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.formatter, required this.onTap});

  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Text(
              value == null ? context.l10n.required : formatter.format(value!),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}