import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/nfc_tag.dart';

class NdefRecordTile extends StatelessWidget {
  final NdefRecord record;
  final int index;

  const NdefRecordTile({
    super.key,
    required this.record,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ExpansionTile(
        leading: _buildIcon(theme),
        title: Text(
          record.type.displayName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: record.decodedPayload != null
            ? Text(
                record.decodedPayload!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              )
            : Text(
                '${record.payloadSize} bytes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Name Format
                _buildInfoRow(
                  context,
                  'Format',
                  record.typeNameFormat ?? 'Inconnu',
                ),

                const SizedBox(height: 8),

                // Payload décodé
                if (record.decodedPayload != null) ...[
                  _buildInfoRow(
                    context,
                    'Contenu',
                    record.decodedPayload!,
                    isSelectable: true,
                  ),
                  const SizedBox(height: 8),
                ],

                // Taille
                _buildInfoRow(
                  context,
                  'Taille',
                  '${record.payloadSize} bytes',
                ),

                const SizedBox(height: 12),

                // Payload hex
                Text(
                  'Données brutes (HEX)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    record.payloadHex,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Actions
                _buildActions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    IconData icon;
    Color color = theme.colorScheme.primary;

    switch (record.type) {
      case NdefRecordType.uri:
        icon = Icons.link;
        color = Colors.blue;
        break;
      case NdefRecordType.text:
        icon = Icons.text_fields;
        color = Colors.green;
        break;
      case NdefRecordType.vcard:
        icon = Icons.contact_page;
        color = Colors.orange;
        break;
      case NdefRecordType.wifi:
        icon = Icons.wifi;
        color = Colors.purple;
        break;
      case NdefRecordType.bluetooth:
        icon = Icons.bluetooth;
        color = Colors.indigo;
        break;
      case NdefRecordType.smartPoster:
        icon = Icons.web;
        color = Colors.teal;
        break;
      case NdefRecordType.androidApp:
        icon = Icons.android;
        color = Colors.green;
        break;
      case NdefRecordType.mimeMedia:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
        break;
      default:
        icon = Icons.description;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isSelectable = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: isSelectable
              ? SelectableText(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                )
              : Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Copier
        OutlinedButton.icon(
          onPressed: () => _copyToClipboard(context),
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copier'),
        ),

        // Action spécifique selon le type
        if (record.type == NdefRecordType.uri && record.decodedPayload != null)
          FilledButton.icon(
            onPressed: () => _openUrl(context),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Ouvrir'),
          ),

        if (record.type == NdefRecordType.vcard && record.decodedPayload != null)
          FilledButton.icon(
            onPressed: () => _addContact(context),
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Ajouter contact'),
          ),

        if (record.type == NdefRecordType.wifi)
          FilledButton.icon(
            onPressed: () => _connectWifi(context),
            icon: const Icon(Icons.wifi, size: 16),
            label: const Text('Connecter'),
          ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context) {
    final text = record.decodedPayload ?? record.payloadHex;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contenu copié'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    final url = record.decodedPayload;
    if (url == null) return;

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir ce lien')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _addContact(BuildContext context) async {
    final vCardData = record.decodedPayload;
    if (vCardData == null) return;

    try {
      // Demander la permission d'accès aux contacts
      if (await FlutterContacts.requestPermission()) {
        // Parser le vCard pour extraire les informations
        final contact = _parseVCard(vCardData);

        // Ouvrir l'éditeur de contact avec les données pré-remplies
        await FlutterContacts.openExternalInsert(contact);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ouverture de l\'application Contacts...')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission refusée pour accéder aux contacts')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  /// Parse un vCard et retourne un objet Contact
  Contact _parseVCard(String vCardData) {
    final contact = Contact();
    final lines = vCardData.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.startsWith('FN:')) {
        contact.displayName = trimmedLine.substring(3);
      } else if (trimmedLine.startsWith('N:')) {
        final parts = trimmedLine.substring(2).split(';');
        contact.name = Name(
          last: parts.isNotEmpty ? parts[0] : '',
          first: parts.length > 1 ? parts[1] : '',
        );
      } else if (trimmedLine.startsWith('TEL')) {
        final value = _extractValue(trimmedLine);
        if (value.isNotEmpty) {
          contact.phones.add(Phone(value));
        }
      } else if (trimmedLine.startsWith('EMAIL')) {
        final value = _extractValue(trimmedLine);
        if (value.isNotEmpty) {
          contact.emails.add(Email(value));
        }
      } else if (trimmedLine.startsWith('ORG:')) {
        contact.organizations.add(Organization(company: trimmedLine.substring(4)));
      } else if (trimmedLine.startsWith('TITLE:')) {
        if (contact.organizations.isNotEmpty) {
          contact.organizations[0] = Organization(
            company: contact.organizations[0].company,
            title: trimmedLine.substring(6),
          );
        } else {
          contact.organizations.add(Organization(title: trimmedLine.substring(6)));
        }
      } else if (trimmedLine.startsWith('URL')) {
        final value = _extractValue(trimmedLine);
        if (value.isNotEmpty) {
          contact.websites.add(Website(value));
        }
      }
    }

    return contact;
  }

  /// Extrait la valeur d'une ligne vCard (après le dernier :)
  String _extractValue(String line) {
    final colonIndex = line.lastIndexOf(':');
    if (colonIndex == -1) return '';
    return line.substring(colonIndex + 1).trim();
  }

  Future<void> _connectWifi(BuildContext context) async {
    final wifiData = record.decodedPayload;
    if (wifiData == null) return;

    // Parse WiFi credentials from NDEF record
    // Format typique: WIFI:T:WPA;S:network_name;P:password;;
    String? ssid;
    String? password;
    String? security;

    final parts = wifiData.split(';');
    for (final part in parts) {
      if (part.startsWith('WIFI:')) {
        // Premier segment avec le type de sécurité
        final subParts = part.substring(5).split(':');
        if (subParts.length >= 2 && subParts[0] == 'T') {
          security = subParts[1];
        }
      } else if (part.startsWith('S:')) {
        ssid = part.substring(2);
      } else if (part.startsWith('P:')) {
        password = part.substring(2);
      } else if (part.startsWith('T:')) {
        security = part.substring(2);
      }
    }

    if (ssid == null || ssid.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'extraire les informations WiFi')),
        );
      }
      return;
    }

    // Afficher les informations et proposer de copier le mot de passe
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Réseau WiFi détecté'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Réseau: $ssid'),
              if (security != null) Text('Sécurité: $security'),
              if (password != null && password.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Mot de passe: $password'),
              ],
              const SizedBox(height: 16),
              const Text(
                'Pour vous connecter, ouvrez les paramètres WiFi de votre appareil.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            if (password != null && password.isNotEmpty)
              FilledButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: password!));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mot de passe copié')),
                  );
                },
                child: const Text('Copier le mot de passe'),
              ),
          ],
        ),
      );
    }
  }
}
