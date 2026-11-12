import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import 'dashboard_provider.dart';

class SeasonBilanScreen extends ConsumerWidget {
  const SeasonBilanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bilanAsync = ref.watch(seasonBilanProvider);
    final isWide = MediaQuery.of(context).size.width >= AppBreakpoints.desktop;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.seasonSummary)),
      body: bilanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (entries) => entries.isEmpty
            ? Center(
                child: Text(
                  context.l10n.noData,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.navyCardAlt,
                    ),
                    columnSpacing: isWide ? 32 : 20,
                    columns: [
                      DataColumn(label: Text(context.l10n.player)),
                      DataColumn(label: Text(context.l10n.position)),
                      DataColumn(
                        label: Text(context.l10n.played),
                        numeric: true,
                      ),
                      DataColumn(label: Text('Min'), numeric: true),
                      DataColumn(
                        label: Text(context.l10n.rating),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(context.l10n.goals),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(context.l10n.assists),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(context.l10n.goalsConceded),
                        numeric: true,
                      ),
                    ],
                    rows: entries.map((e) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              e.fullName,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              e.postePrincipal ?? '-',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${e.nombreMatchsJoues}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${e.tempsDeJeuMinutes}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              e.moyenneNote?.toStringAsFixed(1) ?? '-',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${e.totalButs}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${e.totalPassesDecisives}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${e.totalButsEncaisses}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
      ),
    );
  }
}
