import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vitals_model.dart';
import '../../services/vitals_service.dart';

/// Écran d'affichage des constantes vitales du patient
class PatientVitalsScreen extends StatefulWidget {
  final String patientId;

  const PatientVitalsScreen({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  State<PatientVitalsScreen> createState() => _PatientVitalsScreenState();
}

class _PatientVitalsScreenState extends State<PatientVitalsScreen> {
  late Future<List<VitalsModel>> _vitalsHistory;
  VitalsModel? _latestVitals;

  @override
  void initState() {
    super.initState();
    if (widget.patientId.isEmpty) {
      if (kDebugMode) {
        print('🔴 [PatientVitalsScreen] ERREUR: patientId est vide!');
      }
      _vitalsHistory = Future.value([]);
      _latestVitals = null;
    } else {
      _vitalsHistory = VitalsService.getPatientVitalsHistory(
        widget.patientId,
        limit: 20,
      );
      _loadLatestVitals();
    }
  }

  Future<void> _loadLatestVitals() async {
    try {
      final latest = await VitalsService.getLatestVitals(widget.patientId);
      setState(() => _latestVitals = latest);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [PatientVitalsScreen] Erreur lors du chargement des vitales: $e');
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _vitalsHistory = VitalsService.getPatientVitalsHistory(
        widget.patientId,
        limit: 20,
      );
    });
    await _loadLatestVitals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Constantes Vitales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: widget.patientId.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Patient ID manquant',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Veuillez naviguer vers cet écran avec un ID patient valide.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Dernières constantes
                    if (_latestVitals != null) ...[
                      Text(
                        'Dernières Constantes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLatestVitalsCard(),
                      const SizedBox(height: 32),
                    ],

                    // Section: Historique
                    Text(
                      'Historique des Constantes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildVitalsHistory(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Affiche les dernières constantes vitales
  Widget _buildLatestVitalsCard() {
    if (_latestVitals == null) {
      return const SizedBox.shrink();
    }

    final vitals = _latestVitals!;
    final recordedDate = DateFormat('dd/MM/yyyy HH:mm').format(vitals.recordedAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,  // Gris foncé pour les cartes
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mesure du $recordedDate',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(vitals).withOpacity(0.1),
                  border: Border.all(color: _getStatusColor(vitals)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Normal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(vitals),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildVitalCard(
                icon: Icons.thermostat,
                label: 'Température',
                value: '${vitals.temperature}°C',
                color: Colors.orange,
                status: _getTempStatus(vitals.temperature),
              ),
              _buildVitalCard(
                icon: Icons.favorite,
                label: 'TA Systolique',
                value: '${vitals.tensionSystolique} mmHg',
                color: Colors.red,
                status: _getTensionStatus(vitals.tensionSystolique),
              ),
              _buildVitalCard(
                icon: Icons.favorite_border,
                label: 'FC',
                value: '${vitals.frequenceCardiaque} bpm',
                color: Colors.pink,
                status: _getFCStatus(vitals.frequenceCardiaque),
              ),
              _buildVitalCard(
                icon: Icons.air,
                label: 'Fréquence Resp.',
                value: '${vitals.frequenceRespiratoire} rpm',
                color: AppColors.primary,
                status: 'Normal',
              ),
              _buildVitalCard(
                icon: Icons.bubble_chart,
                label: 'Saturation O₂',
                value: '${vitals.saturOxygene}%',
                color: Colors.lightBlue,
                status: _getO2Status(vitals.saturOxygene),
              ),
              _buildVitalCard(
                icon: Icons.scale,
                label: 'Poids',
                value: '${vitals.poids ?? 'N/A'} kg',
                color: Colors.purple,
                status: 'N/A',
              ),
            ],
          ),
          if (vitals.taille != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,  // Gris foncé pour les cartes
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.height, color: Colors.indigo),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Taille',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${vitals.taille} cm',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (vitals.notes != null && vitals.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,  // Gris foncé pour les cartes
                border: Border.all(color: AppColors.primaryLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes de l\'infirmière:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vitals.notes!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Affiche l'historique des constantes vitales
  Widget _buildVitalsHistory() {
    return FutureBuilder<List<VitalsModel>>(
      future: _vitalsHistory,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final vitals = snapshot.data ?? [];

        if (vitals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: AppColors.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune mesure enregistrée',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textLight,
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: List.generate(vitals.length, (index) {
            final vital = vitals[index];
            final recordedDate =
                DateFormat('dd/MM/yyyy HH:mm').format(vital.recordedAt);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        recordedDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Chip(
                        label: const Text('Voir détails'),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildVitalBadge('Temp', '${vital.temperature}°C'),
                      _buildVitalBadge('TA',
                          '${vital.tensionSystolique}/${vital.tensionDiastolique}'),
                      _buildVitalBadge('FC', '${vital.frequenceCardiaque}'),
                      _buildVitalBadge('FR', '${vital.frequenceRespiratoire}'),
                      _buildVitalBadge('O₂', '${vital.saturOxygene}%'),
                    ],
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  /// Construit un badge pour afficher une constante
  Widget _buildVitalBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte de vitale
  Widget _buildVitalCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              color: _getStatusColorForText(status),
            ),
          ),
        ],
      ),
    );
  }

  /// Retourne la couleur du statut
  Color _getStatusColor(VitalsModel vitals) {
    return Colors.green;
  }

  /// Retourne le statut de la température
  String _getTempStatus(double temp) {
    if (temp < 36.5 || temp > 37.5) return '⚠️ Anormal';
    return 'Normal';
  }

  /// Retourne le statut de la tension
  String _getTensionStatus(int systolic) {
    if (systolic < 90 || systolic > 140) return '⚠️ Anormal';
    return 'Normal';
  }

  /// Retourne le statut de la fréquence cardiaque
  String _getFCStatus(int fc) {
    if (fc < 60 || fc > 100) return '⚠️ Anormal';
    return 'Normal';
  }

  /// Retourne le statut de la saturation en oxygène
  String _getO2Status(double o2) {
    if (o2 < 95) return '⚠️ Anormal';
    return 'Normal';
  }

  /// Retourne la couleur du texte du statut
  Color _getStatusColorForText(String status) {
    if (status.contains('Anormal')) return Colors.red;
    return Colors.green;
  }
}
