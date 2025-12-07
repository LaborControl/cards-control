/// Configuration centralisée des clés API
///
/// IMPORTANT: Les clés API doivent être passées via --dart-define lors du build:
/// flutter run --dart-define=CLAUDE_API_KEY=votre_cle --dart-define=GOOGLE_PLACES_API_KEY=votre_cle
/// flutter build apk --dart-define=CLAUDE_API_KEY=votre_cle --dart-define=GOOGLE_PLACES_API_KEY=votre_cle
class ApiConfig {
  /// Clé API Claude - JAMAIS de valeur par défaut en dur pour la sécurité
  /// Passez la clé via: --dart-define=CLAUDE_API_KEY=sk-ant-xxx
  static const String claudeApiKey = String.fromEnvironment('CLAUDE_API_KEY');

  /// Vérifie si la clé Claude est configurée
  static bool get hasClaudeKey => claudeApiKey.isNotEmpty;

  /// Message d'erreur si la clé n'est pas configurée
  static String get claudeKeyMissingMessage =>
    'Clé API Claude non configurée. La fonctionnalité OCR avancée est désactivée.';

  /// Clé API Google Places pour l'autocomplétion d'adresses
  /// Passez la clé via: --dart-define=GOOGLE_PLACES_API_KEY=AIza...
  static const String googlePlacesApiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  /// Vérifie si la clé Google Places est configurée
  static bool get hasGooglePlacesKey => googlePlacesApiKey.isNotEmpty;
}
