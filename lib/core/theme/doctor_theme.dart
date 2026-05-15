import 'package:flutter/material.dart';

/// Thème premium pour l'interface médecin (Doctor)
/// Palette : Bleu Nuit + Blanc + Or Champagne — Élégant, professionnel, médical
class DoctorTheme {
  // ═══════════════════════════════════════════════════
  // 🎨 DÉGRADÉS PREMIUM
  // ═══════════════════════════════════════════════════

  static const LinearGradient blueNightGradient = LinearGradient(
    colors: [Color(0xFF0F1A2E), Color(0xFF1A2744)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFC9A84C), Color(0xFFE2D08E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF5EEAD4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient medicalGradient = LinearGradient(
    colors: [Color(0xFF0F1A2E), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy compat gradients
  static const LinearGradient neonVioletGradient = LinearGradient(
    colors: [Color(0xFFC9A84C), Color(0xFFE2D08E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueVioletGradient = LinearGradient(
    colors: [Color(0xFF0F1A2E), Color(0xFF1A2744)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenBlueGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkOrangeGradient = LinearGradient(
    colors: [Color(0xFFC9A84C), Color(0xFFE2D08E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFFF8FAFC),
      Color(0xFFF1F5F9),
      Color(0xFFE2E8F0),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  // ═══════════════════════════════════════════════════
  // 🎨 COULEURS PRINCIPALES
  // ═══════════════════════════════════════════════════

  // 🔵 Bleu Nuit
  static const Color neonViolet = Color(0xFFC9A84C);        // Or champagne (remplace violet)
  static const Color neonVioletLight = Color(0xFFE2D08E);   // Or clair
  static const Color neonVioletDark = Color(0xFFA68A3E);    // Or profond

  // Couleurs principales (legacy compat)
  static const Color primaryBlue = Color(0xFF0F1A2E);       // Bleu nuit
  static const Color secondaryViolet = Color(0xFFC9A84C);   // Or champagne
  static const Color accentTeal = Color(0xFF14B8A6);        // Teal santé
  static const Color accentOrange = Color(0xFFFB923C);

  // Couleurs secondaires
  static const Color softBlue = Color(0xFF3B82F6);
  static const Color lightViolet = Color(0xFFE2D08E);       // Or clair

  // Fond et surfaces
  static const Color backgroundColor = Color(0xFFF8FAFC);   // Blanc cassé
  static const Color surfaceColor = Color(0xFFFFFFFF);       // Blanc pur
  static const Color surfaceSecondary = Color(0xFFF1F5F9);  // Gris très clair
  static const Color glassSurface = Color(0xFF0F1A2E);      // Bleu nuit (sidebar/cards sombres)

  // Texte (sur fond clair)
  static const Color textPrimary = Color(0xFF0F1A2E);        // Bleu nuit
  static const Color textSecondary = Color(0xFF64748B);      // Gris ardoise
  static const Color textLight = Color(0xFF94A3B8);          // Gris clair
  static const Color dividerColor = Color(0xFFE2E8F0);       // Divider clair

  // Texte (sur fond sombre — sidebar/cards bleu nuit)
  static const Color textOnDark = Color(0xFFFFFFFF);         // Blanc
  static const Color textOnDarkSecondary = Color(0xFFB8C5D0);// Gris clair sur sombre

  // Statuts
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);

  // 🪟 Glassmorphism (pour sidebar/cards bleu nuit)
  static Color glassBackground = const Color(0xFF0F1A2E).withValues(alpha: 0.95);
  static Color glassBorder = const Color(0xFFC9A84C).withValues(alpha: 0.15);
  static Color glassHighlight = Colors.white.withValues(alpha: 0.05);

  // ✨ Effet lumineux (glow) — Or champagne
  static List<BoxShadow> neonGlow = [
    BoxShadow(
      color: const Color(0xFFC9A84C).withValues(alpha: 0.25),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 0),
    ),
  ];

  static List<BoxShadow> neonGlowStrong = [
    BoxShadow(
      color: const Color(0xFFC9A84C).withValues(alpha: 0.4),
      blurRadius: 30,
      spreadRadius: 2,
      offset: const Offset(0, 0),
    ),
  ];

  // Ombres premium
  static List<BoxShadow> shadowSoft = [
    BoxShadow(
      color: const Color(0xFF0F1A2E).withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: const Color(0xFF0F1A2E).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: const Color(0xFF0F1A2E).withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Border radius
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(10));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusXLarge = BorderRadius.all(Radius.circular(24));

  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Layout
  static const double maxWidth = 1400;
  static const double sidebarWidth = 280;
  static const double topbarHeight = 72;
  static const double cardBorderRadius = 20.0;

  static Color? get primaryColor => null;

  static get borderColor => null;
}
