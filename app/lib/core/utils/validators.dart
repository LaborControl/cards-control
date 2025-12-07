/// Utilitaires de validation
class Validators {
  Validators._();

  /// Valide une adresse email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }

    return null;
  }

  /// Valide une URL
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL optionnelle
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );

    if (!urlRegex.hasMatch(value)) {
      return 'URL invalide';
    }

    return null;
  }

  /// Valide un numéro de téléphone
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Téléphone optionnel
    }

    // Supprimer les espaces, tirets et parenthèses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]+'), '');

    // Format international ou local
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Numéro de téléphone invalide';
    }

    return null;
  }

  /// Valide un champ requis
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName est requis' : 'Ce champ est requis';
    }
    return null;
  }

  /// Valide une longueur minimale
  static String? minLength(String? value, int min, [String? fieldName]) {
    if (value == null || value.length < min) {
      return '${fieldName ?? 'Ce champ'} doit contenir au moins $min caractères';
    }
    return null;
  }

  /// Valide une longueur maximale
  static String? maxLength(String? value, int max, [String? fieldName]) {
    if (value != null && value.length > max) {
      return '${fieldName ?? 'Ce champ'} ne doit pas dépasser $max caractères';
    }
    return null;
  }

  /// Valide un mot de passe
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }

    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une minuscule';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }

    return null;
  }

  /// Valide la confirmation du mot de passe
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer le mot de passe';
    }

    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }

    return null;
  }

  /// Valide un SSID WiFi
  static String? ssid(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom du réseau est requis';
    }

    if (value.length > 32) {
      return 'Le nom du réseau ne peut pas dépasser 32 caractères';
    }

    return null;
  }

  /// Valide un mot de passe WiFi
  static String? wifiPassword(String? value, String authType) {
    if (authType == 'nopass' || authType == 'OPEN') {
      return null; // Pas de mot de passe requis
    }

    if (value == null || value.isEmpty) {
      return 'Le mot de passe WiFi est requis';
    }

    if (authType == 'WEP') {
      if (value.length != 5 && value.length != 13 && value.length != 10 && value.length != 26) {
        return 'Mot de passe WEP invalide (5, 13, 10 ou 26 caractères)';
      }
    } else {
      // WPA/WPA2
      if (value.length < 8 || value.length > 63) {
        return 'Le mot de passe WiFi doit contenir entre 8 et 63 caractères';
      }
    }

    return null;
  }

  /// Combine plusieurs validateurs
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }
}
