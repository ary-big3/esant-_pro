import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';

class PatientRdvScreen extends StatefulWidget {
  final String? childId;
  final String? childName;

  const PatientRdvScreen({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<PatientRdvScreen> createState() => _PatientRdvScreenState();
}

class _PatientRdvScreenState extends State<PatientRdvScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allAppointments = [];
  DateTime _nowSnapshot = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeDataAsync();
  }

  Future<void> _initializeDataAsync() async {
    // Attendre que le token soit prêt
    await TokenHelper.ensureTokenReady();
    // Charger les rendez-vous UNE SEULE FOIS
    _loadAllAppointments();
  }

  Future<void> _loadAllAppointments() async {
    try {
      // Snapshotter le moment AVANT le fetch pour cohérence
      _nowSnapshot = DateTime.now();
      
      final apiService = ApiService();
      final response = await apiService.get('/appointments/patient?limit=20', requireAuth: true);
      
      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _allAppointments = (response['data'] as List).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (kDebugMode) print('Erreur lors du chargement des rendez-vous: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mes Rendez-vous',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () => _showNewRdvDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'À venir'),
                Tab(text: 'Historique'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RdvAVenirTab(
                  appointments: _allAppointments,
                  isLoading: _isLoading,
                  nowSnapshot: _nowSnapshot,
                ),
                _RdvHistoriqueTab(
                  appointments: _allAppointments,
                  isLoading: _isLoading,
                  nowSnapshot: _nowSnapshot,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNewRdvDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NewRdvBottomSheet(),
    );
  }
}

class _RdvAVenirTab extends StatefulWidget {
  final List<dynamic> appointments;
  final bool isLoading;
  final DateTime nowSnapshot;

  const _RdvAVenirTab({
    required this.appointments,
    required this.isLoading,
    required this.nowSnapshot,
  });

  @override
  State<_RdvAVenirTab> createState() => _RdvAVenirTabState();
}

class _RdvAVenirTabState extends State<_RdvAVenirTab> {
  late List<dynamic> _upcomingAppointments;

  @override
  void initState() {
    super.initState();
    _filterAppointments();
  }

  @override
  void didUpdateWidget(_RdvAVenirTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _filterAppointments();
  }

  void _filterAppointments() {
    _upcomingAppointments = widget.appointments
        .where((apt) {
          final aptDate = DateTime.tryParse(apt['appointment_date'] ?? '');
          return aptDate != null && aptDate.isAfter(widget.nowSnapshot);
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_upcomingAppointments.isEmpty) {
      return Center(
        child: Text(
          'Aucun rendez-vous à venir',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _upcomingAppointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appointment = _upcomingAppointments[index];
        final date = DateTime.tryParse(appointment['appointment_date'] ?? '') ?? DateTime.now();
        final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        
        return _RdvCard(
          date: date,
          heure: timeStr,
          medecin: '${appointment['doctor_first_name'] ?? 'Dr.'} ${appointment['doctor_last_name'] ?? ''}',
          specialite: appointment['speciality_name'] ?? 'Consultation',
          hopital: appointment['hospital_name'] ?? 'Hôpital',
          status: appointment['status'] ?? 'en_attente',
          type: 'consultation',
        ).animate(delay: Duration(milliseconds: index * 100)).fadeIn(duration: 400.ms);
      },
    );
  }
}

class _RdvHistoriqueTab extends StatefulWidget {
  final List<dynamic> appointments;
  final bool isLoading;
  final DateTime nowSnapshot;

  const _RdvHistoriqueTab({
    required this.appointments,
    required this.isLoading,
    required this.nowSnapshot,
  });

  @override
  State<_RdvHistoriqueTab> createState() => _RdvHistoriqueTabState();
}

class _RdvHistoriqueTabState extends State<_RdvHistoriqueTab> {
  late List<dynamic> _pastAppointments;

  @override
  void initState() {
    super.initState();
    _filterAppointments();
  }

  @override
  void didUpdateWidget(_RdvHistoriqueTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _filterAppointments();
  }

  void _filterAppointments() {
    _pastAppointments = widget.appointments
        .where((apt) {
          final aptDate = DateTime.tryParse(apt['appointment_date'] ?? '');
          return aptDate != null && aptDate.isBefore(widget.nowSnapshot);
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pastAppointments.isEmpty) {
      return Center(
        child: Text(
          'Aucun historique de rendez-vous',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _pastAppointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appointment = _pastAppointments[index];
        final date = DateTime.tryParse(appointment['appointment_date'] ?? '') ?? DateTime.now();
        final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        
        return _RdvCard(
          date: date,
          heure: timeStr,
          medecin: '${appointment['doctor_first_name'] ?? 'Dr.'} ${appointment['doctor_last_name'] ?? ''}',
          specialite: appointment['speciality_name'] ?? 'Consultation',
          hopital: appointment['hospital_name'] ?? 'Hôpital',
          status: 'termine',
          type: 'consultation',
          isPast: true,
        );
      },
    );
  }
}

class _RdvCard extends StatelessWidget {
  final DateTime date;
  final String heure;
  final String medecin;
  final String specialite;
  final String hopital;
  final String status;
  final String type;
  final bool isPast;

  const _RdvCard({
    required this.date,
    required this.heure,
    required this.medecin,
    required this.specialite,
    required this.hopital,
    required this.status,
    required this.type,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusLabel = _getStatusLabel();
    
    return AppCard(
      onTap: () {},
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${date.day}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      _getMonthName(date.month),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(medecin, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialite,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          heure,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on, size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hopital,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(text: statusLabel, color: statusColor),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case 'confirmed':
      case 'confirme':
        return AppColors.success;
      case 'pending':
      case 'en_attente':
        return AppColors.warning;
      case 'cancelled':
      case 'annule':
        return AppColors.error;
      case 'completed':
      case 'termine':
        return AppColors.textLight;
      case 'no_show':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case 'confirmed':
      case 'confirme':
        return 'Confirmé';
      case 'pending':
      case 'en_attente':
        return 'En attente';
      case 'cancelled':
      case 'annule':
        return 'Annulé';
      case 'completed':
      case 'termine':
        return 'Terminé';
      case 'no_show':
        return 'Absent';
      default:
        return status;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
  }
}

class _NewRdvBottomSheet extends StatefulWidget {
  const _NewRdvBottomSheet();

  @override
  State<_NewRdvBottomSheet> createState() => _NewRdvBottomSheetState();
}

class _NewRdvBottomSheetState extends State<_NewRdvBottomSheet> {
  String? _selectedSpecialite;
  DateTime? _selectedDate;
  String? _selectedHeure;
  String _type = 'consultation';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nouveau rendez-vous',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          // Type de consultation
          Text('Type de consultation', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TypeOption(
                  icon: Icons.local_hospital,
                  label: 'En personne',
                  isSelected: _type == 'consultation',
                  onTap: () => setState(() => _type = 'consultation'),
                ),
              ),

            ],
          ),
          const SizedBox(height: 20),
          // Spécialité (SANS le choix du médecin)
          DropdownButtonFormField<String>(
            initialValue: _selectedSpecialite,
            decoration: const InputDecoration(
              labelText: 'Spécialité',
              prefixIcon: Icon(Icons.medical_services_outlined),
            ),
            items: AppConstants.specialites
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => _selectedSpecialite = value),
          ),
          const SizedBox(height: 16),
          // Date
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Sélectionner une date',
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Heure
          Text('Horaires disponibles', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['09:00', '09:30', '10:00', '10:30', '11:00', '14:00', '14:30', '15:00']
                .map((heure) => ChoiceChip(
                      label: Text(heure),
                      selected: _selectedHeure == heure,
                      onSelected: (selected) {
                        setState(() => _selectedHeure = selected ? heure : null);
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: _isSubmitting ? 'Envoi en cours...' : 'Envoyer la demande',
            onPressed: _isSubmitting ? null : _submitRequest,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (_selectedSpecialite == null || _selectedDate == null || _selectedHeure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final hours = int.parse(_selectedHeure!.split(':')[0]);
      final minutes = int.parse(_selectedHeure!.split(':')[1]);
      final appointmentDateTime = _selectedDate!.copyWith(hour: hours, minute: minutes);
      
      // Format: Y-m-d H:i:s (pour compatibility avec PHP backend)
      final formattedDate = '${appointmentDateTime.year}-'
          '${appointmentDateTime.month.toString().padLeft(2, '0')}-'
          '${appointmentDateTime.day.toString().padLeft(2, '0')} '
          '${appointmentDateTime.hour.toString().padLeft(2, '0')}:'
          '${appointmentDateTime.minute.toString().padLeft(2, '0')}:'
          '${appointmentDateTime.second.toString().padLeft(2, '0')}';

      final apiService = ApiService();
      final response = await apiService.post(
        '/appointment-requests',
        body: {
          'speciality': _selectedSpecialite,
          'appointment_date': formattedDate,
          'appointment_type': _type,
        },
        requireAuth: true,
      );

      if (mounted) {
        if (response['success'] == true) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demande de rendez-vous envoyée avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Erreur lors de l\'envoi'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
