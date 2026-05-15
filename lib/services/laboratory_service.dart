import 'api_service.dart';

/// Service pour communiquer avec l'API laboratoire
class LaboratoryService {
  final ApiService _apiService = ApiService();
  static const String _baseUrl = '/laboratory';

  /// Récupérer le profil du laboratoire
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.get('$_baseUrl/profile');
      return response['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les examens en attente
  Future<Map<String, dynamic>> getPendingExams({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.get(
        '$_baseUrl/exams/pending',
        params: {'page': page, 'limit': limit},
      );
      return {
        'exams': (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        'total': response['total'] ?? 0,
        'page': response['page'] ?? 1,
        'limit': response['limit'] ?? 10,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les examens en cours
  Future<Map<String, dynamic>> getInProgressExams({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.get(
        '$_baseUrl/exams/in-progress',
        params: {'page': page, 'limit': limit},
      );
      return {
        'exams': (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        'total': response['total'] ?? 0,
        'page': response['page'] ?? 1,
        'limit': response['limit'] ?? 10,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les examens complétés
  Future<Map<String, dynamic>> getCompletedExams({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.get(
        '$_baseUrl/exams/completed',
        params: {'page': page, 'limit': limit},
      );
      return {
        'exams': (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        'total': response['total'] ?? 0,
        'page': response['page'] ?? 1,
        'limit': response['limit'] ?? 10,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Accepter un examen
  Future<Map<String, dynamic>> acceptExam(String examId) async {
    try {
      final response = await _apiService.post(
        '$_baseUrl/exams/$examId/accept',
        body: {},
      );
      return response['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// Rejeter un examen
  Future<Map<String, dynamic>> rejectExam(String examId, String raison) async {
    try {
      final response = await _apiService.post(
        '$_baseUrl/exams/$examId/reject',
        body: {'raison': raison},
      );
      return response['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// Démarrer l'examen
  Future<Map<String, dynamic>> startExam(String examId) async {
    try {
      final response = await _apiService.post(
        '$_baseUrl/exams/$examId/start',
        body: {},
      );
      return response['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// Enregistrer les résultats de l'examen
  Future<Map<String, dynamic>> recordExamResults(
    String examId, {
    required String resultats,
    String? commentaires,
    String? fichierResultats,
  }) async {
    try {
      final response = await _apiService.post(
        '$_baseUrl/exams/$examId/record-results',
        body: {
          'resultats': resultats,
          'commentaires': commentaires,
          'fichier_resultats': fichierResultats,
        },
      );
      return response['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les prescriptions en attente
  Future<Map<String, dynamic>> getPendingPrescriptions({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.get(
        '$_baseUrl/prescriptions/pending',
        params: {'page': page, 'limit': limit},
      );
      return {
        'prescriptions': (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        'total': response['total'] ?? 0,
        'page': response['page'] ?? 1,
        'limit': response['limit'] ?? 10,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Uploader un document résultat (PDF/image) pour un examen
  Future<Map<String, dynamic>> uploadResultDocument(
    String examId,
    List<int> fileBytes,
    String fileName, {
    String? description,
  }) async {
    try {
      final response = await _apiService.multipartPostBytes(
        '$_baseUrl/documents/upload',
        bytes: fileBytes,
        fileName: fileName,
        fields: {
          'exam_id': examId,
          'description': description ?? '',
        },
      );
      return response['data'] ?? response;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtenir les statistiques du laboratoire
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _apiService.get('$_baseUrl/statistics');
      return response['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }
}
