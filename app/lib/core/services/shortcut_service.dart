import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Service pour créer des raccourcis sur l'écran d'accueil Android
class ShortcutService {
  static const MethodChannel _channel = MethodChannel('com.cardscontrol.app/shortcuts');

  static ShortcutService? _instance;
  static ShortcutService get instance => _instance ??= ShortcutService._();

  ShortcutService._();

  /// Détecte si l'appareil est un Xiaomi/MIUI
  Future<bool> isMiuiDevice() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isMiuiDevice');
      return result ?? false;
    } catch (e) {
      debugPrint('ShortcutService: Error detecting MIUI: $e');
      return false;
    }
  }

  /// Ouvre les paramètres de l'application pour activer la permission "Créer des raccourcis"
  Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint('ShortcutService: Error opening app settings: $e');
    }
  }

  /// Vérifie si la création de raccourcis est supportée
  Future<bool> isSupported() async {
    if (!Platform.isAndroid) {
      debugPrint('ShortcutService: Not Android');
      return false;
    }

    try {
      debugPrint('ShortcutService: Checking isShortcutSupported...');
      final result = await _channel.invokeMethod<bool>('isShortcutSupported');
      debugPrint('ShortcutService: isShortcutSupported = $result');
      return result ?? false;
    } catch (e) {
      debugPrint('ShortcutService: Error checking support: $e');
      return false;
    }
  }

  /// Crée un raccourci sur l'écran d'accueil pour une carte
  Future<bool> createCardShortcut({
    required String cardId,
    required String cardName,
    required String initials,
    required Color primaryColor,
    String? photoPath,
  }) async {
    if (!Platform.isAndroid) {
      debugPrint('ShortcutService: Not Android, cannot create shortcut');
      return false;
    }

    try {
      debugPrint('ShortcutService: Creating shortcut for card $cardId ($cardName)');

      // Générer l'icône
      debugPrint('ShortcutService: Generating icon...');
      final iconPath = await _generateShortcutIcon(
        initials: initials,
        primaryColor: primaryColor,
        photoPath: photoPath,
      );
      debugPrint('ShortcutService: Icon generated at $iconPath');

      // Créer le raccourci via le canal natif
      debugPrint('ShortcutService: Calling createShortcut...');
      final result = await _channel.invokeMethod<bool>('createShortcut', {
        'shortcutId': 'card_$cardId',
        'shortcutLabel': cardName,
        'iconPath': iconPath,
        'deepLink': 'cardscontrol://emulate/$cardId',
      });

      debugPrint('ShortcutService: createShortcut result = $result');
      return result ?? false;
    } catch (e, stackTrace) {
      debugPrint('ShortcutService: Error creating shortcut: $e');
      debugPrint('ShortcutService: StackTrace: $stackTrace');
      return false;
    }
  }

  /// Génère une icône de raccourci avec les initiales ou la photo
  Future<String> _generateShortcutIcon({
    required String initials,
    required Color primaryColor,
    String? photoPath,
  }) async {
    const int iconSize = 192; // Taille recommandée pour les icônes Android

    // Créer un PictureRecorder pour dessiner l'icône
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint();
    final rect = Rect.fromLTWH(0, 0, iconSize.toDouble(), iconSize.toDouble());

    // Dessiner le fond circulaire avec gradient
    final gradient = RadialGradient(
      colors: [
        primaryColor,
        Color.lerp(primaryColor, Colors.black, 0.3)!,
      ],
    );
    paint.shader = gradient.createShader(rect);
    canvas.drawCircle(
      Offset(iconSize / 2, iconSize / 2),
      iconSize / 2,
      paint,
    );

    // Dessiner les initiales
    final textPainter = TextPainter(
      text: TextSpan(
        text: initials.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: iconSize * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (iconSize - textPainter.width) / 2,
        (iconSize - textPainter.height) / 2,
      ),
    );

    // Dessiner l'icône NFC en bas à droite
    final nfcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    // Petit cercle pour l'indicateur NFC
    canvas.drawCircle(
      Offset(iconSize * 0.78, iconSize * 0.78),
      iconSize * 0.15,
      nfcPaint,
    );

    // Icône NFC simplifiée (3 arcs)
    final nfcIconPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (var i = 1; i <= 3; i++) {
      final radius = iconSize * 0.04 * i;
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(iconSize * 0.78, iconSize * 0.78),
          radius: radius,
        ),
        -2.5,
        2.0,
        false,
        nfcIconPaint,
      );
    }

    // Convertir en image
    final picture = recorder.endRecording();
    final image = await picture.toImage(iconSize, iconSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Impossible de générer l\'icône');
    }

    // Sauvegarder l'icône
    final directory = await getApplicationDocumentsDirectory();
    final iconDir = Directory('${directory.path}/shortcut_icons');
    if (!await iconDir.exists()) {
      await iconDir.create(recursive: true);
    }

    final iconFile = File('${iconDir.path}/card_${DateTime.now().millisecondsSinceEpoch}.png');
    await iconFile.writeAsBytes(byteData.buffer.asUint8List());

    return iconFile.path;
  }

  /// Supprime un raccourci existant
  Future<bool> removeCardShortcut(String cardId) async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('removeShortcut', {
        'shortcutId': 'card_$cardId',
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Erreur suppression raccourci: $e');
      return false;
    }
  }

  /// Vérifie si un raccourci existe pour une carte
  Future<bool> hasShortcut(String cardId) async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('hasShortcut', {
        'shortcutId': 'card_$cardId',
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
