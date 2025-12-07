import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/animations/nfc_scan_animation.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../nfc_reader/domain/entities/nfc_tag.dart';

enum CopyState {
  initial,
  readingSource,
  sourceReady,
  writingTarget,
  success,
  error,
}

class CopyScreen extends ConsumerStatefulWidget {
  const CopyScreen({super.key});

  @override
  ConsumerState<CopyScreen> createState() => _CopyScreenState();
}

class _CopyScreenState extends ConsumerState<CopyScreen> {
  static const _nfcChannel = MethodChannel('com.cardscontrol.app/nfc');

  CopyState _state = CopyState.initial;
  NfcTag? _sourceTag;
  String? _errorMessage;

  // Données source lues du tag
  Map<String, dynamic>? _sourceData;
  List<Map<String, dynamic>>? _sourceNdefRecords;

  // Completers pour les callbacks asynchrones
  Completer<Map<String, dynamic>>? _readCompleter;
  Completer<Map<String, dynamic>>? _writeCompleter;

  // Options de copie avancées
  bool _copyRawData = false;
  bool _ignoreErrors = false;

  @override
  void initState() {
    super.initState();
    _nfcChannel.setMethodCallHandler(_handleNfcCallback);
  }

  @override
  void dispose() {
    _stopNfc();
    super.dispose();
  }

  /// Handler pour les callbacks NFC depuis Android
  Future<dynamic> _handleNfcCallback(MethodCall call) async {
    debugPrint('NFC Copy callback: ${call.method}');

    if (call.method == 'onTagRead') {
      final data = Map<String, dynamic>.from(call.arguments as Map);
      debugPrint('NFC Read callback received: $data');

      if (_readCompleter != null && !_readCompleter!.isCompleted) {
        _readCompleter!.complete(data);
      }
    } else if (call.method == 'onTagWritten') {
      final data = Map<String, dynamic>.from(call.arguments as Map);
      debugPrint('NFC Write callback received: $data');

      if (_writeCompleter != null && !_writeCompleter!.isCompleted) {
        _writeCompleter!.complete(data);
      }
    }
    return null;
  }

  Future<void> _stopNfc() async {
    try {
      await _nfcChannel.invokeMethod('stopReading');
    } catch (_) {}
    try {
      await _nfcChannel.invokeMethod('stopWriting');
    } catch (_) {}

    if (_readCompleter != null && !_readCompleter!.isCompleted) {
      _readCompleter!.complete({'success': false, 'error': 'Cancelled'});
    }
    if (_writeCompleter != null && !_writeCompleter!.isCompleted) {
      _writeCompleter!.complete({'success': false, 'error': 'Cancelled'});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.duplicateTag),
      ),
      body: _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (_state) {
      case CopyState.initial:
        return _buildInitialState(theme);
      case CopyState.readingSource:
        return _buildReadingState(theme);
      case CopyState.sourceReady:
        return _buildSourceReadyState(theme);
      case CopyState.writingTarget:
        return _buildWritingState(theme);
      case CopyState.success:
        return _buildSuccessState(theme);
      case CopyState.error:
        return _buildErrorState(theme);
    }
  }

  Widget _buildInitialState(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Avertissement légal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Text(
                      'Avertissement légal',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'La copie de tags NFC est légale uniquement si vous êtes le propriétaire légitime du tag ou si vous avez l\'autorisation explicite du propriétaire. '
                  'La copie de cartes d\'accès, moyens de paiement ou documents d\'identité sans autorisation est illégale.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Illustration
          Icon(
            Icons.copy_all,
            size: 80,
            color: theme.colorScheme.primary,
          ),

          const SizedBox(height: 24),

          Text(
            'Copier un tag NFC',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cette fonction permet de dupliquer le contenu d\'un tag NFC vers un autre tag vierge ou réinscriptible.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Étapes
          _StepIndicator(
            steps: const [
              'Lire le tag source',
              'Approcher le tag cible',
              'Écriture automatique',
            ],
            currentStep: 0,
          ),

          const SizedBox(height: 32),

          PrimaryButton(
            label: 'Lire le tag source',
            icon: Icons.nfc,
            onPressed: _startReading,
          ),

          const SizedBox(height: 16),

          // Options
          ExpansionTile(
            title: const Text('Options avancées'),
            children: [
              SwitchListTile(
                title: const Text('Copier les données brutes'),
                subtitle: const Text('Copie secteur par secteur (MIFARE uniquement)'),
                value: _copyRawData,
                onChanged: (value) {
                  setState(() => _copyRawData = value);
                },
              ),
              SwitchListTile(
                title: const Text('Ignorer les erreurs'),
                subtitle: const Text('Continuer même en cas d\'erreur de secteur'),
                value: _ignoreErrors,
                onChanged: (value) {
                  setState(() => _ignoreErrors = value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadingState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepIndicator(
              steps: const [
                'Lire le tag source',
                'Approcher le tag cible',
                'Écriture automatique',
              ],
              currentStep: 0,
              activeStep: 0,
            ),

            const SizedBox(height: 48),

            const NfcScanAnimation(isScanning: true),

            const SizedBox(height: 32),

            Text(
              'Approchez le tag source...',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Placez le tag à copier contre l\'arrière de votre téléphone',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            OutlinedButton(
              onPressed: _cancelReading,
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelReading() async {
    if (_readCompleter != null && !_readCompleter!.isCompleted) {
      _readCompleter!.complete({'success': false, 'error': 'Annulé'});
    }
    try {
      await _nfcChannel.invokeMethod('stopReading');
    } catch (_) {}
    setState(() => _state = CopyState.initial);
  }

  Widget _buildSourceReadyState(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _StepIndicator(
            steps: const [
              'Lire le tag source',
              'Approcher le tag cible',
              'Écriture automatique',
            ],
            currentStep: 1,
          ),

          const SizedBox(height: 24),

          // Info tag source
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 12),
                    Text(
                      'Tag source lu avec succès',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (_sourceTag != null) ...[
                  _InfoRow(label: 'Type', value: _sourceTag!.type.displayName),
                  _InfoRow(label: 'UID', value: _sourceTag!.formattedUid),
                  _InfoRow(label: 'Mémoire', value: '${_sourceTag!.usedMemory}/${_sourceTag!.memorySize} bytes'),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Prêt à copier',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Approchez maintenant le tag cible pour y copier les données',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Avertissement compatibilité
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Le tag cible doit être du même type ou compatible',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          PrimaryButton(
            label: 'Copier vers le tag cible',
            icon: Icons.nfc,
            onPressed: _startWriting,
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: _resetState,
            child: const Text('Recommencer'),
          ),
        ],
      ),
    );
  }

  Widget _buildWritingState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepIndicator(
              steps: const [
                'Lire le tag source',
                'Approcher le tag cible',
                'Écriture automatique',
              ],
              currentStep: 2,
              activeStep: 1,
            ),

            const SizedBox(height: 48),

            const NfcScanAnimation(isScanning: true),

            const SizedBox(height: 32),

            Text(
              'Approchez le tag cible...',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Placez le tag de destination contre l\'arrière de votre téléphone',
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

  void _cancelWriting() async {
    if (_writeCompleter != null && !_writeCompleter!.isCompleted) {
      _writeCompleter!.complete({'success': false, 'error': 'Annulé'});
    }
    try {
      await _nfcChannel.invokeMethod('stopWriting');
    } catch (_) {}
    setState(() => _state = CopyState.sourceReady);
  }

  void _resetState() {
    setState(() {
      _state = CopyState.initial;
      _sourceTag = null;
      _sourceData = null;
      _sourceNdefRecords = null;
      _errorMessage = null;
    });
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
              child: Icon(
                Icons.check,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Copie réussie !',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Les données ont été copiées sur le nouveau tag',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Copier un autre tag',
              onPressed: _resetState,
              isExpanded: false,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Terminé'),
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
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Erreur',
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
              onPressed: _resetState,
              isExpanded: false,
            ),
          ],
        ),
      ),
    );
  }

  void _startReading() async {
    setState(() {
      _state = CopyState.readingSource;
      _errorMessage = null;
    });

    try {
      _readCompleter = Completer<Map<String, dynamic>>();

      // Démarrer la lecture NFC
      await _nfcChannel.invokeMethod('startReading');

      // Attendre le callback onTagRead (timeout de 60 secondes)
      final result = await _readCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => {'success': false, 'error': 'Timeout - aucun tag détecté'},
      );

      // Arrêter la lecture
      await _nfcChannel.invokeMethod('stopReading');

      if (!mounted) return;

      if (result['success'] == true) {
        // Extraire les données du tag lu
        _sourceData = result;
        _sourceNdefRecords = _extractNdefRecords(result);

        final uid = result['uid'] as String? ?? '';
        final type = _detectTagType(result);
        final memorySize = result['memorySize'] as int? ?? 0;
        final usedMemory = result['usedMemory'] as int? ?? 0;

        setState(() {
          _sourceTag = NfcTag(
            id: 'copy_source_${DateTime.now().millisecondsSinceEpoch}',
            uid: uid,
            type: type,
            technology: _detectTechnology(result),
            memorySize: memorySize,
            usedMemory: usedMemory,
            isWritable: result['isWritable'] as bool? ?? true,
            scannedAt: DateTime.now(),
          );
          _state = CopyState.sourceReady;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] as String? ?? 'Erreur de lecture';
          _state = CopyState.error;
        });
      }
    } catch (e) {
      try {
        await _nfcChannel.invokeMethod('stopReading');
      } catch (_) {}

      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _state = CopyState.error;
        });
      }
    }
  }

  void _startWriting() async {
    if (_sourceData == null && _sourceNdefRecords == null) {
      setState(() {
        _errorMessage = 'Aucune donnée source à copier';
        _state = CopyState.error;
      });
      return;
    }

    setState(() {
      _state = CopyState.writingTarget;
      _errorMessage = null;
    });

    try {
      _writeCompleter = Completer<Map<String, dynamic>>();

      // Préparer les données à écrire
      final writeData = _prepareWriteData();

      // Démarrer l'écriture NFC avec les données NDEF du tag source
      await _nfcChannel.invokeMethod('startWriting', {
        'data': jsonEncode(writeData),
        'type': 'copy',
        'ndefRecords': _sourceNdefRecords,
      });

      // Attendre le callback onTagWritten (timeout de 60 secondes)
      final result = await _writeCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => {'success': false, 'error': 'Timeout - aucun tag détecté'},
      );

      // Arrêter l'écriture
      await _nfcChannel.invokeMethod('stopWriting');

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() => _state = CopyState.success);
      } else {
        setState(() {
          _errorMessage = result['error'] as String? ?? 'Erreur d\'écriture';
          _state = CopyState.error;
        });
      }
    } catch (e) {
      try {
        await _nfcChannel.invokeMethod('stopWriting');
      } catch (_) {}

      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _state = CopyState.error;
        });
      }
    }
  }

  /// Extrait les enregistrements NDEF du résultat de lecture
  List<Map<String, dynamic>>? _extractNdefRecords(Map<String, dynamic> data) {
    final records = data['ndefRecords'] as List<dynamic>?;
    if (records == null) return null;

    return records
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  /// Prépare les données pour l'écriture
  Map<String, dynamic> _prepareWriteData() {
    return {
      'sourceUid': _sourceTag?.uid ?? '',
      'ndefRecords': _sourceNdefRecords ?? [],
      'copyMode': _copyRawData ? 'raw' : 'ndef',
      'ignoreErrors': _ignoreErrors,
    };
  }

  /// Détecte le type de tag à partir des données lues
  NfcTagType _detectTagType(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type != null) {
      return NfcTagType.fromString(type);
    }

    // Essayer de détecter par la taille mémoire
    final memorySize = data['memorySize'] as int? ?? 0;
    if (memorySize >= 888) return NfcTagType.ntag216;
    if (memorySize >= 504) return NfcTagType.ntag215;
    if (memorySize >= 144) return NfcTagType.ntag213;

    return NfcTagType.unknown;
  }

  /// Détecte la technologie NFC à partir des données lues
  NfcTechnology _detectTechnology(Map<String, dynamic> data) {
    final techList = data['techList'] as List<dynamic>?;
    if (techList == null || techList.isEmpty) return NfcTechnology.unknown;

    final tech = techList.first as String;
    if (tech.contains('NfcA')) return NfcTechnology.nfcA;
    if (tech.contains('NfcB')) return NfcTechnology.nfcB;
    if (tech.contains('NfcF')) return NfcTechnology.nfcF;
    if (tech.contains('NfcV')) return NfcTechnology.nfcV;
    if (tech.contains('IsoDep')) return NfcTechnology.isoDep;
    if (tech.contains('MifareClassic')) return NfcTechnology.mifareClassic;
    if (tech.contains('MifareUltralight')) return NfcTechnology.mifareUltralight;

    return NfcTechnology.unknown;
  }
}

class _StepIndicator extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final int? activeStep;

  const _StepIndicator({
    required this.steps,
    required this.currentStep,
    this.activeStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Ligne de connexion
          final stepIndex = index ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepIndex < currentStep
                  ? AppColors.success
                  : theme.colorScheme.outline,
            ),
          );
        }

        // Cercle d'étape
        final stepIndex = index ~/ 2;
        final isCompleted = stepIndex < currentStep;
        final isActive = stepIndex == (activeStep ?? currentStep);

        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.success
                    : isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.success
                      : isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 80,
              child: Text(
                steps[stepIndex],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
