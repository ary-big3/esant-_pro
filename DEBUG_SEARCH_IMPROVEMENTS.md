# Debugging Recherche Patient - Synthèse des Changements

**Date**: 20 avril 2026  
**Problème**: La recherche patient tourne infiniment sans afficher résultats ni erreurs

## 🔍 Problèmes Découverts

### 1. **URL Backend Correcte**
- Frontend utilise: `http://192.168.8.104/esante/backend/public`
- Test initial avec `127.0.0.1` retournait 404
- L'endpoint `/doctors/search-patients` existe et fonctionne ✅

### 2. **Réponse API Validée**
```bash
# Sans token → "Token manquant"
# Avec token invalide → "Erreur lors du décodage JWT"
# Response format est correct (JSON avec {success, message, statusCode})
```

## 📝 Modifications Apportées

### Backend (`DoctorController.php`)

**Logging amélioré au searchPatients()**:
- `🔵` = Debut/Checkpoint
- `🟢` = Success checkpoint  
- `❌` = Erreur
- Logging à chaque étape:
  - Vérification utilisateur
  - Parsing recherche
  - Exécution SQL
  - Gestion erreurs

**Avant**: Logging basique
```php
error_log('🔵 [searchPatients] Nombre de résultats: ' . $result->num_rows);
```

**Après**: Logging détaillé à chaque étape
```php
error_log('🔵 [searchPatients] DÉBUT');
error_log('🟢 [searchPatients] Doctor ID: ' . $doctorId);
error_log('🔵 [searchPatients] Exécution SQL par ID');
error_log('❌ [searchPatients] Erreur prepare: ' . $this->db->error);
```

### Frontend (`search_patient_screen_new.dart`)

**Ajouts majeurs**:

1. **Timeout Global (35 secondes)**
   ```dart
   final result = await searchFuture.timeout(
     const Duration(seconds: 35),
     onTimeout: () {
       // Affiche timeout et réinitialise l'état
       throw TimeoutException('La recherche a timeout');
     },
   );
   ```

2. **Séparation en 2 méthodes**:
   - `_performSearch()` = Wrapper avec timeout
   - `_performSearchInternal()` = Logique réelle

3. **Logging Granulaire à 7 étapes**:
   ```
   Step 1: Vérification du token
   Step 2: Token vérifié ✅
   Step 3: Corps de la requête
   Step 4: Appel API POST...
   Step 5: Réponse reçue ✅
   Step 6: Widget still mounted
   Step 7: State updated
   ```

4. **Triple Exception Handling**:
   - `on Exception catch(e)` - Exceptions typées
   - `catch(e)` - Autres erreurs  
   - `onTimeout` - Timeouts explicites
   - Chaque cas met `_isSearching = false`

5. **Validation Réponse Strict**:
   ```dart
   final dataList = response['data'] as List;
   _searchResults = dataList.toList();
   ```

### ApiService.dart

**Logging amélioré POST()**:
```dart
print('🔵 [POST] Début - URI: $uri');
print('🟢 [POST] Réponse reçue - Code: ${response.statusCode}');
```

**Logging amélioré _handleResponse()**:
```dart
print('🔵 [_handleResponse] Status Code: ${response.statusCode}');
print('✅ [_handleResponse] Success true');
print('❌ [_handleResponse] HTTP Error ${response.statusCode}');
```

## 🧪 Comment Tester

### Option 1: Test API Direct
```bash
# Sans token
curl -X POST http://192.168.8.104/esante/backend/public/doctors/search-patients \
  -H "Content-Type: application/json" \
  -d '{"search_query": "test"}'

# Devrait retourner: {"success": false, "message": "Token manquant"}
```

### Option 2: Test Flutter
1. `flutter clean && flutter pub get`
2. `flutter run` 
3. Naviguer vers "Rechercher Patient"
4. Taper "test" ou un nom réel
5. **Observer console output**:
   - 🔵 DÉBUT?
   - 🔵 Token vérifié?
   - ✅ Réponse reçue?
   - ⏱️ TIMEOUT? (après 35s)
   - 🟢 Résultats affichés?

## 📊 Diagnostique par Logs

### Si ça s'arrête à "Step 1"
→ Problème: Token unavailable (utilisateur pas authentifié)

### Si ça s'arrête à "Step 4"
→ Problème: Connexion réseau ou serveur down

### Si ça s'arrête à "Step 5"
→ Problème: API retourne réponse invalide

### Si ça affiche "⏱️ TIMEOUT après 35 secondes"
→ Problème: Serveur trop lent ou pas de réponse

### Si ça affiche "❌ Exception"
→ Problème: Exception JSON parsing ou setState

## 🔧 Prochaines Étapes si Problème Persiste

1. **Vérifier logs serveur**:
   ```
   tail -f backend/logs/error.log
   ```

2. **Vérifier base de données**:
   ```sql
   SELECT COUNT(*) FROM patients;
   SELECT * FROM patients LIMIT 5;
   ```

3. **Tester avec un vrai token**:
   - Authentifier un utilisateur d'abord
   - Copier le token JWT
   - Utiliser dans curl avec `Authorization: Bearer TOKEN`

4. **Vérifier PHP config**:
   - max_execution_time
   - memory_limit
   - Erreurs dans error.log

## 📝 Notes d'Implémentation

- Timeout 35s = 30s (ApiService) + 5s (buffer)
- Double setState protection (mounted check)
- Gestion spéciale des exceptions ApiException
- Import ajouté: `import 'dart:async'` pour TimeoutException
