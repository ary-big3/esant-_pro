import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'token_storage_service.dart';
import '../models/user_model.dart';

/// Service d'authentification - Gère la connexion, l'inscription et les tokens JWT
/// 
/// Fonctionnalités:
/// - Inscription (register)
/// - Connexion (login)
/// - Déconnexion (logout)
/// - Rafraîchissement de token
/// - Gestion des tokens JWT
/// - Persistance des données utilisateur
class AuthService extends ChangeNotifier {
  // Services
  final ApiService _apiService = ApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  // Données utilisateur
  UserModel? _currentUser;
  String? _currentToken;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Singleton instance
  static final AuthService _instance = AuthService._internal();

  // Getters
  UserModel? get currentUser => _currentUser;
  String? get currentToken => _currentToken;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructeur privé pour le singleton
  AuthService._internal() {
    _initializeAuth();
  }

  // Factory pour retourner l'instance singleton
  factory AuthService() {
    return _instance;
  }

  /// Initialiser l'authentification (charger les données persistantes)
  Future<void> _initializeAuth() async {
    try {
      if (kDebugMode) print('🔄 [AuthService._initializeAuth] Chargement du token du storage...');
      
      final token = await _tokenStorage.getToken();
      final userJson = await _tokenStorage.getUserData();

      if (token != null && userJson != null) {
        if (kDebugMode) {
          print('✅ [AuthService._initializeAuth] Token trouvé en storage');
          print('   Longueur: ${token.length} caractères');
          print('   Début: ${token.substring(0, 20)}...');
        }
        
        _currentToken = token;
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        
        _apiService.setToken(token);
        if (kDebugMode) print('✅ [AuthService._initializeAuth] Token défini dans ApiService');
        
        _isAuthenticated = true;
        notifyListeners();
      } else {
        if (kDebugMode) print('⚠️ [AuthService._initializeAuth] Aucun token trouvé en storage');
      }
    } catch (e) {
      if (kDebugMode) print('❌ [AuthService._initializeAuth] Erreur: $e');
    }
  }

  /// Inscription d'un nouvel utilisateur
  /// 
  /// Paramètres:
  /// - [email]: Email de l'utilisateur
  /// - [password]: Mot de passe (min 8 caractères)
  /// - [fullName]: Nom complet
  /// - [phone]: Numéro de téléphone
  /// - [role]: Rôle (patient, medecin, infirmiere, laboratoire, admin)
  /// 
  /// Retourne: true si succès, sinon lance une exception
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.post(
        '/auth/register',
        body: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
          'role': role,
          if (gender != null) 'gender': gender,
          if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        },
        requireAuth: false,
      );

      if (response['success'] == true && response['data'] != null) {
        // Sauvegarder le token
        final token = response['data']['token'];
        _currentToken = token;
        _apiService.setToken(token);

        // Diviser fullName en nom et prenom
        List<String> nameParts = fullName.trim().split(' ');
        String prenom = nameParts.first;
        String nom = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : prenom;

        // Créer l'utilisateur
        _currentUser = UserModel(
          id: (response['data']['user_id'] ?? '').toString(),
          email: email,
          nom: nom,
          prenom: prenom,
          telephone: phone,
          role: _stringToRole(role),
          isActive: true,
          createdAt: DateTime.now(),
        );

        // Sauvegarder les données
        await _tokenStorage.saveToken(token);
        await _tokenStorage.saveUserData(jsonEncode(_currentUser!.toJson()));

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();

        return true;
      } else {
        _errorMessage = response['message'] ?? 'Erreur lors de l\'inscription';
        _isLoading = false;
        notifyListeners();
        throw Exception(_errorMessage);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      throw Exception(e.message);
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  /// Connexion d'un utilisateur existant
  /// 
  /// Paramètres:
  /// - [email]: Email de l'utilisateur
  /// - [password]: Mot de passe
  /// 
  /// Retourne: true si succès, sinon lance une exception
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
        requireAuth: false,
      );

      if (response['success'] == true && response['data'] != null) {
        // Sauvegarder le token
        final token = response['data']['token'];
        if (kDebugMode) {
          print('🔐 [AuthService.login] Token reçu du serveur');
          print('   Longueur: ${token.length} caractères');
          print('   Début: ${token.substring(0, 20)}...');
        }
        
        _currentToken = token;
        if (kDebugMode) print('✅ [AuthService.login] _currentToken défini');
        
        _apiService.setToken(token);
        if (kDebugMode) print('✅ [AuthService.login] _apiService.setToken() appelé');
        
        // Vérifier que le token a bien été stocké
        if (kDebugMode) {
          final storedToken = _apiService.getToken();
          if (storedToken != null) {
            print('✅ [AuthService.login] Vérification: token dans ApiService: ${storedToken.substring(0, 20)}...');
          } else {
            print('❌ [AuthService.login] ERREUR: token dans ApiService est NULL!');
          }
        }

        // Créer l'utilisateur (données minimales depuis la réponse)
        final userData = response['data'];
        final fullName = userData?['full_name'] ?? '';
        List<String> nameParts = fullName.trim().split(' ');
        String prenom = nameParts.isNotEmpty ? nameParts.first : '';
        String nom = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : prenom;

        _currentUser = UserModel(
          id: (userData?['user_id'] ?? '').toString(),
          email: userData?['email'] ?? email,
          nom: nom,
          prenom: prenom,
          telephone: userData?['phone']?.toString(),
          role: _stringToRole(userData?['role'] ?? 'patient'),
          isActive: userData?['is_active'] ?? true,
          createdAt: userData?['created_at'] != null
              ? DateTime.parse(userData!['created_at'].toString())
              : DateTime.now(),
        );

        // Marquer comme authentifié IMMÉDIATEMENT
        // Le token est maintenant disponible dans ApiService et AuthService
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();

        // Sauvegarder les données en arrière-plan (non-bloquant)
        _tokenStorage.saveToken(token).catchError((e) {
          if (kDebugMode) print('⚠️ Erreur sauvegarde token: $e');
        });
        _tokenStorage.saveUserData(jsonEncode(_currentUser!.toJson())).catchError((e) {
          if (kDebugMode) print('⚠️ Erreur sauvegarde données: $e');
        });

        if (kDebugMode) print('Connexion réussie: ${_currentUser?.email}');
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Erreur de connexion';
        _isLoading = false;
        notifyListeners();
        throw Exception(_errorMessage);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('ApiException: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('Auth Error: $e');
      throw Exception(_errorMessage);
    }
  }

  /// Convertir un role string du backend en UserRole enum
  UserRole _stringToRole(String roleString) {
    final role = roleString.toLowerCase();
    
    switch (role) {
      case 'admin':
      case 'ministere':
        return UserRole.admin;
      case 'medecin':
      case 'doctor':
        return UserRole.doctor;
      case 'infirmiere':
      case 'nurse':
        return UserRole.nurse;
      case 'laboratoire':
      case 'laboratory':
        return UserRole.laboratory;
      case 'patient':
      default:
        return UserRole.patient;
    }
  }

  /// Déconnexion de l'utilisateur
  Future<void> logout() async {
    try {
      // Supprimer les données stockées
      await _tokenStorage.clearAll();

      // Réinitialiser l'état
      _currentUser = null;
      _currentToken = null;
      _apiService.clearToken();
      _isAuthenticated = false;
      _errorMessage = null;

      notifyListeners();

      if (kDebugMode) print('Déconnexion réussie');
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la déconnexion: $e');
    }
  }

  /// Rafraîchir le token JWT
  /// 
  /// Utilisé quand le token est sur le point d'expirer
  Future<bool> refreshToken() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (_currentToken == null) {
        throw Exception('Pas de token à rafraîchir');
      }

      final response = await _apiService.post(
        '/auth/refresh-token',
        body: {},
        requireAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        final newToken = response['data']['token'];
        _currentToken = newToken;
        _apiService.setToken(newToken);

        // Sauvegarder le nouveau token
        await _tokenStorage.saveToken(newToken);

        _isLoading = false;
        notifyListeners();

        if (kDebugMode) print('Token rafraîchi');
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Erreur de rafraîchissement';
        _isLoading = false;
        
        // Si le rafraîchissement échoue, déconnecter
        await logout();
        
        notifyListeners();
        throw Exception(_errorMessage);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      await logout();
      notifyListeners();
      throw Exception(e.message);
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
      _isLoading = false;
      await logout();
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  /// Vérifier si le token est valide
  Future<bool> verifyToken() async {
    try {
      if (_currentToken == null) {
        return false;
      }

      final response = await _apiService.get(
        '/auth/verify-token',
        requireAuth: true,
      );

      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) print('Token vérification échouée: $e');
      return false;
    }
  }

  /// Obtenir les informations utilisateur actuelles
  Future<UserModel?> getProfile() async {
    try {
      if (!_isAuthenticated || _currentToken == null) {
        return null;
      }

      // Basé sur le rôle de l'utilisateur, faire l'appel approprié
      String endpoint;
      switch (_currentUser?.role) {
        case UserRole.patient:
          endpoint = '/patient/profile';
          break;
        case UserRole.doctor:
          endpoint = '/doctor/profile';
          break;
        case UserRole.nurse:
          endpoint = '/nurse/profile';
          break;
        case UserRole.laboratory:
          endpoint = '/laboratory/profile';
          break;
        case UserRole.admin:
          endpoint = '/admin/profile';
          break;
        default:
          return _currentUser;
      }

      final response = await _apiService.get(endpoint);

      if (response['success'] == true && response['data'] != null) {
        // Mettre à jour les données locales
        final userData = response['data'];
        final fullName = userData['full_name'] ?? _currentUser?.nomComplet ?? '';
        List<String> nameParts = fullName.trim().split(' ');
        String prenom = nameParts.isNotEmpty ? nameParts.first : '';
        String nom = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : prenom;

        _currentUser = UserModel(
          id: (userData['user_id'] ?? _currentUser?.id ?? '').toString(),
          email: userData['email'] ?? _currentUser?.email ?? '',
          nom: nom,
          prenom: prenom,
          telephone: userData['phone'] ?? _currentUser?.telephone,
          role: _currentUser?.role ?? UserRole.patient,
          isActive: userData['is_active'] ?? true,
          createdAt: _currentUser?.createdAt ?? DateTime.now(),
        );

        notifyListeners();
        return _currentUser;
      }

      return _currentUser;
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la récupération du profil: $e');
      return _currentUser;
    }
  }

  /// Nettoyer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
