import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../business_cards/presentation/providers/business_cards_provider.dart';
import '../../domain/entities/contact.dart';
import '../providers/contacts_provider.dart';

/// Liste des domaines de cartes de visite numériques connus
/// Inclut Cards Control et tous les concurrents majeurs
const List<String> _digitalCardDomains = [
  // Cards Control (notre app)
  'cards-control.app',
  'cardscontrol',
  // Concurrents majeurs
  'hihello.me',
  'hihello.com',
  'popl.co',
  'popl.me',
  'linqapp.com',
  'linq.com',
  'blinq.me',
  'bfrnd.link',
  'mobilo.cards',
  'mobilocard.com',
  'dotcards.net',
  'v1ce.co',
  'v1ce.com',
  'tapni.co',
  'tapni.com',
  'haystack.com',
  'switchit.com',
  'knowee.me',
  'wcard.io',
  'camcard.com',
  'beaconstac.com',
  'wave.cards',
  'tapt.io',
  'tapt.com',
  'blue.social',
  'ovou.me',
  'onecardinfo.com',
  'inigo.me',
  'linq.ai',
  'doorway.io',
  'flowcode.com',
  'vizzy.com',
  'covve.com',
  'sansan.com',
  'uniqode.com',
  'qrcode-tiger.com',
  'l-card.app',
  'cardly.net',
  'dibiz.com',
];

class ReadCardNfcScreen extends ConsumerStatefulWidget {
  const ReadCardNfcScreen({super.key});

  @override
  ConsumerState<ReadCardNfcScreen> createState() => _ReadCardNfcScreenState();
}

/// Vérifie si une URL appartient à un service de carte de visite numérique
bool _isDigitalCardUrl(String url) {
  final lowerUrl = url.toLowerCase();
  return _digitalCardDomains.any((domain) => lowerUrl.contains(domain));
}

/// Vérifie si l'URL est de Cards Control (notre app)
bool _isCardsControlUrl(String url) {
  final lowerUrl = url.toLowerCase();
  return lowerUrl.contains('cards-control.app') || lowerUrl.contains('cardscontrol');
}

class _ReadCardNfcScreenState extends ConsumerState<ReadCardNfcScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _nfcAvailable = false;
  String? _error;
  Contact? _scannedContact;
  String? _externalCardUrl; // URL de carte externe (concurrent)
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _checkNfcAvailability();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stopNfcSession();
    super.dispose();
  }

  Future<void> _checkNfcAvailability() async {
    final available = await NfcManager.instance.isAvailable();
    setState(() {
      _nfcAvailable = available;
    });
    if (available) {
      _startNfcSession();
    }
  }

  Future<void> _startNfcSession() async {
    setState(() {
      _isScanning = true;
      _error = null;
      _scannedContact = null;
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              setState(() {
                _error = 'Ce tag ne contient pas de données NDEF';
                _isScanning = false;
              });
              return;
            }

            final cachedMessage = ndef.cachedMessage;
            if (cachedMessage == null) {
              setState(() {
                _error = 'Tag vide ou non lisible';
                _isScanning = false;
              });
              return;
            }

            // Parse vCard data from NDEF
            Contact? contact;
            String? digitalCardUrl;
            bool isCardsControl = false;

            for (final record in cachedMessage.records) {
              final payload = String.fromCharCodes(record.payload);

              // Check for vCard
              if (payload.contains('BEGIN:VCARD')) {
                contact = _parseVCard(payload);
                break;
              }

              // Check for URL record (digital card link)
              if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
                final typeString = String.fromCharCodes(record.type);

                // URI record type = 'U'
                if (typeString == 'U' && record.payload.isNotEmpty) {
                  final url = _parseUriRecord(record.payload);
                  if (url != null && _isDigitalCardUrl(url)) {
                    digitalCardUrl = url;
                    isCardsControl = _isCardsControlUrl(url);
                    break;
                  }
                }

                // Text record type = 'T'
                if (typeString == 'T') {
                  // Text record - might contain contact info or URL
                  final text = payload.length > 3 ? payload.substring(3) : payload;

                  // Check if it's a digital card URL in text format
                  if (_isDigitalCardUrl(text)) {
                    digitalCardUrl = text.trim();
                    isCardsControl = _isCardsControlUrl(text);
                    break;
                  }

                  contact = _parseTextContact(text);
                }
              }

              // Check for absolute URI format
              if (record.typeNameFormat == NdefTypeNameFormat.absoluteUri) {
                final url = String.fromCharCodes(record.payload);
                if (_isDigitalCardUrl(url)) {
                  digitalCardUrl = url;
                  isCardsControl = _isCardsControlUrl(url);
                  break;
                }
              }
            }

            // If we found a digital card URL
            if (digitalCardUrl != null) {
              if (isCardsControl) {
                // Cards Control URL - fetch from Firebase
                await _fetchCardFromUrl(digitalCardUrl);
              } else {
                // Competitor URL - show option to open in browser
                await _handleExternalCardUrl(digitalCardUrl);
              }
              return;
            }

            if (contact != null) {
              setState(() {
                _scannedContact = contact;
                _isScanning = false;
              });
            } else {
              setState(() {
                _error = 'Aucune carte de visite trouvée sur ce tag';
                _isScanning = false;
              });
            }
          } catch (e) {
            setState(() {
              _error = 'Erreur de lecture: $e';
              _isScanning = false;
            });
          }
        },
        onError: (error) async {
          setState(() {
            _error = 'Erreur NFC: ${error.message}';
            _isScanning = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Impossible de démarrer la session NFC: $e';
        _isScanning = false;
      });
    }
  }

  Future<void> _stopNfcSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  Contact _parseVCard(String vcard) {
    String firstName = '';
    String lastName = '';
    String? company;
    String? jobTitle;
    String? email;
    String? phone;
    String? mobile;
    String? website;
    String? address;
    String? notes;

    final lines = vcard.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.startsWith('N:') || trimmedLine.startsWith('N;')) {
        final nameParts = trimmedLine.substring(trimmedLine.indexOf(':') + 1).split(';');
        if (nameParts.isNotEmpty) lastName = nameParts[0];
        if (nameParts.length > 1) firstName = nameParts[1];
      } else if (trimmedLine.startsWith('FN:') || trimmedLine.startsWith('FN;')) {
        final fullName = trimmedLine.substring(trimmedLine.indexOf(':') + 1);
        if (firstName.isEmpty && lastName.isEmpty) {
          final parts = fullName.split(' ');
          if (parts.isNotEmpty) firstName = parts[0];
          if (parts.length > 1) lastName = parts.sublist(1).join(' ');
        }
      } else if (trimmedLine.startsWith('ORG:') || trimmedLine.startsWith('ORG;')) {
        company = trimmedLine.substring(trimmedLine.indexOf(':') + 1).split(';').first;
      } else if (trimmedLine.startsWith('TITLE:') || trimmedLine.startsWith('TITLE;')) {
        jobTitle = trimmedLine.substring(trimmedLine.indexOf(':') + 1);
      } else if (trimmedLine.startsWith('EMAIL') && trimmedLine.contains(':')) {
        email = trimmedLine.substring(trimmedLine.indexOf(':') + 1);
      } else if (trimmedLine.contains('TEL') && trimmedLine.contains(':')) {
        final phoneNum = trimmedLine.substring(trimmedLine.indexOf(':') + 1);
        if (trimmedLine.toLowerCase().contains('cell') ||
            trimmedLine.toLowerCase().contains('mobile')) {
          mobile = phoneNum;
        } else {
          phone = phoneNum;
        }
      } else if (trimmedLine.startsWith('URL') && trimmedLine.contains(':')) {
        website = trimmedLine.substring(trimmedLine.indexOf(':') + 1);
      } else if (trimmedLine.startsWith('ADR') && trimmedLine.contains(':')) {
        final adrParts = trimmedLine.substring(trimmedLine.indexOf(':') + 1).split(';');
        address = adrParts.where((p) => p.isNotEmpty).join(', ');
      } else if (trimmedLine.startsWith('NOTE:') || trimmedLine.startsWith('NOTE;')) {
        notes = trimmedLine.substring(trimmedLine.indexOf(':') + 1);
      }
    }

    return Contact(
      id: '',
      firstName: firstName,
      lastName: lastName,
      company: company?.isNotEmpty == true ? company : null,
      jobTitle: jobTitle?.isNotEmpty == true ? jobTitle : null,
      email: email?.isNotEmpty == true ? email : null,
      phone: phone?.isNotEmpty == true ? phone : null,
      mobile: mobile?.isNotEmpty == true ? mobile : null,
      website: website?.isNotEmpty == true ? website : null,
      address: address?.isNotEmpty == true ? address : null,
      notes: notes?.isNotEmpty == true ? notes : null,
      source: 'nfc',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Contact? _parseTextContact(String text) {
    // Try to parse simple text format
    // Format: Name | Company | Email | Phone
    final parts = text.split('|').map((e) => e.trim()).toList();
    if (parts.isEmpty) return null;

    String firstName = '';
    String lastName = '';

    if (parts.isNotEmpty) {
      final nameParts = parts[0].split(' ');
      if (nameParts.isNotEmpty) firstName = nameParts[0];
      if (nameParts.length > 1) lastName = nameParts.sublist(1).join(' ');
    }

    return Contact(
      id: '',
      firstName: firstName,
      lastName: lastName,
      company: parts.length > 1 ? parts[1] : null,
      email: parts.length > 2 ? parts[2] : null,
      phone: parts.length > 3 ? parts[3] : null,
      source: 'nfc',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Parse NDEF URI record payload to get the full URL
  String? _parseUriRecord(List<int> payload) {
    if (payload.isEmpty) return null;

    // First byte is the URI identifier code
    final uriIdentifier = payload[0];
    final uriContent = String.fromCharCodes(payload.sublist(1));

    // URI identifier codes (NFC Forum)
    const uriPrefixes = {
      0x00: '', // No prepending
      0x01: 'http://www.',
      0x02: 'https://www.',
      0x03: 'http://',
      0x04: 'https://',
      0x05: 'tel:',
      0x06: 'mailto:',
    };

    final prefix = uriPrefixes[uriIdentifier] ?? '';
    return '$prefix$uriContent';
  }

  /// Fetch business card data from Cards Control URL
  Future<void> _fetchCardFromUrl(String url) async {
    try {
      setState(() {
        _isScanning = true;
        _error = null;
      });

      // Extract card ID from URL
      // Formats:
      // - https://cards-control.app/card/ABC123
      // - cardscontrol://card/ABC123
      String? cardId;

      final uri = Uri.tryParse(url);
      if (uri != null) {
        // Check path segments for card ID
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) {
          // Find 'card' segment and get the next one
          for (int i = 0; i < segments.length - 1; i++) {
            if (segments[i] == 'card') {
              cardId = segments[i + 1];
              break;
            }
          }
          // If no 'card' segment, take the last segment
          cardId ??= segments.last;
        }
      }

      // Fallback: try regex extraction
      if (cardId == null || cardId.isEmpty) {
        final cardIdMatch = RegExp(r'card[/:]([a-zA-Z0-9_-]+)').firstMatch(url);
        cardId = cardIdMatch?.group(1);
      }

      if (cardId == null || cardId.isEmpty) {
        setState(() {
          _error = 'Impossible d\'extraire l\'ID de la carte depuis l\'URL';
          _isScanning = false;
        });
        return;
      }

      // Fetch the public card from Firebase
      final card = await ref.read(publicCardProvider(cardId).future);

      if (card == null) {
        setState(() {
          _error = 'Carte non trouvée (ID: $cardId)';
          _isScanning = false;
        });
        return;
      }

      // Convert BusinessCard to Contact
      final contact = Contact(
        id: '',
        firstName: card.firstName,
        lastName: card.lastName,
        company: card.company,
        jobTitle: card.jobTitle,
        email: card.email,
        phone: card.phone,
        mobile: card.mobile,
        website: card.website,
        address: card.address,
        photoUrl: card.photoUrl,
        source: 'nfc',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() {
        _scannedContact = contact;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la récupération de la carte: $e';
        _isScanning = false;
      });
    }
  }

  /// Handle external digital card URL (competitor cards)
  /// Shows the URL and offers to open it in browser
  Future<void> _handleExternalCardUrl(String url) async {
    setState(() {
      _externalCardUrl = url;
      _isScanning = false;
    });
  }

  /// Open external URL in browser
  Future<void> _openExternalUrl() async {
    if (_externalCardUrl == null) return;

    final uri = Uri.tryParse(_externalCardUrl!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
        );
      }
    }
  }

  /// Get the service name from URL for display
  String _getServiceNameFromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('hihello')) return 'HiHello';
    if (lowerUrl.contains('popl')) return 'Popl';
    if (lowerUrl.contains('linq')) return 'Linq';
    if (lowerUrl.contains('blinq')) return 'Blinq';
    if (lowerUrl.contains('mobilo')) return 'Mobilo';
    if (lowerUrl.contains('dotcards')) return 'Dot';
    if (lowerUrl.contains('v1ce')) return 'V1CE';
    if (lowerUrl.contains('tapni')) return 'Tapni';
    if (lowerUrl.contains('haystack')) return 'Haystack';
    if (lowerUrl.contains('switchit')) return 'Switchit';
    if (lowerUrl.contains('knowee')) return 'Knowee';
    if (lowerUrl.contains('wcard')) return 'Wcard';
    if (lowerUrl.contains('camcard')) return 'CamCard';
    if (lowerUrl.contains('beaconstac')) return 'Beaconstac';
    if (lowerUrl.contains('wave.cards')) return 'Wave';
    if (lowerUrl.contains('tapt')) return 'Tapt';
    if (lowerUrl.contains('blue.social')) return 'Blue';
    if (lowerUrl.contains('ovou')) return 'Ovou';
    if (lowerUrl.contains('inigo')) return 'Inigo';
    if (lowerUrl.contains('flowcode')) return 'Flowcode';
    return 'Carte numérique';
  }

  Future<void> _saveContact() async {
    if (_scannedContact == null) return;

    await ref.read(contactsProvider.notifier).createContact(
      firstName: _scannedContact!.firstName,
      lastName: _scannedContact!.lastName,
      company: _scannedContact!.company,
      jobTitle: _scannedContact!.jobTitle,
      email: _scannedContact!.email,
      phone: _scannedContact!.phone,
      mobile: _scannedContact!.mobile,
      website: _scannedContact!.website,
      address: _scannedContact!.address,
      notes: _scannedContact!.notes,
      source: 'nfc',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.contactAdded)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.readCardNfc),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: _scannedContact != null
                  ? _buildContactPreview(theme, l10n)
                  : _externalCardUrl != null
                      ? _buildExternalCardView(theme)
                      : _buildScanningView(theme, l10n),
            ),
            if (_scannedContact != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _scannedContact = null;
                        });
                        _startNfcSession();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.scanAnother),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saveContact,
                      icon: const Icon(Icons.save),
                      label: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
            if (_externalCardUrl != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _externalCardUrl = null;
                        });
                        _startNfcSession();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.scanAnother),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _openExternalUrl,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Ouvrir'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScanningView(ThemeData theme, AppLocalizations l10n) {
    if (!_nfcAvailable) {
      return _buildErrorView(
        theme,
        Icons.nfc_outlined,
        l10n.hceNotSupported,
        l10n.enableNfcInSettings,
      );
    }

    if (_error != null) {
      return _buildErrorView(
        theme,
        Icons.error_outline,
        l10n.error,
        _error!,
        showRetry: true,
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 160 + (_pulseController.value * 20),
              height: 160 + (_pulseController.value * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1 + (_pulseController.value * 0.1)),
              ),
              child: Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.nfc,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          l10n.approachNfcTag,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Approchez une carte de visite NFC',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_isScanning)
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildErrorView(
    ThemeData theme,
    IconData icon,
    String title,
    String message, {
    bool showRetry = false,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Icon(
          icon,
          size: 80,
          color: Colors.red.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (showRetry) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _error = null;
              });
              _startNfcSession();
            },
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
        ],
      ),
    );
  }

  Widget _buildContactPreview(ThemeData theme, AppLocalizations l10n) {
    final contact = _scannedContact!;

    return SingleChildScrollView(
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.readSuccess,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      contact.initials,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    contact.fullName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (contact.jobTitle != null || contact.company != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [contact.jobTitle, contact.company]
                          .whereType<String>()
                          .join(' - '),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (contact.email != null)
                    _ContactDetailRow(
                      icon: Icons.email_outlined,
                      label: l10n.email,
                      value: contact.email!,
                    ),
                  if (contact.phone != null)
                    _ContactDetailRow(
                      icon: Icons.phone_outlined,
                      label: l10n.phone,
                      value: contact.phone!,
                    ),
                  if (contact.mobile != null)
                    _ContactDetailRow(
                      icon: Icons.smartphone,
                      label: l10n.mobile,
                      value: contact.mobile!,
                    ),
                  if (contact.website != null)
                    _ContactDetailRow(
                      icon: Icons.language,
                      label: l10n.website,
                      value: contact.website!,
                    ),
                  if (contact.address != null)
                    _ContactDetailRow(
                      icon: Icons.location_on_outlined,
                      label: l10n.address,
                      value: contact.address!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build view for external digital card URL (competitor cards)
  Widget _buildExternalCardView(ThemeData theme) {
    final serviceName = _getServiceNameFromUrl(_externalCardUrl!);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link,
                size: 64,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Carte $serviceName détectée',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Cette carte provient d\'un autre service. Appuyez sur "Ouvrir" pour voir les informations de contact.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.credit_card,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            serviceName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.link,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _externalCardUrl!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Astuce: Créez votre carte sur Cards Control pour un partage plus rapide !',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
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

class _ContactDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
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
