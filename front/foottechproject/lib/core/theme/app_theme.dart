import 'package:flutter/material.dart';

/// FootTech design system — palette claire, partagée par toutes les cibles.
///
/// Palette :
///  - 🟩 Couleur principale `#0B5D3B` (green)
///  - 🟢 Couleur secondaire `#16A34A` (greenSoftText / accents verts)
///  - ⚪ Arrière-plan `#F8FAFC` (surfaces, cartes, fonds)
///  - ⚫ Texte `#0F172A` (textPrimary / textSecondary / textMuted)
///  - 🔵 Boutons / liens `#2563EB` (blueInfo)
///  - 🟡 Accents `#FACC15` (amberWarning)
///
/// Les noms de jetons sont conservés pour compatibilité avec les écrans
/// existants, mais leurs valeurs correspondent désormais à la palette claire.
class AppColors {
  AppColors._();

  // Fond / surfaces (clair)
  static const Color navyBg = Color(0xFFF8FAFC);
  static const Color navyBgAlt = Color(0xFFFFFFFF);
  static const Color navyCard = Color(0xFFFFFFFF);
  static const Color navyCardAlt = Color(0x1AFFFFFF);
  static const Color navyBorder = Color(0xFFE2E8F0);

  // Verts (principal #0B5D3B, secondaire #16A34A)
  static const Color green = Color(0xFF0B5D3B);
  static const Color greenBgSoft = Color(0xFFE8F4EE);
  static const Color greenTextOnFill = Color(0xFFFFFFFF);
  static const Color greenSoftText = Color(0xFF16A34A);

  // Texte (sombre sur fond clair)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);

  static const Color amberWarning = Color(0xFFFACC15);
  static const Color coralDanger = Color(0xFFDC2626);
  static const Color blueInfo = Color(0xFF2563EB);
}

class AppRadii {
  AppRadii._();
  static const double card = 12;
  static const double sheet = 20;
  static const double pill = 24;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Below this width, use the mobile bottom-nav shell; at/above it, use the
/// desktop/web/tablet NavigationRail shell. Kept in one place so every
/// screen that branches on form factor references the same breakpoint.
class AppBreakpoints {
  AppBreakpoints._();
  static const double desktop = 900;
}

ThemeData buildFootTechTheme() {
  final base = ThemeData.light(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.navyBg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.green,
      secondary: AppColors.blueInfo,
      surface: AppColors.navyCard,
      error: AppColors.coralDanger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navyBg,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.textPrimary,
    ),
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary)
        .copyWith(
          bodySmall: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          labelSmall: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
    cardTheme: CardThemeData(
      color: AppColors.navyCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.navyBorder, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.greenTextOnFill,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.navyBorder),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.navyCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.navyBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.navyBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.coralDanger)),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.navyBgAlt,
      selectedIconTheme: IconThemeData(color: AppColors.green),
      unselectedIconTheme: IconThemeData(color: AppColors.textMuted),
      selectedLabelTextStyle: TextStyle(color: AppColors.green, fontSize: 12),
      unselectedLabelTextStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.navyBgAlt,
      selectedItemColor: AppColors.green,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.navyBorder, thickness: 0.5),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.navyCard,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
