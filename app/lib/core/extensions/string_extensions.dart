/// Extensions sur String
extension StringExtensions on String {
  /// Capitalise la première lettre
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalise chaque mot
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Tronque le texte avec des points de suspension
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Supprime les espaces multiples
  String removeExtraSpaces() {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Vérifie si c'est une URL valide
  bool get isValidUrl {
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(this);
  }

  /// Vérifie si c'est un email valide
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Vérifie si c'est un numéro de téléphone valide
  bool get isValidPhone {
    final cleaned = replaceAll(RegExp(r'[\s\-\(\)]+'), '');
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    return phoneRegex.hasMatch(cleaned);
  }

  /// Extrait les initiales (ex: "Jean Dupont" -> "JD")
  String get initials {
    final words = trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '';
    }
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  /// Convertit en slug (ex: "Hello World" -> "hello-world")
  String toSlug() {
    return toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Masque partiellement le texte (ex: email ou téléphone)
  String mask({int visibleStart = 3, int visibleEnd = 3, String maskChar = '*'}) {
    if (length <= visibleStart + visibleEnd) return this;
    final start = substring(0, visibleStart);
    final end = substring(length - visibleEnd);
    final masked = maskChar * (length - visibleStart - visibleEnd);
    return '$start$masked$end';
  }

  /// Ajoute un préfixe HTTP si nécessaire
  String ensureHttpPrefix() {
    if (startsWith('http://') || startsWith('https://')) {
      return this;
    }
    return 'https://$this';
  }

  /// Supprime le préfixe HTTP
  String removeHttpPrefix() {
    return replaceAll(RegExp(r'^https?://'), '');
  }

  /// Parse en int ou retourne null
  int? toIntOrNull() {
    return int.tryParse(this);
  }

  /// Parse en double ou retourne null
  double? toDoubleOrNull() {
    return double.tryParse(this);
  }

  /// Vérifie si la chaîne contient uniquement des chiffres
  bool get isNumeric {
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }

  /// Vérifie si la chaîne est vide ou ne contient que des espaces
  bool get isBlank {
    return trim().isEmpty;
  }

  /// Inverse de isBlank
  bool get isNotBlank {
    return !isBlank;
  }
}

/// Extensions sur String nullable
extension NullableStringExtensions on String? {
  /// Retourne true si null ou vide
  bool get isNullOrEmpty {
    return this == null || this!.isEmpty;
  }

  /// Retourne true si null, vide ou ne contient que des espaces
  bool get isNullOrBlank {
    return this == null || this!.trim().isEmpty;
  }

  /// Retourne la chaîne ou une valeur par défaut
  String orDefault(String defaultValue) {
    return isNullOrEmpty ? defaultValue : this!;
  }
}
