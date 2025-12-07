import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../nfc_writer/presentation/providers/templates_provider.dart';
import '../../../nfc_writer/domain/entities/write_data.dart';
import '../../../nfc_writer/data/repositories/firebase_templates_repository.dart';

class TemplatesListScreen extends ConsumerWidget {
  const TemplatesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final templatesState = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.templates),
        actions: [
          // Indicateur de synchronisation Firebase
          _SyncStatusIndicator(),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.help,
            onPressed: () => _showTemplateInfo(context, l10n),
          ),
        ],
      ),
      body: templatesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : templatesState.error != null
              ? Center(child: Text('${l10n.error}: ${templatesState.error}'))
              : templatesState.templates.isEmpty
                  ? _EmptyTemplates(l10n: l10n, theme: theme)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: templatesState.templates.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _TemplatesInfoCard(theme: theme);
                        }
                        final template = templatesState.templates[index - 1];
                        return _TemplateCard(
                          template: template,
                          onTap: () => _useTemplate(context, ref, template),
                          onDelete: () => _deleteTemplate(context, ref, template, l10n),
                          onEdit: () => _editTemplate(context, template),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/templates/create'),
        icon: const Icon(Icons.add),
        label: Text(l10n.saveAsTemplate),
      ),
    );
  }

  void _showTemplateInfo(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.templates),
        content: Text(l10n.createTemplatesHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _useTemplate(BuildContext context, WidgetRef ref, WriteTemplate template) {
    // Ouvrir l'écran de prévisualisation du modèle
    context.push('/templates/preview/${template.id}');
  }

  void _editTemplate(BuildContext context, WriteTemplate template) {
    final type = template.type.name;
    context.push('/templates/create/$type', extra: {
      'data': template.data,
      'templateId': template.id,
      'editMode': true,
    });
  }

  Future<void> _deleteTemplate(
    BuildContext context,
    WidgetRef ref,
    WriteTemplate template,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteCardConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(templatesProvider.notifier).deleteTemplate(template.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.templateDeleted)),
        );
      }
    }
  }
}

/// Card d'information en haut de la page Modèles
class _TemplatesInfoCard extends StatelessWidget {
  final ThemeData theme;

  const _TemplatesInfoCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.primary.withValues(alpha: 0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.templatesInfoDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTemplates extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;

  const _EmptyTemplates({required this.l10n, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TemplatesInfoCard(theme: theme),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmarks_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noTemplates,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/templates/create'),
              icon: const Icon(Icons.add),
              label: Text(l10n.saveAsTemplate),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final WriteTemplate template;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _TemplateCard({
    required this.template,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final type = template.type.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTypeLabel(type, l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.editCard),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: AppColors.error),
                        const SizedBox(width: 12),
                        Text(l10n.delete, style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
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
      case 'location':
        return Icons.location_on;
      case 'event':
        return Icons.event;
      default:
        return Icons.text_fields;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'url':
        return AppColors.primary;
      case 'phone':
        return AppColors.success;
      case 'email':
        return AppColors.info;
      case 'sms':
        return AppColors.secondary;
      case 'wifi':
        return AppColors.tertiary;
      case 'vcard':
        return Colors.purple;
      case 'location':
        return Colors.orange;
      case 'event':
        return Colors.deepPurple;
      default:
        return AppColors.primary;
    }
  }

  String _getTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'url':
        return l10n.url;
      case 'phone':
        return l10n.phone;
      case 'email':
        return l10n.email;
      case 'sms':
        return l10n.sms;
      case 'wifi':
        return l10n.wifi;
      case 'vcard':
        return l10n.contact;
      case 'location':
        return l10n.location;
      case 'event':
        return l10n.event;
      default:
        return l10n.text;
    }
  }
}

/// Indicateur de synchronisation Firebase
class _SyncStatusIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isAuthenticated = FirebaseTemplatesRepository.instance.isAuthenticated;

    return Tooltip(
      message: isAuthenticated
          ? 'Synchronisé avec le cloud'
          : 'Non connecté - stockage local uniquement',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          isAuthenticated ? Icons.cloud_done : Icons.cloud_off,
          color: isAuthenticated ? AppColors.success : Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}
