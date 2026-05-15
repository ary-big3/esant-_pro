import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vitals_model.dart';
import '../../services/vitals_service.dart';
import '../../widgets/common_widgets.dart';

class NurseScreen extends StatefulWidget {
  const NurseScreen({Key? key}) : super(key: key);

  @override
  State<NurseScreen> createState() => _NurseScreenState();
}

class _NurseScreenState extends State<NurseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // État
  List<VitalsModel> _vitalsHistory = [];
  bool _isLoading = false;
  bool _isEditing = false;
  VitalsModel? _editingVitals;

  // Contrôleurs formulaire
  final _patientIdController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _tensionSysController = TextEditingController();
  final _tensionDiaController = TextEditingController();
  final _frequenceCardiaqueController = TextEditingController();
  final _poidsController = TextEditingController();
  final _tailleController = TextEditingController();
  final _commentaireController = TextEditingController();
  final _frequenceRespController = TextEditingController();
  final _oxygenController = TextEditingController();

  double? _imc;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVitalsHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _patientIdController.dispose();
    _temperatureController.dispose();
    _tensionSysController.dispose();
    _tensionDiaController.dispose();
    _frequenceCardiaqueController.dispose();
    _frequenceRespController.dispose();
    _oxygenController.dispose();
    _poidsController.dispose();
    _tailleController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _loadVitalsHistory() async {
    setState(() => _isLoading = true);
    try {
      final vitals = await VitalsService.getPatientVitalsHistory('');
      setState(() => _vitalsHistory = vitals);
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateIMC() {
    final poids = double.tryParse(_poidsController.text);
    final taille = double.tryParse(_tailleController.text);

    if (poids != null && taille != null && taille > 0) {
      setState(() {
        _imc = poids / ((taille / 100) * (taille / 100));
      });
    }
  }

  Future<void> _saveVitals() async {
    if (!_formKey.currentState!.validate()) return;
    
    final patientId = _patientIdController.text.trim();
    if (patientId.isEmpty) {
      _showErrorSnackBar('Veuillez entrer l\'ID du patient');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isEditing && _editingVitals != null) {
        // Mise à jour
        // TODO: Implémenter la mise à jour
        _showSuccessSnackBar('Constantes mises à jour');
      } else {
        // Création
        await VitalsService.recordVitals(
          patientId: patientId,
          temperature: double.parse(_temperatureController.text),
          tensionSystolique: int.parse(_tensionSysController.text),
          tensionDiastolique: int.parse(_tensionDiaController.text),
          frequenceCardiaque: int.parse(_frequenceCardiaqueController.text),
          frequenceRespiratoire: int.parse(_frequenceRespController.text),
          saturOxygene: double.parse(_oxygenController.text),
          poids: double.tryParse(_poidsController.text),
          taille: double.tryParse(_tailleController.text),
          notes: _commentaireController.text,
        );
        _showSuccessSnackBar('Constantes enregistrées');
      }

      await _loadVitalsHistory();
      _clearForm();
      setState(() => _isEditing = false);
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editVitals(VitalsModel vitals) {
    setState(() {
      _isEditing = true;
      _editingVitals = vitals;
      _patientIdController.text = vitals.patientId;
      _temperatureController.text = vitals.temperature.toString();
      _tensionSysController.text = vitals.tensionSystolique.toString();
      _tensionDiaController.text = vitals.tensionDiastolique.toString();
      _frequenceCardiaqueController.text = vitals.frequenceCardiaque.toString();
      _frequenceRespController.text = vitals.frequenceRespiratoire.toString();
      _oxygenController.text = vitals.saturOxygene.toString();
      _poidsController.text = vitals.poids?.toString() ?? '';
      _tailleController.text = vitals.taille?.toString() ?? '';
      _commentaireController.text = vitals.notes ?? '';
      if (vitals.poids != null && vitals.taille != null) {
        _imc = vitals.poids! / ((vitals.taille! / 100) * (vitals.taille! / 100));
      }
    });
    _tabController.animateTo(0);
  }

  Future<void> _deleteVitals(VitalsModel vitals) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ces constantes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        // TODO: Implémenter la suppression
        await _loadVitalsHistory();
        _showSuccessSnackBar('Constantes supprimées');
      } catch (e) {
        _showErrorSnackBar('Erreur: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _temperatureController.clear();
    _tensionSysController.clear();
    _tensionDiaController.clear();
    _frequenceCardiaqueController.clear();
    _frequenceRespController.clear();
    _oxygenController.clear();
    _poidsController.clear();
    _tailleController.clear();
    _commentaireController.clear();
    setState(() {
      _imc = null;
      _isEditing = false;
      _editingVitals = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Constantes Vitales'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.edit),
              text: 'Saisie des constantes',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Historique',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSaisieTab(),
          _buildHistoriqueTab(),
        ],
      ),
    );
  }

  // ONGLET 1: Saisie des constantes
  Widget _buildSaisieTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              _isEditing
                  ? 'Modifier les constantes'
                  : 'Saisie des constantes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Température
            AppTextField(
              label: 'Température (°C)',
              hint: '37.5',
              controller: _temperatureController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.thermostat,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Température requise';
                }
                final temp = double.tryParse(value);
                if (temp == null || temp < 35 || temp > 43) {
                  return 'Valeur invalide (35-43°C)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tension artérielle
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'TA Systolique',
                    hint: '120',
                    controller: _tensionSysController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.favorite,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      final val = int.tryParse(value);
                      if (val == null || val < 50 || val > 250) {
                        return 'Invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'TA Diastolique',
                    hint: '80',
                    controller: _tensionDiaController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.favorite,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      final val = int.tryParse(value);
                      if (val == null || val < 30 || val > 150) {
                        return 'Invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fréquence cardiaque
            AppTextField(
              label: 'Fréquence cardiaque (bpm)',
              hint: '72',
              controller: _frequenceCardiaqueController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.favorite_border,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Fréquence cardiaque requise';
                }
                final fc = int.tryParse(value);
                if (fc == null || fc < 30 || fc > 250) {
                  return 'Valeur invalide (30-250 bpm)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Fréquence respiratoire et O2
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Fréquence resp. (rpm)',
                    hint: '16',
                    controller: _frequenceRespController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.air,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Saturation O₂ (%)',
                    hint: '98',
                    controller: _oxygenController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.bubble_chart,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Poids et Taille (pour IMC)
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Poids (kg)',
                    hint: '70',
                    controller: _poidsController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.scale,
                    onChanged: (_) => _calculateIMC(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Poids requis';
                      }
                      final p = double.tryParse(value);
                      if (p == null || p < 2 || p > 300) {
                        return 'Invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Taille (cm)',
                    hint: '175',
                    controller: _tailleController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.height,
                    onChanged: (_) => _calculateIMC(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Taille requise';
                      }
                      final t = int.tryParse(value);
                      if (t == null || t < 50 || t > 250) {
                        return 'Invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // IMC calculé
            if (_imc != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getImcColor(_imc!).withOpacity(0.1),
                  border: Border.all(color: _getImcColor(_imc!)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calculate, color: _getImcColor(_imc!)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IMC',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '${_imc!.toStringAsFixed(1)} (${_getImcCategory(_imc!)})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getImcColor(_imc!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Commentaire
            AppTextField(
              label: 'Commentaire (optionnel)',
              hint: 'Ajouter des notes...',
              controller: _commentaireController,
              maxLines: 3,
              prefixIcon: Icons.note,
            ),
            const SizedBox(height: 16),

            // ID Patient - DERNIER CHAMP
            AppTextField(
              label: 'ID Patient',
              hint: 'Entrez l\'ID du patient',
              controller: _patientIdController,
              keyboardType: TextInputType.text,
              prefixIcon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'ID patient requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _clearForm,
                    icon: const Icon(Icons.clear),
                    label: const Text('Annuler'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveVitals,
                    icon: const Icon(Icons.save),
                    label: Text(_isEditing ? 'Valider' : 'Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ONGLET 2: Historique
  Widget _buildHistoriqueTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vitalsHistory.isEmpty) {
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
              'Aucun enregistrement',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textLight,
                  ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Patient')),
          DataColumn(label: Text('Date/Heure')),
          DataColumn(label: Text('T°C')),
          DataColumn(label: Text('TA')),
          DataColumn(label: Text('FC')),
          DataColumn(label: Text('Poids')),
          DataColumn(label: Text('Taille')),
          DataColumn(label: Text('IMC')),
          DataColumn(label: Text('Action')),
        ],
        rows: _vitalsHistory.map((vitals) {
          final dateTime = DateFormat('dd/MM HH:mm').format(vitals.recordedAt);
          final imc = vitals.poids != null && vitals.taille != null
              ? (vitals.poids! / ((vitals.taille! / 100) * (vitals.taille! / 100)))
                  .toStringAsFixed(1)
              : 'N/A';
          return DataRow(
            cells: [
              DataCell(Text(vitals.patientId)),
              DataCell(Text(dateTime)),
              DataCell(Text('${vitals.temperature}°C')),
              DataCell(Text('${vitals.tensionSystolique}/${vitals.tensionDiastolique}')),
              DataCell(Text('${vitals.frequenceCardiaque} bpm')),
              DataCell(Text('${vitals.poids ?? 'N/A'} kg')),
              DataCell(Text('${vitals.taille ?? 'N/A'} cm')),
              DataCell(Text(imc)),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editVitals(vitals),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteVitals(vitals),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getImcColor(double imc) {
    if (imc < 18.5) return Colors.blue;
    if (imc < 25) return Colors.green;
    if (imc < 30) return Colors.orange;
    return Colors.red;
  }

  String _getImcCategory(double imc) {
    if (imc < 18.5) return 'Insuffisant';
    if (imc < 25) return 'Normal';
    if (imc < 30) return 'Surpoids';
    return 'Obésité';
  }
}
