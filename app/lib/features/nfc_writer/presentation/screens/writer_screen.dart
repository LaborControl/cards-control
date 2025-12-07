import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/write_data.dart';
import '../providers/templates_provider.dart';

class WriterScreen extends ConsumerWidget {
  const WriterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Écrire un tag'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Historique des écritures
            },
            tooltip: 'Historique',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text(
              'Que souhaitez-vous écrire ?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez le type de données à programmer sur votre tag NFC',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // Types courants
            Text(
              'Types courants',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _WriteTypeCard(
                    icon: Icons.link,
                    title: 'URL',
                    subtitle: 'Site web, lien',
                    color: Colors.blue,
                    onTap: () => context.push('/writer/template/url'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WriteTypeCard(
                    icon: Icons.text_fields,
                    title: 'Texte',
                    subtitle: 'Message texte',
                    color: Colors.green,
                    onTap: () => context.push('/writer/template/text'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _WriteTypeCard(
                    icon: Icons.contact_page,
                    title: 'vCard',
                    subtitle: 'Carte de visite',
                    color: Colors.orange,
                    onTap: () => context.push('/writer/template/vcard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WriteTypeCard(
                    icon: Icons.wifi,
                    title: 'WiFi',
                    subtitle: 'Config. réseau',
                    color: Colors.purple,
                    onTap: () => context.push('/writer/template/wifi'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Autres types
            Text(
              'Autres types',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            _WriteTypeListTile(
              icon: Icons.phone,
              title: 'Numéro de téléphone',
              subtitle: 'Appel direct',
              color: Colors.teal,
              onTap: () => context.push('/writer/template/phone'),
            ),

            _WriteTypeListTile(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'Nouveau message',
              color: Colors.red,
              onTap: () => context.push('/writer/template/email'),
            ),

            _WriteTypeListTile(
              icon: Icons.sms,
              title: 'SMS',
              subtitle: 'Message texte',
              color: Colors.indigo,
              onTap: () => context.push('/writer/template/sms'),
            ),

            _WriteTypeListTile(
              icon: Icons.location_on,
              title: 'Localisation',
              subtitle: 'Position GPS',
              color: Colors.pink,
              onTap: () => context.push('/writer/template/location'),
            ),

            _WriteTypeListTile(
              icon: Icons.bluetooth,
              title: 'Bluetooth',
              subtitle: 'Appairage',
              color: Colors.blueAccent,
              isPremium: true,
              onTap: () => context.push('/writer/template/bluetooth'),
            ),

            _WriteTypeListTile(
              icon: Icons.apps,
              title: 'Lancer une app',
              subtitle: 'Application Android',
              color: Colors.green,
              isPremium: true,
              onTap: () => context.push('/writer/template/app'),
            ),

            const SizedBox(height: 24),

            // Templates sauvegardés
            _TemplatesSection(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _TemplatesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final templatesState = ref.watch(templatesProvider);
    final templates = templatesState.templates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes modèles dynamiques',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Mes modèles de tags dynamiques',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (templates.isNotEmpty)
              TextButton(
                onPressed: () => _showManageTemplatesSheet(context, ref),
                child: const Text('Gérer'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (templatesState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (templates.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun modèle',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez vos modèles de tags',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...templates.map((template) => _TemplateListTile(template: template)),
      ],
    );
  }

  void _showManageTemplatesSheet(BuildContext context, WidgetRef ref) {
    final templates = ref.read(templatesProvider).templates;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Gérer les modèles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return ListTile(
                    leading: Icon(_getIconForType(template.type)),
                    title: Text(template.name),
                    subtitle: Text(template.type.displayName),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Supprimer',
                      onPressed: () {
                        ref.read(templatesProvider.notifier).deleteTemplate(template.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Modèle "${template.name}" supprimé')),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
}

class _TemplateListTile extends ConsumerWidget {
  final WriteTemplate template;

  const _TemplateListTile({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storageService = ref.watch(templateStorageServiceProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForType(template.type),
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(template.name),
        subtitle: Text(
          storageService.getTemplateDescription(template),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Utiliser le modèle pour écrire
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Modèle "${template.name}" sélectionné')),
          );
        },
      ),
    );
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
}

class _WriteTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _WriteTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône + Titre sur la même ligne
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WriteTypeListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isPremium;
  final VoidCallback? onTap;

  const _WriteTypeListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isPremium = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        title: Row(
          children: [
            Text(title),
            if (isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PRO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
