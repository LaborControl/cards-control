import 'package:flutter/material.dart';
import '../../domain/entities/business_card.dart';

/// Modal pour sélectionner le type de carte de visite à créer
class CardTypeSelectorModal extends StatelessWidget {
  const CardTypeSelectorModal({super.key});

  static Future<BusinessCardType?> show(BuildContext context) {
    return showModalBottomSheet<BusinessCardType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CardTypeSelectorModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Quel type de carte souhaitez-vous créer ?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez le modèle qui correspond à votre usage',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Card type options
              _CardTypeOption(
                cardType: BusinessCardType.professional,
                icon: Icons.business_center,
                title: 'Professionnelle',
                description: 'Pour le travail : entreprise, poste, coordonnées professionnelles',
                color: Colors.blue,
                onTap: () => Navigator.pop(context, BusinessCardType.professional),
              ),
              const SizedBox(height: 12),

              _CardTypeOption(
                cardType: BusinessCardType.personal,
                icon: Icons.people,
                title: 'Personnelle',
                description: 'Pour les loisirs : club, association, coordonnées personnelles',
                color: Colors.green,
                onTap: () => Navigator.pop(context, BusinessCardType.personal),
              ),
              const SizedBox(height: 12),

              _CardTypeOption(
                cardType: BusinessCardType.profile,
                icon: Icons.person_pin,
                title: 'Profil avec CV',
                description: 'Pour la recherche d\'emploi : bio, profil LinkedIn, CV joint',
                color: Colors.purple,
                onTap: () => Navigator.pop(context, BusinessCardType.profile),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardTypeOption extends StatelessWidget {
  final BusinessCardType cardType;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _CardTypeOption({
    required this.cardType,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
