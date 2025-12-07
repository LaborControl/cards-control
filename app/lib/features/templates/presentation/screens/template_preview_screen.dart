import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../nfc_writer/domain/entities/write_data.dart';
import '../../../nfc_writer/presentation/providers/templates_provider.dart';
import '../../../nfc_writer/data/services/template_storage_service.dart';

/// Écran de prévisualisation et partage d'un modèle (style card_share_screen)
class TemplatePreviewScreen extends ConsumerStatefulWidget {
  final String templateId;

  const TemplatePreviewScreen({super.key, required this.templateId});

  @override
  ConsumerState<TemplatePreviewScreen> createState() => _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends ConsumerState<TemplatePreviewScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final templatesState = ref.watch(templatesProvider);

    final template = templatesState.templates.firstWhere(
      (t) => t.id == widget.templateId,
      orElse: () => WriteTemplate(
        id: '',
        name: '',
        type: WriteDataType.text,
        data: {},
        createdAt: DateTime.now(),
      ),
    );

    if (template.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.template)),
        body: Center(child: Text(l10n.templateNotFound)),
      );
    }

    final storageService = TemplateStorageService.instance;
    final description = storageService.getTemplateDescription(template);

    // Tous les templates sont publiés automatiquement - on utilise toujours l'URL publique
    final shareUrl = template.shareUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(template.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n.editTemplate,
            onPressed: () => _editTemplate(context, template),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // QR Code
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    QrImageView(
                      data: shareUrl,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.scanQrCodeAbove,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Méthodes de partage
            Text(
              l10n.shareMethods,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            _ShareOption(
              icon: Icons.nfc,
              title: l10n.writeNfc,
              subtitle: l10n.writeToNfcDesc,
              color: AppColors.primary,
              onTap: () => _writeToNfc(context, template),
            ),

            _ShareOption(
              icon: Icons.qr_code,
              title: l10n.qrCode,
              subtitle: l10n.scanQrCodeAbove,
              color: AppColors.secondary,
              onTap: () {
                // Déjà affiché en haut
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.scanQrCodeAbove)),
                );
              },
            ),

            _ShareOption(
              icon: Icons.copy,
              title: l10n.copyContent,
              subtitle: shareUrl,
              color: AppColors.info,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: shareUrl));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.contentCopied),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),

            _ShareOption(
              icon: Icons.share,
              title: l10n.shareVia,
              subtitle: l10n.messagingApps,
              color: AppColors.tertiary,
              onTap: () async {
                final text = '${template.name}\n\n$shareUrl';
                await Share.share(text, subject: template.name);
              },
            ),


            const SizedBox(height: 24),

            // Actions rapides
            Text(
              l10n.quickActions,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            // Première ligne : Émuler et Écrire
            Row(
              children: [
                if (Platform.isAndroid)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.wifi_tethering,
                      label: l10n.emulateTag,
                      color: AppColors.primary,
                      onTap: () {
                        // Aller à la page d'émulation avec le template pré-sélectionné
                        context.push('/emulation?tab=templates&templateId=${widget.templateId}');
                      },
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit_note,
                    label: l10n.writeNfc,
                    color: Colors.deepPurple,
                    onTap: () => _writeToNfc(context, template),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Deuxième ligne : Détails et Modifier
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.info_outline,
                    label: l10n.details,
                    color: AppColors.secondary,
                    onTap: () => _showDetails(context, template, theme, l10n),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit,
                    label: l10n.edit,
                    color: AppColors.tertiary,
                    onTap: () => _editTemplate(context, template),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Statistiques
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.statistics,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatItem(
                          icon: Icons.touch_app,
                          value: template.useCount.toString(),
                          label: l10n.uses,
                        ),
                        const SizedBox(width: 24),
                        _StatItem(
                          icon: Icons.calendar_today,
                          value: _formatDate(template.createdAt),
                          label: l10n.createdOn,
                        ),
                      ],
                    ),
                    if (template.lastUsedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.lastUsedOn(_formatDate(template.lastUsedAt!)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _editTemplate(BuildContext context, WriteTemplate template) {
    final type = template.type.name;
    context.push('/templates/create/$type', extra: {
      'data': template.data,
      'templateId': template.id,
      'editMode': true,
      'templateName': template.name,
    });
  }

  void _writeToNfc(BuildContext context, WriteTemplate template) {
    // Écrire l'URL publique du template sur le tag NFC
    context.push('/writer/template/url', extra: {
      'data': {'url': template.shareUrl},
    });
  }

  void _showDetails(BuildContext context, WriteTemplate template, ThemeData theme, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTypeColor(template.type).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTypeIcon(template.type),
                      color: _getTypeColor(template.type),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          template.type.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _getTypeColor(template.type),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.data,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildDetailsList(template, theme, l10n),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailsList(WriteTemplate template, ThemeData theme, AppLocalizations l10n) {
    final data = template.data;
    final widgets = <Widget>[];

    switch (template.type) {
      case WriteDataType.url:
        widgets.add(_DetailRow(label: l10n.url, value: data['url'] ?? ''));
        break;
      case WriteDataType.text:
        widgets.add(_DetailRow(label: l10n.text, value: data['text'] ?? ''));
        break;
      case WriteDataType.wifi:
        widgets.add(_DetailRow(label: l10n.network, value: data['ssid'] ?? ''));
        widgets.add(_DetailRow(label: l10n.security, value: data['authType'] ?? 'WPA2'));
        if (data['hidden'] == true) {
          widgets.add(_DetailRow(label: l10n.hidden, value: l10n.yes));
        }
        break;
      case WriteDataType.vcard:
        final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        widgets.add(_DetailRow(label: l10n.name, value: name));
        if (data['organization'] != null && data['organization'].isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.company, value: data['organization']));
        }
        if (data['title'] != null && data['title'].isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.jobTitle, value: data['title']));
        }
        if (data['phone'] != null && data['phone'].isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.phone, value: data['phone']));
        }
        if (data['email'] != null && data['email'].isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.email, value: data['email']));
        }
        break;
      case WriteDataType.phone:
        widgets.add(_DetailRow(label: l10n.phone, value: data['phone'] ?? ''));
        break;
      case WriteDataType.email:
        widgets.add(_DetailRow(label: l10n.email, value: data['email'] ?? ''));
        if (data['subject'] != null && data['subject'].isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.subject, value: data['subject']));
        }
        break;
      case WriteDataType.sms:
        widgets.add(_DetailRow(label: l10n.phone, value: data['phone'] ?? ''));
        if (data['message'] != null && data['message'].isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.message, value: data['message']));
        }
        break;
      case WriteDataType.location:
        widgets.add(_DetailRow(label: l10n.latitude, value: data['latitude']?.toString() ?? ''));
        widgets.add(_DetailRow(label: l10n.longitude, value: data['longitude']?.toString() ?? ''));
        break;
      case WriteDataType.event:
        widgets.add(_DetailRow(label: l10n.title, value: data['title'] ?? ''));
        if (data['date'] != null) {
          final date = DateTime.tryParse(data['date']);
          if (date != null) {
            widgets.add(_DetailRow(
              label: l10n.date,
              value: '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
            ));
          }
        }
        if (data['time'] != null && data['time'].isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.time, value: data['time']));
        }
        if (data['location'] != null && data['location'].isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.location, value: data['location']));
        }
        if (data['address'] != null && data['address'].isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.address, value: data['address']));
        }
        if (data['description'] != null && data['description'].isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.description, value: data['description']));
        }
        if (data['url'] != null && data['url'].isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.link, value: data['url']));
        }
        break;
      case WriteDataType.googleReview:
        widgets.add(_DetailRow(label: l10n.placeId, value: data['placeId'] ?? ''));
        break;
      case WriteDataType.appDownload:
        if (data['appStoreUrl'] != null && (data['appStoreUrl'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.appStore, value: data['appStoreUrl']));
        }
        if (data['playStoreUrl'] != null && (data['playStoreUrl'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.playStore, value: data['playStoreUrl']));
        }
        break;
      case WriteDataType.tip:
        widgets.add(_DetailRow(label: l10n.provider, value: data['provider'] ?? 'paypal'));
        if (data['paypalUrl'] != null && (data['paypalUrl'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.paypal, value: data['paypalUrl']));
        }
        if (data['stripeUrl'] != null && (data['stripeUrl'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.stripe, value: data['stripeUrl']));
        }
        if (data['customUrl'] != null && (data['customUrl'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.url, value: data['customUrl']));
        }
        break;
      case WriteDataType.medicalId:
        widgets.add(_DetailRow(label: l10n.name, value: data['name'] ?? ''));
        if (data['bloodType'] != null && (data['bloodType'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.bloodType, value: data['bloodType']));
        }
        if (data['allergies'] != null && (data['allergies'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.allergies, value: data['allergies']));
        }
        if (data['medications'] != null && (data['medications'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.medications, value: data['medications']));
        }
        if (data['conditions'] != null && (data['conditions'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.conditions, value: data['conditions']));
        }
        if (data['emergencyContact'] != null && (data['emergencyContact'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.emergencyContact, value: data['emergencyContact']));
        }
        if (data['doctorName'] != null && (data['doctorName'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.doctor, value: data['doctorName']));
        }
        if (data['doctorPhone'] != null && (data['doctorPhone'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.doctorPhone, value: data['doctorPhone']));
        }
        break;
      case WriteDataType.petId:
        widgets.add(_DetailRow(label: l10n.name, value: data['petName'] ?? ''));
        if (data['species'] != null && (data['species'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.species, value: data['species']));
        }
        if (data['breed'] != null && (data['breed'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.breed, value: data['breed']));
        }
        if (data['chipNumber'] != null && (data['chipNumber'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.chipNumber, value: data['chipNumber']));
        }
        widgets.add(_DetailRow(label: l10n.owner, value: data['ownerName'] ?? ''));
        widgets.add(_DetailRow(label: l10n.phone, value: data['ownerPhone'] ?? ''));
        if (data['vetName'] != null && (data['vetName'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.vet, value: data['vetName']));
        }
        if (data['vetPhone'] != null && (data['vetPhone'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.vetPhone, value: data['vetPhone']));
        }
        break;
      case WriteDataType.luggageId:
        widgets.add(_DetailRow(label: l10n.owner, value: data['ownerName'] ?? ''));
        widgets.add(_DetailRow(label: l10n.phone, value: data['ownerPhone'] ?? ''));
        if (data['ownerEmail'] != null && (data['ownerEmail'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.email, value: data['ownerEmail']));
        }
        if (data['address'] != null && (data['address'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.address, value: data['address']));
        }
        if (data['flightNumber'] != null && (data['flightNumber'] as String).isNotEmpty) {
          widgets.add(_DetailRow(label: l10n.flightNumber, value: data['flightNumber']));
        }
        break;
      default:
        widgets.add(Text('Type: ${template.type.displayName}'));
    }

    return widgets;
  }

  IconData _getTypeIcon(WriteDataType type) {
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
      case WriteDataType.event:
        return Icons.event;
      case WriteDataType.googleReview:
        return Icons.star_rate;
      case WriteDataType.appDownload:
        return Icons.download;
      case WriteDataType.tip:
        return Icons.attach_money;
      case WriteDataType.medicalId:
        return Icons.medical_services;
      case WriteDataType.petId:
        return Icons.pets;
      case WriteDataType.luggageId:
        return Icons.luggage;
      default:
        return Icons.nfc;
    }
  }

  Color _getTypeColor(WriteDataType type) {
    switch (type) {
      case WriteDataType.url:
        return AppColors.primary;
      case WriteDataType.text:
        return Colors.green;
      case WriteDataType.wifi:
        return Colors.purple;
      case WriteDataType.vcard:
        return Colors.orange;
      case WriteDataType.phone:
        return AppColors.success;
      case WriteDataType.email:
        return AppColors.info;
      case WriteDataType.sms:
        return AppColors.secondary;
      case WriteDataType.location:
        return Colors.pink;
      case WriteDataType.event:
        return Colors.deepPurple;
      case WriteDataType.googleReview:
        return Colors.amber;
      case WriteDataType.appDownload:
        return Colors.cyan;
      case WriteDataType.tip:
        return Colors.green.shade700;
      case WriteDataType.medicalId:
        return Colors.red.shade700;
      case WriteDataType.petId:
        return Colors.brown;
      case WriteDataType.luggageId:
        return Colors.blueGrey;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
