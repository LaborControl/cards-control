class NfcConstants {
  NfcConstants._();

  // NFC Tag Types
  static const String typeNtag = 'NTAG';
  static const String typeMifareClassic = 'MIFARE Classic';
  static const String typeMifareUltralight = 'MIFARE Ultralight';
  static const String typeMifareDesfire = 'MIFARE DESFire';
  static const String typeMifarePlus = 'MIFARE Plus';
  static const String typeIsoDep = 'ISO-DEP';
  static const String typeNfcA = 'NFC-A';
  static const String typeNfcB = 'NFC-B';
  static const String typeNfcF = 'NFC-F';
  static const String typeNfcV = 'NFC-V';
  static const String typeNdef = 'NDEF';
  static const String typeFeliCa = 'FeliCa';
  static const String typeUnknown = 'Unknown';

  // NTAG Variants
  static const String ntag210 = 'NTAG210';
  static const String ntag212 = 'NTAG212';
  static const String ntag213 = 'NTAG213';
  static const String ntag215 = 'NTAG215';
  static const String ntag216 = 'NTAG216';
  static const String ntag413Dna = 'NTAG413 DNA';
  static const String ntag424Dna = 'NTAG424 DNA';
  static const String ntag5Link = 'NTAG5 Link';

  // NTAG Memory Sizes (in bytes)
  static const int ntag210Memory = 48;
  static const int ntag212Memory = 128;
  static const int ntag213Memory = 144;
  static const int ntag215Memory = 504;
  static const int ntag216Memory = 888;
  static const int ntag424Memory = 416;

  // MIFARE Classic Sizes
  static const int mifareClassic1k = 1024;
  static const int mifareClassic4k = 4096;

  // NDEF Record Types
  static const String ndefTypeText = 'T';
  static const String ndefTypeUri = 'U';
  static const String ndefTypeSmartPoster = 'Sp';
  static const String ndefTypeVcard = 'text/vcard';
  static const String ndefTypeWifi = 'application/vnd.wfa.wsc';
  static const String ndefTypeBluetooth = 'application/vnd.bluetooth.ep.oob';
  static const String ndefTypeMime = 'MIME';
  static const String ndefTypeExternal = 'EXT';
  static const String ndefTypeAar = 'android.com:pkg';

  // URI Prefixes (NDEF URI Record)
  static const Map<int, String> uriPrefixes = {
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

  // TNF (Type Name Format) Values
  static const int tnfEmpty = 0x00;
  static const int tnfWellKnown = 0x01;
  static const int tnfMimeMedia = 0x02;
  static const int tnfAbsoluteUri = 0x03;
  static const int tnfExternal = 0x04;
  static const int tnfUnknown = 0x05;
  static const int tnfUnchanged = 0x06;

  // MIFARE Classic Keys
  static const List<int> mifareDefaultKeyA = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF];
  static const List<int> mifareDefaultKeyB = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF];
  static const List<int> mifareNdefKey = [0xD3, 0xF7, 0xD3, 0xF7, 0xD3, 0xF7];

  // Common Well-Known Keys for MIFARE Classic
  static const List<List<int>> commonMifareKeys = [
    [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], // Default
    [0xD3, 0xF7, 0xD3, 0xF7, 0xD3, 0xF7], // NDEF
    [0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5], // MAD
    [0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5], // Common
    [0x00, 0x00, 0x00, 0x00, 0x00, 0x00], // Zeros
  ];

  // WiFi Config Credential Types
  static const int wifiAuthOpen = 0x0001;
  static const int wifiAuthWpaPsk = 0x0002;
  static const int wifiAuthShared = 0x0004;
  static const int wifiAuthWpa = 0x0008;
  static const int wifiAuthWpa2 = 0x0010;
  static const int wifiAuthWpa2Psk = 0x0020;

  // Encryption Types
  static const int wifiEncNone = 0x0001;
  static const int wifiEncWep = 0x0002;
  static const int wifiEncTkip = 0x0004;
  static const int wifiEncAes = 0x0008;

  // Error Messages
  static const String errorNoNfc = 'NFC non disponible sur cet appareil';
  static const String errorNfcDisabled = 'Le NFC est désactivé. Veuillez l\'activer dans les paramètres.';
  static const String errorNoTag = 'Aucun tag détecté';
  static const String errorTagLost = 'Tag perdu. Veuillez réessayer.';
  static const String errorWriteFailed = 'Échec de l\'écriture sur le tag';
  static const String errorReadFailed = 'Échec de la lecture du tag';
  static const String errorTagReadOnly = 'Ce tag est en lecture seule';
  static const String errorTagFull = 'Pas assez d\'espace sur le tag';
  static const String errorAuthFailed = 'Authentification échouée';
  static const String errorUnsupportedTag = 'Type de tag non supporté';
  static const String errorIOException = 'Erreur de communication avec le tag';
}
