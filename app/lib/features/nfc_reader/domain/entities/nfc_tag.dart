import 'package:equatable/equatable.dart';

/// Représente un tag NFC avec toutes ses informations
class NfcTag extends Equatable {
  final String id;
  final String uid;
  final NfcTagType type;
  final NfcTechnology technology;
  final int memorySize;
  final int usedMemory;
  final bool isWritable;
  final bool isLocked;
  final List<NdefRecord> ndefRecords;
  final List<int>? rawData;
  final DateTime scannedAt;
  final String? notes;
  final bool isFavorite;
  final GeoLocation? location;

  const NfcTag({
    required this.id,
    required this.uid,
    required this.type,
    required this.technology,
    required this.memorySize,
    this.usedMemory = 0,
    this.isWritable = true,
    this.isLocked = false,
    this.ndefRecords = const [],
    this.rawData,
    required this.scannedAt,
    this.notes,
    this.isFavorite = false,
    this.location,
  });

  /// Mémoire disponible en bytes
  int get availableMemory => memorySize - usedMemory;

  /// Pourcentage d'utilisation de la mémoire
  double get memoryUsagePercent =>
      memorySize > 0 ? (usedMemory / memorySize) * 100 : 0;

  /// Vérifie si le tag contient des données NDEF
  bool get hasNdefData => ndefRecords.isNotEmpty;

  /// UID formaté avec séparateurs
  String get formattedUid {
    final bytes = uid.replaceAll(':', '').replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < bytes.length; i += 2) {
      if (i > 0) buffer.write(':');
      buffer.write(bytes.substring(i, i + 2 < bytes.length ? i + 2 : bytes.length));
    }
    return buffer.toString().toUpperCase();
  }

  NfcTag copyWith({
    String? id,
    String? uid,
    NfcTagType? type,
    NfcTechnology? technology,
    int? memorySize,
    int? usedMemory,
    bool? isWritable,
    bool? isLocked,
    List<NdefRecord>? ndefRecords,
    List<int>? rawData,
    DateTime? scannedAt,
    String? notes,
    bool? isFavorite,
    GeoLocation? location,
  }) {
    return NfcTag(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      technology: technology ?? this.technology,
      memorySize: memorySize ?? this.memorySize,
      usedMemory: usedMemory ?? this.usedMemory,
      isWritable: isWritable ?? this.isWritable,
      isLocked: isLocked ?? this.isLocked,
      ndefRecords: ndefRecords ?? this.ndefRecords,
      rawData: rawData ?? this.rawData,
      scannedAt: scannedAt ?? this.scannedAt,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      location: location ?? this.location,
    );
  }

  @override
  List<Object?> get props => [
        id,
        uid,
        type,
        technology,
        memorySize,
        usedMemory,
        isWritable,
        isLocked,
        ndefRecords,
        rawData,
        scannedAt,
        notes,
        isFavorite,
        location,
      ];
}

/// Types de tags NFC supportés
enum NfcTagType {
  ntag210('NTAG210', 48),
  ntag212('NTAG212', 128),
  ntag213('NTAG213', 144),
  ntag215('NTAG215', 504),
  ntag216('NTAG216', 888),
  ntag413dna('NTAG413 DNA', 160),
  ntag424dna('NTAG424 DNA', 416),
  mifareClassic1k('MIFARE Classic 1K', 1024),
  mifareClassic4k('MIFARE Classic 4K', 4096),
  mifareUltralight('MIFARE Ultralight', 64),
  mifareUltralightC('MIFARE Ultralight C', 192),
  mifareUltralightEv1('MIFARE Ultralight EV1', 128),
  mifareDesfire('MIFARE DESFire', 8192),
  mifarePlus('MIFARE Plus', 4096),
  topaz512('Topaz 512', 454),
  felica('FeliCa', 1024),
  icodeSlix('ICODE SLIX', 256),
  st25ta('ST25TA', 2048),
  st25tv('ST25TV', 256),
  unknown('Unknown', 0);

  final String displayName;
  final int typicalMemory;

  const NfcTagType(this.displayName, this.typicalMemory);

  static NfcTagType fromString(String? value) {
    if (value == null) return unknown;
    return NfcTagType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() ||
          e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => unknown,
    );
  }
}

/// Technologies NFC supportées
enum NfcTechnology {
  nfcA('NFC-A (ISO 14443-3A)'),
  nfcB('NFC-B (ISO 14443-3B)'),
  nfcF('NFC-F (FeliCa)'),
  nfcV('NFC-V (ISO 15693)'),
  isoDep('ISO-DEP (ISO 14443-4)'),
  ndef('NDEF'),
  mifareClassic('MIFARE Classic'),
  mifareUltralight('MIFARE Ultralight'),
  unknown('Unknown');

  final String displayName;

  const NfcTechnology(this.displayName);

  static NfcTechnology fromString(String? value) {
    if (value == null) return unknown;
    return NfcTechnology.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => unknown,
    );
  }
}

/// Enregistrement NDEF
class NdefRecord extends Equatable {
  final NdefRecordType type;
  final String? typeNameFormat;
  final List<int> payload;
  final String? identifier;
  final String? decodedPayload;

  const NdefRecord({
    required this.type,
    this.typeNameFormat,
    required this.payload,
    this.identifier,
    this.decodedPayload,
  });

  /// Taille du payload en bytes
  int get payloadSize => payload.length;

  /// Payload en hexadécimal
  String get payloadHex =>
      payload.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ').toUpperCase();

  @override
  List<Object?> get props => [type, typeNameFormat, payload, identifier, decodedPayload];
}

/// Types d'enregistrements NDEF
enum NdefRecordType {
  text('Text'),
  uri('URI'),
  smartPoster('Smart Poster'),
  mimeMedia('MIME Media'),
  absoluteUri('Absolute URI'),
  externalType('External Type'),
  unknown('Unknown'),
  empty('Empty'),
  vcard('vCard'),
  wifi('WiFi'),
  bluetooth('Bluetooth'),
  androidApp('Android App Record');

  final String displayName;

  const NdefRecordType(this.displayName);
}

/// Localisation géographique
class GeoLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}
