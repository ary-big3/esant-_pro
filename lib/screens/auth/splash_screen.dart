import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F1A2E), Color(0xFF1A2744)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Cercles décoratifs
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Contenu principal
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC9A84C), Color(0xFFE2D08E)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      size: 64,
                      color: Color(0xFF0F1A2E),
                    ),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack)
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 32),
                  // Titre
                  Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  )
                      .animate(delay: 300.ms)
                      .slideY(begin: 0.3, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),
                  const SizedBox(height: 12),
                  // Sous-titre
                  Text(
                    'Plateforme Nationale E-Santé',
                    style: TextStyle(
                      color: const Color(0xFFC9A84C).withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  )
                      .animate(delay: 500.ms)
                      .slideY(begin: 0.3, end: 0, duration: 500.ms)
                      .fadeIn(duration: 500.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Intelligente et Sécurisée',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  )
                      .animate(delay: 700.ms)
                      .fadeIn(duration: 500.ms),
                  const SizedBox(height: 60),
                  // Indicateur de chargement
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFFC9A84C).withValues(alpha: 0.8),
                      ),
                    ),
                  ).animate(delay: 900.ms).fadeIn(duration: 300.ms),
                ],
              ),
            ),
            // Version en bas
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security, color: Color(0xFFC9A84C), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Conforme RGPD • Chiffrement bout-en-bout',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version ${AppConstants.appVersion}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 12,
                    ),
                  ),
                ],
              ).animate(delay: 1100.ms).fadeIn(duration: 500.ms),
            ),
          ],
        ),
      ),
    );
  }
}
