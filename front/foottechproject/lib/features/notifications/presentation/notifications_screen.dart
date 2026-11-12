import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, size: 20),
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).markAllAsRead();
              ref.invalidate(notificationsListProvider);
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (notifications) => notifications.isEmpty
            ? Center(
                child: Text(
                  context.l10n.noNotifications,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            : ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return ListTile(
                    onTap: () async {
                      await ref
                          .read(notificationsRepositoryProvider)
                          .markAsRead(n.id);
                      ref.invalidate(notificationsListProvider);
                    },
                    leading: Icon(
                      Icons.circle,
                      size: n.isRead ? 0 : 8,
                      color: AppColors.green,
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: n.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      n.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      DateFormat('d MMM', 'en_US').format(n.createdAt),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: user?.canManageTeam == true
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const _ConvocationSheet(),
              ),
              icon: const Icon(Icons.outgoing_mail),
              label: const Text('Convocation'),
            )
          : null,
    );
  }
}

class _ConvocationSheet extends ConsumerStatefulWidget {
  const _ConvocationSheet();

  @override
  ConsumerState<_ConvocationSheet> createState() => _ConvocationSheetState();
}

class _ConvocationSheetState extends ConsumerState<_ConvocationSheet> {
  final _targetIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _targetType = 'MATCH';
  bool _app = true;
  bool _email = true;
  bool _sms = true;
  bool _submitting = false;

  @override
  void dispose() {
    _targetIdController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Envoyer une convocation',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'FootTech enregistre la notification APP et prépare les envois Courriel/SMS pour le staff et les joueurs.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _targetType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'MATCH', child: Text('Match')),
                DropdownMenuItem(
                  value: 'TRAINING',
                  child: Text('Séance entraînement'),
                ),
              ],
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _targetType = value ?? 'MATCH'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _targetIdController,
              enabled: !_submitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID match / séance',
                helperText: 'Exemple: 1',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _titleController,
              enabled: !_submitting,
              decoration: const InputDecoration(
                labelText: 'Titre personnalisé',
                hintText: 'Convocation match officiel',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _messageController,
              enabled: !_submitting,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Rendez-vous 60 min avant le coup d’envoi.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                FilterChip(
                  selected: _app,
                  label: const Text('APP'),
                  onSelected: _submitting
                      ? null
                      : (value) => setState(() => _app = value),
                ),
                FilterChip(
                  selected: _email,
                  label: const Text('Courriel'),
                  onSelected: _submitting
                      ? null
                      : (value) => setState(() => _email = value),
                ),
                FilterChip(
                  selected: _sms,
                  label: const Text('SMS'),
                  onSelected: _submitting
                      ? null
                      : (value) => setState(() => _sms = value),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final targetId = int.tryParse(_targetIdController.text.trim());
    final channels = [if (_app) 'APP', if (_email) 'EMAIL', if (_sms) 'SMS'];

    if (targetId == null || channels.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un ID valide et au moins un canal.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(notificationsRepositoryProvider)
          .sendConvocation(
            targetType: _targetType,
            targetId: targetId,
            title: _emptyToNull(_titleController.text),
            message: _emptyToNull(_messageController.text),
            channels: channels,
          );
      ref.invalidate(notificationsListProvider);
      if (!mounted) return;
      navigator.pop();
      final plan = result['deliveryPlan'] as Map<String, dynamic>?;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Convocation prête: APP ${plan?['app'] ?? 0}, Courriel ${plan?['email'] ?? 0}, SMS ${plan?['sms'] ?? 0}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
