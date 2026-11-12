import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/localization.dart';
import '../../auth/presentation/auth_provider.dart';
import 'season_form_dialog.dart';
import 'seasons_list.dart';
import 'seasons_provider.dart';

class SeasonsScreen extends ConsumerWidget {
  const SeasonsScreen({super.key});

  Future<void> _openCreateForm(BuildContext context, WidgetRef ref) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const SeasonFormDialog(),
    );
    if (created == true) ref.invalidate(seasonsListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonsAsync = ref.watch(seasonsListProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navSeasons)),
      floatingActionButton: user?.canManageTeam == true
          ? FloatingActionButton(
              onPressed: () => _openCreateForm(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
      body: seasonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (seasons) => SeasonsList(
          seasons: seasons,
          onTap: (season) => context.push('/seasons/${season.id}'),
        ),
      ),
    );
  }
}
