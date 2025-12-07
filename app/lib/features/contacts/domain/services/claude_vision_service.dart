import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scanned_card_data.dart';
import '../../../../core/services/ai_token_service.dart';

/// Service pour parser les cartes de visite avec Claude Vision API
class ClaudeVisionService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-3-haiku-20240307'; // Rapide et économique
  static const String _apiVersion = '2023-06-01';

  final String apiKey;
  final AITokenService? _tokenService;

  ClaudeVisionService({
    required this.apiKey,
    AITokenService? tokenService,
  }) : _tokenService = tokenService;

  /// Parse une carte de visite à partir du texte OCR
  Future<ScannedCardData> parseBusinessCard(String rawText) async {
    if (apiKey.isEmpty) {
      throw Exception('Claude API key is not configured');
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': _apiVersion,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': _buildPrompt(rawText),
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final result = _parseClaudeResponse(response.body, rawText);

        // Enregistrer l'utilisation des tokens
        await _recordTokenUsage(response.body);

        return result;
      } else {
        throw Exception('Claude API error: ${response.statusCode} - ${response.body}');
      }
    } catch (_) {
      rethrow;
    }
  }

  /// Enregistre l'utilisation des tokens après un appel API
  Future<void> _recordTokenUsage(String responseBody) async {
    if (_tokenService == null) return;

    try {
      final jsonResponse = jsonDecode(responseBody);
      final usage = AITokenService.parseClaudeUsage(jsonResponse);

      await _tokenService.recordUsage(
        type: AIUsageType.businessCardOcr,
        inputTokens: usage['input'] ?? 0,
        outputTokens: usage['output'] ?? 0,
        model: _model,
        details: 'Lecture de carte de visite',
      );
    } catch (_) {
      // Ignorer les erreurs de tracking
    }
  }

  /// Construit le prompt pour Claude
  String _buildPrompt(String rawText) {
    return '''Analyse ce texte extrait d'une carte de visite et retourne UNIQUEMENT un JSON valide avec cette structure exacte :

{
  "firstName": "prénom de la personne",
  "lastName": "nom de famille de la personne",
  "email": "adresse email",
  "phone": "numéro de téléphone fixe/bureau au format international",
  "mobile": "numéro de téléphone mobile au format international",
  "company": "nom de l'entreprise",
  "jobTitle": "titre du poste",
  "website": "site web",
  "address": "adresse complète"
}

Règles strictes :
- IMPORTANT: Sépare bien le prénom (firstName) du nom de famille (lastName)
- Si un champ n'est pas trouvé, utilise null (pas de guillemets)
- Ne retourne QUE le JSON, aucun texte avant ou après
- Formate les téléphones en international (+33... pour la France)
- Distingue bien le mobile (commence souvent par 06/07 en France) du fixe
- Vérifie que l'email est valide
- Le prénom et nom doivent être des noms de personne, pas des numéros
- L'entreprise doit être un nom d'entreprise, pas un numéro
- Utilise le domaine de l'email ou du site web pour déduire/confirmer l'entreprise (ex: @cards-control.app -> Cards Control), SAUF pour les domaines génériques (gmail, hotmail, yahoo, outlook, orange, free, sfr, icloud, etc.)
- Assure la cohérence entre l'entreprise et le domaine professionnel

Texte de la carte :
$rawText''';
  }

  /// Parse la réponse de Claude
  ScannedCardData _parseClaudeResponse(String responseBody, String rawText) {
    try {
      final jsonResponse = jsonDecode(responseBody);
      final content = jsonResponse['content'] as List;

      if (content.isEmpty) {
        throw Exception('Empty response from Claude');
      }

      final textContent = content[0]['text'] as String;

      // Extraire le JSON de la réponse (au cas où Claude ajoute du texte)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(textContent);
      if (jsonMatch == null) {
        throw Exception('No JSON found in Claude response');
      }

      final cardData = jsonDecode(jsonMatch.group(0)!);

      // Calculer le score de confiance basé sur les champs détectés
      double confidence = _calculateConfidence(cardData);

      return ScannedCardData(
        firstName: cardData['firstName'],
        lastName: cardData['lastName'],
        email: cardData['email'],
        phone: cardData['phone'],
        mobile: cardData['mobile'],
        company: cardData['company'],
        jobTitle: cardData['jobTitle'],
        website: cardData['website'],
        address: cardData['address'],
        rawText: rawText,
        confidence: confidence,
      );
    } catch (_) {
      rethrow;
    }
  }

  /// Calcule un score de confiance basé sur les champs détectés
  double _calculateConfidence(Map<String, dynamic> data) {
    double score = 0.0;
    int totalWeight = 0;

    // Prénom (poids: 2)
    if (data['firstName'] != null && data['firstName'].toString().isNotEmpty) {
      score += 2.0;
    }
    totalWeight += 2;

    // Nom (poids: 2)
    if (data['lastName'] != null && data['lastName'].toString().isNotEmpty) {
      score += 2.0;
    }
    totalWeight += 2;

    // Email (poids: 3)
    if (data['email'] != null && data['email'].toString().isNotEmpty) {
      score += 3.0;
    }
    totalWeight += 3;

    // Téléphone Fixe (poids: 2)
    if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
      score += 2.0;
    }
    totalWeight += 2;

    // Téléphone Mobile (poids: 2)
    if (data['mobile'] != null && data['mobile'].toString().isNotEmpty) {
      score += 2.0;
    }
    totalWeight += 2;

    // Entreprise (poids: 2)
    if (data['company'] != null && data['company'].toString().isNotEmpty) {
      score += 2.0;
    }
    totalWeight += 2;

    // Poste (poids: 1)
    if (data['jobTitle'] != null && data['jobTitle'].toString().isNotEmpty) {
      score += 1.0;
    }
    totalWeight += 1;

    // Site web (poids: 1)
    if (data['website'] != null && data['website'].toString().isNotEmpty) {
      score += 1.0;
    }
    totalWeight += 1;

    // Adresse (poids: 1)
    if (data['address'] != null && data['address'].toString().isNotEmpty) {
      score += 1.0;
    }
    totalWeight += 1;

    return totalWeight > 0 ? score / totalWeight : 0.0;
  }
}
