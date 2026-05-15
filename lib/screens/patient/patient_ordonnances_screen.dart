import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';

// Conditional imports for file handling
import 'file_saver_stub.dart' if (dart.library.io) 'file_saver_io.dart' as file_saver;

class PatientOrdonnancesScreen extends StatefulWidget {
  final String? childId;
  final String? childName;

  const PatientOrdonnancesScreen({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<PatientOrdonnancesScreen> createState() => _PatientOrdonnancesScreenState();
}

class _PatientOrdonnancesScreenState extends State<PatientOrdonnancesScreen> {
  List<dynamic> _prescriptions = [];
  Map<String, dynamic>? _hospitalInfo;

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    // Attendre que le token soit prêt
    await TokenHelper.ensureTokenReady();
    // Charger les infos de l'hôpital et les ordonnances
    await Future.wait([
      _loadHospitalInfo(),
      _loadPrescriptions(),
    ]);
  }

  Future<void> _loadHospitalInfo() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('/hospital/info', requireAuth: true);
      
      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _hospitalInfo = response['data'];
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erreur lors du chargement des infos hôpital: $e');
    }
  }

  Future<void> _loadPrescriptions() async {
    try {
      final apiService = ApiService();
      // Charger les ordonnances de l'enfant si childId est fourni
      final url = widget.childId != null 
          ? '/patient/${widget.childId}/prescriptions?limit=20' 
          : '/prescriptions/patient?limit=20';
      final response = await apiService.get(url, requireAuth: true);
      
      if (kDebugMode) print('🔍 Response reçu: ${response.toString()}');
      
      if (response['success'] == true && response['data'] != null) {
        if (kDebugMode) {
          print('📦 Nombre d\'ordonnances: ${response['data'].length}');
          if ((response['data'] as List).isNotEmpty) {
            final firstPrescription = response['data'][0];
            print('🔍 Première ordonnance: $firstPrescription');
            print('💊 Médicaments dans première ordonnance: ${firstPrescription['medications']}');
          }
        }
        
        if (mounted) {
          setState(() {
            _prescriptions = response['data'] is List ? response['data'] : [];
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erreur lors du chargement des ordonnances: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Mes Ordonnances',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Expanded(
            child: _prescriptions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Aucune ordonnance enregistrée',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _prescriptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final prescription = _prescriptions[index];
                      return _buildPrescriptionCard(context, prescription, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(BuildContext context, dynamic prescription, int index) {
    try {
      final date = DateTime.tryParse(prescription['created_at'] ?? '');
      
      final doctorFirstName = prescription['doctor_first_name'] ?? 'Dr.';
      final doctorLastName = prescription['doctor_last_name'] ?? '';
      final medecin = '$doctorFirstName ${doctorLastName.isNotEmpty ? doctorLastName : ''}';
      final specialite = prescription['speciality_name'] ?? 'Consultation';
      final notes = prescription['notes'] ?? prescription['description'] ?? 'Ordonnance médicale';
      final status = prescription['status'] ?? 'Actif';
      final estValide = status.toString().toLowerCase() == 'active' || status.toString().toLowerCase() == 'actif';

      return _OrdonnanceCard(
        date: date ?? DateTime.now(),
        medecin: medecin,
        specialite: specialite,
        notes: notes,
        estValide: estValide,
        status: status,
        medicaments: prescription['medications'] is List ? prescription['medications'] : [],
        hospitalInfo: _hospitalInfo,
      );
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la construction de la carte ordonnance: $e');
      return const SizedBox.shrink();
    }
  }
}

class _OrdonnanceCard extends StatelessWidget {
  final DateTime date;
  final String medecin;
  final String specialite;
  final String notes;
  final bool estValide;
  final String status;
  final List<dynamic> medicaments;
  final Map<String, dynamic>? hospitalInfo;

  const _OrdonnanceCard({
    required this.date,
    required this.medecin,
    required this.specialite,
    required this.notes,
    required this.estValide,
    required this.status,
    this.medicaments = const [],
    this.hospitalInfo,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _showOrdonnanceDetails(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medecin, style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        specialite,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              StatusBadge(
                text: estValide ? 'Valide' : 'Expirée',
                color: estValide ? AppColors.success : AppColors.textLight,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            'Détails',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textLight,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              notes,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textLight,
                    ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 200), () {
                          _showOrdonnanceDetails(context);
                        });
                      },
                      icon: const Icon(Icons.visibility, size: 20, color: AppColors.primary),
                      tooltip: 'Voir détails',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrdonnanceDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ordonnance',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 32),
            // Informations de l'hôpital
            if (hospitalInfo != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospitalInfo!['name'] ?? 'Hôpital',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (hospitalInfo!['address'] != null)
                      _HospitalInfoLine(icon: Icons.location_on, text: hospitalInfo!['address']),
                    if (hospitalInfo!['phone'] != null)
                      _HospitalInfoLine(icon: Icons.phone, text: hospitalInfo!['phone']),
                    if (hospitalInfo!['email'] != null)
                      _HospitalInfoLine(icon: Icons.email, text: hospitalInfo!['email']),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Infos hôpital en cours de chargement...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            const SizedBox(height: 24),
            _DetailRow(label: 'Médecin', value: medecin),
            _DetailRow(label: 'Spécialité', value: specialite),
            _DetailRow(label: 'Date', value: '${date.day}/${date.month}/${date.year}'),
            _DetailRow(label: 'Validité', value: estValide ? '3 mois' : 'Expirée'),
            const SizedBox(height: 24),
            Text(
              'Prescriptions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: medicaments.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun médicament prescrit',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: medicaments.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final med = medicaments[index];
                        // Extraire les infos du médicament (Map ou String)
                        late String medicationName;
                        late String dosage;
                        late String frequency;
                        late String duration;
                        
                        if (med is Map) {
                          medicationName = (med['medication_name'] ?? '').toString();
                          dosage = '${med['dosage'] ?? ''}${med['dosage_unit'] ?? ''}'.trim();
                          frequency = (med['frequency'] ?? '').toString();
                          duration = (med['duration'] ?? '').toString();
                        } else {
                          // Fallback si c'est une String
                          medicationName = med.toString();
                          dosage = '1 comprimé';
                          frequency = '2 fois par jour';
                          duration = '7 jours';
                        }
                        
                        return _PrescriptionItem(
                          nom: medicationName,
                          dosage: dosage,
                          frequence: frequency,
                          duree: duration,
                          route: med is Map ? (med['route_of_administration'] ?? 'oral').toString() : 'oral',
                          instructions: med is Map ? (med['special_instructions'] ?? '').toString() : '',
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Télécharger en PDF',
                    icon: Icons.download,
                    onPressed: () => _downloadOrdonnance(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadOrdonnance(BuildContext context) async {
    try {
      // Afficher indicateur de chargement
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Génération de l\'ordonnance en cours...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Générer le PDF
      final pdf = pw.Document();
      final formatter = DateFormat('dd/MM/yyyy');
      final dateStr = formatter.format(date);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête de l'hôpital
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        hospitalInfo?['name'] ?? 'Hôpital e-Santé',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      if (hospitalInfo?['address'] != null)
                        pw.Text(
                          hospitalInfo!['address'],
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      if (hospitalInfo?['phone'] != null)
                        pw.Text(
                          'Tél: ${hospitalInfo!['phone']}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      if (hospitalInfo?['email'] != null)
                        pw.Text(
                          'Email: ${hospitalInfo!['email']}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Titre
                pw.Center(
                  child: pw.Text(
                    'ORDONNANCE MÉDICALE',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.blue, thickness: 2),
                pw.SizedBox(height: 16),

                // Informations du médecin et date
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Médecin:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                              pw.Text(medecin, style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Spécialité:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                              pw.Text(specialite, style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                              pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Validité:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                              pw.Text(estValide ? '3 mois' : 'Expirée', style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Section médicaments avec tableau
                pw.Text(
                  'PRESCRIPTIONS',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 12),

                // Tableau des médicaments
                if (medicaments.isNotEmpty)
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(2),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Médicament', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Dosage', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Fréquence/Jour', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Durée (jours)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                      ...medicaments.asMap().entries.map((entry) {
                        final med = entry.value;
                        late String medicationName, dosage, frequency, duration;
                        if (med is Map) {
                          medicationName = (med['medication_name'] ?? '').toString();
                          dosage = '${med['dosage'] ?? ''}${med['dosage_unit'] ?? ''}'.trim();
                          frequency = (med['frequency'] ?? '').toString();
                          duration = (med['duration'] ?? '').toString();
                        } else {
                          medicationName = med.toString();
                          dosage = '1 comprimé';
                          frequency = '2 fois/jour';
                          duration = '7 jours';
                        }
                        return pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(medicationName, style: const pw.TextStyle(fontSize: 9))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(dosage.isNotEmpty ? dosage : '-', style: const pw.TextStyle(fontSize: 9))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(frequency.isNotEmpty ? frequency : '-', style: const pw.TextStyle(fontSize: 9))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(duration.isNotEmpty ? duration : '-', style: const pw.TextStyle(fontSize: 9))),
                          ],
                        );
                      }),
                    ],
                  )
                else
                  pw.Text('Aucun médicament prescrit', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),

                pw.SizedBox(height: 24),

                // Notes si présentes
                if (notes.isNotEmpty) ...[
                  pw.Text('NOTES:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(notes, style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.SizedBox(height: 24),
                ],

                // Espace pour signature
                pw.Spacer(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Divider(color: PdfColors.grey400),
                    pw.SizedBox(height: 8),
                    pw.Text('Signature du médecin', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('___________________________', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text('Dr. $medecin', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Sauvegarder le PDF
      final bytes = await pdf.save();
      final fileName = 'ordonnance_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      
      await file_saver.FileSaver.saveAndOpen(bytes: bytes, fileName: fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ordonnance téléchargée: $fileName'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Erreur téléchargement PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _HospitalInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HospitalInfoLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionItem extends StatelessWidget {
  final String nom;
  final String dosage;
  final String frequence;
  final String duree;
  final String route;
  final String instructions;

  const _PrescriptionItem({
    required this.nom,
    required this.dosage,
    required this.frequence,
    required this.duree,
    this.route = 'oral',
    this.instructions = '',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.medication, color: AppColors.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Afficher le nom du médicament, ou un message si c'est vide
              Text(
                nom.isEmpty ? '⚠️ Nom non disponible' : nom,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: nom.isEmpty ? Colors.orange : null,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              if (dosage.isNotEmpty)
                Text(
                  'Dosage: $dosage',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              if (dosage.isEmpty)
                Text(
                  'Dosage: ⚠️ Non spécifié',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                ),
              if (frequence.isNotEmpty)
                Text(
                  'Fréquence: $frequence',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              if (duree.isNotEmpty)
                Text(
                  'Durée: $duree',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              if (route.isNotEmpty && route != 'oral')
                Text(
                  'Route: $route',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              if (instructions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Instructions: $instructions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
