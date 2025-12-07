import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';

/// Écran pour créer un nouveau modèle de tag
class CreateTemplateScreen extends ConsumerWidget {
  const CreateTemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createTemplate),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text(
              l10n.whatTemplateType,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.chooseDataType,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // Types courants
            Text(
              l10n.commonTypes,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 110,
              child: Row(
                children: [
                  Expanded(
                    child: _TemplateTypeCard(
                      icon: Icons.link,
                      title: l10n.url,
                      subtitle: l10n.websiteLink,
                      color: Colors.blue,
                      onTap: () => context.push('/templates/create/url'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TemplateTypeCard(
                      icon: Icons.location_on,
                      title: l10n.location,
                      subtitle: l10n.gpsPosition,
                      color: Colors.pink,
                      onTap: () => context.push('/templates/create/location'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 110,
              child: Row(
                children: [
                  Expanded(
                    child: _TemplateTypeCard(
                      icon: Icons.event_available,
                      title: l10n.event,
                      subtitle: l10n.dateTimeLocation,
                      color: Colors.deepPurple,
                      onTap: () => context.push('/templates/create/event'),
                      showAiBadge: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TemplateTypeCard(
                      icon: Icons.wifi,
                      title: l10n.wifi,
                      subtitle: l10n.networkConfig,
                      color: Colors.purple,
                      onTap: () => context.push('/templates/create/wifi'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Autres types
            Text(
              l10n.otherTypes,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            _TemplateTypeListTile(
              icon: Icons.phone,
              title: l10n.phoneNumber,
              subtitle: l10n.directCall,
              color: Colors.teal,
              onTap: () => context.push('/templates/create/phone'),
            ),

            _TemplateTypeListTile(
              icon: Icons.email,
              title: l10n.email,
              subtitle: l10n.newMessage,
              color: Colors.red,
              onTap: () => context.push('/templates/create/email'),
            ),

            _TemplateTypeListTile(
              icon: Icons.sms,
              title: l10n.sms,
              subtitle: l10n.textMessage,
              color: Colors.indigo,
              onTap: () => context.push('/templates/create/sms'),
            ),

            _TemplateTypeListTile(
              icon: Icons.text_fields,
              title: l10n.text,
              subtitle: l10n.textMessage,
              color: Colors.green,
              onTap: () => context.push('/templates/create/text'),
            ),

            _TemplateTypeListTile(
              icon: Icons.contact_page,
              title: l10n.businessCard,
              subtitle: l10n.newBusinessCard,
              color: Colors.purple,
              onTap: () => context.push('/cards/new'),
            ),

            const SizedBox(height: 24),

            // Modèles spéciaux
            Text(
              l10n.specialTemplates,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            _TemplateTypeListTile(
              icon: Icons.star_rate,
              title: l10n.googleReview,
              subtitle: l10n.googleReviewLink,
              color: Colors.amber,
              onTap: () => context.push('/templates/create/googleReview'),
            ),

            _TemplateTypeListTile(
              icon: Icons.download,
              title: l10n.appDownload,
              subtitle: l10n.appStoreLink,
              color: Colors.cyan,
              onTap: () => context.push('/templates/create/appDownload'),
            ),

            _TemplateTypeListTile(
              icon: Icons.attach_money,
              title: l10n.tip,
              subtitle: l10n.tipPlatforms,
              color: Colors.green.shade700,
              onTap: () => context.push('/templates/create/tip'),
            ),

            const SizedBox(height: 24),

            // Modèles d'identification
            Text(
              l10n.idTemplates,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            _TemplateTypeListTile(
              icon: Icons.medical_services,
              title: l10n.medicalId,
              subtitle: l10n.emergencyInfo,
              color: Colors.red.shade700,
              onTap: () => context.push('/templates/create/medicalId'),
            ),

            _TemplateTypeListTile(
              icon: Icons.pets,
              title: l10n.petId,
              subtitle: l10n.petIdInfo,
              color: Colors.brown,
              onTap: () => context.push('/templates/create/petId'),
            ),

            _TemplateTypeListTile(
              icon: Icons.luggage,
              title: l10n.luggageId,
              subtitle: l10n.luggageIdInfo,
              color: Colors.blueGrey,
              onTap: () => context.push('/templates/create/luggageId'),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _TemplateTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool showAiBadge;

  const _TemplateTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.showAiBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  // Description centrée verticalement
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              // Badge IA
              if (showAiBadge)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          l10n.aiBadge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
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
}

class _TemplateTypeListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _TemplateTypeListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
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
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
