import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/calendar_event_model.dart';
import 'calendar_provider.dart';

/// Calendrier partagé de l'équipe.
///
/// Droits par rôle (mêmes règles que le backend) :
///  - JOUEUR : lecture seule (titre seul fourni par le serveur).
///  - COACH / ADJOINT : créer & modifier ; seule le COACH peut supprimer.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _visibleMonth; // premier jour du mois affiché
  late DateTime _selectedDay;

    static const _weekLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _selectedDay = now;
  }

  bool get _canWrite {
    final user = ref.read(authControllerProvider).value;
    return user?.isCoach == true || user?.isAdjoint == true;
  }

  bool get _canDelete {
    final user = ref.read(authControllerProvider).value;
    return user?.isCoach == true;
  }

  int _daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

  List<CalendarEvent> _eventsOn(DateTime day, List<CalendarEvent> all) {
    return all
        .where((e) =>
            e.startTime.year == day.year &&
            e.startTime.month == day.month &&
            e.startTime.day == day.day)
        .toList();
  }

  Color _parseColor(String? hex) {
    if (hex == null) return AppColors.green;
    final h = hex.replaceFirst('#', '');
    final v = int.tryParse(h, radix: 16);
    if (v == null) return AppColors.green;
    return Color(0xFF000000 | v);
  }

  String _formatDay(CalendarEvent e) {
    final fmt = e.allDay ? DateFormat('dd/MM/yyyy') : DateFormat('HH:mm');
    return fmt.format(e.startTime);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider);
    final canWrite = _canWrite;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.navCalendar),
        actions: [
          IconButton(
            tooltip: context.l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(calendarEventsProvider),
          ),
        ],
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton(
              onPressed: () => _openEditor(),
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.greenTextOnFill,
              child: const Icon(Icons.add),
            )
          : null,
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (events) => Column(
          children: [
            _monthHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: _weekLabels
                    .map((l) => Expanded(
                          child: Center(
                            child: Text(l,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _monthGrid(events),
            const Divider(height: AppSpacing.md),
            Expanded(child: _dayEvents(events, canWrite)),
          ],
        ),
      ),
    );
  }

  Widget _monthHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
            }),
          ),
          Expanded(
            child: Center(
              child: Text(
                DateFormat('MMMM yyyy', 'en_US').format(_visibleMonth).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
            }),
          ),
        ],
      ),
    );
  }

  Widget _monthGrid(List<CalendarEvent> events) {
    final leadingBlanks = (_visibleMonth.weekday - 1) % 7; // lundi en premier
    final daysInMonth = _daysInMonth(_visibleMonth);

    final cells = <Widget>[];
    for (int i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(_dayCell(DateTime(_visibleMonth.year, _visibleMonth.month, d), events));
    }
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox());
    }

    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      rows.add(SizedBox(
        height: 52,
        child: Row(
          children: [for (int j = 0; j < 7; j++) Expanded(child: cells[i + j])],
        ),
      ));
    }
    return Column(children: rows);
  }

  Widget _dayCell(DateTime day, List<CalendarEvent> events) {
    final dayEvents = _eventsOn(day, events);
    final isSelected = day.year == _selectedDay.year &&
        day.month == _selectedDay.month &&
        day.day == _selectedDay.day;
    final isToday = _isSameDay(day, DateTime.now());
    final color = dayEvents.isNotEmpty ? _parseColor(dayEvents.first.color) : null;

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = day),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenBgSoft : null,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: isToday ? Border.all(color: AppColors.green, width: 1) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.greenSoftText : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < (dayEvents.length > 3 ? 3 : dayEvents.length); i++)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayEvents(List<CalendarEvent> events, bool canWrite) {
    final dayEvents = _eventsOn(_selectedDay, events);
    final header = Text(
      DateFormat('EEEE d MMMM yyyy', 'en_US').format(_selectedDay),
      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );

    if (dayEvents.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          header,
          const SizedBox(height: AppSpacing.md),
          Text(
            canWrite
                ? context.l10n.noEventsDayTap
                : context.l10n.noEventsDay,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        header,
        const SizedBox(height: AppSpacing.md),
        for (final e in dayEvents) _eventCard(e),
      ],
    );
  }

  Widget _eventCard(CalendarEvent e) {
    final color = _parseColor(e.color);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: () => _showDetail(e),
        leading: Container(
          width: 6,
          height: 44,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(e.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(_formatDay(e), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      ),
    );
  }

  Future<void> _showDetail(CalendarEvent e) async {
    final canWrite = _canWrite;
    final canDelete = _canDelete;
    final color = _parseColor(e.color);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.navyCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 44,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(e.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _detailRow(Icons.schedule, context.l10n.date, DateFormat('dd/MM/yyyy HH:mm', 'en_US').format(e.startTime)),
              if (e.location != null) _detailRow(Icons.place_outlined, context.l10n.location, e.location!),
              if (e.description != null && e.description!.isNotEmpty)
                _detailRow(Icons.notes, context.l10n.description, e.description!),
              const SizedBox(height: AppSpacing.lg),
              if (canWrite || canDelete)
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    if (canWrite)
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openEditor(existing: e);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(context.l10n.edit),
                      ),
                    if (canDelete)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.coralDanger,
                          side: const BorderSide(color: AppColors.coralDanger),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(e);
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(context.l10n.delete),
                      ),
                  ],
                )
              else
                Text(context.l10n.readOnly,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.greenSoftText),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$label : ',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  TextSpan(text: value,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor({CalendarEvent? existing}) async {
    final input = await showDialog<_EventInput>(
      context: context,
      builder: (context) => _EventEditorDialog(existing: existing, defaultDay: _selectedDay),
    );
    if (input == null || !mounted) return;

    final repo = ref.read(calendarRepositoryProvider);
    try {
      if (existing == null) {
        await repo.create(
          title: input.title,
          description: input.description,
          startTime: input.startTime,
          endTime: input.allDay ? null : input.endTime,
          allDay: input.allDay,
          location: input.location,
          color: input.color,
        );
      } else {
        await repo.update(
          existing.id,
          title: input.title,
          description: input.description,
          startTime: input.startTime,
          endTime: input.allDay ? null : input.endTime,
          allDay: input.allDay,
          location: input.location,
          color: input.color,
        );
      }
      ref.invalidate(calendarEventsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existing == null ? context.l10n.eventAdded : context.l10n.eventModified)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _confirmDelete(CalendarEvent e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteTitle),
        content: Text(context.l10n.deleteConfirm(e.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.coralDanger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(calendarRepositoryProvider).delete(e.id);
    ref.invalidate(calendarEventsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.eventDeleted)));
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _EventInput {
  const _EventInput({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.allDay,
    this.description,
    this.location,
    this.color,
  });

  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool allDay;
  final String? description;
  final String? location;
  final String? color;
}

class _EventEditorDialog extends StatefulWidget {
  const _EventEditorDialog({this.existing, this.defaultDay});

  final CalendarEvent? existing;
  final DateTime? defaultDay;

  @override
  State<_EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends State<_EventEditorDialog> {
  static const _colorOptions = ['#00C853', '#378ADD', '#EF9F27', '#D85A30', '#9FB3C0'];

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late bool _allDay;
  late DateTime _date;
  late DateTime _time;
  String _color = _colorOptions.first;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final s = e?.startTime ?? widget.defaultDay ?? DateTime.now();
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _allDay = e?.allDay ?? false;
    _date = s;
    _time = s;
    if (e?.color != null && _colorOptions.contains(e!.color)) _color = e.color!;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_time));
    if (picked != null) {
      setState(() => _time = DateTime(_date.year, _date.month, _date.day, picked.hour, picked.minute));
    }
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.titleRequiredMsg)));
      return;
    }
    final start = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    Navigator.pop(
      context,
      _EventInput(
        title: title,
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        allDay: _allDay,
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        color: _color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? context.l10n.newEvent : context.l10n.edit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: context.l10n.titleRequired),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.allDay,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              value: _allDay,
              onChanged: (v) => setState(() => _allDay = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event, color: AppColors.greenSoftText),
              title: Text(context.l10n.date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              trailing: Text(DateFormat('dd/MM/yyyy').format(_date)),
              onTap: _pickDate,
            ),
            if (!_allDay)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule, color: AppColors.greenSoftText),
                title: Text(context.l10n.time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                trailing: Text(DateFormat('HH:mm').format(_time)),
                onTap: _pickTime,
              ),
            TextField(
              controller: _description,
              decoration: InputDecoration(labelText: context.l10n.description),
              maxLines: 2,
            ),
            TextField(
              controller: _location,
              decoration: InputDecoration(labelText: context.l10n.location),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(context.l10n.color,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                for (final c in _colorOptions)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: _parse(c),
                        shape: BoxShape.circle,
                        border: _color == c ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        FilledButton(onPressed: _save, child: Text(context.l10n.save)),
      ],
    );
  }

  Color _parse(String hex) => Color(0xFF000000 | (int.parse(hex.replaceFirst('#', ''), radix: 16)));
}
