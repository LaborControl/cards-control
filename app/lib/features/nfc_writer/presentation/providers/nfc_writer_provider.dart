import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/write_data.dart';

/// État de l'écriture NFC
enum NfcWriterStatus {
  idle,
  preparing,
  waitingForTag,
  writing,
  success,
  error,
}

/// État du writer NFC
class NfcWriterState {
  final NfcWriterStatus status;
  final WriteData? currentData;
  final String? errorMessage;
  final int progress;

  const NfcWriterState({
    this.status = NfcWriterStatus.idle,
    this.currentData,
    this.errorMessage,
    this.progress = 0,
  });

  NfcWriterState copyWith({
    NfcWriterStatus? status,
    WriteData? currentData,
    String? errorMessage,
    int? progress,
  }) {
    return NfcWriterState(
      status: status ?? this.status,
      currentData: currentData ?? this.currentData,
      errorMessage: errorMessage,
      progress: progress ?? this.progress,
    );
  }
}

/// Notifier pour l'écriture NFC
class NfcWriterNotifier extends StateNotifier<NfcWriterState> {
  final Box _templatesBox;
  final Uuid _uuid = const Uuid();

  NfcWriterNotifier(this._templatesBox) : super(const NfcWriterState());

  /// Prépare les données à écrire
  void prepareData(WriteData data) {
    state = state.copyWith(
      status: NfcWriterStatus.preparing,
      currentData: data,
      errorMessage: null,
    );
  }

  /// Démarre l'écriture sur le tag
  Future<void> startWriting() async {
    if (state.currentData == null) {
      state = state.copyWith(
        status: NfcWriterStatus.error,
        errorMessage: 'Aucune donnée à écrire',
      );
      return;
    }

    state = state.copyWith(
      status: NfcWriterStatus.waitingForTag,
      progress: 0,
    );

    // TODO: Implement actual NFC writing logic
    // For now, simulate the writing process
    await Future.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(
      status: NfcWriterStatus.writing,
      progress: 50,
    );

    await Future.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(
      status: NfcWriterStatus.success,
      progress: 100,
    );
  }

  /// Annule l'écriture en cours
  void cancelWriting() {
    state = state.copyWith(
      status: NfcWriterStatus.idle,
      currentData: null,
      errorMessage: null,
      progress: 0,
    );
  }

  /// Réinitialise l'état
  void reset() {
    state = const NfcWriterState();
  }

  /// Génère les bytes NDEF à partir des données
  List<int> generateNdefPayload(WriteData data) {
    switch (data.type) {
      case WriteDataType.url:
        return _generateUrlPayload((data as UrlWriteData).url);
      case WriteDataType.text:
        return _generateTextPayload((data as TextWriteData).text);
      case WriteDataType.vcard:
        final vcard = data as VCardWriteData;
        return _generateVCardPayload(vcard);
      case WriteDataType.wifi:
        final wifi = data as WifiWriteData;
        return _generateWifiPayload(wifi);
      default:
        return [];
    }
  }

  List<int> _generateUrlPayload(String url) {
    // Simplified URL NDEF record generation
    final prefix = _getUriPrefix(url);
    final urlWithoutPrefix = url.replaceFirst(RegExp(r'^https?://'), '');
    final payload = [prefix, ...urlWithoutPrefix.codeUnits];
    return payload;
  }

  int _getUriPrefix(String url) {
    if (url.startsWith('https://www.')) return 0x02;
    if (url.startsWith('http://www.')) return 0x01;
    if (url.startsWith('https://')) return 0x04;
    if (url.startsWith('http://')) return 0x03;
    return 0x00; // No prefix
  }

  List<int> _generateTextPayload(String text) {
    // Text record with UTF-8 encoding and 'en' language
    final languageCode = 'en'.codeUnits;
    final textBytes = text.codeUnits;
    return [languageCode.length, ...languageCode, ...textBytes];
  }

  List<int> _generateVCardPayload(VCardWriteData vcard) {
    final vcardString = '''BEGIN:VCARD
VERSION:3.0
N:${vcard.lastName};${vcard.firstName};;;
FN:${vcard.firstName} ${vcard.lastName}
${vcard.organization != null ? 'ORG:${vcard.organization}' : ''}
${vcard.title != null ? 'TITLE:${vcard.title}' : ''}
${vcard.email != null ? 'EMAIL:${vcard.email}' : ''}
${vcard.phone != null ? 'TEL:${vcard.phone}' : ''}
${vcard.website != null ? 'URL:${vcard.website}' : ''}
${vcard.address != null ? 'ADR:;;${vcard.address};;;;' : ''}
END:VCARD''';
    return vcardString.codeUnits;
  }

  List<int> _generateWifiPayload(WifiWriteData wifi) {
    // WiFi configuration NDEF record (simplified)
    final wifiConfig = 'WIFI:T:${wifi.authType};S:${wifi.ssid};P:${wifi.password};;';
    return wifiConfig.codeUnits;
  }
}

/// État des templates
class WriteTemplatesState {
  final List<WriteTemplate> templates;
  final bool isLoading;

  const WriteTemplatesState({
    this.templates = const [],
    this.isLoading = false,
  });

  WriteTemplatesState copyWith({
    List<WriteTemplate>? templates,
    bool? isLoading,
  }) {
    return WriteTemplatesState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Template d'écriture sauvegardé
class WriteTemplate {
  final String id;
  final String name;
  final WriteDataType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  const WriteTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  factory WriteTemplate.fromJson(Map<String, dynamic> json) {
    return WriteTemplate(
      id: json['id'],
      name: json['name'],
      type: WriteDataType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WriteDataType.text,
      ),
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  WriteTemplate copyWith({
    String? name,
    Map<String, dynamic>? data,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return WriteTemplate(
      id: id,
      name: name ?? this.name,
      type: type,
      data: data ?? this.data,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// Notifier pour les templates
class WriteTemplatesNotifier extends StateNotifier<WriteTemplatesState> {
  final Box _box;
  final Uuid _uuid = const Uuid();

  WriteTemplatesNotifier(this._box) : super(const WriteTemplatesState()) {
    loadTemplates();
  }

  Future<void> loadTemplates() async {
    state = state.copyWith(isLoading: true);

    try {
      final templatesJson = _box.get('templates', defaultValue: <dynamic>[]);
      final templates = (templatesJson as List)
          .map((json) => WriteTemplate.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      templates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = state.copyWith(templates: templates, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<WriteTemplate> saveTemplate({
    required String name,
    required WriteDataType type,
    required Map<String, dynamic> data,
  }) async {
    final now = DateTime.now();
    final template = WriteTemplate(
      id: _uuid.v4(),
      name: name,
      type: type,
      data: data,
      createdAt: now,
      updatedAt: now,
    );

    final updatedTemplates = [...state.templates, template];
    await _saveTemplates(updatedTemplates);
    state = state.copyWith(templates: updatedTemplates);

    return template;
  }

  Future<void> updateTemplate(WriteTemplate template) async {
    final updatedTemplate = template.copyWith(updatedAt: DateTime.now());
    final updatedTemplates = state.templates.map((t) {
      return t.id == template.id ? updatedTemplate : t;
    }).toList();

    await _saveTemplates(updatedTemplates);
    state = state.copyWith(templates: updatedTemplates);
  }

  Future<void> deleteTemplate(String templateId) async {
    final updatedTemplates = state.templates.where((t) => t.id != templateId).toList();
    await _saveTemplates(updatedTemplates);
    state = state.copyWith(templates: updatedTemplates);
  }

  Future<void> toggleFavorite(String templateId) async {
    final template = state.templates.firstWhere((t) => t.id == templateId);
    await updateTemplate(template.copyWith(isFavorite: !template.isFavorite));
  }

  Future<void> _saveTemplates(List<WriteTemplate> templates) async {
    final templatesJson = templates.map((t) => t.toJson()).toList();
    await _box.put('templates', templatesJson);
  }
}

/// Provider pour la box des templates
final writeTemplatesBoxProvider = Provider<Box>((ref) {
  return Hive.box('write_templates');
});

/// Provider pour le writer NFC
final nfcWriterProvider =
    StateNotifierProvider<NfcWriterNotifier, NfcWriterState>((ref) {
  final box = ref.watch(writeTemplatesBoxProvider);
  return NfcWriterNotifier(box);
});

/// Provider pour les templates d'écriture
final writeTemplatesProvider =
    StateNotifierProvider<WriteTemplatesNotifier, WriteTemplatesState>((ref) {
  final box = ref.watch(writeTemplatesBoxProvider);
  return WriteTemplatesNotifier(box);
});

/// Provider pour les templates favoris
final favoriteTemplatesProvider = Provider<List<WriteTemplate>>((ref) {
  final state = ref.watch(writeTemplatesProvider);
  return state.templates.where((t) => t.isFavorite).toList();
});

/// Provider pour les templates par type
final templatesByTypeProvider =
    Provider.family<List<WriteTemplate>, WriteDataType>((ref, type) {
  final state = ref.watch(writeTemplatesProvider);
  return state.templates.where((t) => t.type == type).toList();
});
