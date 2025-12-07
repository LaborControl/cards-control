import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/template_storage_service.dart';
import '../../domain/entities/write_data.dart';

/// State pour les templates
class TemplatesState {
  final List<WriteTemplate> templates;
  final bool isLoading;
  final String? error;

  const TemplatesState({
    this.templates = const [],
    this.isLoading = false,
    this.error,
  });

  TemplatesState copyWith({
    List<WriteTemplate>? templates,
    bool? isLoading,
    String? error,
  }) {
    return TemplatesState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour gérer les templates
class TemplatesNotifier extends StateNotifier<TemplatesState> {
  final TemplateStorageService _storageService;

  TemplatesNotifier(this._storageService) : super(const TemplatesState()) {
    loadTemplates();
  }

  Future<void> loadTemplates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final templates = await _storageService.loadTemplates();
      state = state.copyWith(templates: templates, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<WriteTemplate?> addTemplate({
    required String name,
    required WriteDataType type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final template = await _storageService.addTemplate(
        name: name,
        type: type,
        data: data,
      );
      await loadTemplates();
      return template;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    try {
      await _storageService.deleteTemplate(templateId);
      await loadTemplates();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateTemplate(WriteTemplate template) async {
    try {
      await _storageService.updateTemplate(template);
      await loadTemplates();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> incrementUseCount(String templateId) async {
    await _storageService.incrementUseCount(templateId);
    await loadTemplates();
  }

  String generateNdefContent(WriteTemplate template) {
    return _storageService.generateNdefContent(template);
  }

  String getTemplateDescription(WriteTemplate template) {
    return _storageService.getTemplateDescription(template);
  }

  /// Publie un template et retourne son URL publique
  Future<String> publishTemplate(String templateId) async {
    final updatedTemplate = await _storageService.publishTemplate(templateId);
    await loadTemplates();
    if (updatedTemplate == null) {
      throw Exception('Vous devez être connecté pour publier un modèle');
    }
    return updatedTemplate.shareUrl;
  }

  /// Retire un template de la publication
  Future<void> unpublishTemplate(String templateId) async {
    await _storageService.unpublishTemplate(templateId);
    await loadTemplates();
  }
}

/// Provider pour le service de stockage
final templateStorageServiceProvider = Provider<TemplateStorageService>((ref) {
  return TemplateStorageService.instance;
});

/// Provider pour les templates
final templatesProvider = StateNotifierProvider<TemplatesNotifier, TemplatesState>((ref) {
  final storageService = ref.watch(templateStorageServiceProvider);
  return TemplatesNotifier(storageService);
});
