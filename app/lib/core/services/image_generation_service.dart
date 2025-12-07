import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_keys_service.dart';
import 'ai_token_service.dart';

/// Résultat de la génération d'image
class ImageGenerationResult {
  final bool success;
  final File? imageFile;
  final String? base64Data;
  final String? mimeType;
  final String? errorMessage;
  final int tokensUsed;

  const ImageGenerationResult({
    required this.success,
    this.imageFile,
    this.base64Data,
    this.mimeType,
    this.errorMessage,
    this.tokensUsed = 0,
  });

  factory ImageGenerationResult.error(String message) {
    return ImageGenerationResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// Service de génération d'images via Google Imagen (Gemini API)
class ImageGenerationService {
  static final ImageGenerationService instance = ImageGenerationService._();
  ImageGenerationService._();

  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.0-flash-preview-image-generation'; // Modèle pour génération d'image

  final ApiKeysService _apiKeysService = ApiKeysService.instance;
  final AITokenService _aiTokenService = AITokenService();

  /// Génère une image à partir d'un prompt textuel
  /// Si [inputImage] est fourni, l'IA va améliorer/transformer cette image
  Future<ImageGenerationResult> generateImage({
    required String prompt,
    String? negativePrompt,
    File? inputImage,
    int width = 1024,
    int height = 1024,
  }) async {
    try {
      // Récupérer la clé API
      final apiKey = await _apiKeysService.getGoogleApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return ImageGenerationResult.error(
          'Clé API Google non configurée. Contactez l\'administrateur.',
        );
      }

      // Vérifier si l'utilisateur a assez de tokens
      final canUse = await _aiTokenService.canUseAI(estimatedTokens: 5000);
      if (!canUse) {
        return ImageGenerationResult.error(
          'Quota de tokens IA épuisé pour ce mois.',
        );
      }

      // Construire le prompt enrichi pour de meilleurs résultats
      final enrichedPrompt = inputImage != null
          ? _buildEnhancementPrompt(prompt, negativePrompt)
          : _buildEnrichedPrompt(prompt, negativePrompt);

      // Appeler l'API Gemini
      final url = Uri.parse('$_baseUrl/models/$_model:generateContent?key=$apiKey');

      // Construire les parts de la requête
      final List<Map<String, dynamic>> parts = [];

      // Ajouter l'image d'entrée si fournie
      if (inputImage != null) {
        final imageBytes = await inputImage.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        final mimeType = inputImage.path.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg';

        parts.add({
          'inlineData': {
            'mimeType': mimeType,
            'data': base64Image,
          }
        });
      }

      // Ajouter le prompt texte
      parts.add({'text': enrichedPrompt});

      final requestBody = {
        'contents': [
          {'parts': parts}
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE'],
        },
      };

      debugPrint('Generating image with prompt: ${prompt.substring(0, prompt.length.clamp(0, 50))}...');
      if (inputImage != null) {
        debugPrint('With input image: ${inputImage.path}');
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');

        // Messages d'erreur spécifiques selon le code
        String errorMessage;
        switch (response.statusCode) {
          case 429:
            errorMessage = 'Quota API Google dépassé. Réessayez dans quelques minutes.';
            break;
          case 400:
            errorMessage = 'Requête invalide. Vérifiez les paramètres.';
            break;
          case 401:
          case 403:
            errorMessage = 'Clé API invalide ou accès refusé.';
            break;
          case 500:
          case 502:
          case 503:
            errorMessage = 'Serveur Google indisponible. Réessayez plus tard.';
            break;
          default:
            errorMessage = 'Erreur API: ${response.statusCode}';
        }

        return ImageGenerationResult.error(errorMessage);
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Extraire l'image de la réponse
      final result = await _extractImageFromResponse(responseData);

      // Enregistrer l'utilisation de tokens
      if (result.success) {
        await _aiTokenService.recordUsage(
          type: AIUsageType.imageGeneration,
          inputTokens: AITokenService.estimateTokens(enrichedPrompt) + (inputImage != null ? 1000 : 0),
          outputTokens: result.tokensUsed > 0 ? result.tokensUsed : 2000,
          model: _model,
          details: inputImage != null
              ? 'Image enhancement: ${prompt.substring(0, prompt.length.clamp(0, 100))}'
              : 'Image generation: ${prompt.substring(0, prompt.length.clamp(0, 100))}',
        );
      }

      return result;
    } catch (e) {
      debugPrint('Error generating image: $e');
      return ImageGenerationResult.error(
        'Erreur lors de la génération: $e',
      );
    }
  }

  /// Construit un prompt pour améliorer une image existante
  String _buildEnhancementPrompt(String prompt, String? negativePrompt) {
    final buffer = StringBuffer();

    buffer.write('Edit this image to create a beautiful event visual. ');
    buffer.write('Keep the person or animal in the photo as the main subject, ');
    buffer.write('but place them in a context related to the event: $prompt. ');
    buffer.write('Enhance the lighting, colors, and overall quality. ');
    buffer.write('The subject should look natural in the new setting. ');
    buffer.write('Preserve the identity and likeness of any people or animals. ');

    if (negativePrompt != null && negativePrompt.isNotEmpty) {
      buffer.write('Avoid: $negativePrompt. ');
    }

    buffer.write('Do not add any text or watermarks.');

    return buffer.toString();
  }

  /// Construit un prompt enrichi pour de meilleurs résultats
  String _buildEnrichedPrompt(String prompt, String? negativePrompt) {
    final buffer = StringBuffer();

    buffer.write('Generate a high-quality, visually appealing image for an event: ');
    buffer.write(prompt);
    buffer.write('. ');
    buffer.write('The image should be suitable for an event poster or invitation. ');
    buffer.write('Make it modern, professional, and eye-catching. ');

    if (negativePrompt != null && negativePrompt.isNotEmpty) {
      buffer.write('Avoid: $negativePrompt. ');
    }

    buffer.write('Do not include any text or watermarks in the image.');

    return buffer.toString();
  }

  /// Extrait l'image de la réponse API
  Future<ImageGenerationResult> _extractImageFromResponse(
    Map<String, dynamic> responseData,
  ) async {
    try {
      final candidates = responseData['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return ImageGenerationResult.error('Aucun résultat généré');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) {
        return ImageGenerationResult.error('Contenu invalide dans la réponse');
      }

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return ImageGenerationResult.error('Aucune partie dans le contenu');
      }

      // Chercher la partie image
      for (final part in parts) {
        final partMap = part as Map<String, dynamic>;

        if (partMap.containsKey('inlineData')) {
          final inlineData = partMap['inlineData'] as Map<String, dynamic>;
          final base64Data = inlineData['data'] as String?;
          final mimeType = inlineData['mimeType'] as String? ?? 'image/png';

          if (base64Data != null && base64Data.isNotEmpty) {
            // Décoder et sauvegarder l'image
            final imageBytes = base64Decode(base64Data);
            final imageFile = await _saveImageToFile(imageBytes, mimeType);

            return ImageGenerationResult(
              success: true,
              imageFile: imageFile,
              base64Data: base64Data,
              mimeType: mimeType,
              tokensUsed: 2000, // Estimation pour la génération d'image
            );
          }
        }
      }

      // Si pas d'image trouvée, vérifier s'il y a un message texte
      for (final part in parts) {
        final partMap = part as Map<String, dynamic>;
        if (partMap.containsKey('text')) {
          final text = partMap['text'] as String;
          debugPrint('API returned text instead of image: $text');
          return ImageGenerationResult.error(
            'L\'API a retourné du texte au lieu d\'une image. Essayez un autre prompt.',
          );
        }
      }

      return ImageGenerationResult.error('Aucune image dans la réponse');
    } catch (e) {
      debugPrint('Error extracting image: $e');
      return ImageGenerationResult.error('Erreur lors de l\'extraction: $e');
    }
  }

  /// Sauvegarde l'image dans un fichier temporaire
  Future<File> _saveImageToFile(Uint8List imageBytes, String mimeType) async {
    final tempDir = await getTemporaryDirectory();
    final extension = mimeType.contains('png') ? 'png' : 'jpg';
    final fileName = 'generated_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(imageBytes);
    return file;
  }

  /// Génère une image pour un événement à partir des détails
  /// Si [inputImage] est fourni, l'IA va améliorer cette photo en la mettant en contexte
  Future<ImageGenerationResult> generateEventImage({
    required String eventTitle,
    String? eventDescription,
    String? eventLocation,
    DateTime? eventDate,
    File? inputImage,
  }) async {
    final promptBuffer = StringBuffer();

    if (inputImage != null) {
      // Mode amélioration : mettre le sujet en situation
      promptBuffer.write('Event: "$eventTitle"');
    } else {
      // Mode génération : créer une nouvelle image
      promptBuffer.write('Create an event image for: "$eventTitle"');
    }

    if (eventDescription != null && eventDescription.isNotEmpty) {
      promptBuffer.write('. Description: $eventDescription');
    }

    if (eventLocation != null && eventLocation.isNotEmpty) {
      promptBuffer.write('. Location: $eventLocation');
    }

    if (eventDate != null) {
      final season = _getSeasonFromDate(eventDate);
      promptBuffer.write('. Season/atmosphere: $season');
    }

    return generateImage(
      prompt: promptBuffer.toString(),
      inputImage: inputImage,
    );
  }

  /// Détermine la saison à partir de la date
  String _getSeasonFromDate(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'spring, fresh, blooming';
    if (month >= 6 && month <= 8) return 'summer, warm, bright';
    if (month >= 9 && month <= 11) return 'autumn, cozy, warm colors';
    return 'winter, festive, cool tones';
  }
}
