import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/biometric_lock_gate.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('fr_FR');
  await initializeDateFormatting('ar');
  runApp(const ProviderScope(child: FootTechApp()));
}

/// Ordered from most-to-least preferred. English is first so it is used as the
/// fallback whenever the device language is not French, Arabic or English.
const List<Locale> _supportedLocales = [
  Locale('en'),
  Locale('fr'),
  Locale('ar'),
];

class FootTechApp extends ConsumerWidget {
  const FootTechApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FootTech',
      debugShowCheckedModeBanner: false,
      theme: buildFootTechTheme(),
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: _supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('en');
        for (final l in _supportedLocales) {
          if (l.languageCode == locale.languageCode) return l;
        }
        return const Locale('en');
      },
      builder: (context, child) =>
          BiometricLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
