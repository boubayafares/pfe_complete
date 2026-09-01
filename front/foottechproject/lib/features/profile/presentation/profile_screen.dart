import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_ref.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../notifications/presentation/notifications_provider.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingAvatar = false;

  Future<void> _changeAvatar(int userId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await ref.read(profileRepositoryProvider).uploadAvatar(userId, bytes: bytes, fileName: picked.name);
      } else {
        await ref.read(profileRepositoryProvider).uploadAvatar(userId, filePath: picked.path);
      }
      ref.invalidate(myProfileProvider);
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final profileAsync = ref.watch(myProfileProvider);
    final avatarImage = ImageRef.resolve(profileAsync.value?.profileImage);
    final unreadAsync = ref.watch(notificationsListProvider);
    final unreadCount = unreadAsync.value?.where((n) => !n.isRead).length ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profile)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: user == null || _uploadingAvatar ? null : () => _changeAvatar(user.id),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.navyBorder,
                            backgroundImage: avatarImage,
                            child: avatarImage == null ? const Icon(Icons.person, color: AppColors.textSecondary) : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                              child: _uploadingAvatar
                                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.greenTextOnFill))
                                  : const Icon(Icons.camera_alt, size: 12, color: AppColors.greenTextOnFill),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(_roleLabel(context, user?.role), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(context.l10n.notifications),
                trailing: unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(10)),
                        child: Text('$unreadCount', style: const TextStyle(color: AppColors.greenTextOnFill, fontSize: 11)),
                      )
                    : const Icon(Icons.chevron_right, color: AppColors.textMuted),
                onTap: () => context.push('/notifications'),
              ),
              if (user?.canManageTeam == true)
                ListTile(
                  leading: const Icon(Icons.bar_chart_outlined),
                  title: Text(context.l10n.seasonSummary),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: () => context.push('/season-bilan'),
                ),
              if (user?.canManageTeam == true)
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: Text(context.l10n.navSeasons),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: () => context.push('/seasons'),
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.coralDanger),
                title: Text(context.l10n.logOut, style: const TextStyle(color: AppColors.coralDanger)),
                onTap: () => ref.read(authControllerProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(BuildContext context, String? role) => switch (role) {
        'COACH' => context.l10n.coachRole,
        'ADJOINT' => context.l10n.assistantRole,
        'JOUEUR' => context.l10n.playerRole,
        _ => '',
      };
}
