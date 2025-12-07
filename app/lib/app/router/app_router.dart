import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/nfc_reader/presentation/screens/reader_screen.dart';
import '../../features/nfc_reader/presentation/screens/tag_details_screen.dart';
import '../../features/nfc_writer/presentation/screens/writer_screen.dart';
import '../../features/nfc_writer/presentation/screens/write_template_screen.dart';
import '../../features/nfc_copy/presentation/screens/copy_screen.dart';
import '../../features/hce_emulation/presentation/screens/emulation_screen.dart';
import '../../features/hce_emulation/presentation/screens/quick_emulation_screen.dart';
import '../../features/business_cards/presentation/screens/cards_list_screen.dart';
import '../../features/business_cards/presentation/screens/cards_menu_screen.dart';
import '../../features/nfc_tags/presentation/screens/tags_menu_screen.dart';
import '../../features/business_cards/presentation/screens/card_editor_screen.dart';
import '../../features/business_cards/presentation/screens/card_preview_screen.dart';
import '../../features/business_cards/presentation/screens/card_share_screen.dart';
import '../../features/contacts/presentation/screens/scan_card_camera_screen.dart';
import '../../features/contacts/presentation/screens/scan_card_preview_screen.dart';
import '../../features/contacts/presentation/screens/scan_card_edit_screen.dart';
import '../../features/contacts/presentation/screens/contacts_list_screen.dart';
import '../../features/contacts/presentation/screens/read_card_nfc_screen.dart';
import '../../features/contacts/domain/models/scanned_card_data.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/subscription/presentation/screens/subscription_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/ai_usage_screen.dart';
import '../../features/settings/presentation/screens/terms_screen.dart';
import '../../features/settings/presentation/screens/privacy_screen.dart';
import '../../features/settings/presentation/screens/nfc_guide_screen.dart';
import '../../features/settings/presentation/screens/help_center_screen.dart';
import '../../features/nfc_tags/presentation/screens/format_tag_screen.dart';
import '../../features/nfc_tags/presentation/screens/modify_tag_screen.dart';
import '../../features/templates/presentation/screens/templates_menu_screen.dart';
import '../../features/templates/presentation/screens/templates_list_screen.dart';
import '../../features/templates/presentation/screens/create_template_screen.dart';
import '../../features/templates/presentation/screens/template_form_screen.dart';
import '../../features/templates/presentation/screens/template_preview_screen.dart';
import '../../shared/widgets/shell/main_shell.dart';
import 'routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Home
          GoRoute(
            path: Routes.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),

          // NFC Reader
          GoRoute(
            path: Routes.reader,
            name: 'reader',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReaderScreen(),
            ),
            routes: [
              GoRoute(
                path: 'details/:tagId',
                name: 'tag-details',
                builder: (context, state) => TagDetailsScreen(
                  tagId: state.pathParameters['tagId']!,
                ),
              ),
            ],
          ),

          // NFC Writer
          GoRoute(
            path: Routes.writer,
            name: 'writer',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WriterScreen(),
            ),
            routes: [
              GoRoute(
                path: 'template/:type',
                name: 'write-template',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return WriteTemplateScreen(
                    templateType: state.pathParameters['type']!,
                    initialUrl: extra?['url'] as String?,
                    initialData: extra?['data'] as Map<String, dynamic>?,
                  );
                },
              ),
            ],
          ),

          // Business Cards - Menu with options
          GoRoute(
            path: Routes.cards,
            name: 'cards',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CardsMenuScreen(),
            ),
            routes: [
              GoRoute(
                path: 'list',
                name: 'cards-list',
                builder: (context, state) => const CardsListScreen(),
              ),
              GoRoute(
                path: 'new',
                name: 'card-new',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return CardEditorScreen(importedData: extra);
                },
              ),
              GoRoute(
                path: 'edit/:cardId',
                name: 'card-edit',
                builder: (context, state) => CardEditorScreen(
                  cardId: state.pathParameters['cardId'],
                ),
              ),
              GoRoute(
                path: 'preview/:cardId',
                name: 'card-preview',
                builder: (context, state) => CardPreviewScreen(
                  cardId: state.pathParameters['cardId']!,
                ),
              ),
              GoRoute(
                path: 'share/:cardId',
                name: 'card-share',
                builder: (context, state) => CardShareScreen(
                  cardId: state.pathParameters['cardId']!,
                ),
              ),
              GoRoute(
                path: 'import',
                name: 'cards-import',
                builder: (context, state) => const CardsListScreen(),
              ),
            ],
          ),

          // Contacts List
          GoRoute(
            path: '/contacts',
            name: 'contacts',
            builder: (context, state) => const ContactsListScreen(),
          ),

          // Contacts - Read Card NFC
          GoRoute(
            path: '/contacts/read-card',
            name: 'read-card-nfc',
            builder: (context, state) => const ReadCardNfcScreen(),
          ),

          // Contacts - Scan Card
          GoRoute(
            path: '/contacts/scan-card',
            name: 'scan-card-camera',
            builder: (context, state) => const ScanCardCameraScreen(),
            routes: [
              GoRoute(
                path: 'preview',
                name: 'scan-card-preview',
                builder: (context, state) {
                  final imagePath = state.extra as String;
                  return ScanCardPreviewScreen(imagePath: imagePath);
                },
              ),
              GoRoute(
                path: 'edit',
                name: 'scan-card-edit',
                builder: (context, state) {
                  final data = state.extra as Map<String, dynamic>;
                  return ScanCardEditScreen(
                    imagePath: data['imagePath'] as String,
                    scannedData: data['scannedData'] as ScannedCardData,
                  );
                },
              ),
            ],
          ),

          // History
          GoRoute(
            path: Routes.history,
            name: 'history',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryScreen(),
            ),
          ),

          // Settings / More
          GoRoute(
            path: Routes.settings,
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),

          // Tags - Menu with options
          GoRoute(
            path: Routes.tags,
            name: 'tags',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TagsMenuScreen(),
            ),
            routes: [
              GoRoute(
                path: 'format',
                name: 'format-tag',
                builder: (context, state) => const FormatTagScreen(),
              ),
              GoRoute(
                path: 'modify',
                name: 'modify-tag',
                builder: (context, state) => const ModifyTagScreen(),
              ),
            ],
          ),

          // Templates - Menu principal
          GoRoute(
            path: Routes.templates,
            name: 'templates',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TemplatesMenuScreen(),
            ),
            routes: [
              // Liste des modèles
              GoRoute(
                path: 'list',
                name: 'templates-list',
                builder: (context, state) => const TemplatesListScreen(),
              ),
              // Créer un nouveau modèle - sélection du type
              GoRoute(
                path: 'create',
                name: 'create-template',
                builder: (context, state) => const CreateTemplateScreen(),
              ),
              // Formulaire de création de modèle
              GoRoute(
                path: 'create/:type',
                name: 'template-form',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return TemplateFormScreen(
                    templateType: state.pathParameters['type']!,
                    templateId: extra?['templateId'] as String?,
                    initialData: extra?['data'] as Map<String, dynamic>?,
                    isEditMode: extra?['editMode'] == true,
                    templateName: extra?['templateName'] as String?,
                  );
                },
              ),
              // Prévisualisation d'un modèle
              GoRoute(
                path: 'preview/:templateId',
                name: 'template-preview',
                builder: (context, state) => TemplatePreviewScreen(
                  templateId: state.pathParameters['templateId']!,
                ),
              ),
            ],
          ),

          // Copy Screen - avec barre de navigation
          GoRoute(
            path: Routes.copy,
            name: 'copy',
            builder: (context, state) => const CopyScreen(),
          ),

          // Emulation Screen - avec barre de navigation
          GoRoute(
            path: Routes.emulation,
            name: 'emulation',
            builder: (context, state) {
              final tab = state.uri.queryParameters['tab'];
              final templateId = state.uri.queryParameters['templateId'];
              return EmulationScreen(initialTab: tab, initialTemplateId: templateId);
            },
          ),

          // Subscription - avec barre de navigation
          GoRoute(
            path: Routes.subscription,
            name: 'subscription',
            builder: (context, state) => const SubscriptionScreen(),
          ),

          // Profile - avec barre de navigation
          GoRoute(
            path: Routes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),

          // AI Usage - avec barre de navigation
          GoRoute(
            path: Routes.aiUsage,
            name: 'aiUsage',
            builder: (context, state) => const AIUsageScreen(),
          ),

          // Legal - avec barre de navigation
          GoRoute(
            path: Routes.terms,
            name: 'terms',
            builder: (context, state) => const TermsScreen(),
          ),
          GoRoute(
            path: Routes.privacy,
            name: 'privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),

          // NFC Guide - avec barre de navigation
          GoRoute(
            path: Routes.nfcGuide,
            name: 'nfc-guide',
            builder: (context, state) => const NfcGuideScreen(),
          ),

          // Help Center - avec barre de navigation
          GoRoute(
            path: Routes.helpCenter,
            name: 'help-center',
            builder: (context, state) {
              final tab = state.uri.queryParameters['tab'];
              return HelpCenterScreen(
                initialTab: tab == 'tutorials' ? 1 : 0,
              );
            },
          ),
        ],
      ),

      // Quick Emulation (from shortcut/deep link) - reste en dehors car c'est un deep link
      GoRoute(
        path: '${Routes.quickEmulation}/:cardId',
        name: 'quick-emulation',
        builder: (context, state) => QuickEmulationScreen(
          cardId: state.pathParameters['cardId']!,
          autoStart: state.uri.queryParameters['autoStart'] != 'false',
        ),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),

    // Redirect logic
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final uri = state.uri;
      var matchedLocation = state.matchedLocation;

      // Gérer les deep links avec scheme nfcpro:// ou cardscontrol://
      // L'URI peut être cardscontrol://emulate/{cardId} qu'on doit convertir en /emulate/{cardId}
      if (uri.scheme == 'nfcpro' || uri.scheme == 'cardscontrol') {
        // cardscontrol://emulate/{cardId} -> host = 'emulate', pathSegments = [cardId]
        if (uri.host == 'emulate' && uri.pathSegments.isNotEmpty) {
          final cardId = uri.pathSegments.first;
          return '/emulate/$cardId';
        }
        // cardscontrol://card/{cardId} -> afficher la carte
        if (uri.host == 'card' && uri.pathSegments.isNotEmpty) {
          final cardId = uri.pathSegments.first;
          return '/cards/view/$cardId';
        }
        // Autres deep links non reconnus -> splash
        return Routes.splash;
      }

      // Pages accessibles sans authentification
      const publicPaths = [
        Routes.splash,
        Routes.login,
        Routes.register,
        Routes.onboarding,
        Routes.terms,
        Routes.privacy,
      ];

      // Routes dynamiques accessibles sans authentification (deep links)
      final isQuickEmulationRoute = matchedLocation.startsWith('/emulate/');

      // Si on est sur splash, laisser le splash gérer la redirection
      if (matchedLocation == Routes.splash) {
        return null;
      }

      // Si authentifié et sur login/register, rediriger vers home
      if (isAuthenticated && (matchedLocation == Routes.login || matchedLocation == Routes.register)) {
        return Routes.home;
      }

      // Si non authentifié et sur une page protégée, rediriger vers login
      // Exception: les routes de quick emulation sont accessibles sans auth
      if (!isAuthenticated && !publicPaths.contains(matchedLocation) && !isQuickEmulationRoute) {
        return Routes.login;
      }

      return null;
    },
  );
});
