import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/media_url.dart';
import '../../ai_insights/presentation/ai_insights_provider.dart';
import 'players_provider.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key, required this.playerId});

  final int playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileProvider(playerId));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: profileAsync.maybeWhen(
            data: (p) => Text(p.fullName),
            orElse: () => Text(context.l10n.player),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.green,
            tabs: [
              Tab(text: context.l10n.tabIdentity),
              Tab(text: context.l10n.tabFamily),
              Tab(text: context.l10n.tabSchool),
              Tab(text: context.l10n.tabInjuries),
            ],
          ),
        ),
        body: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (player) => TabBarView(
            children: [
              _IdentityTab(playerId: playerId, player: player),
              _FamilyTab(playerId: playerId),
              _SchoolTab(playerId: playerId),
              _InjuriesTab(playerId: playerId),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityTab extends ConsumerWidget {
  const _IdentityTab({required this.playerId, required this.player});
  final int playerId;
  final dynamic player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonsAsync = ref.watch(playerSeasonProfilesProvider(playerId));
    final trendAsync = ref.watch(playerTrendProvider(playerId));
    final avatarUrl = MediaUrl.resolve(player.profileImage as String?);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.navyBorder,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      '${player.numeroMaillot ?? '-'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.fullName as String,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (player.postePrincipal != null)
                    Text(
                      '${player.postePrincipal}${player.posteSecondaire != null ? " / ${player.posteSecondaire}" : ""}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            if (player.tailleCm != null)
              Expanded(
                child: _StatChip(
                  label: context.l10n.height,
                  value: '${player.tailleCm} cm',
                ),
              ),
            if (player.poidsKg != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatChip(
                  label: context.l10n.weight,
                  value: '${player.poidsKg} kg',
                ),
              ),
            ],
            if (player.piedFort != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatChip(
                  label: context.l10n.foot,
                  value: player.piedFort as String,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.aiTrendTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        trendAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(
            context.l10n.aiTrendUnavailable,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          data: (trend) {
            final (label, color, icon) = switch (trend.direction) {
              'PROGRESSING' => (
                context.l10n.aiTrendProgressing,
                AppColors.green,
                Icons.trending_up,
              ),
              'DECLINING' => (
                context.l10n.aiTrendDeclining,
                AppColors.coralDanger,
                Icons.trending_down,
              ),
              _ => (
                context.l10n.aiTrendStable,
                AppColors.blueInfo,
                Icons.trending_flat,
              ),
            };
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: color),
              title: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                context.l10n.aiTrendBasedOn('${trend.dataPointsUsed}'),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.evolutionBySeason,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        seasonsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (_, _) =>
              const Text('—', style: TextStyle(color: AppColors.textMuted)),
          data: (seasons) => seasons.isEmpty
              ? Text(
                  context.l10n.noDataRecorded,
                  style: const TextStyle(color: AppColors.textMuted),
                )
              : Column(
                  children: seasons.map((s) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        s.season,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        [
                          if (s.poidsKg != null) '${s.poidsKg} kg',
                          if (s.tailleCm != null) '${s.tailleCm} cm',
                          if (s.poste1 != null) s.poste1!,
                        ].join(' · '),
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
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navyCardAlt,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FamilyTab extends ConsumerWidget {
  const _FamilyTab({required this.playerId});
  final int playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardiansAsync = ref.watch(playerGuardiansProvider(playerId));
    final addressAsync = ref.watch(playerAddressProvider(playerId));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          context.l10n.parentsGuardian,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        guardiansAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (_, _) =>
              const Text('—', style: TextStyle(color: AppColors.textMuted)),
          data: (guardians) => guardians.isEmpty
              ? Text(
                  context.l10n.noContactRecorded,
                  style: const TextStyle(color: AppColors.textMuted),
                )
              : Column(
                  children: guardians.map((g) {
                    final label = switch (g.relation) {
                      'PERE' => context.l10n.father,
                      'MERE' => context.l10n.mother,
                      _ => context.l10n.guardian,
                    };
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '$label — ${g.prenom ?? ''} ${g.nom ?? ''}'.trim(),
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        [
                          if (g.tel1 != null) g.tel1!,
                          if (g.email != null) g.email!,
                        ].join(' · '),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.addressCommute,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        addressAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (_, _) =>
              const Text('—', style: TextStyle(color: AppColors.textMuted)),
          data: (address) => address == null
              ? Text(
                  context.l10n.notProvided,
                  style: const TextStyle(color: AppColors.textMuted),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (address.adresseComplete != null)
                      Text(
                        address.adresseComplete!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    if (address.distanceClubKm != null)
                      Text(
                        context.l10n.kmFromClub('${address.distanceClubKm}'),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    if (address.moyenTransport != null)
                      Text(
                        address.moyenTransport!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SchoolTab extends ConsumerWidget {
  const _SchoolTab({required this.playerId});
  final int playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(playerSchoolInfoProvider(playerId));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: schoolAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Text('—', style: TextStyle(color: AppColors.textMuted)),
        data: (school) => school == null
            ? Text(
                context.l10n.notProvided,
                style: const TextStyle(color: AppColors.textMuted),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (school.etablissement != null)
                    _KeyValue(
                      label: context.l10n.school,
                      value: school.etablissement!,
                    ),
                  if (school.classe != null)
                    _KeyValue(
                      label: context.l10n.classLevel,
                      value: school.classe!,
                    ),
                  if (school.niveauScolaire != null)
                    _KeyValue(
                      label: context.l10n.level,
                      value: school.niveauScolaire!,
                    ),
                ],
              ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _InjuriesTab extends ConsumerWidget {
  const _InjuriesTab({required this.playerId});
  final int playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final injuriesAsync = ref.watch(playerInjuriesProvider(playerId));

    return injuriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (injuries) => injuries.isEmpty
          ? Center(
              child: Text(
                context.l10n.noInjuries,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: injuries.length,
              itemBuilder: (context, index) {
                final injury = injuries[index];
                return ListTile(
                  leading: Icon(
                    injury.isActive
                        ? Icons.warning_amber
                        : Icons.check_circle_outline,
                    color: injury.isActive
                        ? AppColors.coralDanger
                        : AppColors.green,
                  ),
                  title: Text(
                    injury.description ?? context.l10n.injury,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    DateFormat(
                          'd MMM yyyy',
                          'en_US',
                        ).format(injury.dateBlessure) +
                        (injury.dureeIndisponibiliteJours != null
                            ? context.l10n.days(
                                '${injury.dureeIndisponibiliteJours}',
                              )
                            : ''),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
