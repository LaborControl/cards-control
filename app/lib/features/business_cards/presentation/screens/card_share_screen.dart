import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/services/qr_code_service.dart';
import '../../../../core/services/shortcut_service.dart';
import '../../../../core/services/wallet_service.dart';
import '../providers/business_cards_provider.dart';
import '../../../../l10n/app_localizations.dart';

class CardShareScreen extends ConsumerWidget {
  final String cardId;

  const CardShareScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final card = ref.watch(cardByIdProvider(cardId));
    final l10n = AppLocalizations.of(context)!;

    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.share)),
        body: Center(child: Text(l10n.cardNotFound)),
      );
    }

    final shareUrl = QrCodeService.instance.generateBusinessCardUrl(cardId);
    final vCardData = card.toVCard();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.share),
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
                      l10n.scanQrCode,
                      style: theme.textTheme.titleMedium?.copyWith(
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
              ),
            ),

            const SizedBox(height: 24),

            // Options de partage
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
              title: l10n.nfc,
              subtitle: l10n.approachPhone,
              color: AppColors.primary,
              onTap: () {
                if (Platform.isAndroid) {
                  // Sur Android, utiliser l'émulation HCE
                  context.push('/emulate/$cardId?autoStart=true');
                  ref.read(businessCardsProvider.notifier).recordShare(cardId, 'nfc');
                } else {
                  // Sur iOS, informer que l'émulation n'est pas disponible
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le partage NFC n\'est pas disponible sur iOS. Utilisez le QR Code ou le lien.'),
                    ),
                  );
                }
              },
            ),

            _ShareOption(
              icon: Icons.qr_code,
              title: l10n.qrCode,
              subtitle: l10n.scanCode,
              color: AppColors.secondary,
              onTap: () {
                // Déjà affiché
              },
            ),

            _ShareOption(
              icon: Icons.link,
              title: l10n.copyLink,
              subtitle: shareUrl,
              color: AppColors.info,
              onTap: () async {
                await ShareService.instance.copyToClipboard(shareUrl);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.linkCopied)),
                  );
                }
                // Enregistrer le partage
                ref.read(businessCardsProvider.notifier).recordShare(cardId, 'link');
              },
            ),

            _ShareOption(
              icon: Icons.share,
              title: l10n.shareVia,
              subtitle: l10n.messagingApps,
              color: AppColors.tertiary,
              onTap: () async {
                await ShareService.instance.shareText(
                  '${l10n.checkMyCard} : $shareUrl',
                  subject: l10n.myBusinessCard(card.fullName),
                );
                ref.read(businessCardsProvider.notifier).recordShare(cardId, 'share');
              },
            ),

            const SizedBox(height: 24),

            // Actions rapides - Grille de 4 boutons
            Text(
              l10n.quickActions,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            // Première ligne : Émuler et Wallet
            Row(
              children: [
                if (Platform.isAndroid)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.wifi_tethering,
                      label: l10n.emulate,
                      color: AppColors.primary,
                      onTap: () {
                        context.push('/emulate/$cardId');
                      },
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Platform.isIOS ? Icons.apple : Icons.wallet,
                    label: l10n.wallet,
                    color: AppColors.tertiary,
                    isPremium: true,
                    onTap: () async {
                      final walletService = WalletService.instance;

                      // Vérifier la disponibilité
                      final isAvailable = Platform.isIOS
                          ? await walletService.isAppleWalletAvailable()
                          : await walletService.isGoogleWalletAvailable();

                      if (!isAvailable) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                Platform.isIOS
                                    ? l10n.appleWalletNotAvailable
                                    : l10n.googleWalletNotAvailable,
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      // Ajouter au wallet
                      final result = await walletService.addToWallet(card);

                      if (context.mounted) {
                        if (result.success) {
                          ref.read(businessCardsProvider.notifier).recordShare(cardId, 'wallet');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.addedToWallet),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.error ?? l10n.walletError),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Deuxième ligne : vCard et Raccourci
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.contact_page,
                    label: l10n.vCard,
                    color: AppColors.secondary,
                    onTap: () async {
                      await ShareService.instance.shareVCard(
                        vCardData,
                        card.fullName,
                      );
                      ref.read(businessCardsProvider.notifier).recordShare(cardId, 'vcard');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (Platform.isAndroid)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_to_home_screen,
                      label: l10n.shortcut,
                      color: AppColors.success,
                      onTap: () async {
                        final shortcutService = ShortcutService.instance;

                        // Vérifier si les raccourcis sont supportés
                        final isSupported = await shortcutService.isSupported();
                        if (!isSupported) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.shortcutsNotSupported),
                              ),
                            );
                          }
                          return;
                        }

                        // Créer le raccourci
                        final initials = card.fullName.split(' ')
                            .where((s) => s.isNotEmpty)
                            .take(2)
                            .map((s) => s[0].toUpperCase())
                            .join();

                        final primaryColor = Color(
                          int.parse(card.primaryColor.replaceFirst('#', '0xFF'))
                        );

                        final success = await shortcutService.createCardShortcut(
                          cardId: cardId,
                          cardName: card.fullName,
                          initials: initials,
                          primaryColor: primaryColor,
                        );

                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.shortcutAdded),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.shortcutError),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),

            const SizedBox(height: 12),

            // Troisième ligne : Écrire sur NFC (Android uniquement)
            if (Platform.isAndroid)
              SizedBox(
                width: double.infinity,
                child: _ActionButton(
                  icon: Icons.edit_note,
                  label: l10n.writeToNfc,
                  color: Colors.deepPurple,
                  onTap: () {
                    context.push('/writer/template/url', extra: {'url': shareUrl});
                    ref.read(businessCardsProvider.notifier).recordShare(cardId, 'nfc_write');
                  },
                ),
              ),
          ],
        ),
      ),
    );
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
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
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
  final bool isPremium;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isPremium = false,
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
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color),
                  ),
                  if (isPremium)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
