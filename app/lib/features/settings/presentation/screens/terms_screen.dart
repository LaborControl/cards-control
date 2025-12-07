import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.termsOfService),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              theme,
              '1. Acceptation des conditions',
              '''En téléchargeant, installant ou utilisant l'application Cards Control ("l'Application"), vous acceptez d'être lié par les présentes Conditions Générales d'Utilisation ("CGU"). Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser l'Application.

L'Application est éditée par la société LABOR CONTROL, développée par Jean Claude PASTOR ("l'Éditeur").''',
            ),
            _buildSection(
              theme,
              '2. Description du service',
              '''Cards Control est une application mobile permettant de :
• Lire et écrire des tags NFC
• Créer et partager des cartes de visite numériques
• Dupliquer des tags NFC (fonctionnalité Premium)
• Émuler des tags NFC via HCE (fonctionnalité Premium)

Certaines fonctionnalités nécessitent un appareil compatible NFC et un abonnement Premium.''',
            ),
            _buildSection(
              theme,
              '3. Inscription et compte utilisateur',
              '''Pour accéder à certaines fonctionnalités, vous devez créer un compte utilisateur. Vous vous engagez à :
• Fournir des informations exactes et à jour
• Maintenir la confidentialité de vos identifiants de connexion
• Nous informer immédiatement de toute utilisation non autorisée de votre compte

Vous êtes responsable de toutes les activités effectuées sous votre compte.''',
            ),
            _buildSection(
              theme,
              '4. Utilisation autorisée',
              '''Vous vous engagez à utiliser l'Application uniquement à des fins légales et conformément aux présentes CGU. Il est strictement interdit de :
• Utiliser l'Application pour des activités illégales
• Tenter de copier des tags NFC protégés sans autorisation
• Contourner les mesures de sécurité de l'Application
• Distribuer du contenu malveillant via les fonctionnalités de partage
• Revendre ou redistribuer l'Application ou ses fonctionnalités''',
            ),
            _buildSection(
              theme,
              '5. Abonnement Premium',
              '''L'abonnement Premium donne accès à des fonctionnalités avancées. Les conditions sont les suivantes :
• Le paiement est effectué via les stores (App Store / Google Play)
• L'abonnement se renouvelle automatiquement sauf annulation
• L'annulation doit être effectuée au moins 24h avant la fin de la période en cours
• Aucun remboursement n'est accordé pour la période en cours après annulation

Les prix sont affichés dans l'Application et peuvent varier selon les régions.''',
            ),
            _buildSection(
              theme,
              '6. Propriété intellectuelle',
              '''L'Application, son contenu, son design et son code source sont la propriété exclusive de l'Éditeur et sont protégés par les lois sur la propriété intellectuelle.

Vous n'êtes pas autorisé à :
• Copier, modifier ou distribuer l'Application
• Décompiler ou effectuer de l'ingénierie inverse sur l'Application
• Utiliser les marques, logos ou éléments graphiques de l'Application''',
            ),
            _buildSection(
              theme,
              '7. Données utilisateur',
              '''Les données créées par l'utilisateur (cartes de visite, historique de lecture) restent la propriété de l'utilisateur. L'Éditeur s'engage à :
• Stocker ces données de manière sécurisée
• Ne pas les partager avec des tiers sans consentement
• Permettre leur exportation et suppression sur demande

Pour plus de détails, consultez notre Politique de Confidentialité.''',
            ),
            _buildSection(
              theme,
              '8. Limitation de responsabilité',
              '''L'Application est fournie "en l'état". L'Éditeur ne garantit pas que :
• L'Application sera exempte d'erreurs ou d'interruptions
• Tous les tags NFC seront compatibles
• Les fonctionnalités seront disponibles sur tous les appareils

L'Éditeur ne saurait être tenu responsable des dommages indirects, accessoires ou consécutifs résultant de l'utilisation de l'Application.''',
            ),
            _buildSection(
              theme,
              '9. Modifications des CGU',
              '''L'Éditeur se réserve le droit de modifier les présentes CGU à tout moment. Les utilisateurs seront informés des modifications importantes via l'Application ou par email.

La poursuite de l'utilisation de l'Application après modification vaut acceptation des nouvelles CGU.''',
            ),
            _buildSection(
              theme,
              '10. Résiliation',
              '''L'Éditeur peut suspendre ou résilier votre accès à l'Application en cas de violation des présentes CGU, sans préavis ni remboursement.

Vous pouvez cesser d'utiliser l'Application à tout moment en la désinstallant et en supprimant votre compte.''',
            ),
            _buildSection(
              theme,
              '11. Droit applicable',
              '''Les présentes CGU sont régies par le droit français. Tout litige relatif à l'interprétation ou à l'exécution des présentes sera soumis aux tribunaux compétents de Paris, France.''',
            ),
            _buildSection(
              theme,
              '12. Contact',
              '''Pour toute question concernant ces CGU, vous pouvez nous contacter à :
• Email : support@cards-control.app
• Site web : https://cards-control.app''',
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Dernière mise à jour : Novembre 2025',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
