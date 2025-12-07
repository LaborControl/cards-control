import 'package:flutter/material.dart';
import '../../domain/entities/nfc_tag.dart';

class QuickActionsBar extends StatelessWidget {
  final NfcTag tag;
  final VoidCallback? onCopy;
  final VoidCallback? onSaveAsTemplate;
  final VoidCallback? onShare;
  final bool canSaveAsTemplate;

  const QuickActionsBar({
    super.key,
    required this.tag,
    this.onCopy,
    this.onSaveAsTemplate,
    this.onShare,
    this.canSaveAsTemplate = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.copy,
            label: 'Copier',
            onTap: onCopy,
          ),
          _ActionButton(
            icon: Icons.download,
            label: 'Modèle',
            onTap: canSaveAsTemplate ? onSaveAsTemplate : null,
            enabled: canSaveAsTemplate,
          ),
          _ActionButton(
            icon: Icons.share,
            label: 'Partager',
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
