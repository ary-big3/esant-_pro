import 'package:flutter/foundation.dart';
import '../models/patient_model.dart';
import 'api_service.dart';

/// Service pour gérer les patients et leurs profils
/// 
/// Intégration avec l'API Backend:
/// - Base URL: http://localhost/esante/backend/public
/// - Endpoints principaux utilisés:
///   - GET /patient/profile (récupérer mon profil)
///   - PUT /patient/profile (mettre à jour mon profil)
///   - GET /patient/{id}/profile (récupérer profil d'un patient)
///   - GET /medical-dossier/{id}/summary (résumé médical)
///   - GET /medical-dossier/{id}/consultations (consultations)
///   - GET /medical-dossier/{id}/exams (examens)
///   - GET /medical-dossier/{id}/vaccinations (vaccinations)
///   - PUT /medical-dossier/medical-history (antécédents)
class PatientService {
  static final ApiService _apiService = ApiService();

  /// Récupérer le profil du patient actuel
  static Future<PatientModel> getMyProfile() async {
    try {
      final response = await _apiService.get(
        '/patient/profile',
        requireAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        return PatientModel.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Erreur lors de la récupération du profil');
      }
    } catch (e) {
      if (kDebugMode) print('Erreur getMyProfile: $e');
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  /// Inscrire un nouveau patient (NON UTILISÉ - utiliser AuthService.register)
  /// 
  /// Paramètres:
  ///   - userData: Informations utilisateur de base
  ///   - patientData: Informations spécifiques au patient
  /// 
  /// Retourne un PatientModel avec les données sauvegardées
  static Future<PatientModel> registerPatient({
    required Map<String, dynamic> userData,
    required Map<String, dynamic> patientData,
  }) async {
    try {
      // Préparer les données complètes
      final fullName = '${userData['prenom']?.toString() ?? ''} ${userData['nom']?.toString() ?? ''}'.trim();
      
      final registerData = {
        'email': userData['email'],
        'password': userData['password'],
        'full_name': fullName,
        'phone': userData['telephone'],
        'role': 'patient',
        if (userData['sexe'] != null) 'gender': userData['sexe'],
        if (userData['date_naissance'] != null) 'date_of_birth': userData['date_naissance'],
        if (patientData['groupe_sanguin'] != null) 'blood_group': patientData['groupe_sanguin'],
        if (userData['adresse'] != null) 'address': userData['adresse'],
      };

      final response = await ApiService().post(
        '/auth/register',
        body: registerData,
        requireAuth: false,
      );

      if (response['success'] == true && response['data'] != null) {
        return PatientModel.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Erreur lors de l\'inscription');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  /// Récupérer le profil d'un patient par ID
  static Future<PatientModel> getPatientProfile(String patientId) async {
    try {
      // TODO: Implémenter l'appel API réel
      // final response = await http.get(
      //   Uri.parse('https://api.hopital.local/api/patients/$patientId'),
      //   headers: {'Authorization': 'Bearer $token'},
      // );

      // Données simulées pour la démo
      final mockData = {
        'id': patientId,
        'user_id': patientId,
        'email': 'amadou.diallo@email.com',
        'nom': 'Diallo',
        'prenom': 'Amadou',
        'telephone': '+221771234567',
        'adresse': 'Rue 1, Dakar',
        'date_naissance': '1990-01-15',
        'sexe': 'M',
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 365)).toIso8601String(),
        'groupe_sanguin': 'A+',
        'nfc_card_id': 'NFC-2026-0001',
        'numero_securite_sociale': '1960101123456',
        'allergies': ['Pénicilline'],
        'antecedents': ['Hypertension'],
        'poids': 75.0,
        'taille': 180.0,
        'personne_urgence': 'Aissatou Diallo',
        'telephone_urgence': '+221779876543',
      };

      return PatientModel.fromJson(mockData);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  /// Mettre à jour le profil d'un patient
  static Future<PatientModel> updatePatientProfile(
    String patientId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      // TODO: Implémenter l'appel API réel
      // final response = await http.put(
      //   Uri.parse('https://api.hopital.local/api/patients/$patientId'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $token',
      //   },
      //   body: jsonEncode(updateData),
      // );

      // Pour la démo, retourner les données mises à jour
      final updatedData = {
        'id': patientId,
        ...updateData,
        'derniere_mise_a_jour': DateTime.now().toIso8601String(),
      };

      return PatientModel.fromJson(updatedData);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  /// Mettre à jour les allergies d'un patient
  static Future<List<String>> updatePatientAllergies(
    String patientId,
    List<String> allergies,
  ) async {
    try {
      // TODO: Implémenter l'appel API réel
      // final response = await http.put(
      //   Uri.parse('https://api.hopital.local/api/patients/$patientId/allergies'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $token',
      //   },
      //   body: jsonEncode({'allergies': allergies}),
      // );

      return allergies;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des allergies: $e');
    }
  }

  /// Mettre à jour les antécédents d'un patient
  static Future<List<String>> updatePatientAntecedents(
    String patientId,
    List<String> antecedents,
  ) async {
    try {
      // TODO: Implémenter l'appel API réel
      // final response = await http.put(
      //   Uri.parse('https://api.hopital.local/api/patients/$patientId/antecedents'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $token',
      //   },
      //   body: jsonEncode({'antecedents': antecedents}),
      // );

      return antecedents;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des antécédents: $e');
    }
  }

  /// Mettre à jour les antécédents familiaux d'un patient
  static Future<List<String>> updatePatientFamilyHistory(
    String patientId,
    List<String> familyHistory,
  ) async {
    try {
      // TODO: Implémenter l'appel API réel
      // final response = await http.put(
      //   Uri.parse('https://api.hopital.local/api/patients/$patientId/family-history'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $token',
      //   },
      //   body: jsonEncode({'family_history': familyHistory}),
      // );

      return familyHistory;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des antécédents familiaux: $e');
    }
  }

  /// Mettre à jour les maladies chroniques d'un patient
  static Future<List<String>> updatePatientChronicDiseases(
    String patientId,
    List<String> chronicDiseases,
  ) async {
    try {
      // TODO: Implémenter l'appel API réel
      // final response = await http.put(
      //   Uri.parse('https://api.hopital.local/api/patients/$patientId/chronic-diseases'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $token',
      //   },
      //   body: jsonEncode({'chronic_diseases': chronicDiseases}),
      // );

      return chronicDiseases;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des maladies chroniques: $e');
    }
  }

  /// Mettre à jour l'historique médical complet (antécédents, allergies, etc.)
  /// 
  /// Cet appel sauvegarde tous les antécédents médicaux dans la base de données
  /// et les met à disposition du médecin
  static Future<Map<String, dynamic>> updateMedicalHistory(
    String patientId,
    Map<String, dynamic> medicalData,
  ) async {
    try {
      final body = {
        'patient_id': patientId,
        'medical_conditions': medicalData['antecedentsMedicaux'] ?? '',
        'family_history': medicalData['antecedentsFamiliaux'] ?? '',
        'blood_group': medicalData['groupeSanguin'] ?? null,
        'chronic_diseases': medicalData['maladieCchronique'] ?? [],
        'known_allergies': medicalData['allergies'] ?? [],
      };

      final response = await _apiService.put(
        '/medical-dossier/medical-history',
        body: body,
        requireAuth: true,
      );

      if (response['success'] == true) {
        return response['data'] ?? {};
      } else {
        throw Exception(response['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      if (kDebugMode) print('Erreur updateMedicalHistory: $e');
      throw Exception('Erreur lors de la mise à jour des antécédents: $e');
    }
  }

  /// Récupérer l'historique médical d'un patient
  /// 
  /// Récupère tous les antécédents, allergies, maladies chroniques, etc.
  static Future<Map<String, dynamic>> getMedicalHistory(String patientId) async {
    try {
      final response = await _apiService.get(
        '/medical-dossier/$patientId/summary',
        requireAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        return response['data'];
      } else {
        return {}; // Retourner un vide si aucune donnée
      }
    } catch (e) {
      if (kDebugMode) print('Erreur getMedicalHistory: $e');
      return {}; // Retourner un vide en cas d'erreur
    }
  }

  /// Récupérer les consultations d'un patient
  /// 
  /// Retourne une liste paginée de consultations avec les détails du médecin
  static Future<List<Map<String, dynamic>>> getPatientConsultations(
    String patientId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '/patient/$patientId/consultations?page=$page&limit=$limit',
        requireAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        if (response['data'] is List) {
          return List<Map<String, dynamic>>.from(response['data']);
        } else if (response['data']['data'] is List) {
          return List<Map<String, dynamic>>.from(response['data']['data']);
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Erreur getPatientConsultations: $e');
      return [];
    }
  }

  /// Obtenir l'IMC d'un patient
  /// 
  /// Formule: IMC = poids (kg) / (taille (m) ^ 2)
  static double calculateIMC(double poids, double taille) {
    if (taille <= 0) return 0;
    final tailleEnMetres = taille / 100;
    return poids / (tailleEnMetres * tailleEnMetres);
  }

  /// Obtenir la catégorie d'IMC
  static String getIMCCategory(double imc) {
    if (imc < 18.5) return 'Insuffisance pondérale';
    if (imc < 25) return 'Poids normal';
    if (imc < 30) return 'Surpoids';
    if (imc < 35) return 'Obésité modérée';
    if (imc < 40) return 'Obésité sévère';
    return 'Obésité morbide';
  }

  /// Valider l'email
  static bool isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Valider le téléphone
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[\+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,9}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Valider le mot de passe
  /// 
  /// Critères:
  /// - Au minimum 8 caractères
  /// - Au moins une lettre majuscule (optionnel)
  /// - Au moins une lettre minuscule (optionnel)
  /// - Au moins un chiffre (optionnel)
  static bool isValidPassword(String password) {
    return password.length >= 8;
  }

  /// Vérifier l'existence d'un email
  static Future<bool> checkEmailExists(String email) async {
    try {
      // TODO: Implémenter l'appel API réel
      // final response = await http.get(
      //   Uri.parse('https://api.hopital.local/api/auth/check-email?email=$email'),
      // );

      return false; // Simulé
    } catch (e) {
      throw Exception('Erreur lors de la vérification de l\'email: $e');
    }
  }

  /// Supprimer un patient (avec consentement)
  static Future<bool> deletePatientAccount(String patientId) async {
    try {
      // TODO: Implémenter l'appel API réel
      // final response = await http.delete(
      //   Uri.parse('https://api.hopital.local/api/patients/$patientId'),
      //   headers: {'Authorization': 'Bearer $token'},
      // );

      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression du compte: $e');
    }
  }

  /// Exporter les données médicales d'un patient (RGPD)
  static Future<String> exportPatientData(String patientId) async {
    try {
      // TODO: Implémenter l'appel API réel
      final mockJson = '''{
  "patient_id": "$patientId",
  "nom": "Diallo",
  "prenom": "Amadou",
  "email": "amadou.diallo@email.com",
  "telephone": "+221771234567",
  "adresse": "Rue 1, Dakar",
  "date_naissance": "1990-01-15",
  "sexe": "M",
  "groupe_sanguin": "A+",
  "poids": 75.0,
  "taille": 180.0,
  "imc": 23.15,
  "allergies": ["Pénicilline"],
  "antecedents": ["Hypertension"],
  "data_export_date": "${DateTime.now().toIso8601String()}"
}''';
      return mockJson;
    } catch (e) {
      throw Exception('Erreur lors de l\'export des données: $e');
    }
  }
}

/// Provider pour les notifications
class PatientNotificationService {
  /// Envoyer une notification de confirmation d'inscription
  static Future<void> sendRegistrationConfirmation(String email, String nom) async {
    try {
      // TODO: Implémenter l'envoi d'email réel
      if (kDebugMode) print('[NOTIFICATION] Confirmation d\'inscription envoyée à $email pour $nom');
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la notification: $e');
    }
  }

  /// Envoyer un email de vérification
  static Future<void> sendVerificationEmail(String email, String verificationCode) async {
    try {
      // TODO: Implémenter l'envoi d'email réel
      if (kDebugMode) print('[NOTIFICATION] Email de vérification envoyé à $email (Code: $verificationCode)');
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'email de vérification: $e');
    }
  }

  /// Envoyer une alerte de modification de profil
  static Future<void> sendProfileUpdateAlert(String email, String nom) async {
    try {
      // TODO: Implémenter l'envoi d\'SMS/Email réel
      if (kDebugMode) print('[NOTIFICATION] Alerte de modification envoyée à $email pour $nom');
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'alerte: $e');
    }
  }
}

/// Exemple d'utilisation
class PatientRegistrationExample {
  static void demonstrateUsage() {
    // Exemple d'inscription
    // final userData = {
    //   'email': 'amadou.diallo@email.com',
    //   'nom': 'Diallo',
    //   'prenom': 'Amadou',
    //   'telephone': '+221771234567',
    //   'adresse': 'Rue 1, Dakar',
    //   'sexe': 'M',
    //   'date_naissance': '1990-01-15',
    // };
    //
    // final patientData = {
    //   'groupe_sanguin': 'A+',
    //   'numero_securite_sociale': '1960101123456',
    //   'allergies': ['Pénicilline'],
    //   'antecedents': ['Hypertension'],
    //   'poids': 75.0,
    //   'taille': 180.0,
    //   'nfc_card_id': 'NFC-2026-0001',
    //   'personne_urgence': 'Aissatou Diallo',
    //   'telephone_urgence': '+221779876543',
    // };
    //
    // final patient = await PatientService.registerPatient(
    //   userData: userData,
    //   patientData: patientData,
    // );
    //
    // // Envoyer confirmation
    // await PatientNotificationService.sendRegistrationConfirmation(
    //   patient.email,
    //   patient.nomComplet,
    // );
  }
}
