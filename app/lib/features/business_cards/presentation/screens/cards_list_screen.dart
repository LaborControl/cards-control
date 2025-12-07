import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/services/qr_code_service.dart';
import '../../../../core/services/share_service.dart';
import '../../domain/entities/business_card.dart';
import '../providers/business_cards_provider.dart';
import '../widgets/card_type_selector_modal.dart';
import '../../../../l10n/app_localizations.dart';

bool _isValidUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return url.startsWith('http://') || url.startsWith('https://');
}

class CardsListScreen extends ConsumerWidget {
  const CardsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cardsState = ref.watch(businessCardsProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.businessCards),
        actions: [
          _SyncIndicator(
            syncStatus: syncStatus,
            onTap: () {
              ref.read(businessCardsProvider.notifier).forceSyncAllCards();
            },
          ),
        ],
      ),
      body: cardsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cardsState.error != null
              ? Center(child: Text('${l10n.error}: ${cardsState.error}'))
              : cardsState.cards.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cardsState.cards.length,
                      itemBuilder: (context, index) {
                        final card = cardsState.cards[index];
                        return _CardTile(
                          card: card,
                          onTap: () => context.push('/cards/preview/${card.id}'),
                          onEdit: () => context.push('/cards/edit/${card.id}'),
                          onShare: () => context.push('/cards/share/${card.id}'),
                          onShowQr: () => _showQrCodeDialog(context, card),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCardTypeSelector(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newCard),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.contact_page,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.createFirstCard,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.createFirstCardDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showCardTypeSelector(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.createMyCard),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _importFromContacts(context),
              icon: const Icon(Icons.contacts),
              label: Text(l10n.importFromContacts),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/contacts/scan-card'),
              icon: const Icon(Icons.camera_alt),
              label: Text(l10n.scanCard),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromContacts(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Vérifier et demander la permission avec permission_handler
      var status = await Permission.contacts.status;

      if (status.isDenied) {
        status = await Permission.contacts.request();
      }

      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          final shouldOpen = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.permissionRequired),
              content: Text(
                l10n.contactPermissionDesc,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
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

  Future<void> _showCardTypeSelector(BuildContext context) async {
    final cardType = await CardTypeSelectorModal.show(context);
    if (cardType != null && context.mounted) {
      context.push('/cards/new', extra: {'cardType': cardType.value});
    }
  }

  void _showQrCodeDialog(BuildContext context, BusinessCard card) {
    final shareUrl = QrCodeService.instance.generateBusinessCardUrl(card.id);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          card.fullName,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: shareUrl,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.scanQrCode,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.toSeeCard,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ShareService.instance.copyToClipboard(shareUrl);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.linkCopied)),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.copyLink),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final BusinessCard card;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onShowQr;

  const _CardTile({
    required this.card,
    required this.onTap,
    required this.onEdit,
    required this.onShare,
    required this.onShowQr,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // Prévisualisation de la carte
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.primary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Photo ou initiales
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary,
                    backgroundImage: _isValidUrl(card.photoUrl)
                        ? NetworkImage(card.photoUrl!)
                        : null,
                    child: !_isValidUrl(card.photoUrl)
                        ? Text(
                            card.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (card.jobTitle != null && card.jobTitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            card.jobTitle!,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (card.company != null && card.company!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            card.company!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Logo entreprise
                  if (_isValidUrl(card.logoUrl))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: card.logoUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                  Icons.visibility,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  '${card.analytics.totalViews}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 16),
                  if (!card.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Modifier',
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Partager',
                    onPressed: onShare,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicateur de synchronisation dans l'AppBar
class _SyncIndicator extends StatelessWidget {
  final SyncStatus syncStatus;
  final VoidCallback onTap;

  const _SyncIndicator({
    required this.syncStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // En cours de synchronisation
    if (syncStatus.isSyncing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Tooltip(
          message: 'Synchronisation en cours...',
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    // Erreur de synchronisation
    if (syncStatus.error != null) {
      return IconButton(
        icon: const Icon(Icons.cloud_off, color: Colors.red),
        tooltip: syncStatus.error,
        onPressed: onTap,
      );
    }

    // Cartes en attente de synchronisation
    if (syncStatus.hasPendingSync) {
      return IconButton(
        icon: Badge(
          label: Text('${syncStatus.pendingCount}'),
          child: const Icon(Icons.cloud_upload, color: Colors.orange),
        ),
        tooltip: '${syncStatus.pendingCount} carte(s) en attente',
        onPressed: onTap,
      );
    }

    // Tout est synchronisé
    return IconButton(
      icon: const Icon(Icons.cloud_done, color: Colors.green),
      tooltip: 'Synchronisé - Appuyez pour forcer la synchro',
      onPressed: onTap,
    );
  }
}
