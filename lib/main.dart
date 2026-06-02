import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  
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
  
  // Masquer le splash screen une fois que l'app est prête
  FlutterNativeSplash.remove();
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
      
      // Page d'accueil - Welcome Screen
      home: const WelcomeScreen(),
      
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
