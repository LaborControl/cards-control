import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Intercepteur de logging sécurisé pour les requêtes HTTP
/// SÉCURITÉ: Désactivé en production, masque les données sensibles en debug
class LoggingInterceptor extends Interceptor {
  // Liste des clés sensibles à masquer
  static const _sensitiveKeys = [
    'authorization',
    'auth',
    'token',
    'password',
    'secret',
    'apikey',
    'api_key',
    'api-key',
    'credential',
    'bearer',
    'cookie',
    'set-cookie',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // SÉCURITÉ: Ne pas logger en production
    if (kDebugMode) {
      _log('╔══════════════════════════════════════════════════════════');
      _log('║ REQUEST');
      _log('╠══════════════════════════════════════════════════════════');
      _log('║ ${options.method} ${options.uri}');
      _log('║ Headers: ${_sanitizeHeaders(options.headers)}');
      if (options.data != null) {
        _log('║ Body: ${_sanitizeBody(options.data)}');
      }
      _log('╚══════════════════════════════════════════════════════════');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // SÉCURITÉ: Ne pas logger en production
    if (kDebugMode) {
      _log('╔══════════════════════════════════════════════════════════');
      _log('║ RESPONSE');
      _log('╠══════════════════════════════════════════════════════════');
      _log('║ ${response.statusCode} ${response.requestOptions.uri}');
      _log('║ Data: [RESPONSE DATA HIDDEN FOR SECURITY]');
      _log('╚══════════════════════════════════════════════════════════');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // SÉCURITÉ: Logger les erreurs en debug seulement, sans données sensibles
    if (kDebugMode) {
      _log('╔══════════════════════════════════════════════════════════');
      _log('║ ERROR');
      _log('╠══════════════════════════════════════════════════════════');
      _log('║ ${err.requestOptions.method} ${err.requestOptions.uri}');
      _log('║ Status: ${err.response?.statusCode}');
      _log('║ Message: ${err.message}');
      // Ne pas logger le contenu de la réponse d'erreur (peut contenir des tokens)
      _log('╚══════════════════════════════════════════════════════════');
    }

    handler.next(err);
  }

  /// Masque les headers sensibles
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = <String, dynamic>{};
    headers.forEach((key, value) {
      if (_isSensitiveKey(key)) {
        sanitized[key] = '[REDACTED]';
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  /// Masque les données sensibles dans le body
  String _sanitizeBody(dynamic data) {
    if (data == null) return 'null';

    if (data is Map) {
      final sanitized = <String, dynamic>{};
      data.forEach((key, value) {
        if (_isSensitiveKey(key.toString())) {
          sanitized[key] = '[REDACTED]';
        } else {
          sanitized[key] = value;
        }
      });
      return sanitized.toString();
    }

    // Pour les autres types, ne pas afficher le contenu complet
    return '[${data.runtimeType}]';
  }

  /// Vérifie si une clé est sensible
  bool _isSensitiveKey(String key) {
    final lowerKey = key.toLowerCase();
    return _sensitiveKeys.any((sensitive) => lowerKey.contains(sensitive));
  }

  void _log(String message) {
    developer.log(message, name: 'API');
  }
}
