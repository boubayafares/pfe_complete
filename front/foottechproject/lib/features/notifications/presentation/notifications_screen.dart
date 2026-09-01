import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);

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
            ? Center(child: Text(context.l10n.noNotifications, style: const TextStyle(color: AppColors.textSecondary)))
            : ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return ListTile(
                    onTap: () async {
                      await ref.read(notificationsRepositoryProvider).markAsRead(n.id);
                      ref.invalidate(notificationsListProvider);
                    },
                    leading: Icon(Icons.circle, size: n.isRead ? 0 : 8, color: AppColors.green),
                    title: Text(n.title, style: TextStyle(fontSize: 13, fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600)),
                    subtitle: Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: Text(DateFormat('d MMM', 'en_US').format(n.createdAt), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  );
                },
              ),
      ),
    );
  }
}
