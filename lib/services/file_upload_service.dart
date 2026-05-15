import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'api_service.dart';

/// Service pour gérer les uploads de fichiers
class FileUploadService {
  final ApiService _apiService = ApiService();
  static const String _baseUrl = '/uploads';

  /// Uploader un fichier pour les résultats d'examen
  Future<Map<String, dynamic>> uploadExamResultFile(
    String examId,
    File file,
  ) async {
    try {
      final token = _apiService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final uri = Uri.parse('${ApiService.baseUrl}$_baseUrl/exam-results');
      
      // Créer la requête multipart
      final request = http.MultipartRequest('POST', uri);
      
      // Ajouter le token
      request.headers['Authorization'] = 'Bearer $token';
      
      // Ajouter les paramètres
      request.fields['exam_id'] = examId;
      
      // Ajouter le fichier
      request.files.add(
        http.MultipartFile(
          'file',
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: p.basename(file.path),
        ),
      );

      // Envoyer la requête
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erreur upload: ${response.statusCode} - $responseBody');
      }

      // Parser la réponse JSON
      final jsonResponse = jsonDecode(responseBody);
      
      return {
        'success': true,
        'file_path': jsonResponse['file_path'] ?? '',
        'file_url': jsonResponse['file_url'] ?? '',
        'file_name': p.basename(file.path),
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Uploader plusieurs fichiers
  Future<List<Map<String, dynamic>>> uploadMultipleFiles(
    String examId,
    List<File> files,
  ) async {
    final List<Map<String, dynamic>> results = [];
    
    for (final file in files) {
      try {
        final result = await uploadExamResultFile(examId, file);
        results.add(result);
      } catch (e) {
        results.add({
          'success': false,
          'file_name': p.basename(file.path),
          'error': e.toString(),
        });
      }
    }
    
    return results;
  }
}
