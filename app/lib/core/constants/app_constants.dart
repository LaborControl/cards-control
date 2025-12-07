class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Cards Control';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Subscription
  static const String subscriptionPriceAnnual = '19.00';
  static const String subscriptionCurrency = 'EUR';
  static const String androidSubscriptionId = 'cardscontrol_annual_subscription';
  static const String iosSubscriptionId = 'com.cardscontrol.subscription.annual';

  // Limits - Free Tier
  static const int freeWritesPerMonth = 5;
  static const int freeHistoryLimit = 10;
  static const int freeCardsLimit = 1;
  static const int freeTemplatesLimit = 3;

  // Limits - Pro Tier
  static const int proHistoryLimit = -1; // Unlimited
  static const int proCardsLimit = -1; // Unlimited

  // NFC Scan
  static const Duration scanTimeout = Duration(seconds: 30);
  static const Duration scanPollingInterval = Duration(milliseconds: 100);

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Cache
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  // UI
  static const double borderRadius = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusSmall = 8.0;
  static const double cardElevation = 0.0;
  static const double bottomSheetRadius = 20.0;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // External Links
  static const String privacyPolicyUrl = 'https://cards-control.app/privacy';
  static const String termsOfServiceUrl = 'https://cards-control.app/terms';
  static const String supportUrl = 'https://cards-control.app/support';
  static const String websiteUrl = 'https://cards-control.app';

  // Social Links
  static const String twitterUrl = 'https://twitter.com/cardscontrol';
  static const String linkedinUrl = 'https://linkedin.com/company/cards-control';

  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyAnalyticsEnabled = 'analytics_enabled';

  // Date Formats
  static const String dateFormatShort = 'dd/MM/yyyy';
  static const String dateFormatLong = 'dd MMMM yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
}
