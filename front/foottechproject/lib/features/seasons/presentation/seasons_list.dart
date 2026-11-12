import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../data/seasons_model.dart';

class SeasonsList extends StatelessWidget {
  const SeasonsList({super.key, required this.seasons, this.onTap});

  final List<Season> seasons;
  final ValueChanged<Season>? onTap;

  @override
  Widget build(BuildContext context) {
    if (seasons.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noSeasons,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final dateFormat = DateFormat('d MMM yyyy');

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: seasons.length,
      itemBuilder: (context, index) {
        final season = seasons[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            onTap: onTap == null ? null : () => onTap!(season),
            leading: Icon(
              season.isCurrent
                  ? Icons.calendar_month
                  : Icons.calendar_today_outlined,
              color: season.isCurrent ? AppColors.green : AppColors.textMuted,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    season.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (season.isCurrent) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.greenBgSoft,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      context.l10n.current,
                      style: const TextStyle(
                        color: AppColors.greenSoftText,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              context.l10n.fromTo(
                dateFormat.format(season.startDate),
                dateFormat.format(season.endDate),
              ),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        );
      },
    );
  }
}
