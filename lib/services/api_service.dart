import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service API central pour gérer tous les appels HTTP vers le backend
/// 
/// Configuration:
/// - Base URL: http://192.168.8.104/esante/backend/public
/// - Format: JSON
/// - Authentification: Bearer Token JWT
/// - Headers: Content-Type: application/json
class ApiService {
  // Configuration
  static const String baseUrl = 'https://backend-u74a.onrender.com';
  static const String apiVersion = 'v1';
  static const Duration timeout = Duration(seconds: 7);

  // Instance singleton
  static final ApiService _instance = ApiService._internal();

  // Headers par défaut
  Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Token JWT (défini lors de l'authentification)
  String? _token;

  ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  /// Définir le token JWT
  void setToken(String token) {
    _token = token;
    if (kDebugMode) {
      print('🔑 [ApiService] Token défini: ${token.substring(0, 20)}...');
      print('   Longueur: ${token.length} caractères');
    }
  }

  /// Récupérer le token JWT
  String? getToken() {
    if (kDebugMode && _token != null) {
      print('🔑 [ApiService] Token récupéré: ${_token!.substring(0, 20)}...');
    } else if (kDebugMode) {
      print('⚠️ [ApiService] Token est NULL!');
    }
    return _token;
  }

  /// Getter pour accéder au token (alias pour getToken)
  String? get token => _token;

  /// Nettoyer le token (logout)
  void clearToken() {
    _token = null;
  }

  /// Obtenir les headers avec token si disponible
  Map<String, String> _getHeaders({bool requireAuth = true}) {
    final headers = Map<String, String>.from(_defaultHeaders);
    
    if (requireAuth) {
      if (_token != null) {
        headers['Authorization'] = 'Bearer $_token';
        if (kDebugMode) {
          print('✅ [ApiService] Header Authorization ajouté: Bearer ${_token!.substring(0, 20)}...');
        }
      } else {
        if (kDebugMode) {
          print('❌ [ApiService] Token est NULL - pas de header Authorization!');
        }
      }
    }
    
    return headers;
  }

  /// GET request
  /// 
  /// Paramètres:
  /// - [endpoint]: L'endpoint API (ex: '/patient/profile')
  /// - [requireAuth]: Nécessite l'authentification (par défaut: true)
  /// - [params]: Paramètres de requête (optionnel)
  /// 
  /// Retourne: Réponse JSON
  Future<dynamic> get(
    String endpoint, {
    bool requireAuth = true,
    Map<String, dynamic>? params,
  }) async {
    try {
      final uri = _buildUri(endpoint, params);
      if (kDebugMode) print('GET $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(requireAuth: requireAuth),
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) print('GET Error: $e');
      throw Exception('Erreur GET $endpoint: $e');
    }
  }

  /// POST request
  /// 
  /// Paramètres:
  /// - [endpoint]: L'endpoint API
  /// - [body]: Corps de la requête
  /// - [requireAuth]: Nécessite l'authentification
  /// 
  /// Retourne: Réponse JSON
  Future<dynamic> post(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requireAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      if (kDebugMode) print('🔵 [POST] Début - URI: $uri');
      if (kDebugMode) print('🔵 [POST] Body (raw): $body');
      
      final jsonBody = jsonEncode(body);
      if (kDebugMode) print('🔵 [POST] Body (JSON): $jsonBody');

      final response = await http.post(
        uri,
        headers: _getHeaders(requireAuth: requireAuth),
        body: jsonBody,
      ).timeout(timeout);

      if (kDebugMode) print('🟢 [POST] Réponse reçue - Code: ${response.statusCode}');
      if (kDebugMode) print('🟢 [POST] Body length: ${response.body.length}');
      if (kDebugMode) print('🟢 [POST] Réponse brute: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) print('❌ [POST] Exception: $e');
      throw Exception('Erreur POST $endpoint: $e');
    }
  }

  /// PUT request
  /// 
  /// Paramètres:
  /// - [endpoint]: L'endpoint API
  /// - [body]: Corps de la requête
  /// - [requireAuth]: Nécessite l'authentification
  /// 
  /// Retourne: Réponse JSON
  Future<dynamic> put(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requireAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      if (kDebugMode) print('PUT $uri with body: $body');

      final response = await http.put(
        uri,
        headers: _getHeaders(requireAuth: requireAuth),
        body: jsonEncode(body),
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) print('PUT Error: $e');
      throw Exception('Erreur PUT $endpoint: $e');
    }
  }

  /// DELETE request
  /// 
  /// Paramètres:
  /// - [endpoint]: L'endpoint API
  /// - [requireAuth]: Nécessite l'authentification
  /// 
  /// Retourne: Réponse JSON
  Future<dynamic> delete(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      if (kDebugMode) print('DELETE $uri');

      final response = await http.delete(
        uri,
        headers: _getHeaders(requireAuth: requireAuth),
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) print('DELETE Error: $e');
      throw Exception('Erreur DELETE $endpoint: $e');
    }
  }

  /// Construire l'URI complète
  Uri _buildUri(String endpoint, [Map<String, dynamic>? params]) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final urlString = '$baseUrl$path';

    if (params != null && params.isNotEmpty) {
      // Filtrer les paramètres null
      final filteredParams = {
        for (var key in params.keys)
          if (params[key] != null) key: params[key].toString()
      };
      return Uri.parse(urlString).replace(queryParameters: filteredParams);
    }

    return Uri.parse(urlString);
  }

  /// Gérer la réponse HTTP
  dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('🔵 [_handleResponse] Status Code: ${response.statusCode}');
      print('🔵 [_handleResponse] Body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
    }

    try {
      final jsonResponse = jsonDecode(response.body);
      if (kDebugMode) print('🟢 [_handleResponse] JSON decoded successfully');

      // Vérifier le format standard de réponse
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Succès
        if (jsonResponse is Map && jsonResponse.containsKey('success')) {
          if (jsonResponse['success'] == true) {
            if (kDebugMode) print('✅ [_handleResponse] Success true');
            return jsonResponse;
          } else {
            if (kDebugMode) print('❌ [_handleResponse] Success false: ${jsonResponse['message']}');
            throw ApiException(
              message: jsonResponse['message'] ?? 'Erreur API',
              statusCode: response.statusCode,
              errors: jsonResponse['errors'],
            );
          }
        }
        return jsonResponse;
      } else {
        // Erreur
        if (kDebugMode) print('❌ [_handleResponse] HTTP Error ${response.statusCode}');
        throw ApiException(
          message: jsonResponse['message'] ?? 'Erreur serveur',
          statusCode: response.statusCode,
          errors: jsonResponse['errors'],
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ [_handleResponse] Exception: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Erreur de parsing JSON: $e',
        statusCode: response.statusCode,
      );
    }
  }

  /// POST request avec upload de fichier (multipart/form-data)
  /// 
  /// Paramètres:
  /// - [endpoint]: L'endpoint API
  /// - [file]: Le fichier à uploader
  /// - [fields]: Les champs additionnels du formulaire
  /// 
  /// Retourne: Réponse JSON
  Future<dynamic> multipartPost(
    String endpoint, {
    required File file,
    Map<String, String>? fields,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      if (kDebugMode) print('🔵 [MULTIPART POST] Début - URI: $uri');

      // Créer la requête multipart
      var request = http.MultipartRequest('POST', uri);

      // Ajouter le token d'authentification
      final headers = _getHeaders();
      request.headers.addAll(headers);

      // Ajouter le fichier
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final filename = file.path.split(RegExp(r'[\\/]+')).last;
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: filename,
      );
      request.files.add(multipartFile);

      // Ajouter les champs additionnels
      if (fields != null) {
        request.fields.addAll(fields);
        if (kDebugMode) {
          print('🔵 [MULTIPART POST] Champs: $fields');
        }
      }

      // Envoyer la requête
      if (kDebugMode) print('🔵 [MULTIPART POST] Envoi en cours...');
      final response = await request.send().timeout(timeout);

      // Lire la réponse
      final responseBody = await response.stream.bytesToString();
      if (kDebugMode) {
        print('🟢 [MULTIPART POST] Réponse reçue - Code: ${response.statusCode}');
        print('🟢 [MULTIPART POST] Body: $responseBody');
      }

      // Créer un objet Response pour utiliser _handleResponse
      final httpResponse = http.Response(responseBody, response.statusCode);

      return _handleResponse(httpResponse);
    } catch (e) {
      if (kDebugMode) print('❌ [MULTIPART POST] Exception: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Erreur upload fichier: $e',
        statusCode: 500,
      );
    }
  }

  /// Upload multipart via bytes (cross-platform, fonctionne sur web/mobile)
  ///
  /// Paramètres:
  /// - [endpoint]: L'endpoint API
  /// - [bytes]: Les bytes du fichier
  /// - [fileName]: Le nom du fichier
  /// - [fields]: Les champs additionnels du formulaire
  ///
  /// Retourne: Réponse JSON
  Future<dynamic> multipartPostBytes(
    String endpoint, {
    required List<int> bytes,
    required String fileName,
    Map<String, String>? fields,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      if (kDebugMode) print('🔵 [MULTIPART BYTES] Début - URI: $uri');

      var request = http.MultipartRequest('POST', uri);

      final headers = _getHeaders();
      request.headers.addAll(headers);

      // Ajouter le fichier depuis les bytes
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      if (fields != null) {
        request.fields.addAll(fields);
        if (kDebugMode) {
          print('🔵 [MULTIPART BYTES] Champs: $fields');
        }
      }

      if (kDebugMode) print('🔵 [MULTIPART BYTES] Envoi en cours...');
      final response = await request.send().timeout(timeout);

      final responseBody = await response.stream.bytesToString();
      if (kDebugMode) {
        print('🟢 [MULTIPART BYTES] Réponse reçue - Code: ${response.statusCode}');
      }

      final httpResponse = http.Response(responseBody, response.statusCode);
      return _handleResponse(httpResponse);
    } catch (e) {
      if (kDebugMode) print('❌ [MULTIPART BYTES] Exception: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Erreur upload fichier: $e',
        statusCode: 500,
      );
    }
  }

  /// Vérifier la connectivité du serveur
  Future<bool> healthCheck() async {
    try {
      final response = await get('/health', requireAuth: false);
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) print('Health check failed: $e');
      return false;
    }
  }
}

/// Exception custom pour les erreurs API
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic errors;

  ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
  });

  @override
  String toString() => 'ApiException: $message (Code: $statusCode)';
}
