import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/ai_token_service.dart';
import '../../../../l10n/app_localizations.dart';

/// Provider pour le service de tokens IA
final aiTokenServiceProvider = Provider<AITokenService>((ref) {
  return AITokenService();
});

/// Provider pour les stats d'utilisation
final aiUsageStatsProvider = FutureProvider<AIUsageStats>((ref) async {
  final service = ref.read(aiTokenServiceProvider);
  return service.getMonthlyStats();
});

/// Écran affichant l'utilisation des tokens IA
class AIUsageScreen extends ConsumerWidget {
  const AIUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(aiUsageStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiUsage),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(l10n.errorLoadingData),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(aiUsageStatsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(aiUsageStatsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Carte principale avec jauge
                _buildUsageCard(context, theme, l10n, stats),
                const SizedBox(height: 24),

                // Détails par type
                Text(
                  l10n.usageByType,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildUsageByType(context, theme, l10n, stats),

                // Info sur la période (uniquement pour les Pro)
                if (stats.isPremium) ...[
                  const SizedBox(height: 24),
                  _buildPeriodInfo(context, theme, l10n, stats),
                ],

                const SizedBox(height: 24),

                // Section achat de tokens (Pro) ou upgrade (gratuit)
                _buildCreditsSection(context, theme, l10n, stats),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsageCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    AIUsageStats stats,
  ) {
    final usagePercent = stats.usagePercentage / 100;

    Color progressColor = AppColors.success;
    if (usagePercent >= 0.5 && usagePercent < 0.8) {
      progressColor = Colors.orange;
    } else if (usagePercent >= 0.8) {
      progressColor = AppColors.error;
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.aiCredits,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.monthlyUsage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Jauge de progression
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTokens(stats.totalTokensUsed),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                    Text(
                      '/ ${_formatTokens(stats.tokenLimit)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: usagePercent.clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${stats.usagePercentage.toStringAsFixed(1)}% ${l10n.used}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${_formatTokens(stats.tokensRemaining)} ${l10n.remaining}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (stats.hasReachedLimit) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.tokenLimitReached,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageByType(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    AIUsageStats stats,
  ) {
    final usageTypes = [
      (AIUsageType.businessCardOcr, Icons.credit_card, l10n.businessCardReading),
      (AIUsageType.tagAnalysis, Icons.nfc, l10n.tagAnalysis),
      (AIUsageType.templateGeneration, Icons.auto_fix_high, l10n.templateGeneration),
    ];

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: usageTypes.asMap().entries.map((entry) {
          final index = entry.key;
          final (type, icon, label) = entry.value;
          final tokens = stats.usageByType[type] ?? 0;

          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                title: Text(label),
                trailing: Text(
                  _formatTokens(tokens),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (index < usageTypes.length - 1)
                Divider(height: 1, indent: 56, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodInfo(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    AIUsageStats stats,
  ) {
    final dateFormat = '${stats.periodStart.day}/${stats.periodStart.month}/${stats.periodStart.year}';
    final endFormat = '${stats.periodEnd.day}/${stats.periodEnd.month}/${stats.periodEnd.year}';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.billingPeriod,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    '$dateFormat - $endFormat',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              l10n.resetsMonthly,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    AIUsageStats stats,
  ) {
    if (stats.isPremium) {
      // Pour les Pro : section d'achat de tokens supplémentaires via Stripe
      return Card(
        elevation: 0,
        color: Colors.amber.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_shopping_cart, color: Colors.amber.shade700, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.needMoreCredits,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.buyMoreTokens,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Options d'achat de tokens
              _buildTokenPackage(
                context,
                theme,
                tokens: 100000,
                price: l10n.tokenPackagePrice1,
                onTap: () => _purchaseTokens(context, 'pack_100k'),
              ),
              const SizedBox(height: 8),
              _buildTokenPackage(
                context,
                theme,
                tokens: 500000,
                price: l10n.tokenPackagePrice2,
                isPopular: true,
                onTap: () => _purchaseTokens(context, 'pack_500k'),
              ),
              const SizedBox(height: 8),
              _buildTokenPackage(
                context,
                theme,
                tokens: 1000000,
                price: l10n.tokenPackagePrice3,
                onTap: () => _purchaseTokens(context, 'pack_1m'),
              ),
            ],
          ),
        ),
      );
    } else {
      // Pour les gratuits : incitation à passer Pro
      return Card(
        elevation: 0,
        color: Colors.amber.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => context.push('/subscription'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.star, color: Colors.amber.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.needMoreCredits,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.upgradeToPro,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.amber.shade700,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTokenPackage(
    BuildContext context,
    ThemeData theme, {
    required int tokens,
    required String price,
    bool isPopular = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isPopular
              ? Colors.amber.withValues(alpha: 0.15)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPopular
                ? Colors.amber.shade700
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    _formatTokens(tokens),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'tokens',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (isPopular) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'POPULAIRE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              price,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _purchaseTokens(BuildContext context, String packageId) {
    // TODO: Implémenter l'achat via Stripe
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.purchaseComingSoon),
      ),
    );
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1000000) {
      return '${(tokens / 1000000).toStringAsFixed(1)}M';
    } else if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(1)}k';
    }
    return tokens.toString();
  }
}
