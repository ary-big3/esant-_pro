import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/charts_widget.dart';
import '../../models/ia_models.dart';
import '../auth/login_screen.dart';

class MinistereHomeScreen extends StatefulWidget {
  const MinistereHomeScreen({super.key});

  @override
  State<MinistereHomeScreen> createState() => _MinistereHomeScreenState();
}

class _MinistereHomeScreenState extends State<MinistereHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _NationalDashboard(),
          _HealthMapScreen(),
          _EpidemicTrackingScreen(),
          _NationalReportsScreen(),
          _MinistereSettingsScreen(),
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
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'National',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map,
                  label: 'Carte',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.coronavirus_outlined,
                  activeIcon: Icons.coronavirus,
                  label: 'Épidémies',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics,
                  label: 'Rapports',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Paramètres',
                  isActive: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
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
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textLight,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NationalDashboard extends StatelessWidget {
    // Simulation d'événements médicaux collectés
    final List<Map<String, dynamic>> evenementsMedicaux = [
      {'type': 'consultation', 'maladie': 'Grippe', 'region': 'Dakar'},
      {'type': 'consultation', 'maladie': 'Paludisme', 'region': 'Thiès'},
      {'type': 'alerte', 'maladie': 'Grippe', 'region': 'Dakar'},
      {'type': 'consultation', 'maladie': 'Covid-19', 'region': 'Dakar'},
      {'type': 'consultation', 'maladie': 'Grippe', 'region': 'Dakar'},
      {'type': 'consultation', 'maladie': 'Paludisme', 'region': 'Saint-Louis'},
      {'type': 'alerte', 'maladie': 'Paludisme', 'region': 'Saint-Louis'},
    ];

    // Analyse IA nationale
    late final IANationaleSanitaire iaNationale = IANationaleSanitaire(
      statistiquesRegion: _calculerStatsParRegion(),
      maladiesSuivies: _maladiesSuivies(),
      zonesRisque: _zonesRisque(),
      anomaliesSanitaires: _anomaliesSanitaires(),
      projection: 'Risque d\'épidémie de grippe à Dakar dans 2 semaines',
    );

    Map<String, int> _calculerStatsParRegion() {
      final stats = <String, int>{};
      for (var evt in evenementsMedicaux) {
        stats[evt['region']] = (stats[evt['region']] ?? 0) + 1;
      }
      return stats;
    }

    List<String> _maladiesSuivies() {
      return evenementsMedicaux.map((e) => e['maladie'] as String).toSet().toList();
    }

    List<String> _zonesRisque() {
      return ['Dakar', 'Saint-Louis'];
    }

    List<String> _anomaliesSanitaires() {
      return ['Augmentation de 35% des cas de grippe à Dakar', 'Pénurie de vaccins antigrippaux'];
    }
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
                      'Tableau de bord national',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Système opérationnel',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const UserAvatar(
                  initiales: 'MS',
                  size: 48,
                  backgroundColor: AppColors.primary,
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // Statistiques IA nationale
            Row(
              children: [
                Expanded(
                  child: _NationalStatCard(
                    titre: 'Consultations analysées',
                    valeur: iaNationale.statistiquesRegion.values.reduce((a, b) => a + b).toString(),
                    icon: Icons.analytics,
                    color: AppColors.primary,
                    sous_titre: 'Analyse IA nationale',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NationalStatCard(
                    titre: 'Maladies suivies',
                    valeur: iaNationale.maladiesSuivies.length.toString(),
                    icon: Icons.coronavirus,
                    color: AppColors.secondary,
                    sous_titre: iaNationale.maladiesSuivies.join(', '),
                  ),
                ),
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NationalStatCard(
                    titre: 'Zones à risque',
                    valeur: iaNationale.zonesRisque.length.toString(),
                    icon: Icons.warning,
                    color: AppColors.warning,
                    sous_titre: iaNationale.zonesRisque.join(', '),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NationalStatCard(
                    titre: 'Alertes IA',
                    valeur: iaNationale.anomaliesSanitaires.length.toString(),
                    icon: Icons.notification_important,
                    color: AppColors.error,
                    sous_titre: iaNationale.anomaliesSanitaires.join(', '),
                  ),
                ),
              ],
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // Alertes IA nationales
            const SectionHeader(titre: 'Alertes Intelligence Artificielle'),
            const SizedBox(height: 12),
            _NationalAlertCard(
              type: 'Épidémiologique',
              message: 'Augmentation de 35% des cas de grippe dans la région de Dakar',
              niveau: 'warning',
              region: 'Dakar',
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            _NationalAlertCard(
              type: 'Stock critique',
              message: 'Pénurie de vaccins antigrippaux dans 3 hôpitaux',
              niveau: 'urgent',
              region: 'National',
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // Évolution des consultations
            const SectionHeader(titre: 'Évolution des consultations (30 jours)'),
            const SizedBox(height: 12),
            AppCard(
              child: SizedBox(
                height: 200,
                child: HealthLineChart(
                  data: const [
                    6500, 7200, 6800, 7500, 8100, 7800, 8200,
                    8500, 8100, 8800, 9200, 8600, 9100, 8900,
                    9400, 9100, 9600, 9300, 9800, 9500, 10000,
                    9700, 10200, 9900, 10400, 10100, 10600, 10300,
                    10800, 10500,
                  ],
                  labels: const ['1', '', '', '', '5', '', '', '', '', '10', '', '', '', '', '15', '', '', '', '', '20', '', '', '', '', '25', '', '', '', '', '30'],
                  lineColor: AppColors.primary,
                ),
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // Répartition par région
            const SectionHeader(titre: 'Activité par région'),
            const SizedBox(height: 12),
            ...List.generate(3, (index) {
              final regions = [
                {'nom': 'Dakar', 'consultations': 4523, 'variation': '+15%'},
                {'nom': 'Thiès', 'consultations': 1876, 'variation': '+8%'},
                {'nom': 'Saint-Louis', 'consultations': 1234, 'variation': '+5%'},
              ];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RegionCard(
                  region: regions[index]['nom'] as String,
                  consultations: regions[index]['consultations'] as int,
                  variation: regions[index]['variation'] as String,
                ),
              ).animate(delay: Duration(milliseconds: 600 + index * 100)).fadeIn(duration: 400.ms);
            }),
          ],
        ),
      ),
    );
  }
}

class _NationalStatCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icon;
  final Color color;
  final String sous_titre;

  const _NationalStatCard({
    required this.titre,
    required this.valeur,
    required this.icon,
    required this.color,
    required this.sous_titre,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valeur,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            titre,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            sous_titre,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textLight,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _NationalAlertCard extends StatelessWidget {
  final String type;
  final String message;
  final String niveau;
  final String region;

  const _NationalAlertCard({
    required this.type,
    required this.message,
    required this.niveau,
    required this.region,
  });

  Color get _color => niveau == 'urgent' ? AppColors.error : AppColors.warning;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      border: Border.all(color: _color.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  niveau == 'urgent' ? Icons.warning : Icons.info_outline,
                  color: _color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      'Région: $region',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                text: niveau == 'urgent' ? 'Urgent' : 'Attention',
                color: _color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Détails'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Actions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegionCard extends StatelessWidget {
  final String region;
  final int consultations;
  final String variation;

  const _RegionCard({
    required this.region,
    required this.consultations,
    required this.variation,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {},
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(region, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '$consultations consultations',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          StatusBadge(text: variation, color: AppColors.success),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
        ],
      ),
    );
  }
}

class _HealthMapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carte sanitaire nationale',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                // Filtres
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'Tous', isSelected: true),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Hôpitaux'),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Alertes'),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Épidémies'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Placeholder carte
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 80,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Carte du Sénégal',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Intégration carte interactive',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textLight,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Marqueurs exemple
                  Positioned(
                    left: 80,
                    top: 100,
                    child: _MapMarker(
                      label: 'Dakar',
                      count: 5,
                      hasAlert: true,
                    ),
                  ),
                  Positioned(
                    left: 150,
                    top: 150,
                    child: _MapMarker(
                      label: 'Thiès',
                      count: 3,
                    ),
                  ),
                  Positioned(
                    right: 100,
                    top: 80,
                    child: _MapMarker(
                      label: 'Saint-Louis',
                      count: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Légende
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Légende', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _LegendItem(color: AppColors.success, label: 'Normal'),
                      _LegendItem(color: AppColors.warning, label: 'Attention'),
                      _LegendItem(color: AppColors.error, label: 'Alerte'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final String label;
  final int count;
  final bool hasAlert;

  const _MapMarker({
    required this.label,
    required this.count,
    this.hasAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hasAlert ? AppColors.error : AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (hasAlert ? AppColors.error : AppColors.primary).withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            '$count',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EpidemicTrackingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suivi épidémiologique',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            // Maladies surveillées
            const SectionHeader(titre: 'Maladies sous surveillance'),
            const SizedBox(height: 12),
            _EpidemicCard(
              maladie: 'Grippe saisonnière',
              cas: 1234,
              evolution: '+35%',
              isIncreasing: true,
              niveau: 'attention',
            ),
            const SizedBox(height: 8),
            _EpidemicCard(
              maladie: 'Paludisme',
              cas: 456,
              evolution: '-12%',
              isIncreasing: false,
              niveau: 'normal',
            ),
            const SizedBox(height: 8),
            _EpidemicCard(
              maladie: 'Dengue',
              cas: 23,
              evolution: '+5%',
              isIncreasing: true,
              niveau: 'normal',
            ),
            const SizedBox(height: 24),
            // Graphique évolution
            const SectionHeader(titre: 'Évolution hebdomadaire'),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ChartLegend(color: AppColors.primary, label: 'Grippe'),
                      const SizedBox(width: 16),
                      _ChartLegend(color: AppColors.secondary, label: 'Paludisme'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: StatsBarChart(
                      data: const [120, 180, 200, 250, 320, 280, 350],
                      labels: const ['L', 'M', 'M', 'J', 'V', 'S', 'D'],
                      barColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Actions recommandées IA
            const SectionHeader(titre: 'Recommandations IA'),
            const SizedBox(height: 12),
            AppCard(
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.psychology, color: AppColors.info),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Analyse prédictive',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Probabilité d\'épidémie de grippe: 68% dans les 2 semaines',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Régions à risque: Dakar, Pikine, Guédiawaye',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Action recommandée: Renforcer le stock de vaccins',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Voir le plan d\'action'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpidemicCard extends StatelessWidget {
  final String maladie;
  final int cas;
  final String evolution;
  final bool isIncreasing;
  final String niveau;

  const _EpidemicCard({
    required this.maladie,
    required this.cas,
    required this.evolution,
    required this.isIncreasing,
    required this.niveau,
  });

  Color get _niveauColor {
    switch (niveau) {
      case 'urgent':
        return AppColors.error;
      case 'attention':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      border: Border.all(color: _niveauColor.withValues(alpha: 0.3)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _niveauColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.coronavirus, color: _niveauColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(maladie, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '$cas cas cette semaine',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    isIncreasing ? Icons.trending_up : Icons.trending_down,
                    color: isIncreasing ? AppColors.error : AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    evolution,
                    style: TextStyle(
                      color: isIncreasing ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              StatusBadge(
                text: niveau == 'urgent' ? 'Urgent' : (niveau == 'attention' ? 'Attention' : 'Stable'),
                color: _niveauColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _NationalReportsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rapports nationaux',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            // Période
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text('Année 2026', style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  TextButton(onPressed: () {}, child: const Text('Changer')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Rapports
            const SectionHeader(titre: 'Rapports disponibles'),
            const SizedBox(height: 12),
            _NationalReportTile(
              icon: Icons.analytics,
              title: 'Rapport sanitaire annuel',
              subtitle: 'Synthèse nationale complète',
              date: 'Janvier 2026',
            ),
            const SizedBox(height: 8),
            _NationalReportTile(
              icon: Icons.coronavirus,
              title: 'Bulletin épidémiologique',
              subtitle: 'Suivi des maladies surveillées',
              date: 'Semaine 4',
            ),
            const SizedBox(height: 8),
            _NationalReportTile(
              icon: Icons.people,
              title: 'Démographie sanitaire',
              subtitle: 'Couverture population',
              date: '2026',
            ),
            const SizedBox(height: 8),
            _NationalReportTile(
              icon: Icons.inventory,
              title: 'État des stocks nationaux',
              subtitle: 'Médicaments et vaccins',
              date: 'Janvier 2026',
            ),
            const SizedBox(height: 24),
            // Statistiques anonymisées
            const SectionHeader(titre: 'Statistiques anonymisées'),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  _StatRow(label: 'Dossiers médicaux créés', value: '4,234,567'),
                  const Divider(),
                  _StatRow(label: 'Consultations totales', value: '12,456,789'),
                  const Divider(),
                  _StatRow(label: 'Ordonnances électroniques', value: '8,901,234'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NationalReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String date;

  const _NationalReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {},
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textLight,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _MinistereSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Row(
                children: [
                  const UserAvatar(
                    initiales: 'MS',
                    size: 64,
                    backgroundColor: AppColors.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ministère de la Santé',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Direction de la Santé Publique',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(titre: 'Configuration système'),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.storage,
              title: 'État des serveurs',
              subtitle: '3 régionaux + 1 national',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.local_hospital,
              title: 'Hôpitaux connectés',
              subtitle: '12 établissements actifs',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.security,
              title: 'Sécurité & Audit',
              subtitle: 'Journaux d\'accès',
              onTap: () {},
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
        ],
      ),
    );
  }
}
