import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/services/native_nfc_service.dart';
import '../../../../core/services/qr_code_service.dart';
import '../../../../core/services/shortcut_service.dart';
import '../../../../core/services/wallet_service.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/business_card.dart';
import '../providers/business_cards_provider.dart';

bool _isValidUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return url.startsWith('http://') || url.startsWith('https://');
}

class CardPreviewScreen extends ConsumerStatefulWidget {
  final String cardId;

  const CardPreviewScreen({super.key, required this.cardId});

  @override
  ConsumerState<CardPreviewScreen> createState() => _CardPreviewScreenState();
}

class _CardPreviewScreenState extends ConsumerState<CardPreviewScreen> {
  bool _isEmulating = false;
  int _remainingSeconds = 0;
  Timer? _emulationTimer;

  @override
  void dispose() {
    _emulationTimer?.cancel();
    super.dispose();
  }

  Future<void> _startEmulation(BusinessCard card) async {
    final l10n = AppLocalizations.of(context)!;
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.hceOnlyAndroid)),
      );
      return;
    }

    final nfcService = NativeNfcService.instance;

    // Vérifier si NFC est disponible et activé
    final isEnabled = await nfcService.isNfcEnabled();
    if (!isEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.enableNfc),
            action: SnackBarAction(
              label: l10n.settings,
              onPressed: () => nfcService.openNfcSettings(),
            ),
          ),
        );
      }
      return;
    }

    // Arrêter la lecture NFC pendant l'émulation
    await nfcService.stopReading();

    // Configurer la carte pour l'émulation
    final cardUrl = QrCodeService.instance.generateBusinessCardUrl(card.id);
    await nfcService.setBusinessCardForEmulation(
      cardId: card.id,
      cardUrl: cardUrl,
      vCardData: card.toVCard(),
    );

    // Démarrer l'émulation
    await nfcService.setEmulationEnabled(true);

    setState(() {
      _isEmulating = true;
      _remainingSeconds = 10;
    });

    // Afficher le dialogue d'émulation
    _showEmulationDialog(card);

    // Timer de 10 secondes
    _emulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() => _remainingSeconds--);
      } else {
        _stopEmulation();
      }
    });
  }

  Future<void> _stopEmulation({bool closeDialog = true}) async {
    _emulationTimer?.cancel();
    _emulationTimer = null;

    if (_isEmulating) {
      final nfcService = NativeNfcService.instance;
      await nfcService.setEmulationEnabled(false);

      if (mounted) {
        setState(() {
          _isEmulating = false;
          _remainingSeconds = 0;
        });
      }
    }

    // Fermer le dialogue si demandé
    if (closeDialog && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _createShortcut(BusinessCard card) async {
    final l10n = AppLocalizations.of(context)!;
    final shortcutService = ShortcutService.instance;

    // Vérifier si les raccourcis sont supportés
    final isSupported = await shortcutService.isSupported();
    if (!isSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shortcutsNotSupported),
          ),
        );
      }
      return;
    }

    // Détecter MIUI et afficher un dialogue préventif
    final isMiui = await shortcutService.isMiuiDevice();
    if (isMiui && mounted) {
      final shouldContinue = await _showMiuiShortcutDialog();
      if (!shouldContinue) return;
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
      cardId: card.id,
      cardName: card.fullName,
      initials: initials,
      primaryColor: primaryColor,
    );

    if (mounted) {
      if (success) {
        // Sur MIUI, même si success = true, le raccourci peut être bloqué
        if (isMiui) {
          _showMiuiSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.shortcutAdded),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shortcutFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showMiuiShortcutDialog() async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Xiaomi/MIUI'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.miuiShortcutWarning,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(l10n.miuiStep1),
            Text(l10n.miuiStep2),
            Text(l10n.miuiStep3),
            Text(l10n.miuiStep4),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              await ShortcutService.instance.openAppSettings();
              if (context.mounted) Navigator.pop(context, false);
            },
            child: Text(l10n.settings),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.tryAnyway),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showMiuiSuccessDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(l10n.shortcutRequested),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shortcutRequestSent),
            const SizedBox(height: 12),
            Text(
              l10n.miuiShortcutHelp,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ShortcutService.instance.openAppSettings();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.openSettings),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmulationDialog(BusinessCard card) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _HceEmulationDialog(
        card: card,
        remainingSeconds: _remainingSeconds,
        onStop: _stopEmulation,
        getRemainingSeconds: () => _remainingSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final card = ref.watch(cardByIdProvider(widget.cardId));

    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.preview)),
        body: Center(child: Text(l10n.cardNotFound)),
      );
    }

    final primaryColor = Color(
      int.parse(card.primaryColor.replaceFirst('#', '0xFF')),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.preview),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/cards/edit/${widget.cardId}'),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => context.push('/cards/share/${widget.cardId}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Carte de visite visuelle
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _BusinessCardWidget(card: card, primaryColor: primaryColor),
              ),
            ),

            // Actions rapides - Grille 2x2
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Première ligne : Émuler et Wallet
                  Row(
                    children: [
                      if (Platform.isAndroid)
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.wifi_tethering,
                            label: l10n.emulate,
                            color: AppColors.primary,
                            onTap: () => _startEmulation(card),
                          ),
                        )
                      else
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.qr_code,
                            label: l10n.qrCode,
                            color: AppColors.secondary,
                            onTap: () => _showQrCode(context, card),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Platform.isIOS ? Icons.apple : Icons.wallet,
                          label: l10n.wallet,
                          color: AppColors.tertiary,
                          onTap: () async {
                            final result = await WalletService.instance.addToWallet(card);
                            if (context.mounted) {
                              if (result.success) {
                                ref.read(businessCardsProvider.notifier).recordShare(widget.cardId, 'wallet');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.addingToWallet)),
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
                  // Deuxième ligne : QR Code et Raccourci
                  Row(
                    children: [
                      if (Platform.isAndroid)
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.qr_code,
                            label: l10n.qrCode,
                            color: AppColors.secondary,
                            onTap: () => _showQrCode(context, card),
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),
                      const SizedBox(width: 12),
                      if (Platform.isAndroid)
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.add_to_home_screen,
                            label: l10n.shortcut,
                            color: AppColors.success,
                            onTap: () => _createShortcut(card),
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Informations détaillées
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.information,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (card.email != null && card.email!.isNotEmpty)
                    _InfoTile(
                      icon: Icons.email,
                      label: l10n.email,
                      value: card.email!,
                    ),

                  if (card.phone != null && card.phone!.isNotEmpty)
                    _InfoTile(
                      icon: Icons.phone,
                      label: l10n.phone,
                      value: card.phone!,
                    ),

                  if (card.mobile != null && card.mobile!.isNotEmpty)
                    _InfoTile(
                      icon: Icons.smartphone,
                      label: l10n.mobile,
                      value: card.mobile!,
                    ),

                  if (card.website != null && card.website!.isNotEmpty)
                    _InfoTile(
                      icon: Icons.language,
                      label: l10n.website,
                      value: card.website!,
                    ),

                  if (card.address != null && card.address!.isNotEmpty)
                    _InfoTile(
                      icon: Icons.location_on,
                      label: l10n.address,
                      value: card.address!,
                    ),

                  if (card.socialLinks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.socialNetworks,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: card.socialLinks.entries.map((entry) {
                        return Chip(
                          avatar: Icon(
                            _getSocialIcon(entry.key),
                            size: 18,
                          ),
                          label: Text(entry.key),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistiques
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistiques',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              icon: Icons.visibility,
                              value: card.analytics.totalViews.toString(),
                              label: l10n.views,
                            ),
                          ),
                          Expanded(
                            child: _StatItem(
                              icon: Icons.share,
                              value: card.analytics.totalShares.toString(),
                              label: l10n.shares,
                            ),
                          ),
                          Expanded(
                            child: _StatItem(
                              icon: Icons.qr_code_scanner,
                              value: card.analytics.totalScans.toString(),
                              label: l10n.scans,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showQrCode(BuildContext context, BusinessCard card) {
    final shareUrl = QrCodeService.instance.generateBusinessCardUrl(widget.cardId);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.qrCodeOf(card.fullName),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: shareUrl,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.scanToSeeCard,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  IconData _getSocialIcon(String network) {
    switch (network.toLowerCase()) {
      case 'linkedin':
        return Icons.work;
      case 'twitter':
        return Icons.alternate_email;
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'github':
        return Icons.code;
      case 'youtube':
        return Icons.play_arrow;
      default:
        return Icons.link;
    }
  }
}

class _BusinessCardWidget extends StatelessWidget {
  final BusinessCard card;
  final Color primaryColor;

  const _BusinessCardWidget({
    required this.card,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header avec photo
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Photo ou initiales
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: _isValidUrl(card.photoUrl)
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: card.photoUrl!,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryColor,
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                card.initials,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            card.initials,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                // Nom et titre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (card.jobTitle != null && card.jobTitle!.isNotEmpty)
                        Text(
                          card.jobTitle!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (card.company != null && card.company!.isNotEmpty)
                        Text(
                          card.company!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Footer avec coordonnées
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (card.email != null && card.email!.isNotEmpty)
                  _CardContactItem(
                    icon: Icons.email,
                    value: card.email!,
                  ),
                if (card.phone != null && card.phone!.isNotEmpty)
                  _CardContactItem(
                    icon: Icons.phone,
                    value: card.phone!,
                  ),
                if (card.mobile != null && card.mobile!.isNotEmpty)
                  _CardContactItem(
                    icon: Icons.smartphone,
                    value: card.mobile!,
                  ),
                if (card.website != null && card.website!.isNotEmpty)
                  _CardContactItem(
                    icon: Icons.language,
                    value: card.website!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContactItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const _CardContactItem({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;

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
                  color: buttonColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: buttonColor),
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
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

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
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
    );
  }
}

/// Dialogue d'émulation HCE avec animation des téléphones
class _HceEmulationDialog extends StatefulWidget {
  final BusinessCard card;
  final int remainingSeconds;
  final VoidCallback onStop;
  final int Function() getRemainingSeconds;

  const _HceEmulationDialog({
    required this.card,
    required this.remainingSeconds,
    required this.onStop,
    required this.getRemainingSeconds,
  });

  @override
  State<_HceEmulationDialog> createState() => _HceEmulationDialogState();
}

class _HceEmulationDialogState extends State<_HceEmulationDialog>
    with TickerProviderStateMixin {
  late AnimationController _phoneController;
  late AnimationController _waveController;
  late Animation<double> _phoneAnimation;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();

    // Animation du téléphone qui s'approche
    _phoneController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _phoneAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _phoneController, curve: Curves.easeInOut),
    );

    // Animation des ondes NFC
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _phoneController.repeat(reverse: true);
    _waveController.repeat();

    // Timer pour mettre à jour le compte à rebours
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _waveController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingSeconds = widget.getRemainingSeconds();

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animation des deux téléphones
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  child: _buildAnimatedPhones(theme),
                ),
                const SizedBox(height: 12),
                Text(
                  'Émulation active',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Placez votre téléphone comme indiqué',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Compte à rebours
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${remainingSeconds}s',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.card.fullName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.card.company != null && widget.card.company!.isNotEmpty)
            Text(
              widget.card.company!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: [
        FilledButton.tonal(
          onPressed: widget.onStop,
          child: const Text('Arrêter'),
        ),
      ],
    );
  }

  Widget _buildAnimatedPhones(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_phoneAnimation, _waveController]),
      builder: (context, child) {
        final slideOffset = _phoneAnimation.value * 15;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Téléphone récepteur (à gauche, incliné vers la droite)
            Transform.rotate(
              angle: 0.35,
              child: _buildReceiverPhone(theme),
            ),
            const SizedBox(width: 8),
            // Téléphone émetteur avec ondes NFC (glisse vers la gauche)
            Transform.translate(
              offset: Offset(-slideOffset, 0),
              child: Transform.rotate(
                angle: -1.047,
                child: _buildEmitterWithWaves(theme),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmitterWithWaves(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ondes NFC
        SizedBox(
          width: 40,
          height: 25,
          child: CustomPaint(
            painter: _SonarWavePainter(
              progress: _waveController.value,
              color: AppColors.success,
            ),
          ),
        ),
        // Téléphone vu de profil
        Container(
          width: 10,
          height: 55,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: AppColors.success,
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Vous',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiverPhone(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 55,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Bosse caméra
              Positioned(
                top: 3,
                left: -4,
                child: Container(
                  width: 6,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Récepteur',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

/// Painter pour dessiner des ondes sonar
class _SonarWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _SonarWavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height;

    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i * 0.33) % 1.0;
      final radius = 5 + (waveProgress * 20);
      final opacity = (1.0 - waveProgress) * 0.9;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius,
      );

      canvas.drawArc(
        rect,
        -math.pi,
        math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SonarWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
