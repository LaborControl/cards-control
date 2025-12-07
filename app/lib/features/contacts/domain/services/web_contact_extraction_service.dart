import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Données de contact extraites d'une page web
class ExtractedWebContact {
  final String? firstName;
  final String? lastName;
  final String? company;
  final String? jobTitle;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? website;
  final String? address;
  final String? photoUrl;
  final String? companyLogoUrl;
  final Map<String, String> socialLinks;
  final String sourceUrl;
  final double confidence;

  const ExtractedWebContact({
    this.firstName,
    this.lastName,
    this.company,
    this.jobTitle,
    this.email,
    this.phone,
    this.mobile,
    this.website,
    this.address,
    this.photoUrl,
    this.companyLogoUrl,
    this.socialLinks = const {},
    required this.sourceUrl,
    this.confidence = 0.0,
  });

  bool get hasData =>
      firstName != null ||
      lastName != null ||
      email != null ||
      phone != null ||
      company != null;

  String get fullName {
    final parts = [firstName, lastName].whereType<String>().toList();
    return parts.join(' ').trim();
  }
}

/// Service pour extraire les informations de contact d'une page web via Claude Sonnet
class WebContactExtractionService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-20250514';
  static const String _apiVersion = '2023-06-01';

  final String apiKey;

  WebContactExtractionService({required this.apiKey});

  /// Extrait les informations de contact d'une URL
  Future<ExtractedWebContact> extractFromUrl(String url) async {
    if (apiKey.isEmpty) {
      throw Exception('Claude API key is not configured');
    }

    try {
      // 1. Récupérer le contenu HTML de la page
      debugPrint('Fetching URL: $url');
      final htmlContent = await _fetchHtmlContent(url);

      // 2. Nettoyer le HTML
      final cleanedHtml = _cleanHtml(htmlContent);
      debugPrint('HTML cleaned, length: ${cleanedHtml.length}');

      // 3. Envoyer à Claude Sonnet pour extraction
      final extractedData = await _extractWithClaude(cleanedHtml, url);

      return extractedData;
    } catch (e) {
      debugPrint('Error extracting contact from URL: $e');
      rethrow;
    }
  }

  /// Récupère le contenu HTML d'une URL
  Future<String> _fetchHtmlContent(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to fetch URL: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error fetching URL: $e');
    }
  }

  /// Nettoie le HTML en retirant les éléments non pertinents
  String _cleanHtml(String html) {
    // Retirer les scripts
    var cleaned = html.replaceAll(
        RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '');

    // Retirer les styles
    cleaned = cleaned.replaceAll(
        RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');

    // Retirer les commentaires HTML
    cleaned = cleaned.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');

    // Retirer les attributs de style inline excessifs
    cleaned =
        cleaned.replaceAll(RegExp(r'\s+style="[^"]*"', caseSensitive: false), '');

    // Limiter la taille pour l'API (max ~50KB pour éviter les tokens excessifs)
    if (cleaned.length > 50000) {
      cleaned = cleaned.substring(0, 50000);
    }

    return cleaned;
  }

  /// Envoie le contenu à Claude Sonnet pour extraction
  Future<ExtractedWebContact> _extractWithClaude(
      String htmlContent, String url) async {
    final prompt = _buildPrompt(htmlContent, url);

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': _apiVersion,
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 2048,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      return _parseClaudeResponse(response.body, url);
    } else {
      debugPrint('Claude API error: ${response.statusCode} - ${response.body}');
      throw Exception('Claude API error: ${response.statusCode}');
    }
  }

  /// Construit le prompt pour Claude Sonnet
  String _buildPrompt(String htmlContent, String url) {
    return '''Analyse cette page web de carte de visite digitale et extrais les informations de contact.

URL source: $url

Retourne UNIQUEMENT un JSON valide avec cette structure (null si non trouvé):
{
  "firstName": "prénom",
  "lastName": "nom de famille",
  "company": "nom de l'entreprise",
  "jobTitle": "titre/fonction",
  "email": "email professionnel",
  "phone": "téléphone fixe format international",
  "mobile": "téléphone mobile format international",
  "website": "site web (différent de l'URL source si possible)",
  "address": "adresse complète",
  "photoUrl": "URL absolue de la photo de profil",
  "companyLogoUrl": "URL absolue du logo entreprise",
  "socialLinks": {
    "linkedin": "url linkedin complète",
    "twitter": "url twitter complète",
    "instagram": "url instagram complète",
    "facebook": "url facebook complète"
  }
}

Règles strictes:
- Extrais les URLs COMPLÈTES et ABSOLUES des images (photo profil et logo), pas de chemins relatifs
- Pour les images, cherche les balises img avec des attributs comme "profile", "avatar", "photo", "logo"
- Formate les téléphones en format international (+33... pour la France)
- Distingue bien le mobile (commence par 06/07 en France) du fixe
- Si plusieurs emails, privilégie le professionnel (pas gmail, hotmail, etc.)
- Pour socialLinks, inclus UNIQUEMENT les réseaux sociaux effectivement présents
- Ne retourne QUE le JSON, aucun texte avant ou après
- Sépare bien prénom et nom de famille si possible

Contenu HTML de la page:
$htmlContent''';
  }

  /// Parse la réponse de Claude
  ExtractedWebContact _parseClaudeResponse(String responseBody, String url) {
    try {
      final jsonResponse = jsonDecode(responseBody);
      final content = jsonResponse['content'] as List;

      if (content.isEmpty) {
        throw Exception('Empty response from Claude');
      }

      final textContent = content[0]['text'] as String;
      debugPrint('Claude response: $textContent');

      // Extraire le JSON de la réponse
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(textContent);
      if (jsonMatch == null) {
        throw Exception('No JSON found in Claude response');
      }

      final cardData = jsonDecode(jsonMatch.group(0)!);

      // Parser les socialLinks
      Map<String, String> socialLinks = {};
      if (cardData['socialLinks'] != null &&
          cardData['socialLinks'] is Map) {
        final links = cardData['socialLinks'] as Map;
        links.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            socialLinks[key.toString()] = value.toString();
          }
        });
      }

      // Calculer le score de confiance
      double confidence = _calculateConfidence(cardData);

      return ExtractedWebContact(
        firstName: _cleanString(cardData['firstName']),
        lastName: _cleanString(cardData['lastName']),
        company: _cleanString(cardData['company']),
        jobTitle: _cleanString(cardData['jobTitle']),
        email: _cleanString(cardData['email']),
        phone: _cleanString(cardData['phone']),
        mobile: _cleanString(cardData['mobile']),
        website: _cleanString(cardData['website']),
        address: _cleanString(cardData['address']),
        photoUrl: _cleanString(cardData['photoUrl']),
        companyLogoUrl: _cleanString(cardData['companyLogoUrl']),
        socialLinks: socialLinks,
        sourceUrl: url,
        confidence: confidence,
      );
    } catch (e) {
      debugPrint('Error parsing Claude response: $e');
      rethrow;
    }
  }

  /// Nettoie une chaîne (retourne null si vide ou "null")
  String? _cleanString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return null;
    return str;
  }

  /// Calcule un score de confiance basé sur les champs détectés
  double _calculateConfidence(Map<String, dynamic> data) {
    double score = 0.0;
    int totalWeight = 0;

    // Nom (poids: 3)
    if (_hasValue(data['firstName']) || _hasValue(data['lastName'])) {
      score += 3.0;
    }
    totalWeight += 3;

    // Email (poids: 3)
    if (_hasValue(data['email'])) {
      score += 3.0;
    }
    totalWeight += 3;

    // Téléphone (poids: 2)
    if (_hasValue(data['phone']) || _hasValue(data['mobile'])) {
      score += 2.0;
    }
    totalWeight += 2;

    // Entreprise (poids: 2)
    if (_hasValue(data['company'])) {
      score += 2.0;
    }
    totalWeight += 2;

    // Photo (poids: 2)
    if (_hasValue(data['photoUrl'])) {
      score += 2.0;
    }
    totalWeight += 2;

    // Poste (poids: 1)
    if (_hasValue(data['jobTitle'])) {
      score += 1.0;
    }
    totalWeight += 1;

    // Site web (poids: 1)
    if (_hasValue(data['website'])) {
      score += 1.0;
    }
    totalWeight += 1;

    // Adresse (poids: 1)
    if (_hasValue(data['address'])) {
      score += 1.0;
    }
    totalWeight += 1;

    return totalWeight > 0 ? score / totalWeight : 0.0;
  }

  bool _hasValue(dynamic value) {
    if (value == null) return false;
    final str = value.toString().trim();
    return str.isNotEmpty && str.toLowerCase() != 'null';
  }
}
