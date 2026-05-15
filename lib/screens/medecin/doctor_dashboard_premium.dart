import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../core/theme/doctor_theme.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';

/// Dashboard Premium pour médecins avec graphes et cartes améliorées
class DoctorDashboardPremium extends StatefulWidget {
  const DoctorDashboardPremium({super.key});

  @override
  State<DoctorDashboardPremium> createState() => _DoctorDashboardPremiumState();
}

class _DoctorDashboardPremiumState extends State<DoctorDashboardPremium> {
  late ApiService _apiService;

  String _doctorName = 'Dr. ?';
  String _specialty = 'Chargement...';
  String _consultationsCount = '0';
  String _patientsCount = '0';
  String _examsCount = '0';
  String _prescriptionsCount = '0';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    try {
      await TokenHelper.ensureTokenReady();

      final profileResponse = await _apiService.get('/doctor/profile');

      if (profileResponse['success'] == true && profileResponse['data'] != null) {
        final doctorData = profileResponse['data'];

        final statsResponse = await _apiService.get('/doctor/statistics');
        Map<String, dynamic> statsData = {};

        if (statsResponse['success'] == true && statsResponse['data'] != null) {
          statsData = statsResponse['data'];
        }

        if (mounted) {
          setState(() {
            _doctorName = doctorData['full_name'] ?? 'Dr. ?';
            String specialty = doctorData['specialty'] ?? 'Généraliste';
            String hospital = doctorData['hospital_name'] ?? 'Hôpital';
            _specialty = '$specialty • $hospital';

            _consultationsCount = (statsData['consultations_today'] ?? '0').toString();
            _patientsCount = (statsData['distinct_patients'] ?? '0').toString();
            _examsCount = (statsData['urgent_exams'] ?? '0').toString();
            _prescriptionsCount = (statsData['active_prescriptions'] ?? '0').toString();
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement dashboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DoctorTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: DoctorTheme.spacing32),

          // Stats Cards - 2x2 Grid
          _buildStatsGrid(),
          const SizedBox(height: DoctorTheme.spacing32),

          // Quick Actions
          _buildQuickActions(),
          const SizedBox(height: DoctorTheme.spacing32),

          // Recent Activity
          _buildRecentActivity(),
          const SizedBox(height: DoctorTheme.spacing32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tableau de bord',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: DoctorTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: DoctorTheme.spacing8),
        Text(
          'Bienvenue, $_doctorName',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: DoctorTheme.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: DoctorTheme.spacing12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DoctorTheme.spacing12,
            vertical: DoctorTheme.spacing8,
          ),
          decoration: BoxDecoration(
            gradient: DoctorTheme.goldGradient,
            borderRadius: BorderRadius.circular(DoctorTheme.radiusSmall as double),
          ),
          child: Text(
            _specialty,
            style: const TextStyle(
              color: DoctorTheme.primaryBlue,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slide(begin: const Offset(-0.1, 0));
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: DoctorTheme.spacing16,
      crossAxisSpacing: DoctorTheme.spacing16,
      children: [
        _StatCard(
          icon: Icons.note_rounded,
          label: 'Consultations',
          value: _consultationsCount,
          gradient: DoctorTheme.medicalGradient,
          delay: 100,
        ),
        _StatCard(
          icon: Icons.people_rounded,
          label: 'Patients',
          value: _patientsCount,
          gradient: DoctorTheme.tealGradient,
          delay: 200,
        ),
        _StatCard(
          icon: Icons.description_rounded,
          label: 'Examens',
          value: _examsCount,
          gradient: DoctorTheme.blueVioletGradient,
          delay: 300,
        ),
        _StatCard(
          icon: Icons.description_rounded,
          label: 'Ordonnances',
          value: _prescriptionsCount,
          gradient: DoctorTheme.greenBlueGradient,
          delay: 400,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: DoctorTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: DoctorTheme.spacing16),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.search_rounded,
                label: 'Rechercher\npatient',
                color: DoctorTheme.accentTeal,
                delay: 100,
              ),
            ),
            const SizedBox(width: DoctorTheme.spacing12),
            Expanded(
              child: _ActionButton(
                icon: Icons.note_add_rounded,
                label: 'Prescrire\nexamen',
                color: DoctorTheme.softBlue,
                delay: 200,
              ),
            ),
            const SizedBox(width: DoctorTheme.spacing12),
            Expanded(
              child: _ActionButton(
                icon: Icons.cloud_upload_rounded,
                label: 'Uploader\ndocument',
                color: const Color(0xFFFB923C),
                delay: 300,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité récente',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: DoctorTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: DoctorTheme.spacing16),
        _ActivityItem(
          icon: Icons.check_circle_rounded,
          title: 'Consultation complétée',
          subtitle: 'Patient: M. Diallo',
          time: 'Il y a 2h',
          color: DoctorTheme.accentTeal,
          delay: 100,
        ),
        const SizedBox(height: DoctorTheme.spacing12),
        _ActivityItem(
          icon: Icons.file_upload_rounded,
          title: 'Document uploadé',
          subtitle: 'Radioscopie - Patient: Mme Sall',
          time: 'Il y a 4h',
          color: DoctorTheme.softBlue,
          delay: 200,
        ),
        const SizedBox(height: DoctorTheme.spacing12),
        _ActivityItem(
          icon: Icons.description_rounded,
          title: 'Examen prescrit',
          subtitle: 'IRM - Patient: Mr. Sy',
          time: 'Aujourd\'hui',
          color: const Color(0xFFFB923C),
          delay: 300,
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 500.ms);
  }
}

/// Carte de statistique avec dégradé
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final LinearGradient gradient;
  final int delay;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(DoctorTheme.radiusMedium as double),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(

          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(DoctorTheme.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(DoctorTheme.spacing12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DoctorTheme.radiusSmall as double),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: DoctorTheme.spacing4),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: Duration(milliseconds: delay))
        .slide(
          begin: const Offset(0, 0.1),
          duration: 500.ms,
          delay: Duration(milliseconds: delay),
        );
  }
}

/// Bouton d'action rapide
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int delay;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DoctorTheme.radiusMedium as double),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DoctorTheme.radiusMedium as double),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: DoctorTheme.spacing16,
              horizontal: DoctorTheme.spacing12,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
                const SizedBox(height: DoctorTheme.spacing12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: Duration(milliseconds: delay))
        .scale(
          begin: const Offset(0.8, 0.8),
          duration: 500.ms,
          delay: Duration(milliseconds: delay),
        );
  }
}

/// Élément d'activité récente
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
  final int delay;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DoctorTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DoctorTheme.radiusMedium as double),
        border: Border.all(
          color: DoctorTheme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DoctorTheme.spacing12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DoctorTheme.radiusSmall as double),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: DoctorTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: DoctorTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: DoctorTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: DoctorTheme.textLight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: Duration(milliseconds: delay))
        .slideX(
          begin: -0.2,
          duration: 500.ms,
          delay: Duration(milliseconds: delay),
        );
  }
}
