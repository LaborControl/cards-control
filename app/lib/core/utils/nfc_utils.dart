import 'dart:typed_data';

/// Utilitaires pour la manipulation des données NFC
class NfcUtils {
  NfcUtils._();

  /// Convertit une liste de bytes en chaîne hexadécimale
  static String bytesToHex(List<int> bytes, {String separator = ':'}) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(separator);
  }

  /// Convertit une chaîne hexadécimale en liste de bytes
  static List<int> hexToBytes(String hex) {
    hex = hex.replaceAll(RegExp(r'[:\s-]'), '');
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  /// Formate un UID NFC pour l'affichage
  static String formatUid(String uid) {
    if (uid.contains(':')) return uid;
    final buffer = StringBuffer();
    for (var i = 0; i < uid.length; i += 2) {
      if (i > 0) buffer.write(':');
      buffer.write(uid.substring(i, i + 2).toUpperCase());
    }
    return buffer.toString();
  }

  /// Calcule la taille mémoire formatée
  static String formatMemorySize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Décode un préfixe URI NDEF
  static String decodeUriPrefix(int prefix) {
    const prefixes = {
      0x00: '',
      0x01: 'http://www.',
      0x02: 'https://www.',
      0x03: 'http://',
      0x04: 'https://',
      0x05: 'tel:',
      0x06: 'mailto:',
      0x07: 'ftp://anonymous:anonymous@',
      0x08: 'ftp://ftp.',
      0x09: 'ftps://',
      0x0A: 'sftp://',
      0x0B: 'smb://',
      0x0C: 'nfs://',
      0x0D: 'ftp://',
      0x0E: 'dav://',
      0x0F: 'news:',
      0x10: 'telnet://',
      0x11: 'imap:',
      0x12: 'rtsp://',
      0x13: 'urn:',
      0x14: 'pop:',
      0x15: 'sip:',
      0x16: 'sips:',
      0x17: 'tftp:',
      0x18: 'btspp://',
      0x19: 'btl2cap://',
      0x1A: 'btgoep://',
      0x1B: 'tcpobex://',
      0x1C: 'irdaobex://',
      0x1D: 'file://',
      0x1E: 'urn:epc:id:',
      0x1F: 'urn:epc:tag:',
      0x20: 'urn:epc:pat:',
      0x21: 'urn:epc:raw:',
      0x22: 'urn:epc:',
      0x23: 'urn:nfc:',
    };
    return prefixes[prefix] ?? '';
  }

  /// Encode un préfixe URI NDEF
  static int encodeUriPrefix(String uri) {
    if (uri.startsWith('https://www.')) return 0x02;
    if (uri.startsWith('http://www.')) return 0x01;
    if (uri.startsWith('https://')) return 0x04;
    if (uri.startsWith('http://')) return 0x03;
    if (uri.startsWith('tel:')) return 0x05;
    if (uri.startsWith('mailto:')) return 0x06;
    return 0x00;
  }

  /// Supprime le préfixe d'une URI
  static String removeUriPrefix(String uri) {
    final prefixes = [
      'https://www.',
      'http://www.',
      'https://',
      'http://',
      'tel:',
      'mailto:',
    ];
    for (final prefix in prefixes) {
      if (uri.startsWith(prefix)) {
        return uri.substring(prefix.length);
      }
    }
    return uri;
  }

  /// Décode un payload texte NDEF
  static String decodeTextPayload(List<int> payload) {
    if (payload.isEmpty) return '';

    final statusByte = payload[0];
    final languageCodeLength = statusByte & 0x3F;
    final isUtf16 = (statusByte & 0x80) != 0;

    if (payload.length < 1 + languageCodeLength) return '';

    final textBytes = payload.sublist(1 + languageCodeLength);

    if (isUtf16) {
      return String.fromCharCodes(Uint16List.view(Uint8List.fromList(textBytes).buffer));
    } else {
      return String.fromCharCodes(textBytes);
    }
  }

  /// Encode un payload texte NDEF
  static List<int> encodeTextPayload(String text, {String languageCode = 'en'}) {
    final languageCodeBytes = languageCode.codeUnits;
    final textBytes = text.codeUnits;

    return [
      languageCodeBytes.length, // Status byte (UTF-8, language code length)
      ...languageCodeBytes,
      ...textBytes,
    ];
  }

  /// Parse une configuration WiFi
  static Map<String, String>? parseWifiConfig(String payload) {
    // Format: WIFI:T:WPA;S:SSID;P:password;;
    if (!payload.startsWith('WIFI:')) return null;

    final result = <String, String>{};
    final parts = payload.substring(5).split(';');

    for (final part in parts) {
      if (part.isEmpty) continue;
      final colonIndex = part.indexOf(':');
      if (colonIndex == -1) continue;

      final key = part.substring(0, colonIndex);
      final value = part.substring(colonIndex + 1);

      switch (key) {
        case 'T':
          result['authType'] = value;
          break;
        case 'S':
          result['ssid'] = value;
          break;
        case 'P':
          result['password'] = value;
          break;
        case 'H':
          result['hidden'] = value;
          break;
      }
    }

    return result.isNotEmpty ? result : null;
  }

  /// Génère une configuration WiFi NDEF
  static String generateWifiConfig({
    required String ssid,
    required String password,
    String authType = 'WPA',
    bool hidden = false,
  }) {
    final buffer = StringBuffer('WIFI:');
    buffer.write('T:$authType;');
    buffer.write('S:$ssid;');
    buffer.write('P:$password;');
    if (hidden) buffer.write('H:true;');
    buffer.write(';');
    return buffer.toString();
  }

  /// Vérifie si un tag est compatible avec l'écriture
  static bool canWrite(String tagType, int memorySize, int dataSize) {
    if (memorySize < dataSize) return false;

    // Types de tags non inscriptibles
    const readOnlyTypes = ['MIFARE_CLASSIC_1K', 'MIFARE_CLASSIC_4K', 'MIFARE_ULTRALIGHT_C'];
    if (readOnlyTypes.contains(tagType)) return false;

    return true;
  }

  /// Estime la taille NDEF d'un payload
  static int estimateNdefSize(String type, String content) {
    // Header NDEF: ~7 bytes
    // Type: variable
    // Payload: variable

    int headerSize = 7;
    int typeSize = type.length;
    int payloadSize = content.codeUnits.length;

    // Ajouter le préfixe URI si nécessaire
    if (type == 'U') {
      payloadSize += 1; // Byte du préfixe
    } else if (type == 'T') {
      payloadSize += 3; // Status byte + language code
    }

    return headerSize + typeSize + payloadSize;
  }
}

/// Extensions pour les listes de bytes
extension ByteListExtension on List<int> {
  String toHexString({String separator = ':'}) {
    return NfcUtils.bytesToHex(this, separator: separator);
  }

  Uint8List toUint8List() {
    return Uint8List.fromList(this);
  }
}

/// Extensions pour les chaînes hexadécimales
extension HexStringExtension on String {
  List<int> hexToBytes() {
    return NfcUtils.hexToBytes(this);
  }
}
