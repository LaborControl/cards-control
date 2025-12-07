import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Service NFC natif pour Android et iOS
///
/// Ce service communique avec le code natif pour les opérations NFC avancées :
/// - Lecture/écriture de tags NFC
/// - Host Card Emulation (HCE) sur Android
/// - CoreNFC sur iOS
class NativeNfcService {
  static final NativeNfcService instance = NativeNfcService._();
  NativeNfcService._();

  static const _nfcChannel = MethodChannel('com.cardscontrol.app/nfc');
  static const _hceChannel = MethodChannel('com.cardscontrol.app/hce');

  // Stream controllers pour les événements NFC
  final _tagReadController = StreamController<NfcTagData>.broadcast();
  final _tagWrittenController = StreamController<NfcWriteResult>.broadcast();

  /// Stream des tags lus
  Stream<NfcTagData> get onTagRead => _tagReadController.stream;

  /// Stream des résultats d'écriture
  Stream<NfcWriteResult> get onTagWritten => _tagWrittenController.stream;

  /// Initialise le service et configure les handlers
  Future<void> initialize() async {
    _nfcChannel.setMethodCallHandler(_handleNfcMethodCall);
  }

  Future<dynamic> _handleNfcMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onTagRead':
        final data = Map<String, dynamic>.from(call.arguments as Map);
        _tagReadController.add(NfcTagData.fromMap(data));
        break;
      case 'onTagWritten':
        final data = Map<String, dynamic>.from(call.arguments as Map);
        _tagWrittenController.add(NfcWriteResult.fromMap(data));
        break;
    }
    return null;
  }

  // ==================== NFC General ====================

  /// Vérifie si le NFC est disponible sur l'appareil
  Future<bool> isNfcAvailable() async {
    try {
      final result = await _nfcChannel.invokeMethod<bool>('isNfcAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Vérifie si le NFC est activé
  Future<bool> isNfcEnabled() async {
    try {
      final result = await _nfcChannel.invokeMethod<bool>('isNfcEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Ouvre les paramètres NFC du système
  Future<void> openNfcSettings() async {
    try {
      await _nfcChannel.invokeMethod('openNfcSettings');
    } on PlatformException {
      // Ignore
    }
  }

  /// Récupère les informations NFC de l'appareil
  Future<NfcInfo> getNfcInfo() async {
    try {
      final result = await _nfcChannel.invokeMethod<Map>('getNfcInfo');
      if (result != null) {
        return NfcInfo.fromMap(Map<String, dynamic>.from(result));
      }
    } on PlatformException {
      // Ignore
    }
    return NfcInfo.empty();
  }

  // ==================== NFC Reading ====================

  /// Démarre la lecture NFC
  Future<bool> startReading() async {
    try {
      final result = await _nfcChannel.invokeMethod<bool>('startReading');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Arrête la lecture NFC
  Future<void> stopReading() async {
    try {
      await _nfcChannel.invokeMethod('stopReading');
    } on PlatformException {
      // Ignore
    }
  }

  // ==================== NFC Writing ====================

  /// Démarre l'écriture NFC avec les données spécifiées
  Future<bool> startWriting(String data) async {
    try {
      final result = await _nfcChannel.invokeMethod<bool>(
        'startWriting',
        {'data': data},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Arrête l'écriture NFC
  Future<void> stopWriting() async {
    try {
      await _nfcChannel.invokeMethod('stopWriting');
    } on PlatformException {
      // Ignore
    }
  }

  // ==================== HCE (Android only) ====================

  /// Vérifie si le HCE est supporté
  Future<bool> isHceSupported() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _hceChannel.invokeMethod<bool>('isHceSupported');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Vérifie si l'émulation HCE est activée
  Future<bool> isEmulationEnabled() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _hceChannel.invokeMethod<bool>('isEmulationEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Active ou désactive l'émulation HCE
  Future<bool> setEmulationEnabled(bool enabled) async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _hceChannel.invokeMethod<bool>(
        'setEmulationEnabled',
        {'enabled': enabled},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Configure la carte de visite à émuler
  Future<bool> setBusinessCardForEmulation({
    required String cardId,
    required String cardUrl,
    String? vCardData,
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _hceChannel.invokeMethod<bool>(
        'setBusinessCard',
        {
          'cardId': cardId,
          'cardUrl': cardUrl,
          'vCardData': vCardData,
        },
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Configure un template à émuler (avec son URL publique, comme les cartes de visite)
  Future<bool> setTemplateForEmulation({
    required String templateId,
    required String templateUrl,
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _hceChannel.invokeMethod<bool>(
        'setTemplate',
        {
          'templateId': templateId,
          'templateUrl': templateUrl,
        },
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Récupère l'URL de la carte configurée pour l'émulation
  Future<String?> getConfiguredCardUrl() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _hceChannel.invokeMethod<String>('getConfiguredCardUrl');
    } on PlatformException {
      return null;
    }
  }

  /// Efface les données HCE
  Future<void> clearHceData() async {
    if (!Platform.isAndroid) return;
    try {
      await _hceChannel.invokeMethod('clearData');
    } on PlatformException {
      // Ignore
    }
  }

  /// Récupère les informations HCE
  Future<HceInfo> getHceInfo() async {
    if (!Platform.isAndroid) return HceInfo.notSupported();
    try {
      final result = await _hceChannel.invokeMethod<Map>('getHceInfo');
      if (result != null) {
        return HceInfo.fromMap(Map<String, dynamic>.from(result));
      }
    } on PlatformException {
      // Ignore
    }
    return HceInfo.notSupported();
  }

  /// Démarre l'émulation HCE
  /// Cette méthode désactive la lecture NFC et active le service HCE comme service préféré
  Future<bool> startEmulation() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _hceChannel.invokeMethod<bool>('startEmulation');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Arrête l'émulation HCE
  /// Cette méthode désactive le service préféré et réactive la lecture NFC si nécessaire
  Future<bool> stopEmulation() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _hceChannel.invokeMethod<bool>('stopEmulation');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Libère les ressources
  void dispose() {
    _tagReadController.close();
    _tagWrittenController.close();
  }
}

/// Informations NFC de l'appareil
class NfcInfo {
  final bool isAvailable;
  final bool isEnabled;
  final bool hasHce;
  final bool hasHceF;
  final bool hasNfcA;
  final bool hasNfcB;
  final bool hasNfcF;
  final bool hasNfcV;
  final bool hasIsoDep;
  final bool hasMifareClassic;
  final bool hasMifareUltralight;

  NfcInfo({
    required this.isAvailable,
    required this.isEnabled,
    required this.hasHce,
    required this.hasHceF,
    required this.hasNfcA,
    required this.hasNfcB,
    required this.hasNfcF,
    required this.hasNfcV,
    required this.hasIsoDep,
    required this.hasMifareClassic,
    required this.hasMifareUltralight,
  });

  factory NfcInfo.empty() => NfcInfo(
        isAvailable: false,
        isEnabled: false,
        hasHce: false,
        hasHceF: false,
        hasNfcA: false,
        hasNfcB: false,
        hasNfcF: false,
        hasNfcV: false,
        hasIsoDep: false,
        hasMifareClassic: false,
        hasMifareUltralight: false,
      );

  factory NfcInfo.fromMap(Map<String, dynamic> map) => NfcInfo(
        isAvailable: map['isAvailable'] ?? false,
        isEnabled: map['isEnabled'] ?? false,
        hasHce: map['hasHce'] ?? false,
        hasHceF: map['hasHceF'] ?? false,
        hasNfcA: map['hasNfcA'] ?? false,
        hasNfcB: map['hasNfcB'] ?? false,
        hasNfcF: map['hasNfcF'] ?? false,
        hasNfcV: map['hasNfcV'] ?? false,
        hasIsoDep: map['hasIsoDep'] ?? false,
        hasMifareClassic: map['hasMifareClassic'] ?? false,
        hasMifareUltralight: map['hasMifareUltralight'] ?? false,
      );

  List<String> get supportedTechnologies {
    final techs = <String>[];
    if (hasNfcA) techs.add('NfcA');
    if (hasNfcB) techs.add('NfcB');
    if (hasNfcF) techs.add('NfcF');
    if (hasNfcV) techs.add('NfcV');
    if (hasIsoDep) techs.add('IsoDep');
    if (hasMifareClassic) techs.add('MifareClassic');
    if (hasMifareUltralight) techs.add('MifareUltralight');
    if (hasHce) techs.add('HCE');
    if (hasHceF) techs.add('HCE-F');
    return techs;
  }
}

/// Informations HCE
class HceInfo {
  final bool isSupported;
  final bool isEnabled;
  final bool isDefaultService;
  final String? configuredUrl;
  final bool nfcEnabled;

  HceInfo({
    required this.isSupported,
    required this.isEnabled,
    required this.isDefaultService,
    this.configuredUrl,
    required this.nfcEnabled,
  });

  factory HceInfo.notSupported() => HceInfo(
        isSupported: false,
        isEnabled: false,
        isDefaultService: false,
        configuredUrl: null,
        nfcEnabled: false,
      );

  factory HceInfo.fromMap(Map<String, dynamic> map) => HceInfo(
        isSupported: map['isSupported'] ?? false,
        isEnabled: map['isEnabled'] ?? false,
        isDefaultService: map['isDefaultService'] ?? false,
        configuredUrl: map['configuredUrl'] as String?,
        nfcEnabled: map['nfcEnabled'] ?? false,
      );
}

/// Données d'un tag NFC lu
class NfcTagData {
  final String id;
  final List<String> techList;
  final List<NdefRecord>? ndefMessage;
  final String? ndefType;
  final int? ndefMaxSize;
  final bool? ndefCanMakeReadOnly;
  final bool? ndefIsWritable;
  final Map<String, dynamic>? nfcA;
  final Map<String, dynamic>? nfcB;
  final Map<String, dynamic>? nfcF;
  final Map<String, dynamic>? nfcV;
  final Map<String, dynamic>? isoDep;
  final Map<String, dynamic>? mifareClassic;
  final Map<String, dynamic>? mifareUltralight;
  final String? error;

  NfcTagData({
    required this.id,
    required this.techList,
    this.ndefMessage,
    this.ndefType,
    this.ndefMaxSize,
    this.ndefCanMakeReadOnly,
    this.ndefIsWritable,
    this.nfcA,
    this.nfcB,
    this.nfcF,
    this.nfcV,
    this.isoDep,
    this.mifareClassic,
    this.mifareUltralight,
    this.error,
  });

  factory NfcTagData.fromMap(Map<String, dynamic> map) {
    List<NdefRecord>? ndefRecords;
    final ndefMessageData = map['ndefMessage'];
    if (ndefMessageData != null && ndefMessageData is List) {
      ndefRecords = ndefMessageData
          .map((r) => NdefRecord.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    }

    return NfcTagData(
      id: map['id'] ?? '',
      techList: List<String>.from(map['techList'] ?? []),
      ndefMessage: ndefRecords,
      ndefType: map['ndefType'] as String?,
      ndefMaxSize: map['ndefMaxSize'] as int?,
      ndefCanMakeReadOnly: map['ndefCanMakeReadOnly'] as bool?,
      ndefIsWritable: map['ndefIsWritable'] as bool?,
      nfcA: map['nfcA'] != null ? Map<String, dynamic>.from(map['nfcA'] as Map) : null,
      nfcB: map['nfcB'] != null ? Map<String, dynamic>.from(map['nfcB'] as Map) : null,
      nfcF: map['nfcF'] != null ? Map<String, dynamic>.from(map['nfcF'] as Map) : null,
      nfcV: map['nfcV'] != null ? Map<String, dynamic>.from(map['nfcV'] as Map) : null,
      isoDep: map['isoDep'] != null ? Map<String, dynamic>.from(map['isoDep'] as Map) : null,
      mifareClassic: map['mifareClassic'] != null ? Map<String, dynamic>.from(map['mifareClassic'] as Map) : null,
      mifareUltralight: map['mifareUltralight'] != null ? Map<String, dynamic>.from(map['mifareUltralight'] as Map) : null,
      error: map['error'] as String?,
    );
  }

  /// Récupère le contenu texte du premier enregistrement NDEF
  String? get textContent {
    if (ndefMessage == null || ndefMessage!.isEmpty) return null;
    return ndefMessage!.first.payloadString;
  }

  /// Vérifie si le tag contient une URL
  bool get hasUrl {
    if (ndefMessage == null) return false;
    return ndefMessage!.any((r) => r.isUri);
  }

  /// Récupère la première URL trouvée
  String? get url {
    if (ndefMessage == null) return null;
    final uriRecord = ndefMessage!.firstWhere(
      (r) => r.isUri,
      orElse: () => NdefRecord.empty(),
    );
    return uriRecord.payloadString;
  }
}

/// Enregistrement NDEF
class NdefRecord {
  final int tnf;
  final String type;
  final String typeString;
  final String id;
  final String payload;
  final String? payloadString;

  NdefRecord({
    required this.tnf,
    required this.type,
    required this.typeString,
    required this.id,
    required this.payload,
    this.payloadString,
  });

  factory NdefRecord.empty() => NdefRecord(
        tnf: 0,
        type: '',
        typeString: '',
        id: '',
        payload: '',
        payloadString: null,
      );

  factory NdefRecord.fromMap(Map<String, dynamic> map) => NdefRecord(
        tnf: map['tnf'] ?? 0,
        type: map['type'] ?? '',
        typeString: map['typeString'] ?? '',
        id: map['id'] ?? '',
        payload: map['payload'] ?? '',
        payloadString: map['payloadString'] as String?,
      );

  /// TNF Well-Known
  bool get isWellKnown => tnf == 1;

  /// TNF Absolute URI
  bool get isAbsoluteUri => tnf == 3;

  /// Est-ce un enregistrement URI ?
  bool get isUri => (isWellKnown && typeString == 'U') || isAbsoluteUri;

  /// Est-ce un enregistrement Text ?
  bool get isText => isWellKnown && typeString == 'T';
}

/// Résultat d'une opération d'écriture NFC
class NfcWriteResult {
  final bool success;
  final String? error;

  NfcWriteResult({
    required this.success,
    this.error,
  });

  factory NfcWriteResult.fromMap(Map<String, dynamic> map) => NfcWriteResult(
        success: map['success'] ?? false,
        error: map['error'] as String?,
      );
}
