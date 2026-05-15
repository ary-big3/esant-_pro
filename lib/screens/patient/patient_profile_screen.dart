import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/nfc_card_widget.dart';
import '../../models/security_audit_consent_model.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';
import '../auth/login_screen.dart';
import 'patient_home_screen.dart';
import 'patient_medical_history_screen.dart';

class PatientProfileScreen extends StatefulWidget {
    final String? childId;
    final String? childName;

    const PatientProfileScreen({
      Key? key,
      this.childId,
      this.childName,
    }) : super(key: key);

    @override
    State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  Map<String, dynamic> _patientData = {};
  String _displayName = 'Patient';
  String _email = '';
  String _patientId = '';
  String _initiales = 'P';
  late Consentement _consentement;

  @override
  void initState() {
    super.initState();
    _loadPatientDataAsync();
  }

  Future<void> _loadPatientDataAsync() async {
    // Attendre que le token soit prêt
    await TokenHelper.ensureTokenReady();
    // Charger les données
    _loadPatientData();
  }

    Future<void> _loadPatientData() async {
      try {
        final authService = AuthService();
        final apiService = ApiService();
        final currentUser = authService.currentUser;

        if (currentUser != null) {
          setState(() {
            _displayName = '${currentUser.prenom} ${currentUser.nom}';
            _email = currentUser.email;
            _initiales = '${currentUser.prenom.isNotEmpty ? currentUser.prenom[0].toUpperCase() : 'P'}${currentUser.nom.isNotEmpty ? currentUser.nom[0].toUpperCase() : 'P'}';
          });
        }

        // Charger les données détaillées du profil
        final response = await apiService.get('/patient/profile', requireAuth: true);
        if (response['success'] == true && response['data'] != null) {
          final patientData = response['data'];
          setState(() {
            _patientData = patientData;
            _patientId = patientData['patient_id']?.toString() ?? '';
          });
        }

        // Charger les consentements réels depuis la BD
        try {
          final consentsResponse = await apiService.get('/patient/consents', requireAuth: true);
          if (consentsResponse['success'] == true && consentsResponse['data'] != null) {
            final consentData = consentsResponse['data'];
            
            // Extraire les noms des médecins
            final accesAutorises = <String>[];
            if (consentData['accesAutorises'] != null) {
              for (var access in consentData['accesAutorises']) {
                accesAutorises.add(
                  '${access['doctor_name']} (${access['permission_type'] ?? 'view_only'})'
                );
              }
            }
            
            final accesRevokes = <String>[];
            if (consentData['accesRevokes'] != null) {
              for (var access in consentData['accesRevokes']) {
                accesRevokes.add(access['doctor_name'] ?? 'Inconnu');
              }
            }

            setState(() {
              _consentement = Consentement(
                patientId: _patientId,
                accesAutorises: accesAutorises,
                accesRevokes: accesRevokes,
              );
            });
          }
        } catch (e) {
          if (kDebugMode) print('Erreur lors du chargement des consentements: $e');
          // Valeur par défaut si l'endpoint n'existe pas
          setState(() {
            _consentement = Consentement(
              patientId: _patientId,
              accesAutorises: [],
              accesRevokes: [],
            );
          });
        }

      } catch (e) {
        if (kDebugMode) print('Erreur lors du chargement des données du patient: $e');
      }
    }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Bouton retour au compte parent (si compte enfant)
            if (widget.childId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
                      (route) => false,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.secondary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'Retour au compte parent',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // En-tête profil
            AppCard(
              child: Column(
                children: [
                  UserAvatar(
                    initiales: _initiales,
                    size: 80,
                    backgroundColor: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.childId != null ? (widget.childName ?? 'Enfant') : _displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  if (widget.childId == null && _email.isNotEmpty)
                    Text(
                      _email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  const SizedBox(height: 16),
                  const StatusBadge(
                    text: 'Compte vérifié',
                    color: AppColors.success,
                    icon: Icons.verified,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Carte NFC
            NfcCardWidget(
              patientId: widget.childId != null
                  ? (widget.childName == 'Mohamed Diallo' ? 'PAT-2026-0002' : 'PAT-2026-0003')
                  : _patientId,
              patientNom: widget.childId != null ? widget.childName ?? 'Patient' : _displayName,
              groupeSanguin: _patientData['blood_group'] ?? 'A+',
              isActive: true,
            ),
            const SizedBox(height: 24),
            // Options du profil
            _ProfileSection(
              titre: 'Compte',
              items: [
                _ProfileItem(
                  icon: Icons.person_outline,
                  label: 'Informations personnelles',
                  onTap: () {},
                ),
                _ProfileItem(
                  icon: Icons.security,
                  label: 'Sécurité et mot de passe',
                  onTap: () {},
                ),
                _ProfileItem(
                  icon: Icons.credit_card,
                  label: 'Gérer ma carte NFC',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Section "Mes enfants" visible seulement pour le compte parent
            if (widget.childId == null)
              Column(
                children: [
                  _ChildrenAssociationSection(
                    onChildSelected: (childId) {
                      // Basculer vers le compte enfant
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Basculement vers le compte enfant $childId')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            _ProfileSection(
              titre: 'Santé',
              items: [
                _ProfileItem(
                  icon: Icons.medical_information,
                  label: 'Antécédents Médicaux',
                  subtitle: 'Gérer mon historique médical',
                  onTap: () async {
                    final result = await Navigator.of(context).push<Map<String, dynamic>>(
                      MaterialPageRoute(
                        builder: (context) => PatientMedicalHistoryScreen(
                          childId: widget.childId,
                          childName: widget.childName,
                        ),
                      ),
                    );
                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Informations médicales enregistrées avec succès'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              titre: 'Consentements',
              items: [
                _ProfileItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Gestion des accès',
                  subtitle: 'Contrôlez qui peut voir votre dossier',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Accès autorisés'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._consentement.accesAutorises.map((a) => Text('• $a')),
                            const SizedBox(height: 12),
                            Text('Accès révoqués :', style: TextStyle(fontWeight: FontWeight.bold)),
                            ..._consentement.accesRevokes.map((r) => Text('• $r')),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Fermer'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _ProfileItem(
                  icon: Icons.history,
                  label: 'Historique des accès',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Historique des accès'),
                        content: Text('À compléter : journalisation des accès.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Fermer'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              titre: 'Préférences',
              items: [
                _ProfileItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                    activeColor: AppColors.primary,
                  ),
                ),
                _ProfileItem(
                  icon: Icons.language,
                  label: 'Langue',
                  subtitle: 'Français',
                  onTap: () {},
                ),
                _ProfileItem(
                  icon: Icons.dark_mode_outlined,
                  label: 'Mode sombre',
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {},
                    activeColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              titre: 'Support',
              items: [
                _ProfileItem(
                  icon: Icons.help_outline,
                  label: 'Aide et FAQ',
                  onTap: () {},
                ),
                _ProfileItem(
                  icon: Icons.description_outlined,
                  label: 'Conditions d\'utilisation',
                  onTap: () {},
                ),
                _ProfileItem(
                  icon: Icons.policy_outlined,
                  label: 'Politique de confidentialité',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Déconnexion / Retour au parent
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: Icon(
                  widget.childId != null ? Icons.arrow_back : Icons.logout,
                  color: widget.childId != null ? AppColors.primary : AppColors.error,
                ),
                label: Text(
                  widget.childId != null ? 'Retour au compte parent' : 'Déconnexion',
                  style: TextStyle(
                    color: widget.childId != null ? AppColors.primary : AppColors.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: widget.childId != null ? AppColors.primary : AppColors.error,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight,
                  ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isChildAccount = widget.childId != null;
    final dialogTitle = isChildAccount ? 'Retour au compte parent' : 'Déconnexion';
    final dialogContent = isChildAccount 
        ? 'Voulez-vous retourner au compte parent ?' 
        : 'Êtes-vous sûr de vouloir vous déconnecter ?';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(dialogTitle),
        content: Text(dialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (isChildAccount) {
                // Retourner au compte parent
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
                  (route) => false,
                );
              } else {
                // Aller au login
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isChildAccount ? AppColors.primary : AppColors.error
            ),
            child: Text(isChildAccount ? 'Retour' : 'Déconnexion'),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String titre;
  final List<Widget> items;

  const _ProfileSection({required this.titre, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titre,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.map((item) {
              final isLast = items.last == item;
              return Column(
                children: [
                  item,
                  if (!isLast)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ChildrenAssociationSection extends StatefulWidget {
  final Function(String) onChildSelected;

  const _ChildrenAssociationSection({
    required this.onChildSelected,
  });

  @override
  State<_ChildrenAssociationSection> createState() => _ChildrenAssociationSectionState();
}

class _ChildrenAssociationSectionState extends State<_ChildrenAssociationSection> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _associatedChildren = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final response = await _apiService.get('/patient/children');
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> childrenData = response['data'] as List<dynamic>;
        setState(() {
          _associatedChildren = childrenData.map((child) {
            final firstName = child['first_name'] ?? '';
            final lastName = child['last_name'] ?? '';
            final dob = child['date_of_birth'] ?? '';
            String age = '';
            if (dob.isNotEmpty) {
              try {
                final birthDate = DateTime.parse(dob);
                final now = DateTime.now();
                final years = now.difference(birthDate).inDays ~/ 365;
                age = '$years ans';
              } catch (_) {
                age = '';
              }
            }
            return {
              'id': (child['patient_id'] ?? '').toString(),
              'nom': '$firstName $lastName'.trim(),
              'age': age,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading children: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _switchToChild(String childId, String childName) {
    // Basculer vers le compte enfant
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => PatientHomeScreen(
          childId: childId,
          childName: childName,
          childAge: _associatedChildren
              .firstWhere((child) => child['id'].toString() == childId)['age']?.toString() ?? '',
        ),
      ),
      (route) => false,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Basculement vers $childName'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.child_care, color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Mes enfants',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_associatedChildren.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Aucun enfant associé',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: _associatedChildren.asMap().entries.map((entry) {
                final isLast = entry.key == _associatedChildren.length - 1;
                final child = entry.value;
                return Column(
                  children: [
                    InkWell(
                      onTap: () => _switchToChild(child['id'].toString(), child['nom'].toString()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const UserAvatar(
                              initiales: 'EN',
                              size: 40,
                              backgroundColor: AppColors.secondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    child['nom'].toString(),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${child['age'] ?? ''}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast) const Divider(height: 1, indent: 56),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
