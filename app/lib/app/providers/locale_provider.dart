import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Liste des locales supportées (doit correspondre aux fichiers ARB)
class SupportedLocales {
  static const Locale french = Locale('fr');
  static const Locale english = Locale('en');
  static const Locale spanish = Locale('es');
  static const Locale german = Locale('de');
  static const Locale italian = Locale('it');
  static const Locale greek = Locale('el');
  static const Locale dutch = Locale('nl');
  static const Locale arabic = Locale('ar');
  static const Locale chinese = Locale('zh');
  static const Locale bengali = Locale('bn');
  static const Locale hindi = Locale('hi');
  static const Locale japanese = Locale('ja');
  static const Locale korean = Locale('ko');
  static const Locale polish = Locale('pl');
  static const Locale portuguese = Locale('pt');
  static const Locale russian = Locale('ru');
  static const Locale thai = Locale('th');
  static const Locale turkish = Locale('tr');
  static const Locale ukrainian = Locale('uk');
  static const Locale urdu = Locale('ur');
  static const Locale vietnamese = Locale('vi');

  static const List<Locale> all = [
    french,
    english,
    spanish,
    german,
    italian,
    greek,
    dutch,
    arabic,
    chinese,
    bengali,
    hindi,
    japanese,
    korean,
    polish,
    portuguese,
    russian,
    thai,
    turkish,
    ukrainian,
    urdu,
    vietnamese,
  ];

  static String getDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
      case 'el':
        return 'Ελληνικά';
      case 'nl':
        return 'Nederlands';
      case 'ar':
        return 'العربية';
      case 'zh':
        return '中文';
      case 'bn':
        return 'বাংলা';
      case 'hi':
        return 'हिन्दी';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'pl':
        return 'Polski';
      case 'pt':
        return 'Português';
      case 'ru':
        return 'Русский';
      case 'th':
        return 'ไทย';
      case 'tr':
        return 'Türkçe';
      case 'uk':
        return 'Українська';
      case 'ur':
        return 'اردو';
      case 'vi':
        return 'Tiếng Việt';
      default:
        return locale.languageCode;
    }
  }
}

/// Provider pour la locale de l'application
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// Notifier pour gérer la locale
class LocaleNotifier extends StateNotifier<Locale> {
  static const String _boxName = 'settings';
  static const String _key = 'locale';

  LocaleNotifier() : super(SupportedLocales.french) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final box = await Hive.openBox(_boxName);
      final savedLocale = box.get(_key);
      if (savedLocale != null && savedLocale is String) {
        // Trouver la locale correspondante
        final matchingLocale = SupportedLocales.all.firstWhere(
          (l) => l.languageCode == savedLocale,
          orElse: () => SupportedLocales.french,
        );
        state = matchingLocale;
      }
    } catch (e) {
      state = SupportedLocales.french;
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_key, locale.languageCode);
    } catch (e) {
      // Ignorer les erreurs de sauvegarde
    }
  }
}
