import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/nfc_tag.dart';

class TagInfoCard extends StatelessWidget {
  final NfcTag tag;

  const TagInfoCard({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec type et technologie
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.nfc,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag.type.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        tag.technology.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badges d'état
                _buildStatusBadges(context),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // UID
            _buildInfoRow(
              context,
              icon: Icons.fingerprint,
              label: 'UID',
              value: tag.formattedUid,
              isMonospace: true,
              onCopy: () => _copyToClipboard(context, tag.uid),
            ),

            const SizedBox(height: 12),

            // Mémoire
            _buildInfoRow(
              context,
              icon: Icons.memory,
              label: 'Mémoire',
              value: '${tag.usedMemory}/${tag.memorySize} bytes',
              trailing: _buildMemoryIndicator(context),
            ),

            if (tag.ndefRecords.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Aperçu du contenu NDEF
              Text(
                'Contenu NDEF',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              ...tag.ndefRecords.take(2).map((record) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildNdefPreview(context, record),
              )),

              if (tag.ndefRecords.length > 2)
                Text(
                  '+ ${tag.ndefRecords.length - 2} enregistrement(s)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadges(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _StatusBadge(
          icon: tag.isWritable ? Icons.edit : Icons.lock,
          label: tag.isWritable ? 'Modifiable' : 'Lecture seule',
          color: tag.isWritable ? AppColors.success : AppColors.warning,
        ),
        if (tag.isLocked) ...[
          const SizedBox(height: 4),
          _StatusBadge(
            icon: Icons.lock_outline,
            label: 'Verrouillé',
            color: AppColors.error,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
    Widget? trailing,
    VoidCallback? onCopy,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: isMonospace ? 'JetBrainsMono' : null,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
        if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copier',
            onPressed: onCopy,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Widget _buildMemoryIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = tag.memoryUsagePercent;

    Color indicatorColor;
    if (percentage < 50) {
      indicatorColor = AppColors.success;
    } else if (percentage < 80) {
      indicatorColor = AppColors.warning;
    } else {
      indicatorColor = AppColors.error;
    }

    return SizedBox(
      width: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(indicatorColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNdefPreview(BuildContext context, NdefRecord record) {
    final theme = Theme.of(context);

    IconData icon;
    switch (record.type) {
      case NdefRecordType.uri:
        icon = Icons.link;
        break;
      case NdefRecordType.text:
        icon = Icons.text_fields;
        break;
      case NdefRecordType.vcard:
        icon = Icons.contact_page;
        break;
      case NdefRecordType.wifi:
        icon = Icons.wifi;
        break;
      case NdefRecordType.bluetooth:
        icon = Icons.bluetooth;
        break;
      case NdefRecordType.smartPoster:
        icon = Icons.web;
        break;
      default:
        icon = Icons.description;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.type.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (record.decodedPayload != null)
                  Text(
                    record.decodedPayload!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UID copié dans le presse-papiers'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
