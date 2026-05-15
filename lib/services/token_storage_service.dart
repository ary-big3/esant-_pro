import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service de stockage sécurisé des tokens et données utilisateur
/// 
/// Utilise shared_preferences pour la persistance locale
/// Pour la production, considérer flutter_secure_storage pour un chiffrement plus robuste
/// 
/// Les données stockées incluent:
/// - Token JWT
/// - Informations utilisateur
/// - Préférences d'application
class TokenStorageService {
  // Clés de stockage
  static const String _tokenKey = 'esante_auth_token';
  static const String _userDataKey = 'esante_user_data';
  static const String _refreshTokenKey = 'esante_refresh_token';
  static const String _expiryDateKey = 'esante_token_expiry';
  static const String _roleKey = 'esante_user_role';
  static const String _emailKey = 'esante_user_email';

  SharedPreferences? _prefs;

  /// Initialiser le service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      if (kDebugMode) print('Erreur lors de l\'initialisation: $e');
    }
  }

  /// Vérifier que les prefs sont initialisées
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Sauvegarder le token JWT
  Future<void> saveToken(String token) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_tokenKey, token);
      if (kDebugMode) print('Token sauvegardé');
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la sauvegarde du token: $e');
    }
  }

  /// Récupérer le token JWT
  Future<String?> getToken() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_tokenKey);
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  /// Sauvegarder le refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_refreshTokenKey, token);
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la sauvegarde du refresh token: $e');
    }
  }

  /// Récupérer le refresh token
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la récupération du refresh token: $e');
      return null;
    }
  }

  /// Sauvegarder la date d'expiration du token
  Future<void> saveTokenExpiry(DateTime expiryDate) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_expiryDateKey, expiryDate.toIso8601String());
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la sauvegarde de la date d\'expiration: $e');
    }
  }

  /// Récupérer la date d'expiration du token
  Future<DateTime?> getTokenExpiry() async {
    try {
      final prefs = await _getPrefs();
      final expiryString = prefs.getString(_expiryDateKey);
      if (expiryString != null) {
        return DateTime.parse(expiryString);
      }
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la récupération de la date d\'expiration: $e');
    }
    return null;
  }

  /// Vérifier si le token est expiré
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  /// Sauvegarder les données utilisateur (JSON format)
  Future<void> saveUserData(String userDataJson) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_userDataKey, userDataJson);
      if (kDebugMode) print('Données utilisateur sauvegardées');
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la sauvegarde des données utilisateur: $e');
    }
  }

  /// Récupérer les données utilisateur (JSON format)
  Future<String?> getUserData() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_userDataKey);
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la récupération des données utilisateur: $e');
      return null;
    }
  }

  /// Sauvegarder le rôle utilisateur
  Future<void> saveUserRole(String role) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_roleKey, role);
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la sauvegarde du rôle: $e');
    }
  }

  /// Récupérer le rôle utilisateur
  Future<String?> getUserRole() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_roleKey);
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la récupération du rôle: $e');
      return null;
    }
  }

  /// Sauvegarder l'email utilisateur
  Future<void> saveUserEmail(String email) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_emailKey, email);
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la sauvegarde de l\'email: $e');
    }
  }

  /// Récupérer l'email utilisateur
  Future<String?> getUserEmail() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_emailKey);
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la récupération de l\'email: $e');
      return null;
    }
  }

  /// Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la vérification de la connexion: $e');
      return false;
    }
  }

  /// Nettoyer toutes les données (logout)
  Future<void> clearAll() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userDataKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_expiryDateKey);
      await prefs.remove(_roleKey);
      await prefs.remove(_emailKey);
      if (kDebugMode) print('Toutes les données supprimées');
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la suppression des données: $e');
    }
  }

  /// Nettoyer uniquement le token (pour les tests)
  Future<void> clearToken() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_tokenKey);
      if (kDebugMode) print('Token supprimé');
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la suppression du token: $e');
    }
  }

  /// Obtenir toutes les données stockées (DEBUG ONLY)
  Future<Map<String, dynamic>> getAllData() async {
    try {
      final prefs = await _getPrefs();
      final token = prefs.getString(_tokenKey);
      final userData = prefs.getString(_userDataKey);
      final role = prefs.getString(_roleKey);
      final email = prefs.getString(_emailKey);

      return {
        'token': token,
        'userData': userData,
        'role': role,
        'email': email,
      };
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la récupération des données: $e');
      return {};
    }
  }
}
