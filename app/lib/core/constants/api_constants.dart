class ApiConstants {
  ApiConstants._();

  // Base URLs
  static const String baseUrl = 'https://api.cards-control.app/v1';
  static const String stagingUrl = 'https://api-staging.cards-control.app/v1';

  // API Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Auth Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authVerifyEmail = '/auth/verify-email';
  static const String authDeleteAccount = '/auth/account';

  // User Endpoints
  static const String usersMe = '/users/me';
  static const String usersMePhoto = '/users/me/photo';
  static const String usersMeSettings = '/users/me/settings';

  // Business Cards Endpoints
  static const String cards = '/cards';
  static String cardById(String id) => '/cards/$id';
  static String cardDuplicate(String id) => '/cards/$id/duplicate';
  static String cardQr(String id) => '/cards/$id/qr';
  static String cardWallet(String id) => '/cards/$id/wallet';
  static String cardAnalytics(String id) => '/cards/$id/analytics';
  static String cardPublic(String slug) => '/cards/public/$slug';

  // Templates Endpoints
  static const String templates = '/templates';
  static String templateById(String id) => '/templates/$id';

  // Tags Endpoints
  static const String tags = '/tags';
  static String tagById(String id) => '/tags/$id';
  static String tagFavorite(String id) => '/tags/$id/favorite';
  static const String tagsExport = '/tags/export';

  // Write Templates Endpoints
  static const String writeTemplates = '/write-templates';
  static String writeTemplateById(String id) => '/write-templates/$id';

  // Subscription Endpoints
  static const String subscription = '/subscription';
  static const String subscriptionVerify = '/subscription/verify';
  static const String subscriptionRestore = '/subscription/restore';

  // Contacts Endpoints
  static const String contacts = '/contacts';
  static String contactById(String id) => '/contacts/$id';
  static String contactExport(String id) => '/contacts/$id/export';
}
