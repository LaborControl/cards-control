import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête RGPD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conforme RGPD',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Protection de vos données personnelles',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              theme,
              '1. Responsable du traitement',
              '''LABOR CONTROL
Développé par Jean Claude PASTOR
Email : support@labor-control.fr
Site web : https://cards-control.app

En tant que responsable du traitement, nous nous engageons à protéger vos données personnelles conformément au Règlement Général sur la Protection des Données (RGPD) et à la loi Informatique et Libertés.''',
            ),
            _buildSection(
              theme,
              '2. Données collectées',
              '''Nous collectons les catégories de données suivantes :

📧 Données d'identification :
• Nom, prénom
• Adresse email
• Photo de profil (optionnelle)

📱 Données techniques :
• Identifiant unique de l'appareil
• Type d'appareil et version du système
• Logs d'utilisation anonymisés

💳 Données de carte de visite :
• Informations professionnelles que vous saisissez
• Coordonnées de contact

📊 Données d'utilisation :
• Tags NFC scannés
• Historique d'activité
• Préférences de l'application''',
            ),
            _buildSection(
              theme,
              '3. Finalités du traitement',
              '''Vos données sont traitées pour les finalités suivantes :

✅ Gestion de votre compte utilisateur
✅ Fourniture et amélioration des services
✅ Synchronisation de vos données entre appareils
✅ Personnalisation de l'expérience utilisateur
✅ Gestion des abonnements Premium
✅ Support client
✅ Analyses statistiques anonymisées
✅ Prévention de la fraude

Base légale : Ces traitements sont fondés sur l'exécution du contrat (CGU), votre consentement ou nos intérêts légitimes.''',
            ),
            _buildSection(
              theme,
              '4. Durée de conservation',
              '''Vos données sont conservées selon les durées suivantes :

• Données du compte : Pendant la durée de votre inscription + 3 ans après suppression
• Données de carte de visite : Jusqu'à suppression par vos soins
• Historique des tags : 12 mois glissants
• Logs techniques : 6 mois
• Données de facturation : 10 ans (obligation légale)

À l'expiration de ces durées, vos données sont supprimées ou anonymisées.''',
            ),
            _buildSection(
              theme,
              '5. Partage des données',
              '''Vos données peuvent être partagées avec :

🔐 Sous-traitants techniques :
• Firebase (Google) - Hébergement et authentification
• Services de paiement (App Store/Google Play)

Ces partenaires sont soumis à des obligations contractuelles strictes de protection des données.

❌ Nous ne vendons jamais vos données à des tiers.
❌ Nous n'utilisons pas vos données à des fins publicitaires.''',
            ),
            _buildSection(
              theme,
              '6. Transferts internationaux',
              '''Certaines données peuvent être transférées vers des pays hors Union Européenne (notamment les États-Unis via les services Google).

Ces transferts sont encadrés par :
• Les Clauses Contractuelles Types de la Commission Européenne
• Le Data Privacy Framework (UE-USA)

Des garanties appropriées sont mises en place pour assurer un niveau de protection adéquat.''',
            ),
            _buildSection(
              theme,
              '7. Vos droits RGPD',
              '''Conformément au RGPD, vous disposez des droits suivants :

📋 Droit d'accès : Obtenir une copie de vos données
✏️ Droit de rectification : Corriger vos données inexactes
🗑️ Droit à l'effacement : Supprimer vos données
⏸️ Droit à la limitation : Limiter le traitement
📤 Droit à la portabilité : Récupérer vos données
🚫 Droit d'opposition : Vous opposer au traitement
⚙️ Droit de retirer votre consentement

Pour exercer ces droits, contactez-nous à : support@labor-control.fr

Vous pouvez également introduire une réclamation auprès de la CNIL (www.cnil.fr).''',
            ),
            _buildSection(
              theme,
              '8. Sécurité des données',
              '''Nous mettons en œuvre des mesures techniques et organisationnelles appropriées :

🔒 Chiffrement des données en transit (HTTPS/TLS)
🔒 Chiffrement des données sensibles au repos
🔒 Authentification sécurisée (Firebase Auth)
🔒 Accès restreint aux données personnelles
🔒 Audits de sécurité réguliers
🔒 Stockage sécurisé des mots de passe (hashage)''',
            ),
            _buildSection(
              theme,
              '9. Cookies et traceurs',
              '''L'Application utilise des technologies de suivi minimales :

• Identifiants de session pour l'authentification
• Préférences utilisateur stockées localement
• Analyses anonymisées via Firebase Analytics

Vous pouvez désactiver les analyses dans les paramètres de l'Application.''',
            ),
            _buildSection(
              theme,
              '10. Mineurs',
              '''L'Application n'est pas destinée aux personnes de moins de 16 ans. Nous ne collectons pas sciemment de données concernant des mineurs.

Si vous êtes parent et découvrez que votre enfant nous a fourni des données personnelles, contactez-nous pour les supprimer.''',
            ),
            _buildSection(
              theme,
              '11. Modifications de la politique',
              '''Cette politique peut être mise à jour pour refléter les évolutions légales ou de nos pratiques.

En cas de modification substantielle, vous serez informé par :
• Notification dans l'Application
• Email à l'adresse de votre compte

La date de dernière mise à jour est indiquée ci-dessous.''',
            ),
            _buildSection(
              theme,
              '12. Contact DPO',
              '''Pour toute question relative à la protection de vos données :

📧 Email : dpo@labor-control.fr
📧 Support : support@labor-control.fr
🌐 Site web : https://cards-control.app

Nous nous engageons à répondre à vos demandes dans un délai de 30 jours.''',
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
