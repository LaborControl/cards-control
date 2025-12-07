import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart' as nfc_mgr;
import 'package:nfc_manager/platform_tags.dart' as platform_tags;
import 'package:uuid/uuid.dart';
import '../../domain/entities/nfc_tag.dart';

/// Datasource pour les opérations NFC natives
class NfcNativeDatasource {
  final nfc_mgr.NfcManager _nfcManager = nfc_mgr.NfcManager.instance;
  final _uuid = const Uuid();

  StreamController<NfcTag>? _tagStreamController;
  bool _isReading = false;

  /// Référence au dernier tag scanné pour les opérations de lecture mémoire
  nfc_mgr.NfcTag? _lastScannedTag;
  NfcTag? _lastParsedTag;

  /// Getter pour le dernier tag scanné
  nfc_mgr.NfcTag? get lastScannedTag => _lastScannedTag;
  NfcTag? get lastParsedTag => _lastParsedTag;

  /// Vérifie si le NFC est disponible
  Future<bool> isNfcAvailable() async {
    final available = await _nfcManager.isAvailable();
    debugPrint('NFC isAvailable: $available');
    return available;
  }

  /// Démarre la session de lecture
  Future<void> startReading() async {
    debugPrint('NFC startReading called, _isReading: $_isReading');
    if (_isReading) return;

    _tagStreamController = StreamController<NfcTag>.broadcast();
    _isReading = true;

    debugPrint('NFC starting session...');
    await _nfcManager.startSession(
      onDiscovered: (nfc_mgr.NfcTag tag) async {
        debugPrint('NFC tag discovered! Data: ${tag.data}');
        await _onTagDiscovered(tag);
      },
      onError: (nfc_mgr.NfcError error) async {
        debugPrint('NFC error: ${error.message}');
        _onError(error);
      },
    );
    debugPrint('NFC session started');
  }

  /// Arrête la session de lecture
  Future<void> stopReading() async {
    if (!_isReading) return;

    _isReading = false;
    await _nfcManager.stopSession();
    await _tagStreamController?.close();
    _tagStreamController = null;
  }

  /// Stream des tags découverts
  Stream<NfcTag> get tagStream =>
      _tagStreamController?.stream ?? const Stream.empty();

  /// Callback quand un tag est découvert
  Future<void> _onTagDiscovered(nfc_mgr.NfcTag nfcTag) async {
    debugPrint('NFC _onTagDiscovered called');
    try {
      // Sauvegarder la référence au tag pour les lectures futures
      _lastScannedTag = nfcTag;

      final tag = await _parseTag(nfcTag);
      _lastParsedTag = tag;

      debugPrint('NFC tag parsed successfully: ${tag.uid}');
      _tagStreamController?.add(tag);
      debugPrint('NFC tag added to stream');
    } catch (e, stackTrace) {
      debugPrint('NFC error parsing tag: $e');
      debugPrint('NFC stackTrace: $stackTrace');
      _tagStreamController?.addError(e);
    }
  }

  /// Callback en cas d'erreur
  void _onError(dynamic error) {
    debugPrint('NFC _onError called: $error');
    _tagStreamController?.addError(Exception('NFC Error: $error'));
  }

  /// Helper pour convertir les maps dynamiques
  Map<String, dynamic> _toStringDynamicMap(dynamic map) {
    if (map == null) return {};
    return Map<String, dynamic>.from(map as Map);
  }

  /// Parse les données du tag NFC
  Future<NfcTag> _parseTag(dynamic nfcManagerTag) async {
    debugPrint('NFC _parseTag called');
    final tagData = _toStringDynamicMap(nfcManagerTag.data);
    debugPrint('NFC tagData keys: ${tagData.keys.toList()}');

    // Extraction de l'UID
    String uid = '';
    NfcTagType tagType = NfcTagType.unknown;
    NfcTechnology technology = NfcTechnology.unknown;
    int memorySize = 0;
    bool isWritable = true;
    bool isLocked = false;
    List<NdefRecord> ndefRecords = [];
    List<int>? rawData;

    // NFC-A (ISO 14443-3A)
    if (tagData.containsKey('nfca')) {
      final nfca = _toStringDynamicMap(tagData['nfca']);
      uid = _formatUid(nfca['identifier'] as List<dynamic>?);
      technology = NfcTechnology.nfcA;

      // Détection du type basé sur ATQA et SAK
      tagType = _detectTagType(nfca);
    }

    // NDEF
    if (tagData.containsKey('ndef')) {
      final ndef = _toStringDynamicMap(tagData['ndef']);
      technology = NfcTechnology.ndef;

      // Capacité mémoire
      if (ndef.containsKey('maxSize')) {
        memorySize = ndef['maxSize'] as int? ?? 0;
      }

      // État d'écriture
      isWritable = ndef['isWritable'] as bool? ?? true;

      // Message NDEF
      if (ndef.containsKey('cachedMessage')) {
        final cachedMessage = _toStringDynamicMap(ndef['cachedMessage']);
        if (cachedMessage.containsKey('records')) {
          final records = cachedMessage['records'] as List<dynamic>;
          ndefRecords = records.map((r) => _parseNdefRecord(r)).toList();
        }
      }
    }

    // MIFARE Classic
    if (tagData.containsKey('mifareclassic')) {
      final mifare = _toStringDynamicMap(tagData['mifareclassic']);
      technology = NfcTechnology.mifareClassic;
      final type = mifare['type'] as int?;

      if (type == 0) {
        tagType = NfcTagType.mifareClassic1k;
        memorySize = 1024;
      } else if (type == 1) {
        tagType = NfcTagType.mifareClassic4k;
        memorySize = 4096;
      }
    }

    // MIFARE Ultralight
    if (tagData.containsKey('mifareultralight')) {
      final ultralight = _toStringDynamicMap(tagData['mifareultralight']);
      technology = NfcTechnology.mifareUltralight;
      final type = ultralight['type'] as int?;

      if (type == 1) {
        tagType = NfcTagType.mifareUltralight;
        memorySize = 64;
      } else if (type == 2) {
        tagType = NfcTagType.mifareUltralightC;
        memorySize = 192;
      }
    }

    // ISO-DEP (ISO 14443-4)
    if (tagData.containsKey('isodep')) {
      technology = NfcTechnology.isoDep;
      tagType = NfcTagType.mifareDesfire;
    }

    // NFC-F (FeliCa)
    if (tagData.containsKey('nfcf')) {
      final nfcf = _toStringDynamicMap(tagData['nfcf']);
      uid = _formatUid(nfcf['identifier'] as List<dynamic>?);
      technology = NfcTechnology.nfcF;
      tagType = NfcTagType.felica;
    }

    // NFC-V (ISO 15693)
    if (tagData.containsKey('nfcv')) {
      final nfcv = _toStringDynamicMap(tagData['nfcv']);
      uid = _formatUid(nfcv['identifier'] as List<dynamic>?);
      technology = NfcTechnology.nfcV;
      tagType = NfcTagType.icodeSlix;
    }

    // Calcul de la mémoire utilisée
    int usedMemory = 0;
    for (final record in ndefRecords) {
      usedMemory += record.payloadSize + 4; // +4 pour l'en-tête NDEF
    }

    return NfcTag(
      id: _uuid.v4(),
      uid: uid,
      type: tagType,
      technology: technology,
      memorySize: memorySize,
      usedMemory: usedMemory,
      isWritable: isWritable,
      isLocked: isLocked,
      ndefRecords: ndefRecords,
      rawData: rawData,
      scannedAt: DateTime.now(),
    );
  }

  /// Formate l'UID en chaîne hexadécimale
  String _formatUid(List<dynamic>? identifier) {
    if (identifier == null || identifier.isEmpty) return '';
    return identifier
        .map((b) => (b as int).toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }

  /// Détecte le type de tag basé sur les paramètres ATQA/SAK
  NfcTagType _detectTagType(Map<String, dynamic> nfca) {
    final sak = nfca['sak'] as int?;

    if (sak == null) return NfcTagType.unknown;

    // NTAG (SAK = 0x00)
    if (sak == 0x00) {
      // Différencier par la taille - nécessite une lecture supplémentaire
      return NfcTagType.ntag215; // Par défaut
    }

    // MIFARE Classic 1K (SAK = 0x08)
    if (sak == 0x08) return NfcTagType.mifareClassic1k;

    // MIFARE Classic 4K (SAK = 0x18)
    if (sak == 0x18) return NfcTagType.mifareClassic4k;

    // MIFARE Plus (SAK = 0x10 ou 0x11)
    if (sak == 0x10 || sak == 0x11) return NfcTagType.mifarePlus;

    // MIFARE DESFire (SAK = 0x20)
    if (sak == 0x20) return NfcTagType.mifareDesfire;

    return NfcTagType.unknown;
  }

  /// Parse un enregistrement NDEF
  NdefRecord _parseNdefRecord(dynamic recordData) {
    final record = _toStringDynamicMap(recordData);
    final tnf = record['typeNameFormat'] as int? ?? 0;
    final type = record['type'] as List<dynamic>? ?? [];
    final payload = record['payload'] as List<dynamic>? ?? [];
    final identifier = record['identifier'] as List<dynamic>?;

    final payloadBytes = payload.cast<int>();
    final typeBytes = type.cast<int>();

    NdefRecordType recordType = NdefRecordType.unknown;
    String? decodedPayload;

    // Well-Known Type (TNF = 0x01)
    if (tnf == 1) {
      final typeString = String.fromCharCodes(typeBytes);

      if (typeString == 'T') {
        recordType = NdefRecordType.text;
        decodedPayload = _decodeTextPayload(payloadBytes);
      } else if (typeString == 'U') {
        recordType = NdefRecordType.uri;
        decodedPayload = _decodeUriPayload(payloadBytes);
      } else if (typeString == 'Sp') {
        recordType = NdefRecordType.smartPoster;
      }
    }
    // MIME Type (TNF = 0x02)
    else if (tnf == 2) {
      final mimeType = String.fromCharCodes(typeBytes);

      if (mimeType.contains('vcard')) {
        recordType = NdefRecordType.vcard;
        decodedPayload = utf8.decode(payloadBytes, allowMalformed: true);
      } else if (mimeType.contains('wifi')) {
        recordType = NdefRecordType.wifi;
      } else if (mimeType.contains('bluetooth')) {
        recordType = NdefRecordType.bluetooth;
      } else {
        recordType = NdefRecordType.mimeMedia;
        decodedPayload = utf8.decode(payloadBytes, allowMalformed: true);
      }
    }
    // Absolute URI (TNF = 0x03)
    else if (tnf == 3) {
      recordType = NdefRecordType.absoluteUri;
      decodedPayload = String.fromCharCodes(typeBytes);
    }
    // External Type (TNF = 0x04)
    else if (tnf == 4) {
      final typeString = String.fromCharCodes(typeBytes);
      if (typeString.contains('android.com:pkg')) {
        recordType = NdefRecordType.androidApp;
        decodedPayload = utf8.decode(payloadBytes, allowMalformed: true);
      } else {
        recordType = NdefRecordType.externalType;
      }
    }
    // Empty (TNF = 0x00)
    else if (tnf == 0) {
      recordType = NdefRecordType.empty;
    }

    return NdefRecord(
      type: recordType,
      typeNameFormat: 'TNF $tnf',
      payload: payloadBytes,
      identifier: identifier != null ? String.fromCharCodes(identifier.cast<int>()) : null,
      decodedPayload: decodedPayload,
    );
  }

  /// Décode un payload de type texte
  String _decodeTextPayload(List<int> payload) {
    if (payload.isEmpty) return '';

    final statusByte = payload[0];
    final languageCodeLength = statusByte & 0x3F;
    final isUtf16 = (statusByte & 0x80) != 0;

    if (payload.length <= 1 + languageCodeLength) return '';

    final textBytes = payload.sublist(1 + languageCodeLength);

    if (isUtf16) {
      // UTF-16 decoding
      return String.fromCharCodes(textBytes);
    } else {
      // UTF-8 decoding
      return utf8.decode(textBytes, allowMalformed: true);
    }
  }

  /// Décode un payload de type URI
  String _decodeUriPayload(List<int> payload) {
    if (payload.isEmpty) return '';

    final prefixCode = payload[0];
    final uriPart = utf8.decode(payload.sublist(1), allowMalformed: true);

    // Préfixes URI standard
    const uriPrefixes = {
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

    final prefix = uriPrefixes[prefixCode] ?? '';
    return '$prefix$uriPart';
  }

  // ============== LECTURE MÉMOIRE ==============

  /// Démarre une session de lecture mémoire (doit maintenir le tag actif)
  Future<void> startMemoryReadSession({
    required Function(List<int> data, int progress, int total) onProgress,
    required Function(List<int> fullData) onComplete,
    required Function(String error) onError,
  }) async {
    if (_lastScannedTag == null) {
      onError('Aucun tag scanné. Veuillez d\'abord scanner un tag.');
      return;
    }

    debugPrint('Starting memory read session...');

    await _nfcManager.startSession(
      onDiscovered: (nfc_mgr.NfcTag tag) async {
        try {
          final data = await readMemoryFromTag(
            tag,
            onProgress: onProgress,
          );
          onComplete(data);
        } catch (e) {
          onError('Erreur lors de la lecture: $e');
        } finally {
          await _nfcManager.stopSession();
        }
      },
      onError: (nfc_mgr.NfcError error) async {
        onError('Erreur NFC: ${error.message}');
      },
    );
  }

  /// Lit la mémoire complète d'un tag
  Future<List<int>> readMemoryFromTag(
    nfc_mgr.NfcTag tag, {
    Function(List<int> data, int progress, int total)? onProgress,
  }) async {
    final tagData = _toStringDynamicMap(tag.data);
    debugPrint('Reading memory from tag with keys: ${tagData.keys}');

    // MIFARE Ultralight / NTAG
    if (tagData.containsKey('mifareultralight')) {
      return await _readMifareUltralightMemory(tag, onProgress: onProgress);
    }

    // MIFARE Classic
    if (tagData.containsKey('mifareclassic')) {
      return await _readMifareClassicMemory(tag, onProgress: onProgress);
    }

    // NFC-A (utilisé pour NTAG quand mifareultralight n'est pas disponible)
    if (tagData.containsKey('nfca')) {
      return await _readNfcAMemory(tag, onProgress: onProgress);
    }

    // ISO-DEP (MIFARE DESFire, etc.)
    if (tagData.containsKey('isodep')) {
      return await _readIsoDepMemory(tag, onProgress: onProgress);
    }

    // NFC-V (ISO 15693)
    if (tagData.containsKey('nfcv')) {
      return await _readNfcVMemory(tag, onProgress: onProgress);
    }

    // NFC-F (FeliCa)
    if (tagData.containsKey('nfcf')) {
      return await _readNfcFMemory(tag, onProgress: onProgress);
    }

    throw Exception('Type de tag non supporté pour la lecture mémoire');
  }

  /// Lecture mémoire MIFARE Ultralight / NTAG
  Future<List<int>> _readMifareUltralightMemory(
    nfc_mgr.NfcTag tag, {
    Function(List<int> data, int progress, int total)? onProgress,
  }) async {
    debugPrint('Reading MIFARE Ultralight memory...');
    final mifareUltralight = platform_tags.MifareUltralight.from(tag);
    if (mifareUltralight == null) {
      throw Exception('Impossible d\'accéder au tag MIFARE Ultralight');
    }

    final List<int> allData = [];

    // Déterminer le nombre de pages à lire selon le type
    // NTAG213: 45 pages, NTAG215: 135 pages, NTAG216: 231 pages
    // MIFARE Ultralight: 16 pages, Ultralight C: 48 pages
    int totalPages = 45; // Par défaut NTAG213

    // Essayer de lire la page de configuration pour déterminer le type
    try {
      // Lire quelques pages pour estimer la taille
      final testRead = await mifareUltralight.readPages(pageOffset: 0);
      if (testRead.isNotEmpty) {
        // Essayer de lire jusqu'à ce qu'on échoue
        for (int page = 0; page < 256; page += 4) {
          try {
            final data = await mifareUltralight.readPages(pageOffset: page);
            if (data.isEmpty) break;
            allData.addAll(data);
            onProgress?.call(allData.toList(), page + 4, totalPages);

            // Mettre à jour l'estimation du total
            if (page + 4 >= totalPages && allData.isNotEmpty) {
              totalPages = page + 8;
            }
          } catch (e) {
            debugPrint('Fin de lecture à la page $page: $e');
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lecture MIFARE Ultralight: $e');
      throw Exception('Erreur lors de la lecture: $e');
    }

    debugPrint('MIFARE Ultralight: ${allData.length} bytes lus');
    return allData;
  }

  /// Lecture mémoire MIFARE Classic
  Future<List<int>> _readMifareClassicMemory(
    nfc_mgr.NfcTag tag, {
    Function(List<int> data, int progress, int total)? onProgress,
  }) async {
    debugPrint('Reading MIFARE Classic memory...');
    final mifareClassic = platform_tags.MifareClassic.from(tag);
    if (mifareClassic == null) {
      throw Exception('Impossible d\'accéder au tag MIFARE Classic');
    }

    final List<int> allData = [];

    // MIFARE Classic 1K: 16 secteurs, 4 blocs par secteur
    // MIFARE Classic 4K: 32 secteurs de 4 blocs + 8 secteurs de 16 blocs
    final int sectorCount = mifareClassic.sectorCount;
    final int totalBlocks = sectorCount * 4; // Approximation

    // Clés par défaut à essayer
    final List<Uint8List> defaultKeys = [
      Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]), // Clé par défaut
      Uint8List.fromList([0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5]), // MAD key
      Uint8List.fromList([0xD3, 0xF7, 0xD3, 0xF7, 0xD3, 0xF7]), // NDEF key
      Uint8List.fromList([0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), // All zeros
    ];

    int blocksRead = 0;

    for (int sector = 0; sector < sectorCount; sector++) {
      bool authenticated = false;

      // Essayer chaque clé
      for (final key in defaultKeys) {
        try {
          await mifareClassic.authenticateSectorWithKeyA(
            sectorIndex: sector,
            key: key,
          );
          authenticated = true;
          break;
        } catch (e) {
          // Essayer la clé B
          try {
            await mifareClassic.authenticateSectorWithKeyB(
              sectorIndex: sector,
              key: key,
            );
            authenticated = true;
            break;
          } catch (_) {
            continue;
          }
        }
      }

      if (authenticated) {
        // Lire tous les blocs du secteur
        // Calculer le premier bloc du secteur
        // Pour MIFARE Classic 1K: chaque secteur a 4 blocs
        // Pour MIFARE Classic 4K: secteurs 0-31 ont 4 blocs, secteurs 32-39 ont 16 blocs
        final int firstBlock;
        final int blockCount;
        if (sector < 32) {
          firstBlock = sector * 4;
          blockCount = 4;
        } else {
          firstBlock = 32 * 4 + (sector - 32) * 16;
          blockCount = 16;
        }

        for (int i = 0; i < blockCount; i++) {
          try {
            final blockData = await mifareClassic.readBlock(
              blockIndex: firstBlock + i,
            );
            allData.addAll(blockData);
            blocksRead++;
            onProgress?.call(allData.toList(), blocksRead, totalBlocks);
          } catch (e) {
            debugPrint('Erreur lecture bloc ${firstBlock + i}: $e');
            // Ajouter des bytes vides pour ce bloc
            allData.addAll(List.filled(16, 0));
            blocksRead++;
          }
        }
      } else {
        // Secteur protégé - ajouter des bytes vides
        final protectedBlockCount = sector < 32 ? 4 : 16;
        for (int i = 0; i < protectedBlockCount; i++) {
          allData.addAll(List.filled(16, 0));
          blocksRead++;
        }
        debugPrint('Secteur $sector protégé');
      }
    }

    debugPrint('MIFARE Classic: ${allData.length} bytes lus');
    return allData;
  }

  /// Lecture mémoire via NFC-A (commandes brutes)
  Future<List<int>> _readNfcAMemory(
    nfc_mgr.NfcTag tag, {
    Function(List<int> data, int progress, int total)? onProgress,
  }) async {
    debugPrint('Reading NFC-A memory...');
    final nfcA = platform_tags.NfcA.from(tag);
    if (nfcA == null) {
      throw Exception('Impossible d\'accéder au tag NFC-A');
    }

    final List<int> allData = [];
    int page = 0;
    final int estimatedPages = 45; // Par défaut NTAG213

    while (true) {
      try {
        // Commande READ (0x30) suivie du numéro de page
        final command = Uint8List.fromList([0x30, page]);
        final response = await nfcA.transceive(data: command);

        if (response.isEmpty) break;

        // La commande READ retourne 16 bytes (4 pages)
        allData.addAll(response);
        page += 4;
        onProgress?.call(allData.toList(), page, estimatedPages);

        // Limiter à 256 pages max
        if (page >= 256) break;
      } catch (e) {
        debugPrint('Fin de lecture NFC-A à la page $page: $e');
        break;
      }
    }

    debugPrint('NFC-A: ${allData.length} bytes lus');
    return allData;
  }

  /// Lecture mémoire ISO-DEP (MIFARE DESFire, etc.)
  Future<List<int>> _readIsoDepMemory(
    nfc_mgr.NfcTag tag, {
    Function(List<int> data, int progress, int total)? onProgress,
  }) async {
    debugPrint('Reading ISO-DEP memory...');
    final isoDep = platform_tags.IsoDep.from(tag);
    if (isoDep == null) {
      throw Exception('Impossible d\'accéder au tag ISO-DEP');
    }

    final List<int> allData = [];

    try {
      // Commande SELECT pour obtenir les infos
      // Pour DESFire: GetVersion command
      final getVersionCmd = Uint8List.fromList([0x90, 0x60, 0x00, 0x00, 0x00]);
      final versionResponse = await isoDep.transceive(data: getVersionCmd);
      allData.addAll(versionResponse);
      onProgress?.call(allData.toList(), 1, 10);

      // Essayer de lire les fichiers disponibles
      // Commande GetFileIDs
      final getFileIdsCmd = Uint8List.fromList([0x90, 0x6F, 0x00, 0x00, 0x00]);
      try {
        final fileIdsResponse = await isoDep.transceive(data: getFileIdsCmd);
        allData.addAll(fileIdsResponse);
        onProgress?.call(allData.toList(), 2, 10);
      } catch (e) {
        debugPrint('GetFileIDs non supporté: $e');
      }

      // Pour les cartes ISO 7816 standard, essayer de lire le fichier EF.DIR
      final selectMfCmd = Uint8List.fromList([
        0x00, 0xA4, 0x00, 0x00, 0x02, 0x3F, 0x00
      ]);
      try {
        final mfResponse = await isoDep.transceive(data: selectMfCmd);
        allData.addAll(mfResponse);
        onProgress?.call(allData.toList(), 3, 10);
      } catch (e) {
        debugPrint('Select MF non supporté: $e');
      }
    } catch (e) {
      debugPrint('Erreur lecture ISO-DEP: $e');
    }

    debugPrint('ISO-DEP: ${allData.length} bytes lus');
    return allData;
  }

  /// Lecture mémoire NFC-V (ISO 15693)
  Future<List<int>> _readNfcVMemory(
    nfc_mgr.NfcTag tag, {
    Function(List<int> data, int progress, int total)? onProgress,
  }) async {
    debugPrint('Reading NFC-V memory...');
    final nfcV = platform_tags.NfcV.from(tag);
    if (nfcV == null) {
      throw Exception('Impossible d\'accéder au tag NFC-V');
    }

    final List<int> allData = [];
    final int estimatedBlocks = 64; // ICODE SLIX: 32-128 blocs

    for (int block = 0; block < 256; block++) {
      try {
        // Commande READ_SINGLE_BLOCK (0x20)
        // Flags: 0x22 = High data rate + Addressed mode
        final command = Uint8List.fromList([
          0x22, // Flags
          0x20, // Command: Read Single Block
          ...nfcV.identifier.reversed, // UID en little-endian
          block, // Block number
        ]);

        final response = await nfcV.transceive(data: command);

        if (response.isNotEmpty && response[0] == 0x00) {
          // Premier byte est le flag de réponse
          allData.addAll(response.sublist(1));
          onProgress?.call(allData.toList(), block + 1, estimatedBlocks);
        } else {
          break;
        }
      } catch (e) {
        debugPrint('Fin de lecture NFC-V au bloc $block: $e');
        break;
      }
    }

    debugPrint('NFC-V: ${allData.length} bytes lus');
    return allData;
  }

  /// Lecture mémoire NFC-F (FeliCa)
  Future<List<int>> _readNfcFMemory(
    nfc_mgr.NfcTag tag, {
    Function(List<int> data, int progress, int total)? onProgress,
  }) async {
    debugPrint('Reading NFC-F memory...');
    final nfcF = platform_tags.NfcF.from(tag);
    if (nfcF == null) {
      throw Exception('Impossible d\'accéder au tag NFC-F');
    }

    final List<int> allData = [];

    try {
      // FeliCa utilise des commandes spécifiques
      // Commande Read Without Encryption (0x06)
      final idm = nfcF.identifier;

      // Lire le bloc système 0x00
      final command = Uint8List.fromList([
        0x10, // Length
        0x06, // Command: Read Without Encryption
        ...idm, // IDm (8 bytes)
        0x01, // Number of services
        0x0B, 0x00, // Service code (little-endian)
        0x01, // Number of blocks
        0x80, 0x00, // Block list element
      ]);

      final response = await nfcF.transceive(data: command);
      if (response.isNotEmpty) {
        allData.addAll(response);
        onProgress?.call(allData.toList(), 1, 1);
      }
    } catch (e) {
      debugPrint('Erreur lecture NFC-F: $e');
    }

    debugPrint('NFC-F: ${allData.length} bytes lus');
    return allData;
  }

  /// Lit les données brutes du dernier tag scanné (méthode legacy)
  Future<List<int>> readRawData(dynamic tag) async {
    if (tag is nfc_mgr.NfcTag) {
      return await readMemoryFromTag(tag);
    }
    return [];
  }

  // ==================== ÉCRITURE NFC ====================

  bool _isWriting = false;

  /// Démarre une session d'écriture NFC
  Future<void> startWriteSession({
    required NdefWriteData writeData,
    required Function() onWriteSuccess,
    required Function(String error) onWriteError,
  }) async {
    if (_isWriting) {
      onWriteError('Une session d\'écriture est déjà en cours');
      return;
    }

    _isWriting = true;
    debugPrint('NFC Write: Starting write session with data type: ${writeData.type}');

    try {
      await _nfcManager.startSession(
        onDiscovered: (nfc_mgr.NfcTag tag) async {
          debugPrint('NFC Write: Tag discovered for writing');
          try {
            await _writeNdefToTag(tag, writeData);
            _isWriting = false;
            await _nfcManager.stopSession();
            onWriteSuccess();
          } catch (e) {
            debugPrint('NFC Write Error: $e');
            _isWriting = false;
            await _nfcManager.stopSession(errorMessage: e.toString());
            onWriteError(e.toString());
          }
        },
        onError: (nfc_mgr.NfcError error) async {
          debugPrint('NFC Write Session Error: ${error.message}');
          _isWriting = false;
          onWriteError(error.message);
        },
      );
    } catch (e) {
      _isWriting = false;
      onWriteError(e.toString());
    }
  }

  /// Arrête la session d'écriture
  Future<void> stopWriteSession() async {
    if (_isWriting) {
      _isWriting = false;
      await _nfcManager.stopSession();
    }
  }

  /// Écrit les données NDEF sur le tag
  Future<void> _writeNdefToTag(nfc_mgr.NfcTag tag, NdefWriteData writeData) async {
    final ndefMessage = _buildNdefMessage(writeData);
    final messageSize = _calculateNdefMessageSize(ndefMessage);

    // Essayer d'abord NDEF (tag déjà formaté)
    final ndef = nfc_mgr.Ndef.from(tag);
    if (ndef != null) {
      if (!ndef.isWritable) {
        throw Exception('Ce tag est protégé en écriture');
      }

      if (messageSize > ndef.maxSize) {
        throw Exception(
          'Les données sont trop volumineuses pour ce tag '
          '($messageSize bytes, max: ${ndef.maxSize} bytes)'
        );
      }

      debugPrint('NFC Write: Writing $messageSize bytes to NDEF tag (max: ${ndef.maxSize})');
      await ndef.write(ndefMessage);
      debugPrint('NFC Write: Success!');
      return;
    }

    // Si pas NDEF, essayer NdefFormatable (tag vierge à formater)
    final ndefFormatable = platform_tags.NdefFormatable.from(tag);
    if (ndefFormatable != null) {
      debugPrint('NFC Write: Tag needs formatting, using NdefFormatable');
      debugPrint('NFC Write: Formatting and writing $messageSize bytes');
      await ndefFormatable.format(ndefMessage);
      debugPrint('NFC Write: Format and write success!');
      return;
    }

    // Ni NDEF ni NdefFormatable
    throw Exception('Ce tag ne supporte pas NDEF et ne peut pas être formaté');
  }

  /// Construit le message NDEF à écrire
  nfc_mgr.NdefMessage _buildNdefMessage(NdefWriteData writeData) {
    final records = <nfc_mgr.NdefRecord>[];

    switch (writeData.type) {
      case NdefWriteType.url:
        records.add(_createUriRecord(writeData.url!));
        break;

      case NdefWriteType.text:
        records.add(_createTextRecord(writeData.text!));
        break;

      case NdefWriteType.phone:
        records.add(_createUriRecord('tel:${writeData.phone}'));
        break;

      case NdefWriteType.email:
        var uri = 'mailto:${writeData.email}';
        if (writeData.subject != null && writeData.subject!.isNotEmpty) {
          uri += '?subject=${Uri.encodeComponent(writeData.subject!)}';
          if (writeData.body != null && writeData.body!.isNotEmpty) {
            uri += '&body=${Uri.encodeComponent(writeData.body!)}';
          }
        } else if (writeData.body != null && writeData.body!.isNotEmpty) {
          uri += '?body=${Uri.encodeComponent(writeData.body!)}';
        }
        records.add(_createUriRecord(uri));
        break;

      case NdefWriteType.sms:
        var uri = 'sms:${writeData.phone}';
        if (writeData.message != null && writeData.message!.isNotEmpty) {
          uri += '?body=${Uri.encodeComponent(writeData.message!)}';
        }
        records.add(_createUriRecord(uri));
        break;

      case NdefWriteType.wifi:
        records.add(_createWifiRecord(
          ssid: writeData.ssid!,
          password: writeData.password ?? '',
          authType: writeData.authType ?? 'WPA2',
          hidden: writeData.hidden ?? false,
        ));
        break;

      case NdefWriteType.vcard:
        records.add(_createVCardRecord(
          firstName: writeData.firstName ?? '',
          lastName: writeData.lastName ?? '',
          organization: writeData.organization,
          title: writeData.title,
          phone: writeData.phone,
          email: writeData.email,
          website: writeData.website,
        ));
        break;
    }

    return nfc_mgr.NdefMessage(records);
  }

  /// Crée un record URI
  nfc_mgr.NdefRecord _createUriRecord(String uri) {
    // Déterminer le préfixe URI
    int prefixCode = 0x00; // Pas de préfixe
    String uriWithoutPrefix = uri;

    final prefixes = {
      0x01: 'http://www.',
      0x02: 'https://www.',
      0x03: 'http://',
      0x04: 'https://',
      0x05: 'tel:',
      0x06: 'mailto:',
    };

    for (final entry in prefixes.entries) {
      if (uri.startsWith(entry.value)) {
        prefixCode = entry.key;
        uriWithoutPrefix = uri.substring(entry.value.length);
        break;
      }
    }

    final payload = Uint8List.fromList([
      prefixCode,
      ...utf8.encode(uriWithoutPrefix),
    ]);

    return nfc_mgr.NdefRecord(
      typeNameFormat: nfc_mgr.NdefTypeNameFormat.nfcWellknown,
      type: Uint8List.fromList([0x55]), // 'U' for URI
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  /// Crée un record Texte
  nfc_mgr.NdefRecord _createTextRecord(String text, {String language = 'fr'}) {
    final langBytes = utf8.encode(language);
    final textBytes = utf8.encode(text);

    final payload = Uint8List.fromList([
      langBytes.length, // Status byte (length of language code)
      ...langBytes,
      ...textBytes,
    ]);

    return nfc_mgr.NdefRecord(
      typeNameFormat: nfc_mgr.NdefTypeNameFormat.nfcWellknown,
      type: Uint8List.fromList([0x54]), // 'T' for Text
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  /// Crée un record WiFi
  nfc_mgr.NdefRecord _createWifiRecord({
    required String ssid,
    required String password,
    required String authType,
    required bool hidden,
  }) {
    // Format WiFi Simple Configuration (WSC)
    // Authentication Type
    int authTypeValue;
    switch (authType.toUpperCase()) {
      case 'WPA':
        authTypeValue = 0x0002;
        break;
      case 'WPA2':
      case 'WPA2-PSK':
        authTypeValue = 0x0020;
        break;
      case 'WEP':
        authTypeValue = 0x0001;
        break;
      case 'OPEN':
      default:
        authTypeValue = 0x0001;
        break;
    }

    // Encryption Type
    int encryptionType;
    switch (authType.toUpperCase()) {
      case 'WPA':
      case 'WPA2':
      case 'WPA2-PSK':
        encryptionType = 0x0008; // AES
        break;
      case 'WEP':
        encryptionType = 0x0002; // WEP
        break;
      case 'OPEN':
      default:
        encryptionType = 0x0001; // None
        break;
    }

    final buffer = BytesBuilder();

    // Credential
    final credentialBuffer = BytesBuilder();

    // Network Index
    credentialBuffer.add([0x10, 0x26, 0x00, 0x01, 0x01]);

    // SSID
    final ssidBytes = utf8.encode(ssid);
    credentialBuffer.add([0x10, 0x45]);
    credentialBuffer.add([(ssidBytes.length >> 8) & 0xFF, ssidBytes.length & 0xFF]);
    credentialBuffer.add(ssidBytes);

    // Authentication Type
    credentialBuffer.add([0x10, 0x03, 0x00, 0x02]);
    credentialBuffer.add([(authTypeValue >> 8) & 0xFF, authTypeValue & 0xFF]);

    // Encryption Type
    credentialBuffer.add([0x10, 0x0F, 0x00, 0x02]);
    credentialBuffer.add([(encryptionType >> 8) & 0xFF, encryptionType & 0xFF]);

    // Network Key (Password)
    final passwordBytes = utf8.encode(password);
    credentialBuffer.add([0x10, 0x27]);
    credentialBuffer.add([(passwordBytes.length >> 8) & 0xFF, passwordBytes.length & 0xFF]);
    credentialBuffer.add(passwordBytes);

    // MAC Address (Broadcast)
    credentialBuffer.add([0x10, 0x20, 0x00, 0x06, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);

    final credentialBytes = credentialBuffer.toBytes();

    // Add Credential TLV
    buffer.add([0x10, 0x0E]);
    buffer.add([(credentialBytes.length >> 8) & 0xFF, credentialBytes.length & 0xFF]);
    buffer.add(credentialBytes);

    return nfc_mgr.NdefRecord(
      typeNameFormat: nfc_mgr.NdefTypeNameFormat.media,
      type: Uint8List.fromList(utf8.encode('application/vnd.wfa.wsc')),
      identifier: Uint8List(0),
      payload: Uint8List.fromList(buffer.toBytes()),
    );
  }

  /// Crée un record vCard
  nfc_mgr.NdefRecord _createVCardRecord({
    required String firstName,
    required String lastName,
    String? organization,
    String? title,
    String? phone,
    String? email,
    String? website,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('N:$lastName;$firstName;;;');
    buffer.writeln('FN:$firstName $lastName');

    if (organization != null && organization.isNotEmpty) {
      buffer.writeln('ORG:$organization');
    }
    if (title != null && title.isNotEmpty) {
      buffer.writeln('TITLE:$title');
    }
    if (phone != null && phone.isNotEmpty) {
      buffer.writeln('TEL;TYPE=CELL:$phone');
    }
    if (email != null && email.isNotEmpty) {
      buffer.writeln('EMAIL:$email');
    }
    if (website != null && website.isNotEmpty) {
      buffer.writeln('URL:$website');
    }

    buffer.writeln('END:VCARD');

    return nfc_mgr.NdefRecord(
      typeNameFormat: nfc_mgr.NdefTypeNameFormat.media,
      type: Uint8List.fromList(utf8.encode('text/vcard')),
      identifier: Uint8List(0),
      payload: Uint8List.fromList(utf8.encode(buffer.toString())),
    );
  }

  /// Calcule la taille approximative du message NDEF
  int _calculateNdefMessageSize(nfc_mgr.NdefMessage message) {
    int size = 0;
    for (final record in message.records) {
      size += 3; // Header bytes
      size += record.type.length;
      size += record.payload.length;
      size += record.identifier.length;
    }
    return size;
  }
}

/// Types d'écriture NDEF supportés
enum NdefWriteType {
  url,
  text,
  phone,
  email,
  sms,
  wifi,
  vcard,
}

/// Données à écrire sur le tag NFC
class NdefWriteData {
  final NdefWriteType type;

  // URL
  final String? url;

  // Text
  final String? text;

  // Phone / SMS
  final String? phone;
  final String? message;

  // Email
  final String? email;
  final String? subject;
  final String? body;

  // WiFi
  final String? ssid;
  final String? password;
  final String? authType;
  final bool? hidden;

  // vCard
  final String? firstName;
  final String? lastName;
  final String? organization;
  final String? title;
  final String? website;

  const NdefWriteData({
    required this.type,
    this.url,
    this.text,
    this.phone,
    this.message,
    this.email,
    this.subject,
    this.body,
    this.ssid,
    this.password,
    this.authType,
    this.hidden,
    this.firstName,
    this.lastName,
    this.organization,
    this.title,
    this.website,
  });
}
