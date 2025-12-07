import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../contacts/domain/services/web_contact_extraction_service.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/ai_token_service.dart';
import '../../data/datasources/nfc_local_datasource.dart';
import '../../data/datasources/nfc_native_datasource.dart';
import '../../data/repositories/nfc_repository_impl.dart';
import '../../domain/entities/nfc_tag.dart';
import '../../domain/repositories/nfc_repository.dart';
import '../../domain/services/claude_tag_analyzer_service.dart';
import '../../domain/usecases/read_tag.dart';

// Datasources Providers
final nfcNativeDatasourceProvider = Provider<NfcNativeDatasource>((ref) {
  return NfcNativeDatasource();
});

final nfcLocalDatasourceProvider = Provider<NfcLocalDatasource>((ref) {
  final box = Hive.box('tags_history');
  return NfcLocalDatasource(box);
});

// Repository Provider
final nfcRepositoryProvider = Provider<NfcRepository>((ref) {
  return NfcRepositoryImpl(
    nativeDatasource: ref.watch(nfcNativeDatasourceProvider),
    localDatasource: ref.watch(nfcLocalDatasourceProvider),
  );
});

// Use Case Providers
final readTagUseCaseProvider = Provider<ReadTagUseCase>((ref) {
  return ReadTagUseCase(ref.watch(nfcRepositoryProvider));
});

final getTagDetailsUseCaseProvider = Provider<GetTagDetailsUseCase>((ref) {
  return GetTagDetailsUseCase(ref.watch(nfcRepositoryProvider));
});

final tagHistoryUseCaseProvider = Provider<TagHistoryUseCase>((ref) {
  return TagHistoryUseCase(ref.watch(nfcRepositoryProvider));
});

final exportTagUseCaseProvider = Provider<ExportTagUseCase>((ref) {
  return ExportTagUseCase(ref.watch(nfcRepositoryProvider));
});

final readMemoryUseCaseProvider = Provider<ReadMemoryUseCase>((ref) {
  return ReadMemoryUseCase(ref.watch(nfcRepositoryProvider));
});

/// État du lecteur NFC
enum NfcReaderStatus {
  idle,
  checking,
  ready,
  scanning,
  tagFound,
  extractingContact,
  contactExtracted,
  extractionError,
  error,
  nfcDisabled,
  nfcUnavailable,
}

/// État du NFC Reader
class NfcReaderState {
  final NfcReaderStatus status;
  final NfcTag? currentTag;
  final String? errorMessage;
  final bool isNfcAvailable;
  final ExtractedWebContact? extractedContact;
  final String? detectedUrl;
  final TagAnalysisResult? tagAnalysis;
  final bool isAnalyzing;

  const NfcReaderState({
    this.status = NfcReaderStatus.idle,
    this.currentTag,
    this.errorMessage,
    this.isNfcAvailable = false,
    this.extractedContact,
    this.detectedUrl,
    this.tagAnalysis,
    this.isAnalyzing = false,
  });

  NfcReaderState copyWith({
    NfcReaderStatus? status,
    NfcTag? currentTag,
    String? errorMessage,
    bool? isNfcAvailable,
    ExtractedWebContact? extractedContact,
    String? detectedUrl,
    TagAnalysisResult? tagAnalysis,
    bool? isAnalyzing,
  }) {
    return NfcReaderState(
      status: status ?? this.status,
      currentTag: currentTag ?? this.currentTag,
      errorMessage: errorMessage ?? this.errorMessage,
      isNfcAvailable: isNfcAvailable ?? this.isNfcAvailable,
      extractedContact: extractedContact ?? this.extractedContact,
      detectedUrl: detectedUrl ?? this.detectedUrl,
      tagAnalysis: tagAnalysis ?? this.tagAnalysis,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }

  NfcReaderState clearTag() {
    return NfcReaderState(
      status: status,
      currentTag: null,
      errorMessage: errorMessage,
      isNfcAvailable: isNfcAvailable,
      extractedContact: null,
      detectedUrl: null,
      tagAnalysis: null,
      isAnalyzing: false,
    );
  }

  NfcReaderState clearExtraction() {
    return NfcReaderState(
      status: status,
      currentTag: currentTag,
      errorMessage: errorMessage,
      isNfcAvailable: isNfcAvailable,
      extractedContact: null,
      detectedUrl: null,
    );
  }
}

/// Notifier pour le lecteur NFC
class NfcReaderNotifier extends StateNotifier<NfcReaderState> {
  final ReadTagUseCase _readTagUseCase;
  final TagHistoryUseCase _historyUseCase;
  StreamSubscription? _tagSubscription;
  WebContactExtractionService? _extractionService;
  ClaudeTagAnalyzerService? _analyzerService;

  NfcReaderNotifier(this._readTagUseCase, this._historyUseCase)
      : super(const NfcReaderState()) {
    // Initialiser les services si la clé API est disponible
    if (ApiConfig.hasClaudeKey) {
      _extractionService = WebContactExtractionService(
        apiKey: ApiConfig.claudeApiKey,
      );
      _analyzerService = ClaudeTagAnalyzerService(
        apiKey: ApiConfig.claudeApiKey,
        tokenService: AITokenService(),
      );
    }
  }

  /// Vérifie la disponibilité du NFC
  Future<void> checkNfcAvailability() async {
    state = state.copyWith(status: NfcReaderStatus.checking);

    final result = await _readTagUseCase.isNfcAvailable();
    result.fold(
      (failure) {
        state = state.copyWith(
          status: NfcReaderStatus.error,
          errorMessage: failure.message,
          isNfcAvailable: false,
        );
      },
      (isAvailable) {
        if (isAvailable) {
          state = state.copyWith(
            status: NfcReaderStatus.ready,
            isNfcAvailable: true,
          );
        } else {
          state = state.copyWith(
            status: NfcReaderStatus.nfcUnavailable,
            isNfcAvailable: false,
          );
        }
      },
    );
  }

  /// Démarre le scan NFC
  Future<void> startScanning() async {
    if (!state.isNfcAvailable) {
      await checkNfcAvailability();
      if (!state.isNfcAvailable) return;
    }

    state = state.copyWith(
      status: NfcReaderStatus.scanning,
      currentTag: null,
      errorMessage: null,
    );

    final startResult = await _readTagUseCase.startReading();
    startResult.fold(
      (failure) {
        state = state.copyWith(
          status: NfcReaderStatus.error,
          errorMessage: failure.message,
        );
      },
      (_) {
        // Écoute le stream des tags
        _tagSubscription?.cancel();
        _tagSubscription = _readTagUseCase.call().listen(
          (result) {
            result.fold(
              (failure) {
                state = state.copyWith(
                  status: NfcReaderStatus.error,
                  errorMessage: failure.message,
                );
              },
              (tag) async {
                // Sauvegarde automatique dans l'historique et récupère le tag avec l'ID correct
                final saveResult = await _readTagUseCase.saveTag(tag);
                final savedTag = saveResult.fold(
                  (failure) => tag, // En cas d'erreur, on garde le tag original
                  (saved) => saved, // Sinon on utilise le tag avec l'ID correct
                );

                state = state.copyWith(
                  status: NfcReaderStatus.tagFound,
                  currentTag: savedTag,
                  tagAnalysis: null,
                  isAnalyzing: true,
                );

                // Lancer l'analyse IA automatiquement
                _analyzeTag(savedTag);
              },
            );
          },
          onError: (error) {
            state = state.copyWith(
              status: NfcReaderStatus.error,
              errorMessage: error.toString(),
            );
          },
        );
      },
    );
  }

  /// Arrête le scan NFC
  Future<void> stopScanning() async {
    _tagSubscription?.cancel();
    _tagSubscription = null;

    await _readTagUseCase.stopReading();

    state = state.copyWith(status: NfcReaderStatus.ready);
  }

  /// Réinitialise l'état
  void reset() {
    _tagSubscription?.cancel();
    _tagSubscription = null;
    state = state.copyWith(
      status: NfcReaderStatus.ready,
      currentTag: null,
      errorMessage: null,
      tagAnalysis: null,
      isAnalyzing: false,
    );
  }

  /// Analyse le tag avec l'IA pour générer une explication
  Future<void> _analyzeTag(NfcTag tag) async {
    if (_analyzerService == null) {
      // Pas de clé API, utiliser l'analyse locale
      state = state.copyWith(isAnalyzing: false);
      return;
    }

    try {
      final result = await _analyzerService!.analyzeTagForTemplate(tag);
      if (mounted) {
        state = state.copyWith(
          tagAnalysis: result,
          isAnalyzing: false,
        );
      }
    } catch (e) {
      debugPrint('Erreur analyse IA: $e');
      if (mounted) {
        state = state.copyWith(isAnalyzing: false);
      }
    }
  }

  /// Ajoute/retire des favoris
  Future<void> toggleFavorite(String tagId) async {
    await _historyUseCase.toggleFavorite(tagId);

    // Mise à jour de l'état si c'est le tag courant
    if (state.currentTag?.id == tagId) {
      state = state.copyWith(
        currentTag: state.currentTag?.copyWith(
          isFavorite: !state.currentTag!.isFavorite,
        ),
      );
    }
  }

  /// Met à jour les notes
  Future<void> updateNotes(String tagId, String notes) async {
    await _historyUseCase.updateNotes(tagId, notes);

    // Mise à jour de l'état si c'est le tag courant
    if (state.currentTag?.id == tagId) {
      state = state.copyWith(
        currentTag: state.currentTag?.copyWith(notes: notes),
      );
    }
  }

  /// Extrait une URL depuis les records NDEF du tag courant
  String? _extractUrlFromTag(NfcTag tag) {
    for (final record in tag.ndefRecords) {
      final payload = record.decodedPayload;
      if (payload != null &&
          (payload.startsWith('http://') || payload.startsWith('https://'))) {
        return payload;
      }
    }
    return null;
  }

  /// Lance l'extraction automatique de contact depuis une URL
  Future<void> extractContactFromUrl(String url) async {
    if (_extractionService == null) {
      debugPrint('Extraction service not available (no API key)');
      state = state.copyWith(
        status: NfcReaderStatus.extractionError,
        errorMessage: 'Service d\'extraction non disponible',
      );
      return;
    }

    state = state.copyWith(
      status: NfcReaderStatus.extractingContact,
      detectedUrl: url,
    );

    try {
      debugPrint('Extracting contact from URL: $url');
      final extractedContact = await _extractionService!.extractFromUrl(url);

      if (extractedContact.hasData) {
        state = state.copyWith(
          status: NfcReaderStatus.contactExtracted,
          extractedContact: extractedContact,
        );
        debugPrint('Contact extracted successfully: ${extractedContact.fullName}');
      } else {
        state = state.copyWith(
          status: NfcReaderStatus.extractionError,
          errorMessage: 'Aucune information de contact trouvée',
        );
      }
    } catch (e) {
      debugPrint('Error extracting contact: $e');
      state = state.copyWith(
        status: NfcReaderStatus.extractionError,
        errorMessage: 'Erreur lors de l\'extraction: $e',
      );
    }
  }

  /// Lance l'extraction automatique depuis le tag courant (si URL détectée)
  Future<void> autoExtractFromCurrentTag() async {
    final tag = state.currentTag;
    if (tag == null) return;

    final url = _extractUrlFromTag(tag);
    if (url != null) {
      await extractContactFromUrl(url);
    }
  }

  /// Réinitialise l'état d'extraction
  void clearExtraction() {
    state = state.clearExtraction().copyWith(
      status: NfcReaderStatus.tagFound,
    );
  }

  @override
  void dispose() {
    _tagSubscription?.cancel();
    super.dispose();
  }
}

/// Provider principal pour le lecteur NFC
final nfcReaderProvider = StateNotifierProvider<NfcReaderNotifier, NfcReaderState>((ref) {
  return NfcReaderNotifier(
    ref.watch(readTagUseCaseProvider),
    ref.watch(tagHistoryUseCaseProvider),
  );
});

/// Provider pour l'historique des tags
/// Se rafraîchit automatiquement quand un nouveau tag est lu
final tagHistoryProvider = FutureProvider<List<NfcTag>>((ref) async {
  // Écoute l'état du reader pour se rafraîchir quand un tag est trouvé
  final readerState = ref.watch(nfcReaderProvider);

  // Force le rafraîchissement quand le status passe à tagFound
  if (readerState.status == NfcReaderStatus.tagFound) {
    // Ce watch déclenche le recalcul du provider
  }

  final useCase = ref.watch(tagHistoryUseCaseProvider);
  final result = await useCase.getHistory();
  return result.fold(
    (failure) => [],
    (tags) => tags,
  );
});

/// Provider pour les tags favoris
final favoriteTagsProvider = FutureProvider<List<NfcTag>>((ref) async {
  final useCase = ref.watch(tagHistoryUseCaseProvider);
  final result = await useCase.getFavorites();
  return result.fold(
    (failure) => [],
    (tags) => tags,
  );
});

/// Provider pour un tag spécifique
final tagDetailsProvider = FutureProvider.family<NfcTag?, String>((ref, id) async {
  final useCase = ref.watch(getTagDetailsUseCaseProvider);
  final result = await useCase.call(id);
  return result.fold(
    (failure) => null,
    (tag) => tag,
  );
});
