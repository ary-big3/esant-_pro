import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/doctor_layout.dart';
import 'medecin_home_screen.dart';
import 'doctor_dashboard_premium.dart';
import 'doctor_patients_screen_premium.dart';
import 'doctor_agenda_premium.dart';
import 'doctor_notifications_screen.dart';
import 'doctor_profile_premium.dart';

/// Écran principal médecin avec interface PREMIUM
/// - Sidebar bleu nuit (#0F1A2E) avec navigation dorée
/// - 5 pages : Dashboard, Patients, Agenda, Notifications, Profil
/// - Thème professionnel et graphes premium
class MedecinHomeScreenPremium extends StatefulWidget {
  const MedecinHomeScreenPremium({super.key});

  @override
  State<MedecinHomeScreenPremium> createState() =>
      _MedecinHomeScreenPremiumState();
}

class _MedecinHomeScreenPremiumState extends State<MedecinHomeScreenPremium> {
  int _currentIndex = 0;
  String _doctorName = 'Dr. ?';
  String _specialty = 'Chargement...';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Sur mobile, utiliser la bottom navigation classique
    if (isMobile) {
      return const MedecinHomeScreen();
    }

    // Sur desktop, utiliser le layout premium avec sidebar
    return DoctorLayout(
      currentIndex: _currentIndex,
      onNavigate: (index) => setState(() => _currentIndex = index),
      doctorName: _doctorName,
      specialty: _specialty,
      pages: [
        const DoctorDashboardPremium(),
        const DoctorPatientsScreenPremium(),
        const DoctorAgendaPremium(),
        const DoctorNotificationsScreen(),
        const DoctorProfilePremium(),
      ],
    );
  }
}
