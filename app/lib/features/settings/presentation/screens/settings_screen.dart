import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/providers/theme_provider.dart';
import '../../../../app/providers/locale_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.more),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profil utilisateur
          if (authState.isAuthenticated) ...[
            _UserProfileCard(
              user: authState.user!,
              onTap: () => context.push('/profile'),
            ),
          ] else ...[
            _LoginPromptCard(
              onLogin: () => context.push('/login'),
            ),
          ],

          const SizedBox(height: 24),

          // Fonctionnalités Pro
          _SectionTitle(title: l10n.nfcPro),
          _SettingsTile(
            icon: Icons.copy,
            title: l10n.tagCopy,
            subtitle: l10n.duplicateNfcTags,
            color: AppColors.tertiary,
            onTap: () => context.push('/copy'),
          ),
          _SettingsTile(
            icon: Icons.smartphone,
            title: l10n.hceEmulationTitle,
            subtitle: l10n.transformPhone,
            color: AppColors.info,
            isPremium: true,
            proLabel: l10n.pro,
            onTap: () => context.push('/emulation'),
          ),

          const SizedBox(height: 24),

          // Abonnement
          _SectionTitle(title: l10n.subscription),
          _SettingsTile(
            icon: Icons.star,
            title: l10n.nfcProPremium,
            subtitle: authState.user?.isPremium == true
                ? l10n.subscriptionActive
                : l10n.unlockFeatures,
            color: Colors.amber,
            onTap: () => context.push('/subscription'),
          ),
          _SettingsTile(
            icon: Icons.restore,
            title: l10n.restorePurchases,
            subtitle: l10n.recoverPurchase,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.restoringPurchases)),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.auto_awesome,
            title: l10n.aiUsage,
            subtitle: l10n.monthlyUsage,
            color: Colors.purple,
            onTap: () => context.push('/ai-usage'),
          ),

          const SizedBox(height: 24),

          // Paramètres
          _SectionTitle(title: l10n.settings),

          // Toggle biométrie (si disponible)
          if (authState.isBiometricAvailable && authState.isAuthenticated)
            _BiometricToggleTile(ref: ref, authState: authState),

          _SettingsTile(
            icon: Icons.palette_outlined,
            title: l10n.appearance,
            subtitle: _getThemeModeLabel(ref.watch(themeModeProvider), l10n),
            onTap: () {
              _showAppearanceSheet(context, ref, l10n);
            },
          ),
          _SettingsTile(
            icon: Icons.language,
            title: l10n.language,
            subtitle: SupportedLocales.getDisplayName(ref.watch(localeProvider)),
            onTap: () {
              _showLanguageSheet(context, ref, l10n);
            },
          ),

          const SizedBox(height: 24),

          // Aide et informations
          _SectionTitle(title: l10n.help),
          _SettingsTile(
            icon: Icons.menu_book_outlined,
            title: l10n.nfcGuide,
            subtitle: l10n.nfcGuideSubtitle,
            color: AppColors.primary,
            onTap: () => context.push('/nfc-guide'),
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            title: l10n.helpCenter,
            subtitle: l10n.faqAndTutorials,
            onTap: () => context.push('/help-center'),
          ),
          _SettingsTile(
            icon: Icons.feedback_outlined,
            title: l10n.sendFeedback,
            subtitle: l10n.helpImprove,
            onTap: () {
              _showFeedbackSheet(context, l10n);
            },
          ),
          _SettingsTile(
            icon: Icons.bug_report_outlined,
            title: l10n.reportBug,
            onTap: () {
              launchUrl(Uri.parse('mailto:support@cards-control.app?subject=Bug Report - Cards Control'));
            },
          ),

          const SizedBox(height: 24),

          // Légal
          _SectionTitle(title: l10n.legal),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: l10n.termsOfService,
            onTap: () {
              context.push('/terms');
            },
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            onTap: () {
              context.push('/privacy');
            },
          ),

          const SizedBox(height: 24),

          // À propos
          _SectionTitle(title: l10n.about),
          _SettingsTile(
            icon: Icons.info_outline,
            title: l10n.version,
            subtitle: '1.0.0 (Build 1) - by JC Pastor',
          ),
          _SettingsTile(
            icon: Icons.star_outline,
            title: l10n.rateApp,
            onTap: () => _openStore(),
          ),
          _SettingsTile(
            icon: Icons.share_outlined,
            title: l10n.shareApp,
            onTap: () => _shareApp(context, l10n),
          ),

          if (authState.isAuthenticated) ...[
            const SizedBox(height: 24),

            // Déconnexion
            _SettingsTile(
              icon: Icons.logout,
              title: l10n.logout,
              titleColor: Colors.red,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.logout),
                    content: Text(l10n.logoutConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.disconnect),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/');
                  }
                }
              },
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }

  void _openStore() {
    final Uri storeUrl;
    if (Platform.isIOS) {
      // iOS App Store URL (à remplacer par l'ID réel de l'app)
      storeUrl = Uri.parse('https://apps.apple.com/app/id6739503891');
    } else {
      // Google Play Store URL
      storeUrl = Uri.parse('https://play.google.com/store/apps/details?id=com.cardscontrol.app');
    }
    launchUrl(storeUrl, mode: LaunchMode.externalApplication);
  }

  void _shareApp(BuildContext context, AppLocalizations l10n) {
    final String appStoreUrl = Platform.isIOS
        ? 'https://apps.apple.com/app/id6739503891'
        : 'https://play.google.com/store/apps/details?id=com.cardscontrol.app';

    // Message simple de partage
    const String shareMessage = 'Découvrez Cards Control - L\'application professionnelle pour lire, écrire et émuler des tags NFC !';
    final String shareText = '$shareMessage\n$appStoreUrl';
    Share.share(shareText, subject: 'Cards Control');
  }

  void _showAppearanceSheet(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final currentMode = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.appearance,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: Text(l10n.themeSystem),
            trailing: currentMode == ThemeMode.system ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.light_mode),
            title: Text(l10n.themeLight),
            trailing: currentMode == ThemeMode.light ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text(l10n.themeDark),
            trailing: currentMode == ThemeMode.dark ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
              Navigator.pop(sheetContext);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.language,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: SupportedLocales.all.map((locale) => ListTile(
                  title: Text(SupportedLocales.getDisplayName(locale)),
                  trailing: currentLocale.languageCode == locale.languageCode
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(locale);
                    Navigator.pop(sheetContext);
                  },
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.yourFeedback,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.shareSuggestions,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.thanksFeedback)),
                  );
                },
                child: Text(l10n.send),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final Color? titleColor;
  final bool isPremium;
  final String? proLabel;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
    this.titleColor,
    this.isPremium = false,
    this.proLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? theme.colorScheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color ?? theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(color: titleColor),
            ),
            if (isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  proLabel ?? 'PRO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onTap;

  const _UserProfileCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  user.initials,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'User',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (user.isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        l10n.pro,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginPromptCard extends StatelessWidget {
  final VoidCallback onLogin;

  const _LoginPromptCard({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.connectPrompt,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.syncData,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onLogin,
              child: Text(l10n.login),
            ),
          ],
        ),
      ),
    );
  }
}

class _BiometricToggleTile extends StatelessWidget {
  final WidgetRef ref;
  final AuthState authState;

  const _BiometricToggleTile({
    required this.ref,
    required this.authState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.fingerprint,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(l10n.biometricLogin),
        subtitle: Text(l10n.faceIdFingerprint),
        value: authState.isBiometricEnabled,
        onChanged: (value) async {
          if (value) {
            _showBiometricEnableDialog(context, l10n);
          } else {
            await ref.read(authProvider.notifier).setBiometricEnabled(false);
          }
        },
      ),
    );
  }

  void _showBiometricEnableDialog(BuildContext context, AppLocalizations l10n) {
    final passwordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.enableBiometric),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.enterPassword),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  errorText: errorMessage,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final email = ref.read(authProvider).user?.email;
                      if (email != null && passwordController.text.isNotEmpty) {
                        setDialogState(() {
                          isLoading = true;
                          errorMessage = null;
                        });

                        // Vérifier le mot de passe en tentant une ré-authentification
                        final success = await ref
                            .read(authProvider.notifier)
                            .verifyPasswordAndEnableBiometric(
                              email,
                              passwordController.text,
                            );

                        if (context.mounted) {
                          if (success) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.biometricEnabled)),
                            );
                          } else {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage = ref.read(authProvider).errorMessage ??
                                  'Mot de passe incorrect';
                            });
                          }
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.enable),
            ),
          ],
        ),
      ),
    );
  }
}
