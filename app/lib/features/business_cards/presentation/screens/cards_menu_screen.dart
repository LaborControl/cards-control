import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class CardsMenuScreen extends ConsumerWidget {
  const CardsMenuScreen({super.key});

  Future<void> _importFromContacts(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Vérifier et demander la permission
      var status = await Permission.contacts.status;

      if (status.isDenied) {
        status = await Permission.contacts.request();
      }

      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          final shouldOpen = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.permissionRequired),
              content: Text(
                l10n.contactPermissionDesc,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.openSettings),
                ),
              ],
            ),
          );

          if (shouldOpen == true) {
            await openAppSettings();
          }
        }
        return;
      }

      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.contactPermissionDenied)),
          );
        }
        return;
      }

      // Ouvrir le sélecteur de contact natif
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;

      // Récupérer les détails complets du contact
      final fullContact = await FlutterContacts.getContact(
        contact.id,
        withProperties: true,
        withPhoto: true,
      );

      if (fullContact == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.contactDetailsError)),
          );
        }
        return;
      }

      // Naviguer vers l'éditeur avec les données pré-remplies
      if (context.mounted) {
        context.push('/cards/new', extra: {
          'firstName': fullContact.name.first,
          'lastName': fullContact.name.last,
          'email': fullContact.emails.isNotEmpty ? fullContact.emails.first.address : null,
          'phone': fullContact.phones.isNotEmpty ? fullContact.phones.first.number : null,
          'company': fullContact.organizations.isNotEmpty ? fullContact.organizations.first.company : null,
          'jobTitle': fullContact.organizations.isNotEmpty ? fullContact.organizations.first.title : null,
          'website': fullContact.websites.isNotEmpty ? fullContact.websites.first.url : null,
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cardsAndContactsPageTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.myBusinessCards,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Grid of card operations - 6 cards total
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _CardOperationCard(
                  icon: Icons.contact_page,
                  title: l10n.myCardsTitle,
                  subtitle: l10n.myCardsSubtitle,
                  color: AppColors.primary,
                  onTap: () => context.push('/cards/list'),
                ),
                _CardOperationCard(
                  icon: Icons.add_card,
                  title: l10n.createCardTitle,
                  subtitle: l10n.createCardSubtitle,
                  color: AppColors.secondary,
                  onTap: () => context.push('/cards/new'),
                ),
                _CardOperationCard(
                  icon: Icons.camera_alt,
                  title: l10n.readPaperCardTitle,
                  subtitle: l10n.readPaperCardSubtitle,
                  color: AppColors.tertiary,
                  onTap: () => context.push('/contacts/scan-card'),
                  showAiBadge: true,
                ),
                _CardOperationCard(
                  icon: Icons.nfc,
                  title: l10n.scanNfcCardTitle,
                  subtitle: l10n.scanNfcCardSubtitle,
                  color: Colors.deepOrange,
                  onTap: () => context.push('/contacts/read-card'),
                ),
                _CardOperationCard(
                  icon: Icons.contacts,
                  title: l10n.import,
                  subtitle: l10n.fromContacts,
                  color: Colors.teal,
                  onTap: () => _importFromContacts(context),
                ),
                _CardOperationCard(
                  icon: Icons.people,
                  title: l10n.myContacts,
                  subtitle: l10n.manageContacts,
                  color: Colors.indigo,
                  onTap: () => context.push('/contacts'),
                ),
              ],
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _CardOperationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool showAiBadge;

  const _CardOperationCard({
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
