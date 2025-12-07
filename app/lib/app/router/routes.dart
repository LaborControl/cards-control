class Routes {
  Routes._();

  // Splash
  static const String splash = '/splash';

  // Auth
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main Navigation
  static const String home = '/';
  static const String tags = '/tags';
  static const String reader = '/reader';
  static const String writer = '/writer';
  static const String cards = '/cards';
  static const String templates = '/templates';
  static const String history = '/history';
  static const String settings = '/settings';

  // Tag operations
  static const String formatTag = '/tags/format';
  static const String modifyTag = '/tags/modify';

  // Features
  static const String copy = '/copy';
  static const String emulation = '/emulation';
  static const String quickEmulation = '/emulate';
  static const String subscription = '/subscription';
  static const String profile = '/profile';
  static const String aiUsage = '/ai-usage';

  // Quick Emulation
  static String quickEmulate(String cardId) => '/emulate/$cardId';

  // Legal
  static const String terms = '/terms';
  static const String privacy = '/privacy';

  // Guide
  static const String nfcGuide = '/nfc-guide';
  static const String helpCenter = '/help-center';

  // Tag Details
  static String tagDetails(String tagId) => '/reader/details/$tagId';

  // Write Templates
  static String writeTemplate(String type) => '/writer/template/$type';

  // Card Management
  static const String cardNew = '/cards/new';
  static String cardEdit(String cardId) => '/cards/edit/$cardId';
  static String cardPreview(String cardId) => '/cards/preview/$cardId';
  static String cardShare(String cardId) => '/cards/share/$cardId';
}
