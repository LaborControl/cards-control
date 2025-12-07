import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Service pour gérer les deep links de l'application
///
/// Ce service communique avec le code natif Android pour recevoir les deep links
/// et les router vers les bonnes pages de l'application.
///
/// Supporte deux types de liens:
/// - Custom scheme: cardscontrol://emulate/{cardId} (raccourcis)
/// - App Links/Universal Links: https://cards-control.app/card/{cardId} (scan NFC)
class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._();
  DeepLinkService._();

  static const _channel = MethodChannel('com.cardscontrol.app/deeplink');

  GoRouter? _router;
  final _deepLinkController = StreamController<String>.broadcast();
  bool _initialized = false;

  /// Stream des deep links reçus
  Stream<String> get onDeepLink => _deepLinkController.stream;

  /// Initialise le service avec le router
  Future<void> initialize(GoRouter router) async {
    debugPrint('DeepLinkService: initialize called, _initialized=$_initialized');
    if (_initialized) return;

    _router = router;
    _initialized = true;

    // Configure le handler pour les deep links entrants
    _channel.setMethodCallHandler(_handleMethodCall);

    // Vérifie s'il y a un deep link initial (app lancée via shortcut ou App Link)
    await _checkInitialLink();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDeepLink':
        final deepLink = call.arguments as String;
        _handleDeepLink(deepLink);
        break;
    }
    return null;
  }

  Future<void> _checkInitialLink() async {
    debugPrint('DeepLinkService: _checkInitialLink called');
    try {
      final initialLink = await _channel.invokeMethod<String>('getInitialLink');
      debugPrint('DeepLinkService: initialLink=$initialLink');
      if (initialLink != null && initialLink.isNotEmpty) {
        // Petit délai pour s'assurer que le router est prêt
        await Future.delayed(const Duration(milliseconds: 500));
        _handleDeepLink(initialLink);
      }
    } on PlatformException catch (e) {
      debugPrint('DeepLinkService: PlatformException: $e');
      // Ignore - pas de deep link initial
    }
  }

  void _handleDeepLink(String deepLink) {
    debugPrint('DeepLinkService: _handleDeepLink called with: $deepLink');
    _deepLinkController.add(deepLink);

    // Parse le deep link et navigue
    final uri = Uri.tryParse(deepLink);
    debugPrint('DeepLinkService: parsed uri=$uri, scheme=${uri?.scheme}, host=${uri?.host}, pathSegments=${uri?.pathSegments}');

    if (uri == null) {
      debugPrint('DeepLinkService: Invalid URI, ignoring');
      return;
    }

    // Custom scheme: cardscontrol://emulate/{cardId} or cardscontrol://card/{cardId}
    if (uri.scheme == 'cardscontrol') {
      if (uri.host == 'emulate' && uri.pathSegments.isNotEmpty) {
        final cardId = uri.pathSegments.first;
        debugPrint('DeepLinkService: Navigating to /emulate/$cardId');
        _router?.go('/emulate/$cardId');
      } else if (uri.host == 'card' && uri.pathSegments.isNotEmpty) {
        // cardscontrol://card/{cardId} - afficher la carte
        final cardId = uri.pathSegments.first;
        debugPrint('DeepLinkService: Navigating to /cards/view/$cardId');
        _router?.go('/cards/view/$cardId');
      }
      return;
    }

    // App Links / Universal Links: https://cards-control.app/card/{cardId}
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        (uri.host == 'cards-control.app' || uri.host == 'www.cards-control.app')) {

      // Route: /card/{cardId}
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'card') {
        if (uri.pathSegments.length > 1) {
          final cardId = uri.pathSegments[1];
          debugPrint('DeepLinkService: App Link - Navigating to /cards/view/$cardId');
          _router?.go('/cards/view/$cardId');
        } else {
          // /card sans ID - aller à la liste des cartes
          debugPrint('DeepLinkService: App Link - Navigating to /cards');
          _router?.go('/cards');
        }
        return;
      }
    }

    debugPrint('DeepLinkService: Unhandled deep link');
  }

  /// Libère les ressources
  void dispose() {
    _deepLinkController.close();
    _initialized = false;
  }
}
