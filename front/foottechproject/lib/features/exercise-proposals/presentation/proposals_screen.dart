import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/proposal_model.dart';
import 'proposals_provider.dart';

class ProposalsScreen extends ConsumerWidget {
  const ProposalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final canContribute = user?.canManageTeam == true;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bibliotheque tactique'),
          bottom: const TabBar(
            indicatorColor: AppColors.green,
            tabs: [
              Tab(text: 'Communaute'),
              Tab(text: 'Validation'),
            ],
          ),
        ),
        floatingActionButton: canContribute
            ? FloatingActionButton(
                onPressed: () => _showProposeSheet(context, ref),
                tooltip: 'Creer un exercice visuel',
                child: const Icon(Icons.add_chart),
              )
            : null,
        body: const TabBarView(children: [_LibraryTab(), _PendingTab()]),
      ),
    );
  }

  void _showProposeSheet(BuildContext context, WidgetRef ref) {
    final titreController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController(
      text: 'Transition offensive',
    );
    final objectifController = TextEditingController();
    final durationController = TextEditingController(text: '15');
    final tagsController = TextEditingController(
      text: '4-3-3, finition, pressing',
    );
    var difficulty = 'MEDIUM';
    var visibility = 'COMMUNITY';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyCard,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Creation visuelle avancee',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: titreController,
                  decoration: InputDecoration(labelText: context.l10n.title),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: objectifController,
                  decoration: const InputDecoration(
                    labelText: 'Objectif tactique',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Categorie'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: difficulty,
                        decoration: const InputDecoration(
                          labelText: 'Difficulte',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'EASY',
                            child: Text('Facile'),
                          ),
                          DropdownMenuItem(
                            value: 'MEDIUM',
                            child: Text('Moyen'),
                          ),
                          DropdownMenuItem(
                            value: 'HARD',
                            child: Text('Difficile'),
                          ),
                          DropdownMenuItem(
                            value: 'ELITE',
                            child: Text('Elite'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => difficulty = value ?? 'MEDIUM'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Minutes'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  decoration: const InputDecoration(labelText: 'Visibilite'),
                  items: const [
                    DropdownMenuItem(value: 'TEAM', child: Text('Equipe')),
                    DropdownMenuItem(
                      value: 'COMMUNITY',
                      child: Text('Communaute'),
                    ),
                    DropdownMenuItem(value: 'PRIVATE', child: Text('Prive')),
                  ],
                  onChanged: (value) =>
                      setState(() => visibility = value ?? 'TEAM'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(labelText: 'Tags'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.l10n.description,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  onPressed: () async {
                    try {
                      await ref
                          .read(proposalsRepositoryProvider)
                          .create(
                            titre: titreController.text.trim(),
                            description:
                                descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            category: categoryController.text.trim(),
                            objectif: objectifController.text.trim().isEmpty
                                ? null
                                : objectifController.text.trim(),
                            difficulty: difficulty,
                            durationMinutes: int.tryParse(
                              durationController.text,
                            ),
                            visibility: visibility,
                            tags: tagsController.text
                                .split(',')
                                .map((tag) => tag.trim())
                                .where((tag) => tag.isNotEmpty)
                                .toList(),
                          );
                      ref.invalidate(pendingProposalsProvider);
                      ref.invalidate(exerciseLibraryProvider);
                      if (context.mounted) Navigator.of(context).pop();
                    } on ApiException catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error.message)));
                      }
                    }
                  },
                  label: const Text('Creer avec modele IA'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryTab extends ConsumerStatefulWidget {
  const _LibraryTab();

  @override
  ConsumerState<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<_LibraryTab> {
  final _searchController = TextEditingController();
  String _difficulty = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(exerciseLibraryProvider);
    return libraryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (items) {
        final query = _searchController.text.trim().toLowerCase();
        final filtered = items.where((item) {
          final searchable = [
            item.titre,
            item.objectif,
            item.category,
            ...item.tags,
          ].whereType<String>().join(' ').toLowerCase();
          final matchesQuery = query.isEmpty || searchable.contains(query);
          final matchesDifficulty =
              _difficulty == 'ALL' || item.difficulty == _difficulty;
          return matchesQuery && matchesDifficulty;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Rechercher un exercice',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  for (final difficulty in [
                    'ALL',
                    'EASY',
                    'MEDIUM',
                    'HARD',
                    'ELITE',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(difficulty == 'ALL' ? 'Tous' : difficulty),
                        selected: _difficulty == difficulty,
                        onSelected: (_) =>
                            setState(() => _difficulty = difficulty),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun exercice ne correspond aux filtres',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _ExerciseCard(proposal: filtered[index]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PendingTab extends ConsumerWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(pendingProposalsProvider);
    final isCoach = ref.watch(authControllerProvider).value?.isCoach == true;

    return proposalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (proposals) => proposals.isEmpty
          ? Center(
              child: Text(
                context.l10n.noPendingProposal,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: proposals.length,
              itemBuilder: (context, index) {
                final proposal = proposals[index];
                return _ExerciseCard(
                  proposal: proposal,
                  trailing: isCoach
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: AppColors.green,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(proposalsRepositoryProvider)
                                    .review(proposal.id, status: 'VALIDATED');
                                ref.invalidate(pendingProposalsProvider);
                                ref.invalidate(exerciseLibraryProvider);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: AppColors.coralDanger,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(proposalsRepositoryProvider)
                                    .review(proposal.id, status: 'REJECTED');
                                ref.invalidate(pendingProposalsProvider);
                              },
                            ),
                          ],
                        )
                      : Text(
                          context.l10n.pending,
                          style: const TextStyle(color: AppColors.amberWarning),
                        ),
                );
              },
            ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.proposal, this.trailing});

  final ExerciseProposal proposal;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final playerCount =
        (proposal.canvasData?['players'] as List<dynamic>?)?.length ?? 0;
    final animationMode = proposal.animationData?['mode']?.toString() ?? '2D';
    final ai = proposal.aiModel?['intensity']?.toString() ?? 'CONTROLLED';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    proposal.titre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Exporter la fiche JSON',
                      icon: const Icon(Icons.ios_share, size: 18),
                      onPressed: () => _copyExport(context),
                    ),
                    ?trailing,
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              proposal.objectif ??
                  proposal.description ??
                  'Objectif non renseigne',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Chip(label: proposal.category ?? 'Tactique'),
                _Chip(label: proposal.difficultyLabel),
                if (proposal.durationMinutes != null)
                  _Chip(label: '${proposal.durationMinutes} min'),
                _Chip(label: '$playerCount joueurs dessines'),
                _Chip(label: animationMode),
                _Chip(label: 'IA $ai'),
              ],
            ),
            if (proposal.tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                proposal.tags.map((tag) => '#$tag').join('  '),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            SizedBox(height: 96, child: _MiniPitch(proposal: proposal)),
          ],
        ),
      ),
    );
  }

  void _copyExport(BuildContext context) {
    final export = jsonEncode({
      'format': 'foottech.tactical-exercise.v1',
      'title': proposal.titre,
      'description': proposal.description,
      'category': proposal.category,
      'objective': proposal.objectif,
      'difficulty': proposal.difficulty,
      'durationMinutes': proposal.durationMinutes,
      'tags': proposal.tags,
      'canvasData': proposal.canvasData,
      'animationData': proposal.animationData,
      'aiModel': proposal.aiModel,
    });
    Clipboard.setData(ClipboardData(text: export));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fiche tactique exportée dans le presse-papiers.'),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.greenBgSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.green, fontSize: 11),
      ),
    );
  }
}

class _MiniPitch extends StatefulWidget {
  const _MiniPitch({required this.proposal});

  final ExerciseProposal proposal;

  @override
  State<_MiniPitch> createState() => _MiniPitchState();
}

class _MiniPitchState extends State<_MiniPitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final players =
        widget.proposal.canvasData?['players'] as List<dynamic>? ?? const [];
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _MiniPitchPainter(
                  players: players,
                  progress: _controller.value,
                ),
              ),
              const Positioned(
                right: 8,
                bottom: 6,
                child: Text(
                  'Animation 2D • 3D ready',
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniPitchPainter extends CustomPainter {
  const _MiniPitchPainter({required this.players, required this.progress});

  final List<dynamic> players;
  final double progress;

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
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      line,
    );
    canvas.drawLine(
      Offset(size.width / 2, 8),
      Offset(size.width / 2, size.height - 8),
      line,
    );
    for (final player in players) {
      if (player is! Map) continue;
      final baseX = ((player['x'] as num?)?.toDouble() ?? 0.5) * size.width;
      final baseY = ((player['y'] as num?)?.toDouble() ?? 0.5) * size.height;
      final phase = (player['id'] as num?)?.toDouble() ?? 1;
      final movement = math.sin(progress * math.pi * 2 + phase) * 5;
      final position = Offset(
        (baseX + movement).clamp(10.0, size.width - 10).toDouble(),
        (baseY - movement * 0.45).clamp(10.0, size.height - 10).toDouble(),
      );
      canvas.drawCircle(position, 6, Paint()..color = AppColors.green);
      canvas.drawCircle(
        position,
        9,
        Paint()
          ..color = AppColors.green.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPitchPainter oldDelegate) =>
      oldDelegate.players != players || oldDelegate.progress != progress;
}
