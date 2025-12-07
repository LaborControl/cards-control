import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class NfcGuideScreen extends StatelessWidget {
  const NfcGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nfcGuide),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction
            _buildIntroCard(theme, l10n),
            const SizedBox(height: 24),

            // Section LECTURE
            _buildSectionTitle(theme, l10n.readCapabilities, Icons.nfc, AppColors.primary),
            const SizedBox(height: 12),
            _buildReadSection(theme, l10n),
            const SizedBox(height: 24),

            // Section ECRITURE
            _buildSectionTitle(theme, l10n.writeCapabilities, Icons.edit, AppColors.secondary),
            const SizedBox(height: 12),
            _buildWriteSection(theme, l10n),
            const SizedBox(height: 24),

            // Section COPIE
            _buildSectionTitle(theme, l10n.copyCapabilities, Icons.copy, AppColors.tertiary),
            const SizedBox(height: 12),
            _buildCopySection(theme, l10n),
            const SizedBox(height: 24),

            // Section EMULATION HCE
            _buildSectionTitle(theme, l10n.emulationCapabilities, Icons.smartphone, AppColors.info),
            const SizedBox(height: 12),
            _buildEmulationSection(theme, l10n),
            const SizedBox(height: 24),

            // Section LIMITES TECHNIQUES
            _buildSectionTitle(theme, l10n.technicalLimits, Icons.warning_amber, Colors.orange),
            const SizedBox(height: 12),
            _buildTechnicalLimitsSection(theme, l10n),
            const SizedBox(height: 24),

            // Section LIMITES LEGALES
            _buildSectionTitle(theme, l10n.legalLimits, Icons.gavel, Colors.red),
            const SizedBox(height: 12),
            _buildLegalLimitsSection(theme, l10n),
            const SizedBox(height: 24),

            // Section TECHNOLOGIES SUPPORTEES
            _buildSectionTitle(theme, l10n.supportedTechnologies, Icons.memory, AppColors.primary),
            const SizedBox(height: 12),
            _buildTechnologiesSection(theme, l10n),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(ThemeData theme, AppLocalizations l10n) {
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.aboutNfcGuide,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.nfcGuideIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildReadSection(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCapabilityItem(theme, l10n.readNdef, l10n.readNdefDesc, true),
            const Divider(),
            _buildCapabilityItem(theme, l10n.readTagInfo, l10n.readTagInfoDesc, true),
            const Divider(),
            _buildCapabilityItem(theme, l10n.readMifare, l10n.readMifareDesc, true),
            const Divider(),
            _buildCapabilityItem(theme, l10n.readProtectedTags, l10n.readProtectedTagsDesc, false),
            const Divider(),
            _buildCapabilityItem(theme, l10n.readBankCards, l10n.readBankCardsDesc, false),
          ],
        ),
      ),
    );
  }

  Widget _buildWriteSection(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCapabilityItem(theme, l10n.writeNdef, l10n.writeNdefDesc, true),
            const Divider(),
            _buildCapabilityItem(theme, l10n.writeUrl, l10n.writeUrlDesc, true),
            const Divider(),
            _buildCapabilityItem(theme, l10n.writeText, l10n.writeTextDesc, true),
            const Divider(),
            _buildCapabilityItem(theme, l10n.writeVcard, l10n.writeVcardDesc, true),
            const Divider(),
            _buildCapabilityItem(theme, l10n.writeWifi, l10n.writeWifiDesc, true),
            const Divider(),
            _buildCapabilityItem(theme, l10n.writeLock, l10n.writeLockDesc, true),
            const Divider(),
            _buildCapabilityItem(theme, l10n.writeProtectedTags, l10n.writeProtectedTagsDesc, false),
          ],
        ),
      ),
    );
  }

  Widget _buildCopySection(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCapabilityItem(theme, l10n.copyNdef, l10n.copyNdefDesc, true),
            const Divider(),
            _buildCapabilityItem(theme, l10n.copyUid, l10n.copyUidDesc, false),
            const Divider(),
            _buildCapabilityItem(theme, l10n.copyProtected, l10n.copyProtectedDesc, false),
          ],
        ),
      ),
    );
  }

  Widget _buildEmulationSection(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCapabilityItem(theme, l10n.emulateCard, l10n.emulateCardDesc, true),
            const Divider(),
            _buildCapabilityItem(theme, l10n.emulateNdef, l10n.emulateNdefDesc, true),
            const Divider(),
            _buildCapabilityItem(theme, l10n.emulateUid, l10n.emulateUidDesc, false),
            const Divider(),
            _buildCapabilityItem(theme, l10n.emulateBank, l10n.emulateBankDesc, false),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalLimitsSection(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLimitItem(theme, Icons.fingerprint, l10n.limitUid, l10n.limitUidDesc),
            const SizedBox(height: 12),
            _buildLimitItem(theme, Icons.lock, l10n.limitCrypto, l10n.limitCryptoDesc),
            const SizedBox(height: 12),
            _buildLimitItem(theme, Icons.smartphone, l10n.limitHce, l10n.limitHceDesc),
            const SizedBox(height: 12),
            _buildLimitItem(theme, Icons.signal_cellular_alt, l10n.limitRange, l10n.limitRangeDesc),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalLimitsSection(ThemeData theme, AppLocalizations l10n) {
    return Card(
      color: Colors.red.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.legalWarning,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLegalItem(theme, l10n.legalCopyAccess, l10n.legalCopyAccessDesc),
            const SizedBox(height: 8),
            _buildLegalItem(theme, l10n.legalFraud, l10n.legalFraudDesc),
            const SizedBox(height: 8),
            _buildLegalItem(theme, l10n.legalPrivacy, l10n.legalPrivacyDesc),
            const SizedBox(height: 8),
            _buildLegalItem(theme, l10n.legalAuthorization, l10n.legalAuthorizationDesc),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnologiesSection(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTechRow(theme, 'NfcA (ISO 14443-3A)', l10n.techNfcA),
            const Divider(),
            _buildTechRow(theme, 'NfcB (ISO 14443-3B)', l10n.techNfcB),
            const Divider(),
            _buildTechRow(theme, 'NfcF (JIS 6319-4)', l10n.techNfcF),
            const Divider(),
            _buildTechRow(theme, 'NfcV (ISO 15693)', l10n.techNfcV),
            const Divider(),
            _buildTechRow(theme, 'IsoDep (ISO 14443-4)', l10n.techIsoDep),
            const Divider(),
            _buildTechRow(theme, 'NDEF', l10n.techNdef),
            const Divider(),
            _buildTechRow(theme, 'MIFARE Classic', l10n.techMifareClassic),
            const Divider(),
            _buildTechRow(theme, 'MIFARE Ultralight', l10n.techMifareUltralight),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityItem(ThemeData theme, String title, String description, bool supported) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            supported ? Icons.check_circle : Icons.cancel,
            color: supported ? Colors.green : Colors.red,
            size: 20,
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
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitItem(ThemeData theme, IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.orange, size: 20),
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
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalItem(ThemeData theme, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTechRow(ThemeData theme, String techName, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  techName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
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
        ],
      ),
    );
  }
}
