import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/services/ai_token_service.dart';

/// Résultat de la génération IA pour un template
class TemplateAIResult {
  final String? enhancedDescription;
  final String? suggestedName;
  final List<String>? tags;
  final bool success;
  final String? error;

  const TemplateAIResult({
    this.enhancedDescription,
    this.suggestedName,
    this.tags,
    this.success = true,
    this.error,
  });

  factory TemplateAIResult.failure(String error) {
    return TemplateAIResult(success: false, error: error);
  }
}

/// Service pour enrichir les templates avec l'IA
class TemplateAIService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-3-haiku-20240307';
  static const String _apiVersion = '2023-06-01';

  final String apiKey;
  final AITokenService? _tokenService;

  TemplateAIService({
    required this.apiKey,
    AITokenService? tokenService,
  }) : _tokenService = tokenService;

  /// Génère une description enrichie pour un template d'événement
  Future<TemplateAIResult> enhanceEventDescription({
    required String title,
    String? date,
    String? time,
    String? location,
    String? description,
  }) async {
    if (apiKey.isEmpty) {
      return TemplateAIResult.failure('API key not configured');
    }

    final prompt = _buildEventPrompt(
      title: title,
      date: date,
      time: time,
      location: location,
      description: description,
    );

    return _callAPI(prompt, 'event');
  }

  /// Génère une description pour un template générique
  Future<TemplateAIResult> enhanceTemplateDescription({
    required String type,
    required Map<String, dynamic> data,
    String? currentName,
  }) async {
    if (apiKey.isEmpty) {
      return TemplateAIResult.failure('API key not configured');
    }

    final prompt = _buildGenericPrompt(type, data, currentName);
    return _callAPI(prompt, type);
  }

  Future<TemplateAIResult> _callAPI(String prompt, String templateType) async {
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
          'max_tokens': 500,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final result = _parseResponse(response.body);
        await _recordTokenUsage(response.body, templateType);
        return result;
      } else {
        return TemplateAIResult.failure('API error: ${response.statusCode}');
      }
    } catch (e) {
      return TemplateAIResult.failure('Network error: $e');
    }
  }

  String _buildEventPrompt({
    required String title,
    String? date,
    String? time,
    String? location,
    String? description,
  }) {
    return '''Tu es un assistant qui aide à créer des descriptions attractives pour des événements partagés via NFC.

Informations de l'événement:
- Titre: $title
${date != null ? '- Date: $date' : ''}
${time != null ? '- Heure: $time' : ''}
${location != null && location.isNotEmpty ? '- Lieu: $location' : ''}
${description != null && description.isNotEmpty ? '- Description actuelle: $description' : ''}

Génère une réponse JSON avec:
1. "enhancedDescription": Une description engageante et professionnelle (2-3 phrases max, sans emoji)
2. "suggestedName": Un nom court et accrocheur pour ce template (si le titre actuel peut être amélioré)
3. "tags": 2-3 mots-clés pertinents pour cet événement

Réponds UNIQUEMENT avec le JSON, sans texte avant ou après.

Exemple de format:
{
  "enhancedDescription": "Rejoignez-nous pour une soirée exceptionnelle...",
  "suggestedName": "Gala 2025",
  "tags": ["networking", "soirée", "business"]
}''';
  }

  String _buildGenericPrompt(String type, Map<String, dynamic> data, String? currentName) {
    final dataStr = data.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map((e) => '- ${e.key}: ${e.value}')
        .join('\n');

    final typeLabels = {
      'url': 'lien web',
      'text': 'texte',
      'wifi': 'configuration WiFi',
      'vcard': 'carte de visite',
      'phone': 'numéro de téléphone',
      'email': 'email',
      'sms': 'SMS',
      'location': 'localisation',
      'googleReview': 'avis Google',
      'appDownload': 'téléchargement d\'application',
      'tip': 'pourboire',
      'medicalId': 'ID médical',
      'petId': 'ID animal',
      'luggageId': 'ID bagage',
    };

    final typeLabel = typeLabels[type] ?? type;

    return '''Tu es un assistant qui aide à créer des noms et descriptions pour des tags NFC.

Type de template: $typeLabel
${currentName != null ? 'Nom actuel: $currentName' : ''}
Données:
$dataStr

Génère une réponse JSON avec:
1. "suggestedName": Un nom court et descriptif pour ce template (10-30 caractères)
2. "enhancedDescription": Une courte description de ce que fait ce tag (1 phrase)
3. "tags": 2-3 mots-clés pertinents

Réponds UNIQUEMENT avec le JSON, sans texte avant ou après.''';
  }

  TemplateAIResult _parseResponse(String responseBody) {
    try {
      final jsonResponse = jsonDecode(responseBody);
      final content = jsonResponse['content'] as List;

      if (content.isEmpty) {
        return TemplateAIResult.failure('Empty response');
      }

      final textContent = content[0]['text'] as String;

      // Extraire le JSON
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(textContent);
      if (jsonMatch == null) {
        return TemplateAIResult.failure('No JSON in response');
      }

      final resultData = jsonDecode(jsonMatch.group(0)!);

      return TemplateAIResult(
        enhancedDescription: resultData['enhancedDescription'] as String?,
        suggestedName: resultData['suggestedName'] as String?,
        tags: resultData['tags'] != null
            ? List<String>.from(resultData['tags'])
            : null,
      );
    } catch (e) {
      return TemplateAIResult.failure('Parse error: $e');
    }
  }

  Future<void> _recordTokenUsage(String responseBody, String templateType) async {
    if (_tokenService == null) return;

    try {
      final jsonResponse = jsonDecode(responseBody);
      final usage = AITokenService.parseClaudeUsage(jsonResponse);

      await _tokenService.recordUsage(
        type: AIUsageType.templateGeneration,
        inputTokens: usage['input'] ?? 0,
        outputTokens: usage['output'] ?? 0,
        model: _model,
        details: 'Génération template: $templateType',
      );
    } catch (_) {
      // Ignorer les erreurs de tracking
    }
  }
}
