import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Service pour la génération de QR codes
class QrCodeService {
  QrCodeService._();

  static final QrCodeService instance = QrCodeService._();

  /// Génère un QR code en tant que Widget
  Widget generateQrWidget({
    required String data,
    double size = 200,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
    String? embeddedImagePath,
    double embeddedImageSize = 40,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: foregroundColor,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foregroundColor,
      ),
      embeddedImage: embeddedImagePath != null
          ? AssetImage(embeddedImagePath)
          : null,
      embeddedImageStyle: embeddedImagePath != null
          ? QrEmbeddedImageStyle(
              size: Size(embeddedImageSize, embeddedImageSize),
            )
          : null,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }

  /// URL de base pour les cartes de visite publiques
  /// Utilise Firebase Hosting
  static const String defaultBaseUrl = 'https://cards-control.app/card';

  /// Génère une URL de carte de visite
  String generateBusinessCardUrl(String cardId, {String? baseUrl}) {
    final base = baseUrl ?? defaultBaseUrl;
    return '$base/$cardId';
  }

  /// Génère une vCard encodée pour QR code
  String generateVCardQrData({
    required String firstName,
    required String lastName,
    String? company,
    String? jobTitle,
    String? email,
    String? phone,
    String? website,
    String? address,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('N:$lastName;$firstName;;;');
    buffer.writeln('FN:$firstName $lastName');

    if (company != null && company.isNotEmpty) {
      buffer.writeln('ORG:$company');
    }
    if (jobTitle != null && jobTitle.isNotEmpty) {
      buffer.writeln('TITLE:$jobTitle');
    }
    if (email != null && email.isNotEmpty) {
      buffer.writeln('EMAIL:$email');
    }
    if (phone != null && phone.isNotEmpty) {
      buffer.writeln('TEL:$phone');
    }
    if (website != null && website.isNotEmpty) {
      buffer.writeln('URL:$website');
    }
    if (address != null && address.isNotEmpty) {
      buffer.writeln('ADR:;;$address;;;;');
    }

    buffer.writeln('END:VCARD');
    return buffer.toString();
  }

  /// Génère une configuration WiFi pour QR code
  String generateWifiQrData({
    required String ssid,
    required String password,
    String authType = 'WPA',
    bool hidden = false,
  }) {
    return 'WIFI:T:$authType;S:$ssid;P:$password;H:${hidden ? 'true' : 'false'};;';
  }

  /// Génère un QR code pour un email
  String generateEmailQrData({
    required String email,
    String? subject,
    String? body,
  }) {
    final buffer = StringBuffer('mailto:$email');
    final params = <String>[];

    if (subject != null && subject.isNotEmpty) {
      params.add('subject=${Uri.encodeComponent(subject)}');
    }
    if (body != null && body.isNotEmpty) {
      params.add('body=${Uri.encodeComponent(body)}');
    }

    if (params.isNotEmpty) {
      buffer.write('?${params.join('&')}');
    }

    return buffer.toString();
  }

  /// Génère un QR code pour un SMS
  String generateSmsQrData({
    required String phone,
    String? message,
  }) {
    final buffer = StringBuffer('sms:$phone');

    if (message != null && message.isNotEmpty) {
      buffer.write('?body=${Uri.encodeComponent(message)}');
    }

    return buffer.toString();
  }

  /// Génère un QR code pour une localisation
  String generateLocationQrData({
    required double latitude,
    required double longitude,
    String? label,
  }) {
    if (label != null && label.isNotEmpty) {
      return 'geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(label)})';
    }
    return 'geo:$latitude,$longitude';
  }

  /// Génère un QR code pour un appel téléphonique
  String generatePhoneQrData(String phone) {
    return 'tel:$phone';
  }

  /// Calcule la version optimale du QR code
  int calculateOptimalVersion(String data) {
    final length = data.length;

    // Versions basées sur la capacité en mode alphanumérique avec correction L
    if (length <= 25) return 1;
    if (length <= 47) return 2;
    if (length <= 77) return 3;
    if (length <= 114) return 4;
    if (length <= 154) return 5;
    if (length <= 195) return 6;
    if (length <= 224) return 7;
    if (length <= 279) return 8;
    if (length <= 335) return 9;
    if (length <= 395) return 10;

    return QrVersions.auto;
  }
}
