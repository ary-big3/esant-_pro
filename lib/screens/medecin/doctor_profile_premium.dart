import 'package:flutter/material.dart';
import '../../core/theme/doctor_theme.dart';
import '../../widgets/doctor_premium_widgets.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';

class DoctorProfilePremium extends StatefulWidget {
  const DoctorProfilePremium({super.key});

  @override
  State<DoctorProfilePremium> createState() => _DoctorProfilePremiumState();
}

class _DoctorProfilePremiumState extends State<DoctorProfilePremium> {
  late ApiService _apiService;

  String _doctorName = 'Chargement...';
  String _specialty = 'Chargement...';
  String _hospital = 'Chargement...';
  String _email = 'Chargement...';
  String _phone = 'Chargement...';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.get('/doctor/profile');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        if (mounted) {
          setState(() {
            _doctorName = data['full_name'] ?? 'Inconnu';
            _specialty = data['specialty'] ?? 'Non spécifié';
            _hospital = data['hospital_name'] ?? 'Non spécifié';
            _email = data['email'] ?? 'Non spécifié';
            _phone = data['phone'] ?? 'Non spécifié';
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeaderDoctorUI(
          title: 'Mon Profil',
          subtitle: 'Gérez vos informations personnelles',
        ),
        const SizedBox(height: DoctorTheme.spacing32),
        Row(
          children: [
            Expanded(
              child: _buildProfileCard(),
            ),
            const SizedBox(width: DoctorTheme.spacing24),
            Expanded(
              child: _buildProfileActions(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    final initials = _getInitials(_doctorName);

    return DoctorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: DoctorTheme.blueVioletGradient,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: DoctorTheme.spacing20),

          // Nom
          Text(
            _doctorName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: DoctorTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DoctorTheme.spacing8),

          // Spécialité
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DoctorTheme.spacing12,
              vertical: DoctorTheme.spacing8,
            ),
            decoration: BoxDecoration(
              gradient: DoctorTheme.greenBlueGradient,
              borderRadius: DoctorTheme.radiusSmall,
            ),
            child: Text(
              _specialty,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: DoctorTheme.spacing16),

          // Hôpital
          Text(
            _hospital,
            style: const TextStyle(
              fontSize: 14,
              color: DoctorTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DoctorTheme.spacing24),

          // Divider
          Container(height: 1, color: DoctorTheme.dividerColor),
          const SizedBox(height: DoctorTheme.spacing24),

          // Informations de contact
          _buildInfoField('Email', _email, Icons.email_rounded),
          const SizedBox(height: DoctorTheme.spacing16),
          _buildInfoField('Téléphone', _phone, Icons.phone_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: DoctorTheme.primaryBlue),
            const SizedBox(width: DoctorTheme.spacing8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: DoctorTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: DoctorTheme.spacing4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: DoctorTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DoctorCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paramètres du compte',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: DoctorTheme.spacing16),
              _buildSettingItem(
                icon: Icons.security_rounded,
                title: 'Sécurité',
                subtitle: 'Changer le mot de passe',
                onTap: () => _showChangePasswordDialog(),
              ),
              const Divider(height: DoctorTheme.spacing16),
              _buildSettingItem(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Gérer les préférences',
                onTap: () {},
              ),
              const Divider(height: DoctorTheme.spacing16),
              _buildSettingItem(
                icon: Icons.dark_mode_rounded,
                title: 'Apparence',
                subtitle: 'Mode clair/sombre',
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: DoctorTheme.spacing16),
        DoctorCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistiques',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: DoctorTheme.spacing16),
              _buildStatRow('Consultations totales', '245'),
              const SizedBox(height: DoctorTheme.spacing8),
              _buildStatRow('Patients', '128'),
              const SizedBox(height: DoctorTheme.spacing8),
              _buildStatRow('Membre depuis', 'Janvier 2024'),
            ],
          ),
        ),
        const SizedBox(height: DoctorTheme.spacing16),
        DoctorButton(
          label: 'Éditer le profil',
          onPressed: () => _showEditProfileDialog(),
          icon: Icons.edit_rounded,
          gradient: DoctorTheme.blueVioletGradient,
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DoctorTheme.spacing8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: DoctorTheme.primaryBlue),
            const SizedBox(width: DoctorTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DoctorTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DoctorTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 18, color: DoctorTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: DoctorTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: DoctorTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Éditer le profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  hintText: _doctorName,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Spécialité',
                  hintText: _specialty,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Téléphone',
                  hintText: _phone,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Ancien mot de passe',
                  hintText: '••••••••',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  hintText: '••••••••',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  hintText: '••••••••',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
