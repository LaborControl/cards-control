import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final isPremium = authState.user?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cards Control Pro'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Premium
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber[700]!,
                    Colors.orange[600]!,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPremium ? 'Vous êtes Pro !' : 'Passez à Pro',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPremium
                        ? 'Profitez de toutes les fonctionnalités'
                        : 'Débloquez tout le potentiel de Cards Control',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fonctionnalités Pro
                  Text(
                    'Fonctionnalités Pro',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _FeatureItem(
                    icon: Icons.smartphone,
                    title: 'Émulation HCE',
                    description: 'Transformez votre téléphone en tag NFC',
                    isIncluded: true,
                  ),
                  _FeatureItem(
                    icon: Icons.copy,
                    title: 'Copie illimitée',
                    description: 'Dupliquez autant de tags que vous voulez',
                    isIncluded: true,
                  ),
                  _FeatureItem(
                    icon: Icons.contact_page,
                    title: 'Cartes de visite illimitées',
                    description: 'Créez des cartes de visite sans limite',
                    isIncluded: true,
                  ),
                  _FeatureItem(
                    icon: Icons.analytics,
                    title: 'Analytiques avancées',
                    description: 'Statistiques détaillées de vos partages',
                    isIncluded: true,
                  ),
                  _FeatureItem(
                    icon: Icons.cloud_sync,
                    title: 'Synchronisation cloud',
                    description: 'Sauvegardez et synchronisez vos données',
                    isIncluded: true,
                  ),
                  _FeatureItem(
                    icon: Icons.security,
                    title: 'Protection par mot de passe',
                    description: 'Sécurisez vos tags avec un code',
                    isIncluded: true,
                  ),
                  _FeatureItem(
                    icon: Icons.block,
                    title: 'Sans publicités',
                    description: 'Une expérience sans interruption',
                    isIncluded: true,
                  ),
                  _FeatureItem(
                    icon: Icons.support_agent,
                    title: 'Support prioritaire',
                    description: 'Assistance rapide et dédiée',
                    isIncluded: true,
                  ),

                  const SizedBox(height: 32),

                  if (!isPremium) ...[
                    // Plans d'abonnement
                    Text(
                      'Choisissez votre plan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Plan annuel
                    _PricingCard(
                      title: 'Annuel',
                      price: '49 € HT',
                      period: '/an',
                      description: 'Facturation annuelle, toutes les fonctionnalités Pro',
                      isRecommended: true,
                      onTap: () => _subscribe(context, 'yearly'),
                    ),

                    const SizedBox(height: 12),

                    // Plan à vie
                    _PricingCard(
                      title: 'À vie',
                      price: '199 € HT',
                      period: '',
                      description: 'Paiement unique, accès permanent à toutes les fonctionnalités',
                      isRecommended: false,
                      onTap: () => _subscribe(context, 'lifetime'),
                    ),

                    const SizedBox(height: 24),

                    // Garantie
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Garantie satisfait ou remboursé',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                                Text(
                                  '7 jours pour essayer sans risque',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Informations abonnement actif
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Abonnement actif',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Pro annuel',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            _InfoRow(
                              label: 'Date de début',
                              value: '15 Nov 2024',
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Prochain renouvellement',
                              value: '15 Nov 2025',
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Montant',
                              value: '49 € HT/an',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Gérer l'abonnement
                    OutlinedButton.icon(
                      onPressed: () => _manageSubscription(context),
                      icon: const Icon(Icons.settings),
                      label: const Text('Gérer mon abonnement'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Mentions légales
                  Text(
                    'En vous abonnant, vous acceptez nos Conditions d\'utilisation '
                    'et notre Politique de confidentialité. L\'abonnement se '
                    'renouvelle automatiquement sauf annulation 24h avant la fin '
                    'de la période en cours.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Restaurer les achats
                  TextButton(
                    onPressed: () => _restorePurchases(context),
                    child: const Text('Restaurer mes achats'),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _subscribe(BuildContext context, String plan) {
    // TODO: Implémenter l'achat in-app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Achat du plan $plan en cours...'),
      ),
    );
  }

  void _manageSubscription(BuildContext context) {
    // TODO: Ouvrir les paramètres d'abonnement du store
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture des paramètres d\'abonnement...'),
      ),
    );
  }

  void _restorePurchases(BuildContext context) {
    // TODO: Restaurer les achats
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restauration des achats en cours...'),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isIncluded;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isIncluded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.amber[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isIncluded)
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String description;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRecommended
            ? BorderSide(color: Colors.amber[700]!, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            if (isRecommended)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.amber[700],
                child: const Text(
                  'RECOMMANDÉ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isRecommended ? Colors.amber[700] : null,
                        ),
                      ),
                      if (period.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            period,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
