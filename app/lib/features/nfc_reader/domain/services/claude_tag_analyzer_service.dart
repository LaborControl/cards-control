import 'dart:convert';
import 'package:http/http.dart' as http;
import '../entities/nfc_tag.dart';
import '../../../../core/services/ai_token_service.dart';

/// Résultat de l'analyse d'un tag NFC par Claude
class TagAnalysisResult {
  final bool canCreateTemplate;
  final String? templateType;
  final Map<String, dynamic>? extractedData;
  final String? explanation;
  final double confidence;

  const TagAnalysisResult({
    required this.canCreateTemplate,
    this.templateType,
    this.extractedData,
    this.explanation,
    this.confidence = 0.0,
  });

  factory TagAnalysisResult.cannotCreate(String explanation) {
    return TagAnalysisResult(
      canCreateTemplate: false,
      explanation: explanation,
      confidence: 0.0,
    );
  }
}

/// Service pour analyser le contenu des tags NFC avec Claude API
class ClaudeTagAnalyzerService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-3-haiku-20240307';
  static const String _apiVersion = '2023-06-01';

  final String apiKey;
  final AITokenService? _tokenService;

  ClaudeTagAnalyzerService({
    required this.apiKey,
    AITokenService? tokenService,
  }) : _tokenService = tokenService;

  /// Analyse le contenu d'un tag NFC et détermine s'il peut être sauvegardé comme modèle
  Future<TagAnalysisResult> analyzeTagForTemplate(NfcTag tag) async {
    if (apiKey.isEmpty) {
      // Fallback vers analyse locale si pas de clé API
      return _analyzeLocally(tag);
    }

    // Préparer le contenu du tag pour l'analyse
    final tagContent = _extractTagContent(tag);

    if (tagContent.isEmpty) {
      return TagAnalysisResult.cannotCreate(
        'Ce tag est vide et ne contient aucune donnée exploitable pour créer un modèle.',
      );
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
              'content': _buildPrompt(tagContent, tag),
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final result = _parseClaudeResponse(response.body);

        // Enregistrer l'utilisation des tokens
        await _recordTokenUsage(response.body);

        return result;
      } else {
        // En cas d'erreur API, fallback vers analyse locale
        return _analyzeLocally(tag);
      }
    } catch (_) {
      // En cas d'erreur réseau, fallback vers analyse locale
      return _analyzeLocally(tag);
    }
  }

  /// Enregistre l'utilisation des tokens après un appel API
  Future<void> _recordTokenUsage(String responseBody) async {
    if (_tokenService == null) return;

    try {
      final jsonResponse = jsonDecode(responseBody);
      final usage = AITokenService.parseClaudeUsage(jsonResponse);

      await _tokenService.recordUsage(
        type: AIUsageType.tagAnalysis,
        inputTokens: usage['input'] ?? 0,
        outputTokens: usage['output'] ?? 0,
        model: _model,
        details: 'Analyse de tag NFC',
      );
    } catch (_) {
      // Ignorer les erreurs de tracking
    }
  }

  /// Extrait le contenu lisible du tag
  String _extractTagContent(NfcTag tag) {
    final buffer = StringBuffer();

    buffer.writeln('Type de tag: ${tag.type.displayName}');
    buffer.writeln('Technologie: ${tag.technology.displayName}');
    buffer.writeln('UID: ${tag.formattedUid}');
    buffer.writeln('Mémoire: ${tag.usedMemory}/${tag.memorySize} bytes');

    if (tag.ndefRecords.isNotEmpty) {
      buffer.writeln('\nEnregistrements NDEF:');
      for (int i = 0; i < tag.ndefRecords.length; i++) {
        final record = tag.ndefRecords[i];
        buffer.writeln('Record ${i + 1}:');
        buffer.writeln('  Type: ${record.type.displayName}');
        if (record.decodedPayload != null && record.decodedPayload!.isNotEmpty) {
          buffer.writeln('  Contenu: ${record.decodedPayload}');
        } else {
          buffer.writeln('  Données brutes (hex): ${record.payloadHex}');
        }
      }
    }

    return buffer.toString();
  }

  /// Construit le prompt pour Claude
  String _buildPrompt(String tagContent, NfcTag tag) {
    return '''Analyse ce contenu d'un tag NFC et détermine s'il contient des informations utiles pour créer un modèle réutilisable.

Types de modèles supportés:
- url: Site web, lien
- text: Texte simple, message
- vcard: Carte de visite (nom, téléphone, email, entreprise)
- wifi: Configuration WiFi (SSID, mot de passe)
- phone: Numéro de téléphone
- email: Adresse email
- sms: Message SMS (numéro + message optionnel)
- location: Coordonnées GPS

Contenu du tag:
$tagContent

Réponds UNIQUEMENT avec un JSON valide dans ce format exact:
{
  "canCreateTemplate": true/false,
  "templateType": "url|text|vcard|wifi|phone|email|sms|location|null",
  "extractedData": { ... données extraites selon le type ... },
  "explanation": "explication en français de ce que contient le tag et pourquoi il peut/ne peut pas être transformé en modèle",
  "confidence": 0.0 à 1.0
}

Règles:
- Si le tag est vide ou contient uniquement des données techniques (UID, mémoire vide), canCreateTemplate = false
- Si le contenu est trop court ou incompréhensible pour être utile, canCreateTemplate = false
- extractedData doit contenir les champs appropriés au type:
  - url: {"url": "..."}
  - text: {"text": "..."}
  - vcard: {"firstName": "...", "lastName": "...", "phone": "...", "email": "...", "organization": "...", "title": "...", "website": "..."}
  - wifi: {"ssid": "...", "password": "...", "authType": "wpa2|wep|open", "hidden": true/false}
  - phone: {"phone": "..."}
  - email: {"email": "..."}
  - sms: {"phone": "...", "message": "..."}
  - location: {"latitude": ..., "longitude": ..., "label": "..."}
- L'explication doit être claire et en français pour l'utilisateur''';
  }

  /// Parse la réponse de Claude
  TagAnalysisResult _parseClaudeResponse(String responseBody) {
    try {
      final jsonResponse = jsonDecode(responseBody);
      final content = jsonResponse['content'] as List;

      if (content.isEmpty) {
        return TagAnalysisResult.cannotCreate(
          'Impossible d\'analyser le contenu du tag.',
        );
      }

      final textContent = content[0]['text'] as String;

      // Extraire le JSON de la réponse
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(textContent);
      if (jsonMatch == null) {
        return TagAnalysisResult.cannotCreate(
          'Impossible d\'analyser le contenu du tag.',
        );
      }

      final analysisData = jsonDecode(jsonMatch.group(0)!);

      return TagAnalysisResult(
        canCreateTemplate: analysisData['canCreateTemplate'] == true,
        templateType: analysisData['templateType'],
        extractedData: analysisData['extractedData'] != null
            ? Map<String, dynamic>.from(analysisData['extractedData'])
            : null,
        explanation: analysisData['explanation'],
        confidence: (analysisData['confidence'] ?? 0.0).toDouble(),
      );
    } catch (_) {
      return TagAnalysisResult.cannotCreate(
        'Erreur lors de l\'analyse du contenu du tag.',
      );
    }
  }

  /// Analyse locale en fallback (sans API)
  TagAnalysisResult _analyzeLocally(NfcTag tag) {
    if (tag.ndefRecords.isEmpty) {
      return TagAnalysisResult.cannotCreate(
        'Ce tag NFC est vide. Il ne contient aucune donnée NDEF qui pourrait être utilisée pour créer un modèle.',
      );
    }

    for (final record in tag.ndefRecords) {
      final payload = record.decodedPayload ?? '';

      switch (record.type) {
        case NdefRecordType.uri:
          if (payload.isNotEmpty) {
            // Détecter le type d'URI
            if (payload.startsWith('tel:')) {
              return TagAnalysisResult(
                canCreateTemplate: true,
                templateType: 'phone',
                extractedData: {'phone': payload.replaceFirst('tel:', '')},
                explanation: 'Ce tag contient un numéro de téléphone. Vous pouvez le sauvegarder comme modèle pour le partager facilement.',
                confidence: 0.95,
              );
            } else if (payload.startsWith('mailto:')) {
              final email = payload.replaceFirst('mailto:', '').split('?').first;
              return TagAnalysisResult(
                canCreateTemplate: true,
                templateType: 'email',
                extractedData: {'email': email},
                explanation: 'Ce tag contient une adresse email. Vous pouvez le sauvegarder comme modèle pour le partager facilement.',
                confidence: 0.95,
              );
            } else if (payload.startsWith('sms:')) {
              final parts = payload.replaceFirst('sms:', '').split('?');
              final phone = parts.first;
              String? body;
              if (parts.length > 1 && parts[1].contains('body=')) {
                body = Uri.decodeComponent(parts[1].replaceFirst('body=', ''));
              }
              return TagAnalysisResult(
                canCreateTemplate: true,
                templateType: 'sms',
                extractedData: {'phone': phone, 'message': body ?? ''},
                explanation: 'Ce tag contient un SMS pré-configuré. Vous pouvez le sauvegarder comme modèle.',
                confidence: 0.95,
              );
            } else if (payload.startsWith('WIFI:')) {
              final wifiData = _parseWifiString(payload);
              if (wifiData != null) {
                return TagAnalysisResult(
                  canCreateTemplate: true,
                  templateType: 'wifi',
                  extractedData: wifiData,
                  explanation: 'Ce tag contient une configuration WiFi. Vous pouvez le sauvegarder comme modèle pour partager votre réseau WiFi.',
                  confidence: 0.95,
                );
              }
            } else if (payload.startsWith('geo:')) {
              final geoMatch = RegExp(r'geo:([0-9.\-]+),([0-9.\-]+)').firstMatch(payload);
              if (geoMatch != null) {
                return TagAnalysisResult(
                  canCreateTemplate: true,
                  templateType: 'location',
                  extractedData: {
                    'latitude': double.tryParse(geoMatch.group(1)!) ?? 0.0,
                    'longitude': double.tryParse(geoMatch.group(2)!) ?? 0.0,
                    'label': '',
                  },
                  explanation: 'Ce tag contient des coordonnées GPS. Vous pouvez le sauvegarder comme modèle de localisation.',
                  confidence: 0.9,
                );
              }
            } else {
              // URL standard
              return TagAnalysisResult(
                canCreateTemplate: true,
                templateType: 'url',
                extractedData: {'url': payload},
                explanation: 'Ce tag contient un lien URL. Vous pouvez le sauvegarder comme modèle pour le partager facilement.',
                confidence: 0.9,
              );
            }
          }
          break;

        case NdefRecordType.text:
          if (payload.trim().isNotEmpty) {
            return TagAnalysisResult(
              canCreateTemplate: true,
              templateType: 'text',
              extractedData: {'text': payload},
              explanation: 'Ce tag contient du texte. Vous pouvez le sauvegarder comme modèle pour le réutiliser.',
              confidence: 0.85,
            );
          }
          break;

        case NdefRecordType.vcard:
        case NdefRecordType.mimeMedia:
          if (payload.contains('BEGIN:VCARD')) {
            final vcardData = _parseVCard(payload);
            if (vcardData != null) {
              return TagAnalysisResult(
                canCreateTemplate: true,
                templateType: 'vcard',
                extractedData: vcardData,
                explanation: 'Ce tag contient une carte de visite (vCard). Vous pouvez le sauvegarder comme modèle de contact.',
                confidence: 0.95,
              );
            }
          }
          break;

        case NdefRecordType.wifi:
          final wifiData = _parseWifiString(payload);
          if (wifiData != null) {
            return TagAnalysisResult(
              canCreateTemplate: true,
              templateType: 'wifi',
              extractedData: wifiData,
              explanation: 'Ce tag contient une configuration WiFi. Vous pouvez le sauvegarder comme modèle pour partager votre réseau.',
              confidence: 0.95,
            );
          }
          break;

        default:
          break;
      }
    }

    // Vérifier si c'est un tag avec uniquement des données techniques
    final hasOnlyRawData = tag.ndefRecords.every((r) =>
      r.decodedPayload == null || r.decodedPayload!.isEmpty);

    if (hasOnlyRawData) {
      return TagAnalysisResult.cannotCreate(
        'Ce tag contient des données brutes qui ne correspondent à aucun format standard (URL, texte, vCard, WiFi...). '
        'Il n\'est pas possible de créer un modèle à partir de ces données.',
      );
    }

    return TagAnalysisResult.cannotCreate(
      'Le contenu de ce tag n\'est pas reconnu comme un format exploitable pour créer un modèle. '
      'Les formats supportés sont : URL, texte, carte de visite, configuration WiFi, téléphone, email, SMS.',
    );
  }

  /// Parse une chaîne WiFi au format WIFI:T:WPA;S:ssid;P:password;;
  Map<String, dynamic>? _parseWifiString(String wifiString) {
    if (!wifiString.startsWith('WIFI:')) return null;

    String? ssid;
    String? password;
    String authType = 'wpa2';
    bool hidden = false;

    final content = wifiString.substring(5);
    final parts = content.split(';');

    for (final part in parts) {
      if (part.startsWith('S:')) {
        ssid = part.substring(2);
      } else if (part.startsWith('P:')) {
        password = part.substring(2);
      } else if (part.startsWith('T:')) {
        final type = part.substring(2).toUpperCase();
        if (type == 'WEP') {
          authType = 'wep';
        } else if (type == 'WPA' || type == 'WPA2') {
          authType = 'wpa2';
        } else if (type == 'NOPASS' || type.isEmpty) {
          authType = 'open';
        }
      } else if (part.startsWith('H:')) {
        hidden = part.substring(2).toLowerCase() == 'true';
      }
    }

    if (ssid == null || ssid.isEmpty) return null;

    return {
      'ssid': ssid,
      'password': password ?? '',
      'authType': authType,
      'hidden': hidden,
    };
  }

  /// Parse une vCard
  Map<String, dynamic>? _parseVCard(String vcard) {
    final lines = vcard.split(RegExp(r'\r?\n'));
    String? firstName;
    String? lastName;
    String? organization;
    String? title;
    String? phone;
    String? email;
    String? website;

    for (final line in lines) {
      if (line.startsWith('N:') || line.startsWith('N;')) {
        final parts = line.split(':').last.split(';');
        if (parts.isNotEmpty) lastName = parts[0];
        if (parts.length > 1) firstName = parts[1];
      } else if (line.startsWith('FN:') || line.startsWith('FN;')) {
        final fullName = line.split(':').last;
        if (firstName == null && lastName == null) {
          final parts = fullName.split(' ');
          if (parts.isNotEmpty) firstName = parts.first;
          if (parts.length > 1) lastName = parts.sublist(1).join(' ');
        }
      } else if (line.startsWith('ORG:') || line.startsWith('ORG;')) {
        organization = line.split(':').last.replaceAll(';', ' ').trim();
      } else if (line.startsWith('TITLE:') || line.startsWith('TITLE;')) {
        title = line.split(':').last;
      } else if (line.startsWith('TEL:') || line.startsWith('TEL;')) {
        phone ??= line.split(':').last;
      } else if (line.startsWith('EMAIL:') || line.startsWith('EMAIL;')) {
        email ??= line.split(':').last;
      } else if (line.startsWith('URL:') || line.startsWith('URL;')) {
        website ??= line.split(':').sublist(1).join(':');
      }
    }

    if (firstName == null && lastName == null && phone == null && email == null) {
      return null;
    }

    return {
      'firstName': firstName ?? '',
      'lastName': lastName ?? '',
      'organization': organization ?? '',
      'title': title ?? '',
      'phone': phone ?? '',
      'email': email ?? '',
      'website': website ?? '',
    };
  }
}
