import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les locales pour intl
  await initializeDateFormatting('fr_FR', null);
  
  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,  // Icônes claires pour fond sombre
      systemNavigationBarColor: Color(0xFF1A1A3E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Orientation portrait uniquement
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const ESanteApp());
}

/// Application principale - Plateforme Nationale E-Santé
/// 
/// Cette application propose une solution complète de gestion hospitalière
/// incluant :
/// - Dossier médical électronique avec carte NFC
/// - Gestion des rendez-vous et consultations

/// - Prescriptions électroniques

/// - Intelligence Artificielle pour aide au diagnostic
class ESanteApp extends StatelessWidget {
  const ESanteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Santé Nationale',
      debugShowCheckedModeBanner: false,
      
      // Thème personnalisé professionnel
      theme: AppTheme.lightTheme,
      
      // Page d'accueil - Splash Screen
      home: const SplashScreen(),
      
      // Configuration des routes (pour navigation future)
      // routes: {
      //   '/splash': (context) => const SplashScreen(),
      //   '/role-selection': (context) => const RoleSelectionScreen(),
      //   '/login': (context) => const LoginScreen(),
      //   '/patient-home': (context) => const PatientHomeScreen(),
      //   '/medecin-home': (context) => const MedecinHomeScreen(),
      //   '/admin-home': (context) => const AdminHomeScreen(),

      // },
    );
  }
}
