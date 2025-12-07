import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/animations/nfc_scan_animation.dart';
import '../../../nfc_reader/domain/entities/nfc_tag.dart';
import '../../../nfc_reader/presentation/providers/nfc_reader_provider.dart';

class ModifyTagScreen extends ConsumerStatefulWidget {
  const ModifyTagScreen({super.key});

  @override
  ConsumerState<ModifyTagScreen> createState() => _ModifyTagScreenState();
}

class _ModifyTagScreenState extends ConsumerState<ModifyTagScreen> {
  bool _isScanning = false;
  NfcTag? _tagData;
  String? _errorMessage;
  void Function()? _cancelListener;

  @override
  void dispose() {
    _stopScanning();
    super.dispose();
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _tagData = null;
      _errorMessage = null;
    });

    try {
      final nfcNotifier = ref.read(nfcReaderProvider.notifier);

      // Vérifier la disponibilité du NFC
      await nfcNotifier.checkNfcAvailability();
      final state = ref.read(nfcReaderProvider);

      if (!state.isNfcAvailable) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'NFC non disponible sur cet appareil';
        });
        return;
      }

      // Démarrer le scan
      await nfcNotifier.startScanning();

      // Écouter les changements d'état
      _cancelListener = ref.listenManual(nfcReaderProvider, (previous, next) {
        if (next.status == NfcReaderStatus.tagFound && next.currentTag != null) {
          setState(() {
            _isScanning = false;
            _tagData = next.currentTag;
          });
          _stopScanning();
        } else if (next.status == NfcReaderStatus.error) {
          setState(() {
            _isScanning = false;
            _errorMessage = next.errorMessage ?? 'Erreur inconnue';
          });
          _stopScanning();
        }
      }).close;

    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _stopScanning() async {
    _cancelListener?.call();
    _cancelListener = null;

    if (_isScanning) {
      try {
        await ref.read(nfcReaderProvider.notifier).stopScanning();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _editContent() {
    if (_tagData == null) return;

    // Determine the type from NDEF records
    final records = _tagData!.ndefRecords;
    if (records.isNotEmpty) {
      final firstRecord = records.first;
      final type = _detectRecordType(firstRecord);

      // Navigate to writer with pre-filled data
      context.push('/writer/template/$type', extra: {
        'prefill': true,
        'data': {
          'type': firstRecord.type.name,
          'payload': firstRecord.decodedPayload ?? firstRecord.payloadHex,
        },
        'tagUid': _tagData!.uid,
      });
    } else {
      // If no NDEF records, go to writer to write new content
      context.push('/writer');
    }
  }

  String _detectRecordType(NdefRecord record) {
    switch (record.type) {
      case NdefRecordType.uri:
        final payload = record.decodedPayload ?? '';
        if (payload.startsWith('tel:')) return 'phone';
        if (payload.startsWith('mailto:')) return 'email';
        if (payload.startsWith('sms:')) return 'sms';
        return 'url';
      case NdefRecordType.text:
        return 'text';
      case NdefRecordType.wifi:
        return 'wifi';
      case NdefRecordType.vcard:
        return 'vcard';
      case NdefRecordType.smartPoster:
        return 'url';
      default:
        return 'text';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Écouter les changements d'état pendant le scan
    if (_isScanning) {
      final state = ref.watch(nfcReaderProvider);
      if (state.status == NfcReaderStatus.tagFound && state.currentTag != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isScanning) {
            setState(() {
              _isScanning = false;
              _tagData = state.currentTag;
            });
            _stopScanning();
          }
        });
      } else if (state.status == NfcReaderStatus.error && state.errorMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isScanning) {
            setState(() {
              _isScanning = false;
              _errorMessage = state.errorMessage;
            });
            _stopScanning();
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.modifyTag),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Info card
            Card(
              color: AppColors.info.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.modifyTagInfoTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.modifyTagInfoMessage,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_isScanning) ...[
              const Spacer(),
              const NfcScanAnimation(),
              const SizedBox(height: 24),
              Text(
                l10n.approachNfcTag,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.scanningToModify,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _stopScanning,
                  icon: const Icon(Icons.close),
                  label: Text(l10n.cancel),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else if (_tagData != null) ...[
              // Show tag content
              Expanded(
                child: _buildTagContent(theme, l10n),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _tagData = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.scanAnother),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _editContent,
                      icon: const Icon(Icons.edit),
                      label: Text(l10n.editContent),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_errorMessage != null) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 80,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.readFailed,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startScanning,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_note,
                  size: 64,
                  color: AppColors.tertiary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.modifyTagInstruction,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.modifyTagDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startScanning,
                  icon: const Icon(Icons.nfc),
                  label: Text(l10n.scanTagToModify),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTagContent(ThemeData theme, AppLocalizations l10n) {
    final tag = _tagData!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag info header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.nfc, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.tagDetected,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              tag.type.displayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // État du tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tag.isWritable && !tag.isLocked
                              ? AppColors.success.withValues(alpha: 0.2)
                              : AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag.isWritable && !tag.isLocked ? 'Modifiable' : 'Protégé',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tag.isWritable && !tag.isLocked
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _InfoRow(label: l10n.tagUid, value: tag.formattedUid),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Mémoire', value: '${tag.usedMemory}/${tag.memorySize} bytes'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            l10n.currentContent,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          if (tag.ndefRecords.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.noNdefContent,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...tag.ndefRecords.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              final recordType = _detectRecordType(record);
              final value = record.decodedPayload ?? record.payloadHex;

              return Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getRecordIcon(recordType),
                      color: AppColors.secondary,
                    ),
                  ),
                  title: Text('${_getRecordTypeLabel(recordType, l10n)} ${index + 1}'),
                  subtitle: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),

          // Avertissement si le tag n'est pas modifiable
          if (!tag.isWritable || tag.isLocked) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.warning.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tag.isLocked
                            ? 'Ce tag est verrouillé et ne peut pas être modifié.'
                            : 'Ce tag est en lecture seule.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getRecordIcon(String type) {
    switch (type) {
      case 'url':
        return Icons.link;
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'sms':
        return Icons.sms;
      case 'wifi':
        return Icons.wifi;
      case 'vcard':
        return Icons.contact_page;
      default:
        return Icons.text_fields;
    }
  }

  String _getRecordTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'url':
        return l10n.url;
      case 'phone':
        return l10n.phone;
      case 'email':
        return l10n.email;
      case 'sms':
        return 'SMS';
      case 'wifi':
        return l10n.wifi;
      case 'vcard':
        return l10n.contact;
      default:
        return l10n.text;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ),
      ],
    );
  }
}
