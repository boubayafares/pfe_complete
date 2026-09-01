import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.sports_soccer, color: AppColors.greenTextOnFill, size: 32),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('FootTech', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(context.l10n.onboardingSubtitle,
                      textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/login'),
                      child: Text(context.l10n.onboardingCoachBtn),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.push('/player-login'),
                      child: Text(context.l10n.onboardingPlayerBtn),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextButton(
                    onPressed: () => context.push('/register-coach'),
                    child: Text(context.l10n.onboardingCreateCoach, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
