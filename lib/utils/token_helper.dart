import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Helper pour s'assurer que le token est prêt avant les appels API
class TokenHelper {
  /// Attendre que le token soit défini (max 5 secondes)
  /// S'assure que AuthService est complètement initialisé
  static Future<void> ensureTokenReady() async {
    if (kDebugMode) print('🔐 [TokenHelper] Vérification du token...');
    
    final apiService = ApiService();
    final authService = AuthService();
    
    // Vérifier si le token est déjà défini dans ApiService (cas le plus fréquent après login)
    if (apiService.getToken() != null) {
      if (kDebugMode) print('✅ [TokenHelper] Token trouvé dans ApiService');
      return;
    }
    
    // Si ApiService n'a pas le token mais AuthService l'a, le copier
    if (authService.currentToken != null) {
      apiService.setToken(authService.currentToken!);
      if (kDebugMode) print('✅ [TokenHelper] Token copié depuis AuthService vers ApiService');
      return;
    }
    
    // Sinon, attendre que le token soit disponible (cas du démarrage de l'app)
    if (kDebugMode) print('⏳ [TokenHelper] Token pas trouvé, attente du stockage (max 5s)...');
    int retries = 50; // 5 secondes (50 * 100ms)
    
    while (retries > 0) {
      // Vérifier ApiService
      final token = apiService.getToken();
      if (token != null) {
        if (kDebugMode) print('✅ [TokenHelper] Token disponible dans ApiService');
        return;
      }
      
      // Vérifier AuthService
      final authToken = authService.currentToken;
      if (authToken != null) {
        apiService.setToken(authToken);
        if (kDebugMode) print('✅ [TokenHelper] Token disponible dans AuthService, copié vers ApiService');
        return;
      }
      
      // Attendre un peu avant de réessayer
      await Future.delayed(const Duration(milliseconds: 100));
      retries--;
    }
    
    // Timeout - mais on continue quand même (l'API renverra 401 si pas authtifié)
    if (kDebugMode) {
      print('⚠️ [TokenHelper] Timeout après 5s: Token toujours indisponible');
      print('   État: ApiService=${apiService.getToken() != null}, AuthService=${authService.currentToken != null}');
    }
  }
}


