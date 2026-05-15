import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/vitals_service.dart';

/// Page de diagnostic pour tester l'API des vitales
class DebugVitalsScreen extends StatefulWidget {
  const DebugVitalsScreen({Key? key}) : super(key: key);

  @override
  State<DebugVitalsScreen> createState() => _DebugVitalsScreenState();
}

class _DebugVitalsScreenState extends State<DebugVitalsScreen> {
  final _patientIdController = TextEditingController();
  String _debugOutput = '';
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _debugOutput += '\n[${DateTime.now().toIso8601String()}] $message';
    });
    if (kDebugMode) {
      print(message);
    }
  }

  void _clearLogs() {
    setState(() => _debugOutput = '');
  }

  Future<void> _testGetVitalsHistory() async {
    final patientId = _patientIdController.text.trim();
    if (patientId.isEmpty) {
      _addLog('❌ ERREUR: Patient ID vide');
      return;
    }

    _addLog('🔍 TEST 1: Récupération de l\'historique pour patient $patientId');
    setState(() => _isLoading = true);

    try {
      final vitals = await VitalsService.getPatientVitalsHistory(
        patientId,
        limit: 10,
      );
      
      _addLog('✅ Réponse reçue: ${vitals.length} vitales trouvées');
      
      if (vitals.isEmpty) {
        _addLog('⚠️ Liste vide - aucune vitale pour ce patient');
      } else {
        for (int i = 0; i < vitals.length; i++) {
          final v = vitals[i];
          _addLog('  Vitale $i: ID=${v.id}, Temp=${v.temperature}°C, Date=${v.recordedAt}');
        }
      }
    } catch (e) {
      _addLog('❌ ERREUR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetLatestVitals() async {
    final patientId = _patientIdController.text.trim();
    if (patientId.isEmpty) {
      _addLog('❌ ERREUR: Patient ID vide');
      return;
    }

    _addLog('🔍 TEST 2: Récupération de la dernière vitale pour patient $patientId');
    setState(() => _isLoading = true);

    try {
      final vital = await VitalsService.getLatestVitals(patientId);
      
      if (vital == null) {
        _addLog('⚠️ Aucune vitale trouvée');
      } else {
        _addLog('✅ Vitale trouvée:');
        _addLog('  - ID: ${vital.id}');
        _addLog('  - Patient: ${vital.patientId}');
        _addLog('  - Température: ${vital.temperature}°C');
        _addLog('  - TA: ${vital.tensionSystolique}/${vital.tensionDiastolique}');
        _addLog('  - FC: ${vital.frequenceCardiaque} bpm');
        _addLog('  - Date: ${vital.recordedAt}');
      }
    } catch (e) {
      _addLog('❌ ERREUR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testQueryDatabase() async {
    final patientId = _patientIdController.text.trim();
    if (patientId.isEmpty) {
      _addLog('❌ ERREUR: Patient ID vide');
      return;
    }

    _addLog('🔍 TEST 3: Vérification directe en base de données');
    _addLog('SELECT * FROM vital_signs WHERE patient_id = $patientId ORDER BY measurement_date DESC;');
    
    // On ne peut pas directement interroger la DB depuis Flutter
    // Mais on peut voir les détails dans les logs
    _addLog('⚠️ Veuillez vérifier manuellement en phpMyAdmin:');
    _addLog('  1. Ouvrir phpMyAdmin');
    _addLog('  2. Sélectionner DB: esante_db');
    _addLog('  3. Table: vital_signs');
    _addLog('  4. Filtrer: patient_id = $patientId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐛 Debug - API Vitales'),
        backgroundColor: Colors.red[700],
      ),
      body: Column(
        children: [
          // Section: Entrée Patient ID
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Patient ID:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _patientIdController,
                  decoration: InputDecoration(
                    hintText: 'Ex: 1, 2, 3...',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _patientIdController.clear,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),

          // Section: Boutons de test
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testGetVitalsHistory,
                  icon: const Icon(Icons.search),
                  label: const Text('Test: Historique Vitales'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testGetLatestVitals,
                  icon: const Icon(Icons.update),
                  label: const Text('Test: Dernière Vitale'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testQueryDatabase,
                  icon: const Icon(Icons.storage),
                  label: const Text('Test: Base de Données'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),

          // Section: Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Logs',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.green, size: 20),
                        onPressed: _clearLogs,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.green),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _debugOutput.isEmpty ? 'En attente de tests...' : _debugOutput,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section: Status
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: const CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    super.dispose();
  }
}
