import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/media_url.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../players/presentation/players_provider.dart';
import 'teams_provider.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final teamAsync = ref.watch(myTeamProvider);
    final teams = ref.watch(myTeamsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.navTeam),
        actions: [
          if (teams.length > 1)
            PopupMenuButton<int>(
              initialValue: user?.teamId,
              tooltip: context.l10n.navTeam,
              icon: const Icon(Icons.swap_horiz),
              onSelected: (teamId) => _selectTeam(context, ref, teamId),
              itemBuilder: (_) => teams
                  .map(
                    (team) => PopupMenuItem<int>(
                      value: team.id,
                      child: Text(team.name),
                    ),
                  )
                  .toList(),
            ),
          if (user?.isCoach == true && teamAsync.value != null)
            IconButton(
              tooltip: context.l10n.create,
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateTeamDialog(context, ref),
            ),
        ],
      ),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (team) {
          if (team == null) {
            if (user?.isCoach == true) return const _CreateTeamPrompt();
            return Center(
              child: Text(
                context.l10n.noTeamLinked,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return _TeamContent(team: team);
        },
      ),
    );
  }

  Future<void> _selectTeam(
    BuildContext context,
    WidgetRef ref,
    int teamId,
  ) async {
    try {
      await ref.read(authControllerProvider.notifier).selectTeam(teamId);
      ref.invalidate(myTeamProvider);
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _showCreateTeamDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.create),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: context.l10n.teamName),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                labelText: context.l10n.category('e.g., Juvenile'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: Text(context.l10n.create),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      nameController.dispose();
      categoryController.dispose();
      return;
    }
    try {
      final team = await ref
          .read(teamsRepositoryProvider)
          .create(
            name: nameController.text.trim(),
            category: categoryController.text.trim().isEmpty
                ? null
                : categoryController.text.trim(),
          );
      await ref.read(authControllerProvider.notifier).selectTeam(team.id);
      ref.invalidate(myTeamsProvider);
      ref.invalidate(myTeamProvider);
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      nameController.dispose();
      categoryController.dispose();
    }
  }
}

class _CreateTeamPrompt extends ConsumerStatefulWidget {
  const _CreateTeamPrompt();

  @override
  ConsumerState<_CreateTeamPrompt> createState() => _CreateTeamPromptState();
}

class _CreateTeamPromptState extends ConsumerState<_CreateTeamPrompt> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(teamsRepositoryProvider)
          .create(
            name: _nameController.text.trim(),
            category: _categoryController.text.trim().isEmpty
                ? null
                : _categoryController.text.trim(),
          );
      await ref.read(authControllerProvider.notifier).refreshProfile();
      ref.invalidate(myTeamProvider);
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.createFirstTeam,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.canAddPlayersAssistants,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: context.l10n.teamName),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: context.l10n.category('e.g., Juvenile'),
                ),
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
    );
  }
}

class _TeamContent extends ConsumerWidget {
  const _TeamContent({required this.team});
  final dynamic team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final playersAsync = ref.watch(teamPlayersProvider);
    final staffAsync = ref.watch(teamStaffProvider);
    final isWide = MediaQuery.of(context).size.width >= AppBreakpoints.desktop;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teamPlayersProvider);
        ref.invalidate(teamStaffProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  team.name as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (user?.canManageTeam == true)
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1, size: 20),
                  tooltip: context.l10n.addPlayer,
                  onPressed: () => context.push('/players/new'),
                ),
              if (user?.isCoach == true)
                IconButton(
                  icon: const Icon(Icons.badge_outlined, size: 20),
                  tooltip: context.l10n.addAssistant,
                  onPressed: () => _showAddAdjointSheet(context, ref),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _TeamVisualBoard(
            players: playersAsync.valueOrNull ?? const [],
            staffCount: staffAsync.valueOrNull?.length ?? 0,
            canManage: user?.canManageTeam == true,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.players,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          playersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('$error'),
            data: (players) => players.isEmpty
                ? Text(
                    context.l10n.noPlayersYet,
                    style: const TextStyle(color: AppColors.textMuted),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 6 : 3,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final avatarUrl = MediaUrl.resolve(player.profileImage);
                      return InkWell(
                        onTap: () => context.push('/players/${player.id}'),
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.navyCard,
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            border: Border.all(
                              color: AppColors.navyBorder,
                              width: 0.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.navyBorder,
                                backgroundImage: avatarUrl != null
                                    ? CachedNetworkImageProvider(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? Text(
                                        '${player.numeroMaillot ?? '-'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                player.fullName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.staff,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          staffAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('$error'),
            data: (staff) => staff.isEmpty
                ? Text(
                    context.l10n.noAssistantsYet,
                    style: const TextStyle(color: AppColors.textMuted),
                  )
                : Column(
                    children: staff.map((member) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.navyBorder,
                          child: Icon(Icons.badge_outlined, size: 18),
                        ),
                        title: Text(
                          member.fullName,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          member.accountStatus == 'ACTIVE'
                              ? member.phone
                              : context.l10n.awaitingActivation(member.phone),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddAdjointSheet(BuildContext context, WidgetRef ref) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyCard,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.addAssistant,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: context.l10n.firstName),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: context.l10n.lastName),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: context.l10n.phone),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: context.l10n.loginEmail),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(teamsRepositoryProvider)
                      .addAdjoint(
                        team.id as int,
                        firstName: firstNameController.text.trim(),
                        lastName: lastNameController.text.trim(),
                        phone: phoneController.text.trim(),
                        email: emailController.text.trim(),
                      );
                  ref.invalidate(teamStaffProvider);
                  if (context.mounted) Navigator.of(context).pop();
                } on ApiException catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.message)));
                  }
                }
              },
              child: Text(context.l10n.add),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamVisualBoard extends StatelessWidget {
  const _TeamVisualBoard({
    required this.players,
    required this.staffCount,
    required this.canManage,
  });

  final List<dynamic> players;
  final int staffCount;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navyCardAlt,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            height: 86,
            child: CustomPaint(
              painter: _TeamPitchPainter(playerCount: players.length),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestion visuelle équipe/staff',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${players.length} joueurs • $staffCount staff',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Vue orientée dessin pour préparer compositions, ateliers et rôles.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                if (canManage) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/exercise-proposals'),
                    icon: const Icon(Icons.draw, size: 16),
                    label: const Text('Créer un atelier'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPitchPainter extends CustomPainter {
  const _TeamPitchPainter({required this.playerCount});

  final int playerCount;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFF16382A);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      fill,
    );
    canvas.drawRect(
      Rect.fromLTWH(7, 7, size.width - 14, size.height - 14),
      line,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 13, line);
    canvas.drawLine(
      Offset(size.width / 2, 7),
      Offset(size.width / 2, size.height - 7),
      line,
    );

    final shown = playerCount.clamp(0, 11);
    for (var i = 0; i < shown; i++) {
      final row = i ~/ 4;
      final col = i % 4;
      final x = size.width * (0.18 + col * 0.21);
      final y = size.height * (0.22 + row * 0.24);
      canvas.drawCircle(Offset(x, y), 4.6, Paint()..color = AppColors.green);
    }
  }

  @override
  bool shouldRepaint(covariant _TeamPitchPainter oldDelegate) =>
      oldDelegate.playerCount != playerCount;
}
