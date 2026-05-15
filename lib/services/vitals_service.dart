import 'package:flutter/foundation.dart';
import '../models/vitals_model.dart';
import 'api_service.dart';

/// Service pour gérer les constantes vitales enregistrées par les infirmières
/// Utilise l'API backend pour persister les données
class VitalsService {
  static final ApiService _apiService = ApiService();

  /// Créer un enregistrement de constantes vitales
  /// Sauvegarde directement dans la base de données via l'API backend
  static Future<VitalsModel> recordVitals({
    required String patientId,
    required double temperature,
    required int tensionSystolique,
    required int tensionDiastolique,
    required int frequenceCardiaque,
    required int frequenceRespiratoire,
    required double saturOxygene,
    double? poids,
    double? taille,
    String? notes,
  }) async {
    try {
      if (kDebugMode) {
        print('📝 [VitalsService.recordVitals] Sauvegarde des vitales pour patient: $patientId');
      }

      final response = await _apiService.post(
        '/nurse/vitals',
        body: {
          'patient_id': int.tryParse(patientId) ?? 0,
          'temperature_celsius': temperature,
          'systolic_pressure': tensionSystolique,
          'diastolic_pressure': tensionDiastolique,
          'pulse_bpm': frequenceCardiaque,
          'respiratory_rate': frequenceRespiratoire,
          'oxygen_saturation': saturOxygene,
          if (poids != null) 'weight_kg': poids,
          if (taille != null) 'height_cm': taille,
          if (notes != null) 'notes': notes,
        },
        requireAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        if (kDebugMode) {
          print('✅ [VitalsService.recordVitals] Vitales sauvegardées avec succès');
        }

        final now = DateTime.now();
        return VitalsModel(
          id: (response['data']['vital_sign_id'] ?? now.millisecondsSinceEpoch).toString(),
          patientId: patientId,
          nurseId: '', // Récupéré par le backend automatiquement
          temperature: temperature,
          tensionSystolique: tensionSystolique,
          tensionDiastolique: tensionDiastolique,
          frequenceCardiaque: frequenceCardiaque,
          frequenceRespiratoire: frequenceRespiratoire,
          saturOxygene: saturOxygene,
          poids: poids,
          taille: taille,
          notes: notes,
          recordedAt: now,
          createdAt: now,
        );
      } else {
        throw Exception(response['message'] ?? 'Erreur lors de l\'enregistrement');
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        print('❌ [VitalsService.recordVitals] Erreur API: ${e.message}');
      }
      throw Exception('Erreur: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('❌ [VitalsService.recordVitals] Erreur: $e');
      }
      throw Exception('Erreur lors de l\'enregistrement des constantes: $e');
    }
  }

  /// Récupérer l'historique des constantes vitales d'un patient
  /// Récupère les données du backend
  static Future<List<VitalsModel>> getPatientVitalsHistory(
    String patientId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      if (kDebugMode) {
        print('📊 [VitalsService.getPatientVitalsHistory] Récupération des vitales pour patient: $patientId');
      }

      final patientIdInt = int.tryParse(patientId) ?? 0;
      if (patientIdInt == 0 && patientId.isNotEmpty) {
        if (kDebugMode) {
          print('⚠️ [VitalsService] Patient ID invalid: $patientId');
        }
        return [];
      }

      final response = await _apiService.get(
        '/nurse/vitals/$patientId?page=$page&limit=$limit',
        requireAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        final vitalsData = List<Map<String, dynamic>>.from(response['data'] as List);
        
        if (kDebugMode) {
          print('✅ [VitalsService] ${vitalsData.length} vitales récupérées');
        }

        return vitalsData
            .map((data) => VitalsModel.fromJson(data))
            .toList();
      } else {
        if (kDebugMode) {
          print('⚠️ [VitalsService] Aucunes vitales trouvées');
        }
        return [];
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        print('❌ [VitalsService.getPatientVitalsHistory] Erreur API: ${e.message}');
      }
      // Retourner une liste vide au lieu de lever une exception
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ [VitalsService.getPatientVitalsHistory] Erreur: $e');
      }
      return [];
    }
  }

  /// Récupérer les constantes vitales les plus récentes d'un patient
  static Future<VitalsModel?> getLatestVitals(String patientId) async {
    try {
      if (kDebugMode) {
        print('🔍 [VitalsService.getLatestVitals] Récupération des dernières vitales pour: $patientId');
      }

      final history = await getPatientVitalsHistory(patientId, limit: 1);
      
      if (history.isNotEmpty) {
        if (kDebugMode) {
          print('✅ [VitalsService] Dernières vitales trouvées');
        }
        return history.first;
      } else {
        if (kDebugMode) {
          print('⚠️ [VitalsService] Aucune vitale trouvée');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [VitalsService.getLatestVitals] Erreur: $e');
      }
      return null;
    }
  }

  /// Mettre à jour les constantes vitales
  static Future<void> updateVitals(
    String vitalId, {
    required double temperature,
    required int tensionSystolique,
    required int tensionDiastolique,
    required int frequenceCardiaque,
    required int frequenceRespiratoire,
    required double saturOxygene,
    double? poids,
    double? taille,
    String? notes,
  }) async {
    try {
      if (kDebugMode) {
        print('✏️ [VitalsService.updateVitals] Mise à jour de la vitale: $vitalId');
      }

      final response = await _apiService.put(
        '/nurse/vitals/$vitalId',
        body: {
          'temperature_celsius': temperature,
          'systolic_pressure': tensionSystolique,
          'diastolic_pressure': tensionDiastolique,
          'pulse_bpm': frequenceCardiaque,
          'respiratory_rate': frequenceRespiratoire,
          'oxygen_saturation': saturOxygene,
          if (poids != null) 'weight_kg': poids,
          if (taille != null) 'height_cm': taille,
          if (notes != null) 'notes': notes,
        },
        requireAuth: true,
      );

      if (response['success'] == true) {
        if (kDebugMode) {
          print('✅ [VitalsService.updateVitals] Vitales mises à jour avec succès');
        }
      } else {
        throw Exception(response['message'] ?? 'Erreur lors de la mise à jour');
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        print('❌ [VitalsService.updateVitals] Erreur API: ${e.message}');
      }
      throw Exception('Erreur: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('❌ [VitalsService.updateVitals] Erreur: $e');
      }
      throw Exception('Erreur lors de la mise à jour des constantes: $e');
    }
  }

  /// Supprimer les constantes vitales
  static Future<void> deleteVitals(String vitalId) async {
    try {
      if (kDebugMode) {
        print('🗑️ [VitalsService.deleteVitals] Suppression de la vitale: $vitalId');
      }

      final response = await _apiService.delete(
        '/nurse/vitals/$vitalId',
        requireAuth: true,
      );

      if (response['success'] == true) {
        if (kDebugMode) {
          print('✅ [VitalsService.deleteVitals] Vitales supprimées avec succès');
        }
      } else {
        throw Exception(response['message'] ?? 'Erreur lors de la suppression');
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        print('❌ [VitalsService.deleteVitals] Erreur API: ${e.message}');
      }
      throw Exception('Erreur: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('❌ [VitalsService.deleteVitals] Erreur: $e');
      }
      throw Exception('Erreur lors de la suppression des constantes: $e');
    }
  }
}
