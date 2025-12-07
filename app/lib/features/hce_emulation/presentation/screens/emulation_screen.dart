import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../core/services/native_nfc_service.dart';
import '../../../../core/services/qr_code_service.dart';
import '../../../../shared/widgets/animations/nfc_scan_animation.dart';
import '../../../nfc_reader/data/datasources/nfc_native_datasource.dart';
import '../../../nfc_reader/presentation/providers/nfc_reader_provider.dart';
import '../../../business_cards/presentation/providers/business_cards_provider.dart';
import '../../../nfc_writer/presentation/providers/templates_provider.dart';
import '../../../nfc_writer/domain/entities/write_data.dart';
import '../../../nfc_writer/data/services/template_storage_service.dart';

/// Nombre d'émulations gratuites pour les nouveaux utilisateurs
const int kFreeEmulationsCount = 5;

/// Provider pour le service NFC natif
final nativeNfcServiceProvider = Provider<NativeNfcService>((ref) {
  return NativeNfcService.instance;
});

/// Provider pour les informations HCE
final hceInfoProvider = FutureProvider<HceInfo>((ref) async {
  final nfcService = ref.watch(nativeNfcServiceProvider);
  return nfcService.getHceInfo();
});

/// Provider pour l'état de l'émulation
final emulationStateProvider = StateProvider<bool>((ref) => false);

/// Type de contenu sélectionné
enum EmulationContentType { businessCards, templates }

/// Provider pour le type de contenu sélectionné
final selectedContentTypeProvider = StateProvider<EmulationContentType>(
  (ref) => EmulationContentType.businessCards,
);

/// Provider pour gérer les émulations gratuites
final freeEmulationsProvider = StateNotifierProvider<FreeEmulationsNotifier, int>((ref) {
  return FreeEmulationsNotifier();
});

/// Notifier pour gérer le compteur d'émulations gratuites
class FreeEmulationsNotifier extends StateNotifier<int> {
  static const String _storageKey = 'free_emulations_remaining';
  bool _isInitialized = false;

  FreeEmulationsNotifier() : super(-1) {
    // État initial -1 indique "chargement en cours"
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final box = Hive.box('settings');
      final remaining = box.get(_storageKey);
      if (remaining != null) {
        state = remaining as int;
      } else {
        // Premier lancement, initialiser à 5
        await box.put(_storageKey, kFreeEmulationsCount);
        state = kFreeEmulationsCount;
      }
      _isInitialized = true;
      debugPrint('Free emulations loaded: $state');
    } catch (e) {
      debugPrint('Error loading free emulations: $e');
      // En cas d'erreur, utiliser la valeur par défaut
      state = kFreeEmulationsCount;
      _isInitialized = true;
    }
  }

  Future<void> useOneEmulation() async {
    if (state > 0) {
      final newState = state - 1;
      try {
        final box = Hive.box('settings');
        await box.put(_storageKey, newState);
        state = newState;
        debugPrint('Free emulations used, remaining: $state');
      } catch (e) {
        debugPrint('Error saving free emulations: $e');
      }
    }
  }

  bool get isInitialized => _isInitialized;
  bool get hasRemainingEmulations => state > 0;
}

class EmulationScreen extends ConsumerStatefulWidget {
  final String? initialTab;
  final String? initialTemplateId;

  const EmulationScreen({super.key, this.initialTab, this.initialTemplateId});

  @override
  ConsumerState<EmulationScreen> createState() => _EmulationScreenState();
}

class _EmulationScreenState extends ConsumerState<EmulationScreen> {
  String? _selectedCardId;
  String? _selectedTemplateId;

  @override
  void initState() {
    super.initState();
    _initNfc();
    // Appliquer l'onglet initial si spécifié
    if (widget.initialTab == 'templates') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedContentTypeProvider.notifier).state = EmulationContentType.templates;
        // Si un templateId est fourni, le sélectionner automatiquement
        if (widget.initialTemplateId != null) {
          _selectTemplate(widget.initialTemplateId!);
        }
      });
    } else if (widget.initialTab == 'cards') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedContentTypeProvider.notifier).state = EmulationContentType.businessCards;
      });
    }
  }

  Future<void> _initNfc() async {
    final nfcService = NativeNfcService.instance;
    await nfcService.initialize();

    // Charger l'URL configurée
    final configuredUrl = await nfcService.getConfiguredCardUrl();
    if (configuredUrl != null && mounted) {
      // Trouver la carte correspondante
      final cards = ref.read(businessCardsProvider).cards;
      for (final card in cards) {
        final cardUrl = QrCodeService.instance.generateBusinessCardUrl(card.id);
        if (cardUrl == configuredUrl) {
          setState(() => _selectedCardId = card.id);
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hceInfo = ref.watch(hceInfoProvider);
    final isEmulating = ref.watch(emulationStateProvider);
    final cardsState = ref.watch(businessCardsProvider);
    final templatesState = ref.watch(templatesProvider);
    final contentType = ref.watch(selectedContentTypeProvider);

    // Vérifier si on est sur iOS - afficher Tag Adaptateur
    if (!Platform.isAndroid) {
      return _IosTagAdaptateurScreen(
        initialTab: widget.initialTab,
        initialTemplateId: widget.initialTemplateId,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Émulation HCE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Aide',
            onPressed: _showHelp,
          ),
        ],
      ),
      body: hceInfo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Erreur: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(hceInfoProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (info) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // État NFC
              if (!info.nfcEnabled)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.nfc, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NFC désactivé',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                            const Text('Activez le NFC dans les paramètres'),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => NativeNfcService.instance.openNfcSettings(),
                        child: const Text('Activer'),
                      ),
                    ],
                  ),
                ),

              // État HCE
              if (!info.isSupported)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HCE non supporté',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[800],
                              ),
                            ),
                            const Text('Votre appareil ne supporte pas l\'émulation HCE'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // État de l'émulation - plus petit et centré
              Center(
                child: _EmulationStatusCard(
                  isEmulating: isEmulating,
                  isEnabled: info.isSupported && info.nfcEnabled,
                ),
              ),

              const SizedBox(height: 24),

              // Sélecteur de type de contenu
              _ContentTypeSelector(
                selectedType: contentType,
                onTypeChanged: (type) {
                  ref.read(selectedContentTypeProvider.notifier).state = type;
                },
              ),

              const SizedBox(height: 16),

              // Contenu selon le type sélectionné
              if (contentType == EmulationContentType.businessCards)
                _buildBusinessCardsSection(theme, cardsState, isEmulating)
              else
                _buildTemplatesSection(theme, templatesState, isEmulating),

              const SizedBox(height: 24),

              // Afficher les émulations gratuites restantes
              _FreeEmulationsCard(),

              const SizedBox(height: 16),

              // Bouton démarrer/arrêter
              PrimaryButton(
                label: isEmulating ? 'Arrêter l\'émulation' : 'Démarrer l\'émulation',
                icon: isEmulating ? Icons.stop : Icons.play_arrow,
                isLoading: false,
                onPressed: _canStartEmulation(info, contentType)
                    ? () => _toggleEmulation(isEmulating, contentType)
                    : null,
              ),

              const SizedBox(height: 24),

              // Informations
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Comment ça marche ?',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        contentType == EmulationContentType.businessCards
                            ? '1. Sélectionnez votre carte de visite\n'
                              '2. Appuyez sur "Démarrer l\'émulation"\n'
                              '3. Approchez votre téléphone d\'un autre appareil NFC\n'
                              '4. L\'autre appareil recevra le lien vers votre carte'
                            : '1. Sélectionnez un template\n'
                              '2. Appuyez sur "Démarrer l\'émulation"\n'
                              '3. Approchez votre téléphone d\'un autre appareil NFC\n'
                              '4. L\'autre appareil recevra les données du template',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessCardsSection(ThemeData theme, dynamic cardsState, bool isEmulating) {
    if (cardsState.cards.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.contact_page_outlined, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              const Text('Aucune carte de visite'),
              const SizedBox(height: 8),
              Text(
                'Créez d\'abord une carte de visite pour l\'émuler',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: cardsState.cards.map<Widget>((card) {
        final isSelected = _selectedCardId == card.id;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          child: RadioListTile<String>(
            value: card.id,
            groupValue: _selectedCardId,
            onChanged: isEmulating ? null : (value) => _selectCard(value!),
            title: Text(card.fullName),
            subtitle: Text(card.company ?? card.email ?? ''),
            secondary: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(int.parse(card.primaryColor.replaceFirst('#', '0xFF'))).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person,
                color: Color(int.parse(card.primaryColor.replaceFirst('#', '0xFF'))),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTemplatesSection(ThemeData theme, TemplatesState templatesState, bool isEmulating) {
    if (templatesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (templatesState.templates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.description_outlined, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              const Text('Aucun template'),
              const SizedBox(height: 8),
              Text(
                'Créez des templates dans "Écrire un tag" pour les émuler ici',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final storageService = TemplateStorageService.instance;

    return Column(
      children: templatesState.templates.map<Widget>((template) {
        final isSelected = _selectedTemplateId == template.id;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          child: RadioListTile<String>(
            value: template.id,
            groupValue: _selectedTemplateId,
            onChanged: isEmulating ? null : (value) => _selectTemplate(value!),
            title: Text(template.name),
            subtitle: Text(storageService.getTemplateDescription(template)),
            secondary: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getColorForType(template.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconForType(template.type),
                color: _getColorForType(template.type),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _canStartEmulation(HceInfo info, EmulationContentType contentType) {
    if (!info.isSupported || !info.nfcEnabled) return false;

    // Vérifier les émulations gratuites (si déjà en train d'émuler, on peut arrêter)
    final isEmulating = ref.read(emulationStateProvider);
    if (!isEmulating) {
      final remainingEmulations = ref.read(freeEmulationsProvider);
      // Si encore en chargement (-1), ne pas permettre le démarrage
      if (remainingEmulations < 0) return false;
      // TODO: Ajouter vérification abonnement PRO ici
      if (remainingEmulations <= 0) return false;
    }

    if (contentType == EmulationContentType.businessCards) {
      return _selectedCardId != null;
    } else {
      return _selectedTemplateId != null;
    }
  }

  IconData _getIconForType(WriteDataType type) {
    switch (type) {
      case WriteDataType.url:
        return Icons.link;
      case WriteDataType.text:
        return Icons.text_fields;
      case WriteDataType.wifi:
        return Icons.wifi;
      case WriteDataType.vcard:
        return Icons.contact_page;
      case WriteDataType.phone:
        return Icons.phone;
      case WriteDataType.email:
        return Icons.email;
      case WriteDataType.sms:
        return Icons.sms;
      case WriteDataType.location:
        return Icons.location_on;
      case WriteDataType.bluetooth:
        return Icons.bluetooth;
      case WriteDataType.launchApp:
        return Icons.apps;
      default:
        return Icons.nfc;
    }
  }

  Color _getColorForType(WriteDataType type) {
    switch (type) {
      case WriteDataType.url:
        return Colors.blue;
      case WriteDataType.text:
        return Colors.green;
      case WriteDataType.wifi:
        return Colors.purple;
      case WriteDataType.vcard:
        return Colors.orange;
      case WriteDataType.phone:
        return Colors.teal;
      case WriteDataType.email:
        return Colors.red;
      case WriteDataType.sms:
        return Colors.indigo;
      case WriteDataType.location:
        return Colors.pink;
      case WriteDataType.bluetooth:
        return Colors.blueAccent;
      case WriteDataType.launchApp:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectCard(String cardId) async {
    setState(() {
      _selectedCardId = cardId;
      _selectedTemplateId = null;
    });

    // Configurer le HCE avec cette carte
    final cardUrl = QrCodeService.instance.generateBusinessCardUrl(cardId);
    final card = ref.read(businessCardsProvider).cards.firstWhere((c) => c.id == cardId);

    await NativeNfcService.instance.setBusinessCardForEmulation(
      cardId: cardId,
      cardUrl: cardUrl,
      vCardData: card.toVCard(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Carte "${card.fullName}" configurée')),
      );
    }
  }

  Future<void> _selectTemplate(String templateId) async {
    setState(() {
      _selectedTemplateId = templateId;
      _selectedCardId = null;
    });

    // Configurer le HCE avec l'URL publique du template (comme pour les cartes de visite)
    final template = ref.read(templatesProvider).templates.firstWhere((t) => t.id == templateId);

    await NativeNfcService.instance.setTemplateForEmulation(
      templateId: templateId,
      templateUrl: template.shareUrl,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template "${template.name}" configuré')),
      );
    }
  }

  Future<void> _toggleEmulation(bool currentState, EmulationContentType contentType) async {
    final nfcService = NativeNfcService.instance;
    final newState = !currentState;

    if (newState) {
      // Décrémenter le compteur d'émulations gratuites
      await ref.read(freeEmulationsProvider.notifier).useOneEmulation();

      // Démarrer l'émulation - désactive le foreground dispatch et active le service préféré
      await nfcService.startEmulation();
    } else {
      // Arrêter l'émulation - désactive le service préféré et réactive le foreground dispatch
      await nfcService.stopEmulation();
    }
    await nfcService.setEmulationEnabled(newState);
    ref.read(emulationStateProvider.notifier).state = newState;

    // Incrémenter le compteur d'utilisation pour les templates
    if (newState && contentType == EmulationContentType.templates && _selectedTemplateId != null) {
      ref.read(templatesProvider.notifier).incrementUseCount(_selectedTemplateId!);
    }

    if (mounted) {
      final remainingEmulations = ref.read(freeEmulationsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState
              ? 'Émulation démarrée - Approchez un lecteur NFC${remainingEmulations > 0 ? ' ($remainingEmulations essais gratuits restants)' : ''}'
              : 'Émulation arrêtée'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Émulation HCE'),
        content: const SingleChildScrollView(
          child: Text(
            'L\'émulation HCE (Host Card Emulation) permet à votre téléphone Android '
            'd\'agir comme un tag NFC. '
            '\n\nQuand l\'émulation est active, approchez votre téléphone '
            'd\'un autre appareil NFC et les données sélectionnées seront transmises.\n\n'
            'Vous pouvez émuler :\n'
            '• Vos cartes de visite\n'
            '• Vos templates (URL, WiFi, texte, etc.)\n\n'
            'L\'autre appareil pourra lire les données comme s\'il s\'agissait d\'un tag NFC physique.\n\n'
            'Note : L\'émulation HCE est disponible uniquement sur Android.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

class _EmulationStatusCard extends StatefulWidget {
  final bool isEmulating;
  final bool isEnabled;

  const _EmulationStatusCard({
    required this.isEmulating,
    required this.isEnabled,
  });

  @override
  State<_EmulationStatusCard> createState() => _EmulationStatusCardState();
}

class _EmulationStatusCardState extends State<_EmulationStatusCard>
    with TickerProviderStateMixin {
  late AnimationController _phoneController;
  late AnimationController _waveController;
  late Animation<double> _phoneAnimation;

  @override
  void initState() {
    super.initState();

    // Animation du téléphone qui s'approche
    _phoneController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _phoneAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _phoneController, curve: Curves.easeInOut),
    );

    // Animation des ondes NFC
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    if (widget.isEmulating) {
      _phoneController.repeat(reverse: true);
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(_EmulationStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEmulating && !oldWidget.isEmulating) {
      _phoneController.repeat(reverse: true);
      _waveController.repeat();
    } else if (!widget.isEmulating && oldWidget.isEmulating) {
      _phoneController.stop();
      _phoneController.reset();
      _waveController.stop();
      _waveController.reset();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isEmulating
            ? AppColors.success.withOpacity(0.1)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: widget.isEmulating ? Border.all(color: AppColors.success) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animation des deux téléphones
          SizedBox(
            height: 120,
            child: widget.isEmulating
                ? _buildAnimatedPhones(theme)
                : _buildStaticIcon(theme),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isEmulating ? 'Émulation active' : 'Prêt à émuler',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.isEmulating ? AppColors.success : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isEmulating
                ? 'Placez votre téléphone comme indiqué par l\'animation'
                : widget.isEnabled
                    ? 'Sélectionnez un contenu et démarrez'
                    : 'NFC indisponible',
            style: theme.textTheme.bodySmall?.copyWith(
              color: widget.isEmulating
                  ? AppColors.success
                  : theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStaticIcon(ThemeData theme) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: widget.isEnabled
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.outline.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.nfc,
          size: 32,
          color: widget.isEnabled
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildAnimatedPhones(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_phoneAnimation, _waveController]),
      builder: (context, child) {
        // Animation : le téléphone émetteur glisse de droite à gauche
        final slideOffset = _phoneAnimation.value * 15;

        return SizedBox(
          width: double.infinity,
          height: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Téléphone récepteur (à gauche, incliné de 20° vers la droite)
              Transform.rotate(
                angle: 0.35, // ~20 degrés vers la droite
                child: _buildReceiverPhoneVertical(theme),
              ),

              const SizedBox(width: 8),

              // Téléphone émetteur avec ondes NFC attachées en haut (glisse vers la gauche)
              Transform.translate(
                offset: Offset(-slideOffset, 0),
                child: Transform.rotate(
                  angle: -1.047, // ~-60 degrés (vers la gauche)
                  child: _buildEmitterWithWaves(theme),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Téléphone émetteur avec ondes NFC attachées en haut
  Widget _buildEmitterWithWaves(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ondes NFC collées au téléphone (sortent vers l'extérieur)
        _buildNfcWavesWidget(theme),
        // Téléphone vu de profil (tranche verticale fine)
        Container(
          width: 10, // Tranche fine
          height: 55, // Hauteur du téléphone
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: AppColors.success,
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Label
        Text(
          'Vous',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildNfcWavesWidget(ThemeData theme) {
    return SizedBox(
      width: 40,
      height: 25,
      child: CustomPaint(
        painter: _SonarWavePainter(
          progress: _waveController.value,
          color: AppColors.success,
        ),
      ),
    );
  }

  /// Téléphone récepteur vu de PROFIL/TRANCHE (à gauche, incliné 10° vers la droite)
  Widget _buildReceiverPhoneVertical(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Téléphone vu de profil (tranche verticale fine)
        Container(
          width: 10, // Tranche fine
          height: 55, // Hauteur du téléphone
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Bosse caméra en haut (sur le dos)
              Positioned(
                top: 3,
                left: -4,
                child: Container(
                  width: 6,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Label
        Text(
          'Récepteur',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

}

class _ContentTypeSelector extends StatelessWidget {
  final EmulationContentType selectedType;
  final ValueChanged<EmulationContentType> onTypeChanged;

  const _ContentTypeSelector({
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Cartes de visite',
              icon: Icons.contact_page,
              isSelected: selectedType == EmulationContentType.businessCards,
              onTap: () => onTypeChanged(EmulationContentType.businessCards),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Modèles',
              icon: Icons.description,
              isSelected: selectedType == EmulationContentType.templates,
              onTap: () => onTypeChanged(EmulationContentType.templates),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Écran Tag Adaptateur pour iOS
/// Remplace l'émulation HCE par l'écriture sur un tag NFC physique
class _IosTagAdaptateurScreen extends ConsumerStatefulWidget {
  final String? initialTab;
  final String? initialTemplateId;

  const _IosTagAdaptateurScreen({
    this.initialTab,
    this.initialTemplateId,
  });

  @override
  ConsumerState<_IosTagAdaptateurScreen> createState() => _IosTagAdaptateurScreenState();
}

class _IosTagAdaptateurScreenState extends ConsumerState<_IosTagAdaptateurScreen> {
  String? _selectedCardId;
  String? _selectedTemplateId;
  bool _isWriting = false;
  bool _writeSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Appliquer l'onglet initial si spécifié
    if (widget.initialTab == 'templates') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedContentTypeProvider.notifier).state = EmulationContentType.templates;
        if (widget.initialTemplateId != null) {
          setState(() => _selectedTemplateId = widget.initialTemplateId);
        }
      });
    } else if (widget.initialTab == 'cards') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedContentTypeProvider.notifier).state = EmulationContentType.businessCards;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardsState = ref.watch(businessCardsProvider);
    final templatesState = ref.watch(templatesProvider);
    final contentType = ref.watch(selectedContentTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tag Adaptateur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Aide',
            onPressed: _showHelp,
          ),
        ],
      ),
      body: _isWriting
          ? _buildWritingState(theme)
          : _writeSuccess
              ? _buildSuccessState(theme)
              : _errorMessage != null
                  ? _buildErrorState(theme)
                  : _buildMainContent(theme, cardsState, templatesState, contentType),
    );
  }

  Widget _buildMainContent(
    ThemeData theme,
    dynamic cardsState,
    TemplatesState templatesState,
    EmulationContentType contentType,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Explication Tag Adaptateur
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.nfc,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tag Adaptateur NFC',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Écrivez votre carte sur un tag NFC physique',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'L\'émulation HCE n\'est pas disponible sur iOS. '
                  'Utilisez un Tag Adaptateur pour partager vos données en NFC.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sélecteur de type de contenu
          _ContentTypeSelector(
            selectedType: contentType,
            onTypeChanged: (type) {
              ref.read(selectedContentTypeProvider.notifier).state = type;
            },
          ),

          const SizedBox(height: 16),

          // Contenu selon le type sélectionné
          if (contentType == EmulationContentType.businessCards)
            _buildBusinessCardsSection(theme, cardsState)
          else
            _buildTemplatesSection(theme, templatesState),

          const SizedBox(height: 24),

          // Bouton écrire sur tag
          PrimaryButton(
            label: 'Écrire sur le tag',
            icon: Icons.edit_note,
            isLoading: false,
            onPressed: _canWrite(contentType) ? _startWriting : null,
          ),

          const SizedBox(height: 24),

          // Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Comment ça marche ?',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1. Sélectionnez votre carte ou template\n'
                    '2. Appuyez sur "Écrire sur le tag"\n'
                    '3. Approchez votre tag NFC vierge\n'
                    '4. Le tag contiendra le lien vers votre carte\n'
                    '5. Partagez ce tag avec vos contacts !',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Acheter des tags
          _buildBuyTagsCard(theme),
        ],
      ),
    );
  }

  Widget _buildBusinessCardsSection(ThemeData theme, dynamic cardsState) {
    if (cardsState.cards.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.contact_page_outlined, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              const Text('Aucune carte de visite'),
              const SizedBox(height: 8),
              Text(
                'Créez d\'abord une carte de visite pour l\'écrire sur un tag',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: cardsState.cards.map<Widget>((card) {
        final isSelected = _selectedCardId == card.id;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          child: RadioListTile<String>(
            value: card.id,
            groupValue: _selectedCardId,
            onChanged: (value) {
              setState(() {
                _selectedCardId = value;
                _selectedTemplateId = null;
              });
            },
            title: Text(card.fullName),
            subtitle: Text(card.company ?? card.email ?? ''),
            secondary: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(int.parse(card.primaryColor.replaceFirst('#', '0xFF'))).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person,
                color: Color(int.parse(card.primaryColor.replaceFirst('#', '0xFF'))),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTemplatesSection(ThemeData theme, TemplatesState templatesState) {
    if (templatesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (templatesState.templates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.description_outlined, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              const Text('Aucun template'),
              const SizedBox(height: 8),
              Text(
                'Créez des templates dans "Écrire un tag" pour les utiliser ici',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final storageService = TemplateStorageService.instance;

    return Column(
      children: templatesState.templates.map<Widget>((template) {
        final isSelected = _selectedTemplateId == template.id;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          child: RadioListTile<String>(
            value: template.id,
            groupValue: _selectedTemplateId,
            onChanged: (value) {
              setState(() {
                _selectedTemplateId = value;
                _selectedCardId = null;
              });
            },
            title: Text(template.name),
            subtitle: Text(storageService.getTemplateDescription(template)),
            secondary: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getColorForType(template.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconForType(template.type),
                color: _getColorForType(template.type),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWritingState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const NfcScanAnimation(isScanning: true),
            const SizedBox(height: 32),
            Text(
              'Approchez le tag NFC...',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tenez le tag contre le haut de votre iPhone',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            OutlinedButton(
              onPressed: _cancelWriting,
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Tag programmé !',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Votre tag NFC est prêt à être partagé',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Programmer un autre tag',
              onPressed: () {
                setState(() => _writeSuccess = false);
              },
              isExpanded: false,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Erreur d\'écriture',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: () {
                setState(() => _errorMessage = null);
                _startWriting();
              },
              isExpanded: false,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() => _errorMessage = null);
              },
              child: const Text('Changer de carte'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyTagsCard(ThemeData theme) {
    return Card(
      color: Colors.amber.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.shopping_cart,
                color: Colors.amber[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Besoin de tags NFC ?',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Commandez nos tags compatibles',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Ouvrir le lien d'achat
              },
              child: const Text('Acheter'),
            ),
          ],
        ),
      ),
    );
  }

  bool _canWrite(EmulationContentType contentType) {
    if (contentType == EmulationContentType.businessCards) {
      return _selectedCardId != null;
    } else {
      return _selectedTemplateId != null;
    }
  }

  IconData _getIconForType(WriteDataType type) {
    switch (type) {
      case WriteDataType.url:
        return Icons.link;
      case WriteDataType.text:
        return Icons.text_fields;
      case WriteDataType.wifi:
        return Icons.wifi;
      case WriteDataType.vcard:
        return Icons.contact_page;
      case WriteDataType.phone:
        return Icons.phone;
      case WriteDataType.email:
        return Icons.email;
      case WriteDataType.sms:
        return Icons.sms;
      case WriteDataType.location:
        return Icons.location_on;
      case WriteDataType.bluetooth:
        return Icons.bluetooth;
      case WriteDataType.launchApp:
        return Icons.apps;
      default:
        return Icons.nfc;
    }
  }

  Color _getColorForType(WriteDataType type) {
    switch (type) {
      case WriteDataType.url:
        return Colors.blue;
      case WriteDataType.text:
        return Colors.green;
      case WriteDataType.wifi:
        return Colors.purple;
      case WriteDataType.vcard:
        return Colors.orange;
      case WriteDataType.phone:
        return Colors.teal;
      case WriteDataType.email:
        return Colors.red;
      case WriteDataType.sms:
        return Colors.indigo;
      case WriteDataType.location:
        return Colors.pink;
      case WriteDataType.bluetooth:
        return Colors.blueAccent;
      case WriteDataType.launchApp:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _startWriting() async {
    final contentType = ref.read(selectedContentTypeProvider);

    setState(() {
      _isWriting = true;
      _errorMessage = null;
    });

    try {
      NdefWriteData writeData;

      if (contentType == EmulationContentType.businessCards && _selectedCardId != null) {
        // Écrire l'URL de la carte de visite
        final cardUrl = QrCodeService.instance.generateBusinessCardUrl(_selectedCardId!);
        writeData = NdefWriteData(
          type: NdefWriteType.url,
          url: cardUrl,
        );
      } else if (_selectedTemplateId != null) {
        // Écrire l'URL du template
        final template = ref.read(templatesProvider).templates.firstWhere(
          (t) => t.id == _selectedTemplateId,
        );
        writeData = NdefWriteData(
          type: NdefWriteType.url,
          url: template.shareUrl,
        );
      } else {
        throw Exception('Aucun contenu sélectionné');
      }

      final datasource = ref.read(nfcNativeDatasourceProvider);

      await datasource.startWriteSession(
        writeData: writeData,
        onWriteSuccess: () {
          if (mounted) {
            setState(() {
              _isWriting = false;
              _writeSuccess = true;
            });
          }
        },
        onWriteError: (error) {
          if (mounted) {
            setState(() {
              _isWriting = false;
              _errorMessage = error;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isWriting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _cancelWriting() async {
    try {
      final datasource = ref.read(nfcNativeDatasourceProvider);
      await datasource.stopWriteSession();
    } catch (_) {}

    if (mounted) {
      setState(() => _isWriting = false);
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tag Adaptateur'),
        content: const SingleChildScrollView(
          child: Text(
            'Le Tag Adaptateur vous permet de partager vos données via NFC sur iOS.\n\n'
            'Comme iOS ne permet pas l\'émulation HCE, vous devez utiliser un tag NFC physique '
            'sur lequel vous écrivez vos données.\n\n'
            'Étapes :\n'
            '1. Sélectionnez votre carte de visite ou template\n'
            '2. Appuyez sur "Écrire sur le tag"\n'
            '3. Approchez un tag NFC vierge compatible (NTAG213, NTAG215, etc.)\n'
            '4. Le tag contiendra un lien vers vos données\n\n'
            'Ensuite, partagez ce tag avec vos contacts. Quand ils le scannent, '
            'ils accèdent directement à votre carte !',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

/// Widget affichant les émulations gratuites restantes
class _FreeEmulationsCard extends ConsumerWidget {
  const _FreeEmulationsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final remainingEmulations = ref.watch(freeEmulationsProvider);

    // Ne pas afficher si l'utilisateur a un abonnement PRO (à implémenter plus tard)
    // Pour l'instant, on affiche toujours

    // État de chargement (-1 = chargement en cours)
    if (remainingEmulations < 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Chargement...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final hasEmulations = remainingEmulations > 0;
    final progressValue = remainingEmulations / kFreeEmulationsCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasEmulations
            ? Colors.amber.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasEmulations
              ? Colors.amber.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasEmulations ? Icons.star : Icons.star_border,
                  color: Colors.amber[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Essais gratuits',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hasEmulations
                          ? '$remainingEmulations émulation${remainingEmulations > 1 ? 's' : ''} restante${remainingEmulations > 1 ? 's' : ''}'
                          : 'Aucune émulation gratuite restante',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$remainingEmulations/$kFreeEmulationsCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                hasEmulations ? Colors.amber : AppColors.error,
              ),
              minHeight: 6,
            ),
          ),
          if (!hasEmulations) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 16,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Passez à PRO pour des émulations illimitées',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Painter pour dessiner des ondes sonar (arcs de cercle qui s'éloignent)
class _SonarWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _SonarWavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height; // Point d'origine en bas (haut du téléphone)

    // Dessiner 3 arcs qui s'éloignent progressivement
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i * 0.33) % 1.0;

      // L'arc commence petit et grandit en s'éloignant
      final radius = 5 + (waveProgress * 20); // De 5 à 25 pixels

      // Opacité décroissante à mesure que l'arc s'éloigne
      final opacity = (1.0 - waveProgress) * 0.9;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      // Dessiner un arc de cercle (demi-cercle orienté vers le haut)
      final rect = Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius,
      );

      // Arc de 180° orienté vers le haut (de -π à 0)
      canvas.drawArc(
        rect,
        -math.pi, // Angle de départ (gauche)
        math.pi,  // Angle balayé (180°)
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SonarWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
