import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/cards/info_card.dart';
import '../../../nfc_reader/presentation/providers/nfc_reader_provider.dart';
import '../../../settings/presentation/screens/ai_usage_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagHistoryAsync = ref.watch(tagHistoryProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/coche.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Text(l10n.appTitle),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tagHistoryProvider);
          ref.invalidate(aiUsageStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Actions rapides
              Text(
                l10n.quickActions,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Cartes et Modèles - Navigation directe
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 140,
                      child: _QuickActionCard(
                        icon: Icons.contact_page,
                        title: 'Cartes & Contacts',
                        subtitle: 'Mes cartes de visite et mes contacts',
                        color: AppColors.info,
                        onTap: () => context.go('/cards'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 140,
                      child: _QuickActionCard(
                        icon: Icons.bookmarks,
                        title: l10n.templates,
                        subtitle: l10n.myTemplates,
                        color: AppColors.secondary,
                        onTap: () => context.go('/templates'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Tags et Émuler - Navigation directe
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 140,
                      child: _QuickActionCard(
                        icon: Icons.nfc,
                        title: l10n.tags,
                        subtitle: l10n.tagOperations,
                        color: AppColors.primary,
                        onTap: () => context.go('/tags'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 140,
                      child: _QuickActionCard(
                        icon: Icons.smartphone,
                        title: l10n.emulate,
                        subtitle: l10n.emulateDescription,
                        color: AppColors.tertiary,
                        onTap: () => context.push('/emulation'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Statistiques
              Text(
                l10n.statistics,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              _StatisticsSection(),

              const SizedBox(height: 24),

              // Historique récent
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.recentHistory,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/history'),
                    child: Text(l10n.viewAll),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              tagHistoryAsync.when(
                data: (tags) {
                  if (tags.isEmpty) {
                    return Center(
                      child: _EmptyHistoryCard(
                        onScan: () => context.go('/reader'),
                      ),
                    );
                  }

                  return Column(
                    children: tags.take(3).map((tag) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InfoCard(
                          title: tag.type.displayName,
                          subtitle: tag.formattedUid,
                          icon: Icons.nfc,
                          iconColor: AppColors.primary,
                          onTap: () => context.push('/reader/details/${tag.id}'),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text('${l10n.error}: $error'),
                ),
              ),

              const SizedBox(height: 80), // Espace pour la bottom nav
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône + Titre sur la même ligne
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description centrée verticalement
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  final VoidCallback? onScan;

  const _EmptyHistoryCard({this.onScan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noTagsScanned,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.scanFirstTag,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.nfc),
              label: Text(l10n.scanTag2),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tagHistoryAsync = ref.watch(tagHistoryProvider);
    final aiStatsAsync = ref.watch(aiUsageStatsProvider);

    return Row(
      children: [
        // Tags scannés
        Expanded(
          child: tagHistoryAsync.when(
            data: (tags) => StatsCard(
              value: tags.length.toString(),
              label: l10n.scannedTags,
              icon: Icons.nfc,
              color: AppColors.primary,
              onTap: () => context.push('/history'),
            ),
            loading: () => StatsCard(
              value: '...',
              label: l10n.scannedTags,
              icon: Icons.nfc,
              color: AppColors.primary,
            ),
            error: (_, __) => StatsCard(
              value: '0',
              label: l10n.scannedTags,
              icon: Icons.nfc,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Crédits IA
        Expanded(
          child: aiStatsAsync.when(
            data: (stats) {
              final remaining = stats.tokensRemaining;
              String value;
              if (remaining >= 1000000) {
                value = '${(remaining / 1000000).toStringAsFixed(1)}M';
              } else if (remaining >= 1000) {
                value = '${(remaining / 1000).toStringAsFixed(0)}k';
              } else {
                value = remaining.toString();
              }

              return StatsCard(
                value: value,
                label: l10n.aiCredits,
                icon: Icons.auto_awesome,
                color: const Color(0xFF8B5CF6),
                onTap: () => context.push('/settings/ai-usage'),
              );
            },
            loading: () => StatsCard(
              value: '...',
              label: l10n.aiCredits,
              icon: Icons.auto_awesome,
              color: const Color(0xFF8B5CF6),
            ),
            error: (_, __) => StatsCard(
              value: '-',
              label: l10n.aiCredits,
              icon: Icons.auto_awesome,
              color: const Color(0xFF8B5CF6),
            ),
          ),
        ),
      ],
    );
  }
}
