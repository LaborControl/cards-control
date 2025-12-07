import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service pour extraire le texte d'une image de carte de visite
/// en utilisant Google ML Kit Text Recognition
class CardOcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extrait le texte brut d'une image
  ///
  /// [imagePath] Chemin vers l'image à analyser
  /// Returns Le texte extrait ou une chaîne vide en cas d'erreur
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Retourne le texte avec les lignes séparées
      return recognizedText.text;
    } catch (_) {
      return '';
    }
  }

  /// Extrait le texte avec les blocs structurés
  /// Utile pour obtenir les positions des éléments
  Future<RecognizedText?> extractStructuredText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      return await _textRecognizer.processImage(inputImage);
    } catch (_) {
      return null;
    }
  }

  /// Nettoie le texte extrait
  String cleanText(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  /// Libère les ressources
  void dispose() {
    _textRecognizer.close();
  }
}
