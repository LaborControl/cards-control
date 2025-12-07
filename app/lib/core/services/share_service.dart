import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service pour le partage de données
class ShareService {
  ShareService._();

  static final ShareService instance = ShareService._();

  /// Partage un texte simple
  Future<void> shareText(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }

  /// Partage une URL
  Future<void> shareUrl(String url, {String? title}) async {
    await Share.share(url, subject: title);
  }

  /// Partage une vCard
  Future<void> shareVCard(String vCardContent, String contactName) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = '${contactName.replaceAll(' ', '_')}.vcf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(vCardContent);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Carte de visite - $contactName',
      );
    } catch (e) {
      // Fallback: partager le texte brut
      await shareText(vCardContent, subject: 'Carte de visite - $contactName');
    }
  }

  /// Partage une image
  Future<void> shareImage(Uint8List imageBytes, String fileName, {String? text}) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
      );
    } catch (e) {
      throw Exception('Impossible de partager l\'image: $e');
    }
  }

  /// Partage un fichier
  Future<void> shareFile(String filePath, {String? text, String? subject}) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: text,
      subject: subject,
    );
  }

  /// Partage des données NFC exportées
  Future<void> shareNfcExport(String jsonContent, String tagId) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'nfc_tag_$tagId.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonContent);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Export Tag NFC',
      );
    } catch (e) {
      // Fallback: partager le texte brut
      await shareText(jsonContent, subject: 'Export Tag NFC');
    }
  }

  /// Copie du texte dans le presse-papiers
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Récupère le texte du presse-papiers
  Future<String?> getFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }
}
