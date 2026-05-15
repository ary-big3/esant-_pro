import 'package:flutter/material.dart';
import '../../core/theme/doctor_theme.dart';
import '../../widgets/doctor_premium_widgets.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';

class DoctorPatientsScreenPremium extends StatefulWidget {
  const DoctorPatientsScreenPremium({super.key});

  @override
  State<DoctorPatientsScreenPremium> createState() => _DoctorPatientsScreenPremiumState();
}

class _DoctorPatientsScreenPremiumState extends State<DoctorPatientsScreenPremium> {
  late ApiService _apiService;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.get('/doctor/patients');

      if (response['success'] == true && response['data'] != null) {
        final patients = List<Map<String, dynamic>>.from(
          (response['data'] as List).map((p) => Map<String, dynamic>.from(p as Map))
        );

        if (mounted) {
          setState(() {
            _allPatients = patients;
            _filteredPatients = patients;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement patients: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _allPatients;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredPatients = _allPatients
            .where((p) =>
                (p['full_name'] as String? ?? '').toLowerCase().contains(lowerQuery) ||
                (p['patient_id'].toString()).contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderDoctorUI(
          title: 'Mes Patients',
          subtitle: 'Gérez vos patients et leur dossiers médicaux',
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DoctorTheme.spacing12,
              vertical: DoctorTheme.spacing8,
            ),
            decoration: BoxDecoration(
              color: DoctorTheme.surfaceSecondary,
              borderRadius: DoctorTheme.radiusSmall,
            ),
            child: Row(
              children: [
                const Icon(Icons.person_add_rounded, size: 18, color: DoctorTheme.primaryBlue),
                const SizedBox(width: DoctorTheme.spacing8),
                Text(
                  '${_filteredPatients.length} patients',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DoctorTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DoctorTheme.spacing16),
        _buildSearchBar(),
        const SizedBox(height: DoctorTheme.spacing16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_filteredPatients.isEmpty)
          _buildEmptyState()
        else
          _buildPatientsList(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: DoctorTheme.surfaceColor,
        borderRadius: DoctorTheme.radiusMedium,
        boxShadow: DoctorTheme.shadowSoft,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterPatients,
        decoration: InputDecoration(
          hintText: 'Chercher par nom ou ID...',
          hintStyle: const TextStyle(color: DoctorTheme.textLight),
          prefixIcon: const Icon(Icons.search_rounded, color: DoctorTheme.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _filterPatients('');
                  },
                  child: const Icon(Icons.close_rounded, color: DoctorTheme.textSecondary),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DoctorTheme.spacing16,
            vertical: DoctorTheme.spacing12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DoctorTheme.spacing32),
        child: Column(
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: DoctorTheme.textLight,
            ),
            const SizedBox(height: DoctorTheme.spacing16),
            const Text(
              'Aucun patient trouvé',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DoctorTheme.textSecondary,
              ),
            ),
            const SizedBox(height: DoctorTheme.spacing8),
            const Text(
              'Commencez à ajouter des patients',
              style: TextStyle(
                fontSize: 14,
                color: DoctorTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredPatients.length,
      separatorBuilder: (_, __) => const SizedBox(height: DoctorTheme.spacing12),
      itemBuilder: (context, index) {
        final patient = _filteredPatients[index];
        return _buildPatientCard(patient);
      },
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return DoctorCard(
      onTap: () {
        // TODO: Navigate to patient dossier
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voir dossier de ${patient['full_name']}')),
        );
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: DoctorTheme.blueVioletGradient,
              borderRadius: DoctorTheme.radiusSmall,
            ),
            child: Center(
              child: Text(
                (patient['full_name'] as String? ?? 'P').characters.first,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: DoctorTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient['full_name'] ?? 'Anonyme',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: DoctorTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: DoctorTheme.spacing4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DoctorTheme.spacing8,
                        vertical: DoctorTheme.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: DoctorTheme.infoBlue.withValues(alpha: 0.1),
                        borderRadius: DoctorTheme.radiusSmall,
                      ),
                      child: Text(
                        'ID: ${patient['patient_id']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: DoctorTheme.infoBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: DoctorTheme.spacing8),
                    if (patient['email'] != null)
                      Text(
                        patient['email'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: DoctorTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_rounded,
            color: DoctorTheme.textLight,
            size: 20,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
