import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/nfc_tag.dart';
import '../../domain/repositories/nfc_repository.dart';
import '../providers/nfc_reader_provider.dart';
import '../widgets/memory_view.dart';
import '../widgets/ndef_record_tile.dart';
import '../../../nfc_writer/data/services/template_storage_service.dart';
import '../../../nfc_writer/presentation/providers/templates_provider.dart';

class TagDetailsScreen extends ConsumerStatefulWidget {
  final String tagId;

  const TagDetailsScreen({super.key, required this.tagId});

  @override
  ConsumerState<TagDetailsScreen> createState() => _TagDetailsScreenState();
}

class _TagDetailsScreenState extends ConsumerState<TagDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagAsync = ref.watch(tagDetailsProvider(widget.tagId));
    final theme = Theme.of(context);

    return tagAsync.when(
      data: (tag) {
        if (tag == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tag non trouvé')),
            body: const Center(child: Text('Ce tag n\'existe plus')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(tag.type.displayName),
            actions: [
              IconButton(
                icon: Icon(
                  tag.isFavorite ? Icons.star : Icons.star_outline,
                  color: tag.isFavorite ? Colors.amber : null,
                ),
                tooltip: tag.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                onPressed: () => _toggleFavorite(tag),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, tag),
                itemBuilder: (context) => [
                  // Option sauvegarder en template (si NDEF exploitable)
                  if (_hasExploitableNdef(tag))
                    const PopupMenuItem(
                      value: 'save_template',
                      child: ListTile(
                        leading: Icon(Icons.bookmark_add, color: AppColors.primary),
                        title: Text('Sauvegarder en template'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (_hasExploitableNdef(tag))
                    const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'export_json',
                    child: ListTile(
                      leading: Icon(Icons.code),
                      title: Text('Exporter JSON'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_xml',
                    child: ListTile(
                      leading: Icon(Icons.description),
                      title: Text('Exporter XML'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_hex',
                    child: ListTile(
                      leading: Icon(Icons.memory),
                      title: Text('Exporter HEX'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Partager'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'copy',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Copier sur un tag'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Infos'),
                Tab(text: 'NDEF'),
                Tab(text: 'Mémoire'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(tag, theme),
              _buildNdefTab(tag, theme),
              _buildMemoryTab(tag, theme),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildInfoTab(NfcTag tag, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte UID
          _InfoCard(
            title: 'Identifiant',
            children: [
              _InfoRow(
                label: 'UID',
                value: tag.formattedUid,
                onCopy: () => _copyToClipboard(tag.uid, 'UID copié'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Carte Type
          _InfoCard(
            title: 'Type de puce',
            children: [
              _InfoRow(label: 'Type', value: tag.type.displayName),
              _InfoRow(label: 'Technologie', value: tag.technology.displayName),
            ],
          ),

          const SizedBox(height: 16),

          // Carte Mémoire
          _InfoCard(
            title: 'Mémoire',
            children: [
              _InfoRow(label: 'Capacité totale', value: '${tag.memorySize} bytes'),
              _InfoRow(label: 'Utilisée', value: '${tag.usedMemory} bytes'),
              _InfoRow(label: 'Disponible', value: '${tag.availableMemory} bytes'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: tag.memoryUsagePercent / 100,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  tag.memoryUsagePercent > 80
                      ? AppColors.warning
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${tag.memoryUsagePercent.toStringAsFixed(1)}% utilisé',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Carte État avec bouton Modifier
          _WritableCard(
            tag: tag,
            onModify: _canModifyTag(tag) ? () => _navigateToModify(tag) : null,
          ),

          const SizedBox(height: 16),

          // Carte Scan
          _InfoCard(
            title: 'Scan',
            children: [
              _InfoRow(
                label: 'Date',
                value: _formatDate(tag.scannedAt),
              ),
              _InfoRow(
                label: 'Heure',
                value: _formatTime(tag.scannedAt),
              ),
              if (tag.location != null)
                _InfoRow(
                  label: 'Lieu',
                  value: tag.location!.address ??
                      '${tag.location!.latitude.toStringAsFixed(4)}, ${tag.location!.longitude.toStringAsFixed(4)}',
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Notes
          _NotesCard(
            notes: tag.notes,
            onSave: (notes) => _updateNotes(tag.id, notes),
          ),
        ],
      ),
    );
  }

  Widget _buildNdefTab(NfcTag tag, ThemeData theme) {
    if (tag.ndefRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun enregistrement NDEF',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ce tag ne contient pas de données NDEF',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tag.ndefRecords.length,
      itemBuilder: (context, index) {
        final record = tag.ndefRecords[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NdefRecordTile(
            record: record,
            index: index,
          ),
        );
      },
    );
  }

  Widget _buildMemoryTab(NfcTag tag, ThemeData theme) {
    if (tag.rawData == null || tag.rawData!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.memory,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Données mémoire non disponibles',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le dump mémoire n\'a pas été effectué',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _startMemoryRead(tag),
              icon: const Icon(Icons.download),
              label: const Text('Lire la mémoire'),
            ),
          ],
        ),
      );
    }

    return MemoryView(data: tag.rawData!);
  }

  /// Démarre la lecture mémoire du tag
  void _startMemoryRead(NfcTag tag) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _MemoryReadDialog(
        tagId: tag.id,
        tagType: tag.type.displayName,
        onComplete: (rawData) {
          // Mettre à jour le tag avec les données lues
          final useCase = ref.read(readMemoryUseCaseProvider);
          useCase.updateRawData(tag.id, rawData).then((result) {
            result.fold(
              (failure) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${failure.message}')),
                  );
                }
              },
              (updatedTag) {
                // Rafraîchir les données du tag
                ref.invalidate(tagDetailsProvider(widget.tagId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${rawData.length} bytes lus avec succès'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            );
          });
        },
      ),
    );
  }

  void _toggleFavorite(NfcTag tag) {
    ref.read(nfcReaderProvider.notifier).toggleFavorite(tag.id);
    ref.invalidate(tagDetailsProvider(widget.tagId));
  }

  void _updateNotes(String id, String notes) {
    ref.read(nfcReaderProvider.notifier).updateNotes(id, notes);
    ref.invalidate(tagDetailsProvider(widget.tagId));
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _handleMenuAction(String action, NfcTag tag) async {
    switch (action) {
      case 'save_template':
        await _saveAsTemplate(tag);
        break;
      case 'export_json':
        await _exportTag(tag, ExportFormat.json);
        break;
      case 'export_xml':
        await _exportTag(tag, ExportFormat.xml);
        break;
      case 'export_hex':
        await _exportTag(tag, ExportFormat.hex);
        break;
      case 'share':
        await _shareTag(tag);
        break;
      case 'copy':
        context.push('/copy', extra: tag);
        break;
      case 'delete':
        await _deleteTag(tag);
        break;
    }
  }

  Future<void> _exportTag(NfcTag tag, ExportFormat format) async {
    final useCase = ref.read(exportTagUseCaseProvider);
    final result = await useCase.call(tag.id, format);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${failure.message}')),
        );
      },
      (exported) {
        // Partage le fichier exporté
        Share.share(exported, subject: 'Export NFC Tag ${tag.formattedUid}');
      },
    );
  }

  Future<void> _shareTag(NfcTag tag) async {
    final text = '''
NFC Tag: ${tag.type.displayName}
UID: ${tag.formattedUid}
Mémoire: ${tag.memorySize} bytes
${tag.ndefRecords.isNotEmpty ? 'Contenu: ${tag.ndefRecords.first.decodedPayload ?? 'Données binaires'}' : ''}
    ''';

    await Share.share(text, subject: 'Tag NFC - ${tag.formattedUid}');
  }

  Future<void> _deleteTag(NfcTag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le tag'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce tag de l\'historique ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final historyUseCase = ref.read(tagHistoryUseCaseProvider);
      await historyUseCase.deleteTag(tag.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Vérifie si le tag peut être modifié
  bool _canModifyTag(NfcTag tag) {
    // Le tag peut être modifié s'il est inscriptible et non verrouillé
    return tag.isWritable && !tag.isLocked;
  }

  /// Navigue vers l'écran de modification du tag
  void _navigateToModify(NfcTag tag) {
    context.push('/tags/modify');
  }

  /// Vérifie si le tag contient des données NDEF exploitables pour créer un template
  bool _hasExploitableNdef(NfcTag tag) {
    if (tag.ndefRecords.isEmpty) return false;

    for (final record in tag.ndefRecords) {
      if (TemplateStorageService.canConvertToTemplate(
        record.type.name,
        record.decodedPayload,
      )) {
        return true;
      }
    }
    return false;
  }

  /// Sauvegarde les données NDEF du tag en tant que template
  Future<void> _saveAsTemplate(NfcTag tag) async {
    // Trouver le premier enregistrement NDEF exploitable
    NdefRecord? exploitableRecord;
    for (final record in tag.ndefRecords) {
      if (TemplateStorageService.canConvertToTemplate(
        record.type.name,
        record.decodedPayload,
      )) {
        exploitableRecord = record;
        break;
      }
    }

    if (exploitableRecord == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune donnée exploitable trouvée')),
        );
      }
      return;
    }

    // Demander un nom pour le template
    final templateName = await showDialog<String>(
      context: context,
      builder: (context) => _SaveTemplateDialog(
        suggestedName: _getSuggestedTemplateName(exploitableRecord!),
        contentPreview: exploitableRecord.decodedPayload ?? '',
        recordType: exploitableRecord.type.displayName,
      ),
    );

    if (templateName == null || templateName.isEmpty) return;

    // Créer le template
    final templateService = TemplateStorageService.instance;
    final template = await templateService.createTemplateFromNdef(
      name: templateName,
      ndefType: exploitableRecord.type.name,
      decodedPayload: exploitableRecord.decodedPayload,
      payload: exploitableRecord.payload,
    );

    if (mounted) {
      if (template != null) {
        // Rafraîchir la liste des templates
        ref.invalidate(templatesProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template "$templateName" créé avec succès'),
            action: SnackBarAction(
              label: 'Voir',
              onPressed: () => context.push('/templates'),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création du template')),
        );
      }
    }
  }

  /// Suggère un nom pour le template basé sur le contenu
  String _getSuggestedTemplateName(NdefRecord record) {
    final content = record.decodedPayload ?? '';

    switch (record.type) {
      case NdefRecordType.uri:
        if (content.startsWith('tel:')) {
          return 'Téléphone ${content.substring(4)}';
        } else if (content.startsWith('mailto:')) {
          final email = content.substring(7).split('?').first;
          return 'Email $email';
        } else if (content.startsWith('http')) {
          // Extraire le domaine
          final uri = Uri.tryParse(content);
          if (uri != null) {
            return 'URL ${uri.host}';
          }
        }
        return 'URL';
      case NdefRecordType.text:
        final preview = content.length > 20 ? '${content.substring(0, 20)}...' : content;
        return 'Texte: $preview';
      case NdefRecordType.wifi:
        final ssidMatch = RegExp(r'S:([^;]+)').firstMatch(content);
        if (ssidMatch != null) {
          return 'WiFi ${ssidMatch.group(1)}';
        }
        return 'WiFi';
      case NdefRecordType.vcard:
        final fnMatch = RegExp(r'FN:(.+)').firstMatch(content);
        if (fnMatch != null) {
          return 'Contact ${fnMatch.group(1)}';
        }
        return 'Contact';
      default:
        return 'Template du ${_formatDate(DateTime.now())}';
    }
  }
}

/// Dialog pour sauvegarder un template
class _SaveTemplateDialog extends StatefulWidget {
  final String suggestedName;
  final String contentPreview;
  final String recordType;

  const _SaveTemplateDialog({
    required this.suggestedName,
    required this.contentPreview,
    required this.recordType,
  });

  @override
  State<_SaveTemplateDialog> createState() => _SaveTemplateDialogState();
}

class _SaveTemplateDialogState extends State<_SaveTemplateDialog> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.suggestedName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = widget.contentPreview.length > 100
        ? '${widget.contentPreview.substring(0, 100)}...'
        : widget.contentPreview;

    return AlertDialog(
      title: const Text('Sauvegarder en template'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aperçu du contenu
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bookmark,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.recordType,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  preview,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'JetBrainsMono',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Champ nom
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom du template',
              hintText: 'Ex: WiFi Maison, Contact Pro...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(context, name);
            }
          },
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onCopy;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
                fontFamily: label == 'UID' ? 'JetBrainsMono' : null,
              ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copier',
              onPressed: onCopy,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatefulWidget {
  final String? notes;
  final ValueChanged<String> onSave;

  const _NotesCard({
    this.notes,
    required this.onSave,
  });

  @override
  State<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends State<_NotesCard> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.notes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Notes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (_isEditing) ...[
                  TextButton(
                    onPressed: () {
                      setState(() => _isEditing = false);
                      _controller.text = widget.notes ?? '';
                    },
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onSave(_controller.text);
                      setState(() => _isEditing = false);
                    },
                    child: const Text('Enregistrer'),
                  ),
                ] else
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Modifier',
                    onPressed: () => setState(() => _isEditing = true),
                  ),
              ],
            ),
            const Divider(height: 16),
            if (_isEditing)
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Ajouter des notes...',
                  border: OutlineInputBorder(),
                ),
              )
            else
              Text(
                widget.notes?.isEmpty ?? true
                    ? 'Aucune note'
                    : widget.notes!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: widget.notes?.isEmpty ?? true
                      ? theme.colorScheme.outline
                      : null,
                  fontStyle: widget.notes?.isEmpty ?? true
                      ? FontStyle.italic
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Carte affichant l'état du tag et le bouton Modifier
class _WritableCard extends StatelessWidget {
  final NfcTag tag;
  final VoidCallback? onModify;

  const _WritableCard({
    required this.tag,
    this.onModify,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final canModify = tag.isWritable && !tag.isLocked;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tagState,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const Divider(height: 24),
            _InfoRow(
              label: l10n.writingState,
              value: tag.isWritable ? l10n.allowed : l10n.blocked,
              valueColor: tag.isWritable ? AppColors.success : AppColors.error,
            ),
            _InfoRow(
              label: l10n.lockState,
              value: tag.isLocked ? l10n.locked : l10n.notLocked,
              valueColor: tag.isLocked ? AppColors.warning : null,
            ),
            const SizedBox(height: 16),
            // Bouton Modifier
            SizedBox(
              width: double.infinity,
              child: canModify
                  ? FilledButton.icon(
                      onPressed: onModify,
                      icon: const Icon(Icons.edit),
                      label: Text(l10n.modifyTag),
                    )
                  : OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock),
                      label: Text(l10n.tagNotModifiable),
                    ),
            ),
            if (!canModify) ...[
              const SizedBox(height: 8),
              Text(
                tag.isLocked
                    ? l10n.tagLockedMessage
                    : l10n.tagNotWritableMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dialog pour la lecture mémoire NFC
class _MemoryReadDialog extends ConsumerStatefulWidget {
  final String tagId;
  final String tagType;
  final Function(List<int> rawData) onComplete;

  const _MemoryReadDialog({
    required this.tagId,
    required this.tagType,
    required this.onComplete,
  });

  @override
  ConsumerState<_MemoryReadDialog> createState() => _MemoryReadDialogState();
}

class _MemoryReadDialogState extends ConsumerState<_MemoryReadDialog> {
  bool _isScanning = false;
  bool _isComplete = false;
  String _statusMessage = 'Approchez le tag NFC pour lire sa mémoire';
  double _progress = 0;
  List<int> _readData = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startMemoryRead();
  }

  Future<void> _startMemoryRead() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Approchez le tag NFC...';
      _progress = 0;
      _errorMessage = null;
    });

    final useCase = ref.read(readMemoryUseCaseProvider);

    await useCase.startSession(
      onProgress: (data, current, total) {
        if (mounted) {
          setState(() {
            _readData = data;
            _progress = total > 0 ? current / total : 0;
            _statusMessage = 'Lecture en cours... ${data.length} bytes';
          });
        }
      },
      onComplete: (fullData) {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _isComplete = true;
            _readData = fullData;
            _statusMessage = 'Lecture terminée: ${fullData.length} bytes';
            _progress = 1.0;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _errorMessage = error;
            _statusMessage = 'Erreur';
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isComplete
                ? Icons.check_circle
                : _errorMessage != null
                    ? Icons.error
                    : Icons.memory,
            color: _isComplete
                ? AppColors.success
                : _errorMessage != null
                    ? AppColors.error
                    : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lecture mémoire',
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône animée
          if (_isScanning && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        strokeWidth: 4,
                      ),
                    ),
                    Icon(
                      Icons.nfc,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),

          // Icône de succès
          if (_isComplete)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: AppColors.success,
              ),
            ),

          // Icône d'erreur
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.error_outline,
                size: 80,
                color: AppColors.error,
              ),
            ),

          const SizedBox(height: 16),

          // Message de statut
          Text(
            _statusMessage,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),

          // Message d'erreur
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // Barre de progression
          if (_isScanning && _progress > 0) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toInt()}%',
              style: theme.textTheme.bodySmall,
            ),
          ],

          // Type de tag
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.tagType,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (_errorMessage != null)
          TextButton(
            onPressed: _startMemoryRead,
            child: const Text('Réessayer'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(_isComplete ? 'Fermer' : 'Annuler'),
        ),
        if (_isComplete)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onComplete(_readData);
            },
            child: const Text('Enregistrer'),
          ),
      ],
    );
  }
}
