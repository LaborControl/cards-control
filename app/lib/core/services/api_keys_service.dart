import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service pour récupérer les clés API stockées de manière sécurisée dans Firestore
class ApiKeysService {
  static final ApiKeysService instance = ApiKeysService._();
  ApiKeysService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache des clés pour éviter les lectures répétées
  final Map<String, String> _keysCache = {};
  DateTime? _lastFetch;
  static const Duration _cacheValidity = Duration(hours: 1);

  /// Récupère la clé API Google (Gemini/Imagen)
  Future<String?> getGoogleApiKey() async {
    return _getKey('google_api_key');
  }

  /// Récupère la clé API Claude
  Future<String?> getClaudeApiKey() async {
    return _getKey('claude_api_key');
  }

  /// Méthode générique pour récupérer une clé
  Future<String?> _getKey(String keyName) async {
    // Vérifier le cache
    if (_keysCache.containsKey(keyName) &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheValidity) {
      return _keysCache[keyName];
    }

    try {
      final doc = await _firestore.collection('config').doc('api_keys').get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey(keyName)) {
          final key = data[keyName] as String?;
          if (key != null && key.isNotEmpty) {
            _keysCache[keyName] = key;
            _lastFetch = DateTime.now();
            return key;
          }
        }
      }

      debugPrint('API key not found: $keyName');
      return null;
    } catch (e) {
      debugPrint('Error fetching API key: $e');
      return null;
    }
  }

  /// Invalide le cache (utile après une mise à jour)
  void invalidateCache() {
    _keysCache.clear();
    _lastFetch = null;
  }
}
