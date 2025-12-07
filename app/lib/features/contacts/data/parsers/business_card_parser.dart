import 'package:email_validator/email_validator.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../../domain/models/scanned_card_data.dart';
import '../../domain/services/claude_vision_service.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/ai_token_service.dart';

/// Parser intelligent pour extraire les informations structurées
/// d'un texte brut de carte de visite
///
/// Utilise Claude Vision API si disponible, sinon fallback sur regex
class BusinessCardParser {
  ClaudeVisionService? _claudeService;

  BusinessCardParser() {
    // Initialise Claude si la clé API est disponible
    if (ApiConfig.hasClaudeKey) {
      _claudeService = ClaudeVisionService(
        apiKey: ApiConfig.claudeApiKey,
        tokenService: AITokenService(),
      );
    }
  }

  /// Parse le texte brut et retourne les données structurées
  /// Tente d'abord Claude AI, puis fallback sur regex si échec
  Future<ScannedCardData> parse(String rawText) async {
    if (rawText.isEmpty) {
      return ScannedCardData(rawText: rawText);
    }

    // Tente d'abord Claude AI si disponible
    if (_claudeService != null) {
      try {
        final result = await _claudeService!.parseBusinessCard(rawText);
        return result;
      } catch (_) {
        // Fallback silencieux vers le parsing regex
      }
    }

    // Fallback: parsing regex
    return _parseWithRegex(rawText);
  }

  /// Parse avec regex (fallback)
  ScannedCardData _parseWithRegex(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Extraction dans l'ordre pour éviter les conflits
    final email = _extractEmail(rawText);
    final phone = _extractPhone(rawText);
    final website = _extractWebsite(rawText);

    // Filtrer les lignes qui contiennent email/phone/website pour le reste
    final cleanLines = lines.where((line) {
      if (email != null && line.toLowerCase().contains(email.toLowerCase())) return false;
      if (phone != null && _containsPhonePattern(line)) return false;
      if (website != null && line.toLowerCase().contains(website.toLowerCase().replaceAll('https://', '').replaceAll('http://', ''))) return false;
      return true;
    }).toList();

    final fullName = _extractName(cleanLines);
    final (firstName, lastName) = _splitName(fullName);
    final company = _extractCompany(cleanLines, fullName);
    final jobTitle = _extractJobTitle(cleanLines, fullName, company);
    final address = _extractAddress(rawText);

    // Calcul du score de confiance basé sur la qualité de détection
    double confidence = _calculateConfidence(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      company: company,
      jobTitle: jobTitle,
      website: website,
      address: address,
    );

    return ScannedCardData(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      company: company,
      jobTitle: jobTitle,
      website: website,
      address: address,
      rawText: rawText,
      confidence: confidence,
    );
  }

  /// Sépare le nom complet en prénom et nom de famille
  (String?, String?) _splitName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return (null, null);

    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return (null, null);

    if (parts.length == 1) {
      return (parts[0], null);
    }

    // Premier mot = prénom, le reste = nom de famille
    final firstName = parts.first;
    final lastName = parts.sublist(1).join(' ');
    return (firstName, lastName);
  }

  /// Calcule un score de confiance réaliste
  double _calculateConfidence({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? company,
    String? jobTitle,
    String? website,
    String? address,
  }) {
    double score = 0.0;
    int totalWeight = 0;

    // Prénom (poids: 2)
    if (firstName != null && firstName.isNotEmpty) {
      score += 2.0;
    }
    totalWeight += 2;

    // Nom (poids: 2)
    if (lastName != null && lastName.isNotEmpty) {
      score += 2.0;
    }
    totalWeight += 2;

    // Email (poids: 3) - très important et fiable
    if (email != null) {
      score += 3.0;
    }
    totalWeight += 3;

    // Téléphone (poids: 2) - important
    if (phone != null) {
      score += 2.0;
    }
    totalWeight += 2;

    // Entreprise (poids: 2) - important
    if (company != null && _isValidCompany(company)) {
      score += 2.0;
    }
    totalWeight += 2;

    // Poste (poids: 1) - utile mais pas critique
    if (jobTitle != null) {
      score += 1.0;
    }
    totalWeight += 1;

    // Site web (poids: 1) - utile
    if (website != null) {
      score += 1.0;
    }
    totalWeight += 1;

    // Adresse (poids: 1) - bonus
    if (address != null) {
      score += 1.0;
    }
    totalWeight += 1;

    return score / totalWeight;
  }

  /// Vérifie si une ligne contient un pattern de téléphone
  bool _containsPhonePattern(String line) {
    // Cherche des patterns de numéros de téléphone
    final phonePatterns = [
      RegExp(r'\+?\d{1,3}[-.\s]?\d{1,4}[-.\s]?\d{1,4}[-.\s]?\d{1,9}'),
      RegExp(r'\d{2,4}[-.\s]\d{2,4}[-.\s]\d{2,4}'),
    ];

    return phonePatterns.any((pattern) => pattern.hasMatch(line));
  }

  /// Vérifie si un nom est valide
  bool _isValidName(String name) {
    // Un nom valide ne doit pas contenir que des chiffres
    if (RegExp(r'^\d+$').hasMatch(name)) return false;

    // Un nom valide ne doit pas être trop court
    if (name.length < 3) return false;

    // Un nom valide doit avoir au moins 2 mots
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length < 2) return false;

    // Chaque mot doit commencer par une lettre
    return words.every((word) => RegExp(r'^[A-Za-zÀ-ÿ]').hasMatch(word));
  }

  /// Vérifie si une entreprise est valide
  bool _isValidCompany(String company) {
    // Une entreprise ne doit pas être juste un numéro
    if (RegExp(r'^\d+$').hasMatch(company)) return false;

    // Une entreprise doit avoir au moins 2 caractères
    return company.length >= 2;
  }

  /// Extrait l'email du texte
  String? _extractEmail(String text) {
    final emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    );
    final match = emailRegex.firstMatch(text);
    final email = match?.group(0);

    // Validation supplémentaire
    if (email != null && EmailValidator.validate(email)) {
      return email.toLowerCase();
    }
    return null;
  }

  /// Extrait le numéro de téléphone
  String? _extractPhone(String text) {
    try {
      // Patterns de téléphone plus stricts
      final phoneRegex = RegExp(
        r'(?:\+33|0)[1-9](?:[-.\s]?\d{2}){4}|(?:\+\d{1,3}[-.\s]?)?\(?\d{1,4}\)?[-.\s]?\d{1,4}[-.\s]?\d{1,9}',
      );
      final matches = phoneRegex.allMatches(text);

      for (final match in matches) {
        final phoneStr = match.group(0);
        if (phoneStr != null) {
          final digitsOnly = phoneStr.replaceAll(RegExp(r'\D'), '');

          // Doit avoir au moins 9 chiffres pour être un vrai numéro
          if (digitsOnly.length >= 9 && digitsOnly.length <= 15) {
            try {
              final phone = PhoneNumber.parse(phoneStr, callerCountry: IsoCode.FR);
              return phone.international;
            } catch (e) {
              // Si le parsing échoue, retourne le numéro brut nettoyé
              return phoneStr;
            }
          }
        }
      }
    } catch (_) {
      // Silently ignore phone extraction errors
    }
    return null;
  }

  /// Extrait le site web
  String? _extractWebsite(String text) {
    final urlRegex = RegExp(
      r'(?:https?://)?(?:www\.)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(?:/[^\s]*)?',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(text.toLowerCase());

    for (final match in matches) {
      var url = match.group(0);
      if (url != null) {
        // Ignore les emails
        if (url.contains('@')) continue;

        // Ajoute https:// si manquant
        if (!url.startsWith('http')) {
          url = 'https://$url';
        }
        return url;
      }
    }
    return null;
  }

  /// Extrait le nom (première ligne qui ressemble à un nom)
  String? _extractName(List<String> lines) {
    if (lines.isEmpty) return null;

    for (final line in lines) {
      // Ignore les lignes qui sont clairement pas des noms
      if (_isLikelyCompany(line)) continue;
      if (_isLikelyJobTitle(line)) continue;
      if (RegExp(r'^\d+$').hasMatch(line)) continue; // Que des chiffres
      if (line.length < 3) continue; // Trop court

      // Vérifie que c'est probablement un nom
      final words = line.split(' ').where((w) => w.isNotEmpty).toList();

      // Un nom a généralement 2-4 mots
      if (words.length >= 2 && words.length <= 4) {
        // Chaque mot doit commencer par une majuscule et une lettre
        if (words.every((w) =>
          w.length > 0 &&
          w[0] == w[0].toUpperCase() &&
          RegExp(r'^[A-Za-zÀ-ÿ]').hasMatch(w[0])
        )) {
          // Pas de chiffres dans le nom
          if (!RegExp(r'\d').hasMatch(line)) {
            return line;
          }
        }
      }
    }

    return null;
  }

  /// Extrait l'entreprise
  String? _extractCompany(List<String> lines, String? name) {
    final companyKeywords = [
      'SA', 'SARL', 'SAS', 'SASU', 'SNC', 'SCS', 'EURL',
      'Inc', 'Ltd', 'LLC', 'Corp', 'Corporation', 'GmbH', 'AG',
      'Société', 'Company', 'Entreprise', 'Group', 'Groupe'
    ];

    for (final line in lines) {
      // Ignore le nom
      if (name != null && line == name) continue;

      // Ignore les lignes qui sont juste des numéros
      if (RegExp(r'^\d+$').hasMatch(line)) continue;

      // Ignore les titres de poste
      if (_isLikelyJobTitle(line)) continue;

      // Cherche les mots-clés d'entreprise
      for (final keyword in companyKeywords) {
        if (line.toUpperCase().contains(keyword.toUpperCase())) {
          return line;
        }
      }

      // Ligne en majuscules (souvent le nom d'entreprise)
      if (line == line.toUpperCase() && line.length > 3 && !RegExp(r'^\d+$').hasMatch(line)) {
        return line;
      }
    }

    return null;
  }

  /// Extrait le poste/titre
  String? _extractJobTitle(List<String> lines, String? name, String? company) {
    for (final line in lines) {
      // Ignore le nom et l'entreprise
      if (name != null && line == name) continue;
      if (company != null && line == company) continue;

      // Ignore les numéros
      if (RegExp(r'^\d+$').hasMatch(line)) continue;

      if (_isLikelyJobTitle(line)) {
        return line;
      }
    }

    return null;
  }

  /// Vérifie si une ligne ressemble à un titre de poste
  bool _isLikelyJobTitle(String line) {
    final titleKeywords = [
      'CEO', 'CTO', 'CFO', 'COO', 'CIO', 'CMO',
      'Director', 'Directeur', 'Directrice',
      'Manager', 'Responsable', 'Chef',
      'President', 'Président', 'Présidente',
      'Vice', 'Assistant', 'Assistante',
      'Consultant', 'Consultante',
      'Engineer', 'Ingénieur', 'Ingénieure',
      'Developer', 'Développeur', 'Développeuse',
      'Designer', 'Architect', 'Architecte',
      'Founder', 'Fondateur', 'Fondatrice',
      'Owner', 'Propriétaire',
      'Partner', 'Associé', 'Associée',
      'Coordinator', 'Coordinateur', 'Coordinatrice'
    ];

    final lineLower = line.toLowerCase();
    return titleKeywords.any((keyword) => lineLower.contains(keyword.toLowerCase()));
  }

  /// Extrait l'adresse
  String? _extractAddress(String text) {
    // Cherche les codes postaux français (5 chiffres)
    final postalCodeRegex = RegExp(r'\b\d{5}\b');
    final match = postalCodeRegex.firstMatch(text);

    if (match != null) {
      final lines = text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(match.group(0)!)) {
          // Prend la ligne avec le code postal et éventuellement la précédente
          if (i > 0) {
            return '${lines[i - 1]}\n${lines[i]}'.trim();
          }
          return lines[i].trim();
        }
      }
    }

    return null;
  }

  /// Vérifie si une ligne ressemble à un nom d'entreprise
  bool _isLikelyCompany(String line) {
    final companyIndicators = [
      'SA', 'SARL', 'SAS', 'SASU', 'Inc', 'Ltd', 'LLC', 'Corp',
      'Société', 'Company', 'Entreprise', 'Group'
    ];
    return companyIndicators.any(
      (indicator) => line.toUpperCase().contains(indicator.toUpperCase()),
    );
  }
}
