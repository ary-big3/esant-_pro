import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_background.dart';
import '../../widgets/common_widgets.dart';
import 'laboratory_screen.dart';
import '../auth/login_screen.dart';

/// Écran d'accueil du Laboratoire
/// Page principale avec navigation pour les responsables du laboratoire
class LaboratoryHomeScreen extends StatefulWidget {
  const LaboratoryHomeScreen({super.key});

  @override
  State<LaboratoryHomeScreen> createState() => _LaboratoryHomeScreenState();
}

class _LaboratoryHomeScreenState extends State<LaboratoryHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Page 0: Gestion des examens
            LaboratoryScreen(),
            // Page 1: Statistiques
            _LaboratoryStatsScreen(),
            // Page 2: Paramètres
            _LaboratorySettingsScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.science_outlined,
                  activeIcon: Icons.science,
                  label: 'Examens',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics,
                  label: 'Statistiques',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
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

/// Écran de statistiques du laboratoire
class _LaboratoryStatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // Cartes statistiques
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    title: 'Examens ce mois',
                    value: '124',
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    title: 'Moyennes/jour',
                    value: '18',
                    icon: Icons.access_time,
                    color: AppColors.info,
                  ),
                ),
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    title: 'Taux réussite',
                    value: '98%',
                    icon: Icons.check_circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    title: 'Temps moyen',
                    value: '24h',
                    icon: Icons.schedule,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'Répartition par type d\'examen',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _ExamTypeRow(label: 'Biologie médicale', count: 45, percentage: 36),
                  const SizedBox(height: 12),
                  _ExamTypeRow(label: 'Radiologie', count: 28, percentage: 23),
                  const SizedBox(height: 12),
                  _ExamTypeRow(label: 'Hématologie', count: 25, percentage: 20),
                  const SizedBox(height: 12),
                  _ExamTypeRow(label: 'Autres', count: 26, percentage: 21),
                ],
              ),
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

/// Écran de paramètres du laboratoire
class _LaboratorySettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laboratoire Central',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analyses médicales & Imagerie',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const UserAvatar(
                  initiales: 'LAB',
                  size: 48,
                  backgroundColor: AppColors.info,
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // Infos du laboratoire
            _SettingSection(
              title: 'Informations',
              children: [
                _SettingItem(
                  icon: Icons.person,
                  title: 'Responsable',
                  subtitle: 'Dr. Aminata Diallo',
                ),
                const SizedBox(height: 12),
                _SettingItem(
                  icon: Icons.phone,
                  title: 'Téléphone',
                  subtitle: '+221 77 123 45 67',
                ),
                const SizedBox(height: 12),
                _SettingItem(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: 'laboratoire@hopital.sn',
                ),
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // Paramètres
            _SettingSection(
              title: 'Paramètres',
              children: [
                _SettingToggle(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  value: true,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 12),
                _SettingToggle(
                  icon: Icons.visibility,
                  title: 'Afficher les stats',
                  value: true,
                  onChanged: (_) {},
                ),
              ],
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // Déconnexion
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Déconnexion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Widget pour afficher une boîte de statistique
class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher une ligne de type d'examen
class _ExamTypeRow extends StatelessWidget {
  final String label;
  final int count;
  final int percentage;

  const _ExamTypeRow({
    required this.label,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${percentage}% ($count)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Section de paramètres
class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Élément de paramètre info
class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Élément de paramètre toggle
class _SettingToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final Function(bool) onChanged;

  const _SettingToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}

/// Élément de navigation
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppColors.primary : AppColors.textLight,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isActive ? AppColors.primary : AppColors.textLight,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
