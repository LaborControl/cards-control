import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/animations/nfc_scan_animation.dart';
import '../../../contacts/presentation/screens/nfc_contact_preview_screen.dart';
import '../../domain/entities/nfc_tag.dart';
import '../../domain/services/claude_tag_analyzer_service.dart';
import '../providers/nfc_reader_provider.dart';
import '../widgets/tag_info_card.dart';
import '../widgets/quick_actions_bar.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Vérifie la disponibilité NFC au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nfcReaderProvider.notifier).checkNfcAvailability();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(nfcReaderProvider.notifier).checkNfcAvailability();
    } else if (state == AppLifecycleState.paused) {
      ref.read(nfcReaderProvider.notifier).stopScanning();
    }
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(nfcReaderProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecteur NFC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/history'),
            tooltip: 'Historique',
          ),
          IconButton(
            icon: const Icon(Icons.star_outline),
            onPressed: () => _showFavorites(context),
            tooltip: 'Favoris',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Zone principale de scan
            Expanded(
              child: _buildMainContent(context, readerState, theme),
            ),

            // Actions rapides en bas
            if (readerState.currentTag != null)
              QuickActionsBar(
                tag: readerState.currentTag!,
                onCopy: () => _copyTag(readerState.currentTag!),
                onSaveAsTemplate: () async => await _saveAsTemplate(context, readerState.currentTag!),
                onShare: () => _shareTag(readerState.currentTag!),
                canSaveAsTemplate: _canSaveAsTemplate(readerState.currentTag!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    NfcReaderState state,
    ThemeData theme,
  ) {
    switch (state.status) {
      case NfcReaderStatus.checking:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Vérification du NFC...'),
            ],
          ),
        );

      case NfcReaderStatus.nfcUnavailable:
        return _buildNfcUnavailable(context, theme);

      case NfcReaderStatus.nfcDisabled:
        return _buildNfcDisabled(context, theme);

      case NfcReaderStatus.error:
        return _buildError(context, state.errorMessage, theme);

      case NfcReaderStatus.tagFound:
        return _buildTagFound(context, state, theme);

      case NfcReaderStatus.extractingContact:
        return _buildExtractingContact(context, state, theme);

      case NfcReaderStatus.contactExtracted:
        return _buildContactExtracted(context, state, theme);

      case NfcReaderStatus.extractionError:
        return _buildExtractionError(context, state, theme);

      case NfcReaderStatus.idle:
      case NfcReaderStatus.ready:
      case NfcReaderStatus.scanning:
      default:
        return _buildScanArea(context, state, theme);
    }
  }

  Widget _buildScanArea(
    BuildContext context,
    NfcReaderState state,
    ThemeData theme,
  ) {
    final isScanning = state.status == NfcReaderStatus.scanning;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Animation de scan - tap pour démarrer/arrêter
          NfcScanAnimation(
            isScanning: isScanning,
            onTap: () {
              if (isScanning) {
                ref.read(nfcReaderProvider.notifier).stopScanning();
              } else {
                ref.read(nfcReaderProvider.notifier).startScanning();
              }
            },
          ),

          const SizedBox(height: 32),

          // Texte d'instruction
          Text(
            isScanning
                ? 'Approchez un tag NFC...'
                : 'Appuyez pour scanner',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            isScanning
                ? 'Appuyez sur le cercle pour arrêter'
                : 'Détection automatique du type de puce',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Conseil
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.info,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Conseil: Tenez le tag contre le centre arrière de votre téléphone pour une meilleure détection',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Raccourcis
          _buildShortcuts(context, theme),
        ],
      ),
    );
  }

  Widget _buildShortcuts(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _ShortcutButton(
            icon: Icons.history,
            label: 'Historique',
            onTap: () => context.push('/history'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShortcutButton(
            icon: Icons.star_outline,
            label: 'Favoris',
            onTap: () => _showFavorites(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShortcutButton(
            icon: Icons.description_outlined,
            label: 'Templates',
            onTap: () => context.push('/writer'),
          ),
        ),
      ],
    );
  }

  Widget _buildTagFound(
    BuildContext context,
    NfcReaderState state,
    ThemeData theme,
  ) {
    final tag = state.currentTag!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indicateur de succès
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tag lu avec succès',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        tag.type.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    tag.isFavorite ? Icons.star : Icons.star_outline,
                    color: tag.isFavorite ? Colors.amber : null,
                  ),
                  tooltip: tag.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                  onPressed: () {
                    ref.read(nfcReaderProvider.notifier).toggleFavorite(tag.id);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Carte d'informations du tag
          TagInfoCard(tag: tag),

          const SizedBox(height: 16),

          // Analyse IA du contenu
          _buildAiAnalysisCard(state, theme),

          const SizedBox(height: 16),

          // Bouton voir détails
          OutlinedButton.icon(
            onPressed: () => context.push('/reader/details/${tag.id}'),
            icon: const Icon(Icons.visibility),
            label: const Text('Voir tous les détails'),
          ),

          const SizedBox(height: 8),

          // Bouton scanner à nouveau
          TextButton.icon(
            onPressed: () {
              ref.read(nfcReaderProvider.notifier).reset();
              ref.read(nfcReaderProvider.notifier).startScanning();
            },
            icon: const Icon(Icons.nfc),
            label: const Text('Scanner un autre tag'),
          ),
        ],
      ),
    );
  }

  /// Carte d'analyse IA du contenu du tag
  Widget _buildAiAnalysisCard(NfcReaderState state, ThemeData theme) {
    final analysis = state.tagAnalysis;
    final isAnalyzing = state.isAnalyzing;
    final tag = state.currentTag;

    // Si pas de records NDEF, afficher un message simple
    if (tag != null && tag.ndefRecords.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ce tag ne contient pas de données NDEF. Il peut s\'agir d\'un tag vierge ou d\'un tag avec des données propriétaires.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Analyse en cours
    if (isAnalyzing) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Analyse du contenu en cours...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),
      );
    }

    // Analyse terminée
    if (analysis != null && analysis.explanation != null) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec badge IA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    const Color(0xFFEC4899).withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analyse IA',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  const Spacer(),
                  if (analysis.canCreateTemplate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'Template possible',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analysis.explanation!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (analysis.templateType != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _getIconForTemplateType(analysis.templateType!),
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Type détecté : ${_getTemplateTypeName(analysis.templateType!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Pas d'analyse disponible
    return const SizedBox.shrink();
  }

  IconData _getIconForTemplateType(String type) {
    switch (type) {
      case 'url':
        return Icons.link;
      case 'text':
        return Icons.text_fields;
      case 'vcard':
        return Icons.contact_page;
      case 'wifi':
        return Icons.wifi;
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'sms':
        return Icons.sms;
      case 'location':
        return Icons.location_on;
      default:
        return Icons.nfc;
    }
  }

  String _getTemplateTypeName(String type) {
    switch (type) {
      case 'url':
        return 'Lien URL';
      case 'text':
        return 'Texte';
      case 'vcard':
        return 'Carte de visite';
      case 'wifi':
        return 'Configuration WiFi';
      case 'phone':
        return 'Numéro de téléphone';
      case 'email':
        return 'Email';
      case 'sms':
        return 'SMS';
      case 'location':
        return 'Localisation';
      default:
        return type;
    }
  }

  Widget _buildExtractingContact(
    BuildContext context,
    NfcReaderState state,
    ThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 32),
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.aiExtracting,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.aiExtractingSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.detectedUrl != null) ...[
              const SizedBox(height: 16),
              Text(
                state.detectedUrl!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 32),
            TextButton(
              onPressed: () {
                ref.read(nfcReaderProvider.notifier).clearExtraction();
              },
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactExtracted(
    BuildContext context,
    NfcReaderState state,
    ThemeData theme,
  ) {
    final contact = state.extractedContact;
    if (contact == null) {
      return _buildExtractionError(context, state, theme);
    }

    // Naviguer vers l'écran de prévisualisation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NfcContactPreviewScreen(
            extractedContact: contact,
            sourceUrl: state.detectedUrl ?? '',
          ),
        ),
      ).then((_) {
        // Réinitialiser après retour
        ref.read(nfcReaderProvider.notifier).reset();
      });
    });

    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildExtractionError(
    BuildContext context,
    NfcReaderState state,
    ThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.extractionIncomplete,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              state.errorMessage ?? l10n.noContactInfoFound,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                // Naviguer vers création manuelle
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NfcContactPreviewScreen(
                      extractedContact: null,
                      sourceUrl: state.detectedUrl ?? '',
                    ),
                  ),
                ).then((_) {
                  ref.read(nfcReaderProvider.notifier).reset();
                });
              },
              icon: const Icon(Icons.edit),
              label: Text(l10n.createContactManually),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                if (state.detectedUrl != null) {
                  ref.read(nfcReaderProvider.notifier).extractContactFromUrl(state.detectedUrl!);
                }
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ref.read(nfcReaderProvider.notifier).clearExtraction();
              },
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNfcUnavailable(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nfc_outlined,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'NFC non disponible',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Votre appareil ne supporte pas la technologie NFC ou celle-ci est désactivée.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(nfcReaderProvider.notifier).checkNfcAvailability();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNfcDisabled(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nfc_outlined,
              size: 80,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(height: 24),
            Text(
              'NFC désactivé',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Veuillez activer le NFC dans les paramètres de votre appareil.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Ouvre les paramètres NFC
                // AndroidIntent ou similaire
              },
              icon: const Icon(Icons.settings),
              label: const Text('Ouvrir les paramètres'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ref.read(nfcReaderProvider.notifier).checkNfcAvailability();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    String? errorMessage,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Erreur',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'Une erreur est survenue',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(nfcReaderProvider.notifier).reset();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFavorites(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _FavoritesSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _copyTag(NfcTag tag) {
    context.push('/copy', extra: tag);
  }

  /// Vérifie rapidement si le tag contient des données potentiellement exploitables
  /// (vérification rapide pour activer/désactiver le bouton)
  bool _canSaveAsTemplate(NfcTag tag) {
    // Un tag avec des records NDEF non vides peut potentiellement être transformé en modèle
    if (tag.ndefRecords.isEmpty) return false;

    for (final record in tag.ndefRecords) {
      final payload = record.decodedPayload;
      if (payload != null && payload.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// Analyse le tag avec l'IA et sauvegarde comme modèle si possible
  Future<void> _saveAsTemplate(BuildContext context, NfcTag tag) async {
    // Stocker les références avant d'ouvrir le dialogue
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyse du tag en cours...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // Récupérer la clé API depuis les variables d'environnement
      const apiKey = String.fromEnvironment('CLAUDE_API_KEY', defaultValue: '');
      final analyzerService = ClaudeTagAnalyzerService(apiKey: apiKey);

      // Analyser le tag avec Claude
      final result = await analyzerService.analyzeTagForTemplate(tag);

      // Fermer le dialogue de chargement avec rootNavigator
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!context.mounted) return;

      if (result.canCreateTemplate &&
          result.templateType != null &&
          result.extractedData != null) {
        // Naviguer vers le formulaire de création de modèle
        context.push('/templates/create/${result.templateType}', extra: {
          'data': result.extractedData,
          'editMode': false,
        });
      } else {
        // Afficher un dialogue explicatif si le tag ne peut pas être transformé
        _showCannotCreateTemplateDialog(
          context,
          result.explanation ??
              'Ce tag ne contient pas de données exploitables pour créer un modèle.',
        );
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!context.mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'analyse: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Affiche un dialogue explicatif quand le tag ne peut pas créer de modèle
  void _showCannotCreateTemplateDialog(BuildContext context, String explanation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.info_outline,
          color: AppColors.warning,
          size: 48,
        ),
        title: const Text('Modèle non disponible'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              explanation,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Formats supportés : URL, texte, carte de visite, WiFi, téléphone, email, SMS, localisation.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.info,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _shareTag(NfcTag tag) {
    final StringBuffer shareText = StringBuffer();
    shareText.writeln('Tag NFC: ${tag.type.displayName}');
    shareText.writeln('UID: ${tag.formattedUid}');
    shareText.writeln('Mémoire: ${tag.memorySize} bytes');

    if (tag.ndefRecords.isNotEmpty) {
      shareText.writeln('\nContenu NDEF:');
      for (final record in tag.ndefRecords) {
        shareText.writeln('- ${record.type.displayName}: ${record.decodedPayload ?? "Données binaires"}');
      }
    }

    Share.share(
      shareText.toString(),
      subject: 'Tag NFC - ${tag.formattedUid}',
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const _FavoritesSheet({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteTagsProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Titre
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Tags favoris',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Liste
        Expanded(
          child: favoritesAsync.when(
            data: (favorites) {
              if (favorites.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_outline,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun favori',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final tag = favorites[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.nfc,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      title: Text(tag.type.displayName),
                      subtitle: Text(tag.formattedUid),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/reader/details/${tag.id}');
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Erreur: $error')),
          ),
        ),
      ],
    );
  }
}
