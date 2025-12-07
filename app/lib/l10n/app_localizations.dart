import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('uk'),
    Locale('ur'),
    Locale('vi'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cards Control'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue !'**
  String get welcome;

  /// No description provided for @whatToDo.
  ///
  /// In fr, this message translates to:
  /// **'Que souhaitez-vous faire aujourd\'hui ?'**
  String get whatToDo;

  /// No description provided for @quickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get quickActions;

  /// No description provided for @read.
  ///
  /// In fr, this message translates to:
  /// **'Lire'**
  String get read;

  /// No description provided for @scanTag.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un tag'**
  String get scanTag;

  /// No description provided for @write.
  ///
  /// In fr, this message translates to:
  /// **'Écrire'**
  String get write;

  /// No description provided for @programTag.
  ///
  /// In fr, this message translates to:
  /// **'Programmer un tag'**
  String get programTag;

  /// No description provided for @copy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get copy;

  /// No description provided for @duplicateTag.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer un tag'**
  String get duplicateTag;

  /// No description provided for @cards.
  ///
  /// In fr, this message translates to:
  /// **'Cartes'**
  String get cards;

  /// No description provided for @businessCards.
  ///
  /// In fr, this message translates to:
  /// **'Cartes de visite'**
  String get businessCards;

  /// No description provided for @statistics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statistics;

  /// No description provided for @scannedTags.
  ///
  /// In fr, this message translates to:
  /// **'Tags scannés'**
  String get scannedTags;

  /// No description provided for @favorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favorites;

  /// No description provided for @features.
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalités'**
  String get features;

  /// No description provided for @hceEmulation.
  ///
  /// In fr, this message translates to:
  /// **'Émulation HCE'**
  String get hceEmulation;

  /// No description provided for @hceDescription.
  ///
  /// In fr, this message translates to:
  /// **'Transformez votre téléphone en tag NFC'**
  String get hceDescription;

  /// No description provided for @googleWallet.
  ///
  /// In fr, this message translates to:
  /// **'Google Wallet'**
  String get googleWallet;

  /// No description provided for @walletDescription.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos cartes de visite au wallet'**
  String get walletDescription;

  /// No description provided for @recentHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique récent'**
  String get recentHistory;

  /// No description provided for @viewAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get viewAll;

  /// No description provided for @noTagsScanned.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tag scanné'**
  String get noTagsScanned;

  /// No description provided for @scanFirstTag.
  ///
  /// In fr, this message translates to:
  /// **'Commencez par scanner votre premier tag NFC'**
  String get scanFirstTag;

  /// No description provided for @scanTag2.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un tag'**
  String get scanTag2;

  /// No description provided for @more.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get more;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// No description provided for @nfcPro.
  ///
  /// In fr, this message translates to:
  /// **'Cards Control'**
  String get nfcPro;

  /// No description provided for @tagCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copie de tags'**
  String get tagCopy;

  /// No description provided for @duplicateNfcTags.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer des tags NFC'**
  String get duplicateNfcTags;

  /// No description provided for @hceEmulationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Émulation HCE'**
  String get hceEmulationTitle;

  /// No description provided for @transformPhone.
  ///
  /// In fr, this message translates to:
  /// **'Transformer votre téléphone en tag'**
  String get transformPhone;

  /// No description provided for @subscription.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get subscription;

  /// No description provided for @nfcProPremium.
  ///
  /// In fr, this message translates to:
  /// **'Cards Control Pro'**
  String get nfcProPremium;

  /// No description provided for @subscriptionActive.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement actif'**
  String get subscriptionActive;

  /// No description provided for @unlockFeatures.
  ///
  /// In fr, this message translates to:
  /// **'Débloquez toutes les fonctionnalités'**
  String get unlockFeatures;

  /// No description provided for @restorePurchases.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer les achats'**
  String get restorePurchases;

  /// No description provided for @recoverPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer un achat précédent'**
  String get recoverPurchase;

  /// No description provided for @restoringPurchases.
  ///
  /// In fr, this message translates to:
  /// **'Restauration en cours...'**
  String get restoringPurchases;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @biometricLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion biométrique'**
  String get biometricLogin;

  /// No description provided for @faceIdFingerprint.
  ///
  /// In fr, this message translates to:
  /// **'Face ID / Empreinte digitale'**
  String get faceIdFingerprint;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @themeAndDisplay.
  ///
  /// In fr, this message translates to:
  /// **'Thème et affichage'**
  String get themeAndDisplay;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @help.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get help;

  /// No description provided for @helpCenter.
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'aide'**
  String get helpCenter;

  /// No description provided for @faqAndTutorials.
  ///
  /// In fr, this message translates to:
  /// **'FAQ et tutoriels'**
  String get faqAndTutorials;

  /// No description provided for @sendFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un feedback'**
  String get sendFeedback;

  /// No description provided for @helpImprove.
  ///
  /// In fr, this message translates to:
  /// **'Aidez-nous à améliorer l\'app'**
  String get helpImprove;

  /// No description provided for @reportBug.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un bug'**
  String get reportBug;

  /// No description provided for @yourFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Votre feedback'**
  String get yourFeedback;

  /// No description provided for @shareSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Partagez vos suggestions ou remarques...'**
  String get shareSuggestions;

  /// No description provided for @send.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get send;

  /// No description provided for @thanksFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre feedback !'**
  String get thanksFeedback;

  /// No description provided for @legal.
  ///
  /// In fr, this message translates to:
  /// **'Légal'**
  String get legal;

  /// No description provided for @termsOfService.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// No description provided for @openSourceLicenses.
  ///
  /// In fr, this message translates to:
  /// **'Licences open source'**
  String get openSourceLicenses;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @rateApp.
  ///
  /// In fr, this message translates to:
  /// **'Noter l\'application'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In fr, this message translates to:
  /// **'Partager l\'application'**
  String get shareApp;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter ?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @disconnect.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get disconnect;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @connectPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous'**
  String get connectPrompt;

  /// No description provided for @syncData.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisez vos données et accédez à toutes les fonctionnalités'**
  String get syncData;

  /// No description provided for @enableBiometric.
  ///
  /// In fr, this message translates to:
  /// **'Activer la biométrie'**
  String get enableBiometric;

  /// No description provided for @enterPassword.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre mot de passe pour activer la connexion biométrique.'**
  String get enterPassword;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @enable.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get enable;

  /// No description provided for @biometricEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Biométrie activée'**
  String get biometricEnabled;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @cardNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Carte non trouvée'**
  String get cardNotFound;

  /// No description provided for @scanQrCode.
  ///
  /// In fr, this message translates to:
  /// **'Scannez ce QR code'**
  String get scanQrCode;

  /// No description provided for @toSeeCard.
  ///
  /// In fr, this message translates to:
  /// **'pour voir ma carte de visite'**
  String get toSeeCard;

  /// No description provided for @shareMethods.
  ///
  /// In fr, this message translates to:
  /// **'Méthodes de partage'**
  String get shareMethods;

  /// No description provided for @nfc.
  ///
  /// In fr, this message translates to:
  /// **'NFC'**
  String get nfc;

  /// No description provided for @approachPhone.
  ///
  /// In fr, this message translates to:
  /// **'Approchez votre téléphone'**
  String get approachPhone;

  /// No description provided for @qrCode.
  ///
  /// In fr, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @scanCode.
  ///
  /// In fr, this message translates to:
  /// **'Faire scanner le code'**
  String get scanCode;

  /// No description provided for @copyLink.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien'**
  String get copyLink;

  /// No description provided for @shareVia.
  ///
  /// In fr, this message translates to:
  /// **'Partager via...'**
  String get shareVia;

  /// No description provided for @messagingApps.
  ///
  /// In fr, this message translates to:
  /// **'Applications de messagerie'**
  String get messagingApps;

  /// No description provided for @linkCopied.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié !'**
  String get linkCopied;

  /// No description provided for @export.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get export;

  /// No description provided for @vCard.
  ///
  /// In fr, this message translates to:
  /// **'vCard'**
  String get vCard;

  /// No description provided for @appleWallet.
  ///
  /// In fr, this message translates to:
  /// **'Apple Wallet'**
  String get appleWallet;

  /// No description provided for @walletNotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Wallet n\'est pas disponible'**
  String get walletNotAvailable;

  /// No description provided for @addedToWallet.
  ///
  /// In fr, this message translates to:
  /// **'Carte ajoutée au Wallet'**
  String get addedToWallet;

  /// No description provided for @walletError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'ajout au Wallet'**
  String get walletError;

  /// No description provided for @addingToWallet.
  ///
  /// In fr, this message translates to:
  /// **'Ajout au Wallet...'**
  String get addingToWallet;

  /// No description provided for @checkMyCard.
  ///
  /// In fr, this message translates to:
  /// **'Consultez ma carte de visite'**
  String get checkMyCard;

  /// No description provided for @newCard.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle carte'**
  String get newCard;

  /// No description provided for @editCard.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la carte'**
  String get editCard;

  /// No description provided for @firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastName;

  /// No description provided for @company.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise'**
  String get company;

  /// No description provided for @jobTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fonction'**
  String get jobTitle;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @mobile.
  ///
  /// In fr, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @website.
  ///
  /// In fr, this message translates to:
  /// **'Site web'**
  String get website;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @bio.
  ///
  /// In fr, this message translates to:
  /// **'Biographie'**
  String get bio;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @deleteCard.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la carte'**
  String get deleteCard;

  /// No description provided for @deleteCardConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer cette carte ?'**
  String get deleteCardConfirm;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @success.
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In fr, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @german.
  ///
  /// In fr, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @italian.
  ///
  /// In fr, this message translates to:
  /// **'Italiano'**
  String get italian;

  /// No description provided for @greek.
  ///
  /// In fr, this message translates to:
  /// **'Ελληνικά'**
  String get greek;

  /// No description provided for @dutch.
  ///
  /// In fr, this message translates to:
  /// **'Nederlands'**
  String get dutch;

  /// No description provided for @arabic.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @chinese.
  ///
  /// In fr, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @urdu.
  ///
  /// In fr, this message translates to:
  /// **'اردو'**
  String get urdu;

  /// No description provided for @russian.
  ///
  /// In fr, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @portuguese.
  ///
  /// In fr, this message translates to:
  /// **'Português'**
  String get portuguese;

  /// No description provided for @hindi.
  ///
  /// In fr, this message translates to:
  /// **'हिन्दी'**
  String get hindi;

  /// No description provided for @japanese.
  ///
  /// In fr, this message translates to:
  /// **'日本語'**
  String get japanese;

  /// No description provided for @turkish.
  ///
  /// In fr, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @korean.
  ///
  /// In fr, this message translates to:
  /// **'한국어'**
  String get korean;

  /// No description provided for @polish.
  ///
  /// In fr, this message translates to:
  /// **'Polski'**
  String get polish;

  /// No description provided for @ukrainian.
  ///
  /// In fr, this message translates to:
  /// **'Українська'**
  String get ukrainian;

  /// No description provided for @vietnamese.
  ///
  /// In fr, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnamese;

  /// No description provided for @thai.
  ///
  /// In fr, this message translates to:
  /// **'ไทย'**
  String get thai;

  /// No description provided for @bengali.
  ///
  /// In fr, this message translates to:
  /// **'বাংলা'**
  String get bengali;

  /// No description provided for @pro.
  ///
  /// In fr, this message translates to:
  /// **'PRO'**
  String get pro;

  /// No description provided for @premium.
  ///
  /// In fr, this message translates to:
  /// **'Pro'**
  String get premium;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @reader.
  ///
  /// In fr, this message translates to:
  /// **'Lecteur'**
  String get reader;

  /// No description provided for @writer.
  ///
  /// In fr, this message translates to:
  /// **'Écrivain'**
  String get writer;

  /// No description provided for @tagDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du tag'**
  String get tagDetails;

  /// No description provided for @tagType.
  ///
  /// In fr, this message translates to:
  /// **'Type de tag'**
  String get tagType;

  /// No description provided for @tagUid.
  ///
  /// In fr, this message translates to:
  /// **'UID du tag'**
  String get tagUid;

  /// No description provided for @tagSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get tagSize;

  /// No description provided for @tagTechnologies.
  ///
  /// In fr, this message translates to:
  /// **'Technologies'**
  String get tagTechnologies;

  /// No description provided for @writeSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Écriture réussie'**
  String get writeSuccess;

  /// No description provided for @writeFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'écriture'**
  String get writeFailed;

  /// No description provided for @readSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Lecture réussie'**
  String get readSuccess;

  /// No description provided for @readFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la lecture'**
  String get readFailed;

  /// No description provided for @approachNfcTag.
  ///
  /// In fr, this message translates to:
  /// **'Approchez un tag NFC'**
  String get approachNfcTag;

  /// No description provided for @scanning.
  ///
  /// In fr, this message translates to:
  /// **'Scan en cours...'**
  String get scanning;

  /// No description provided for @writing.
  ///
  /// In fr, this message translates to:
  /// **'Écriture en cours...'**
  String get writing;

  /// No description provided for @url.
  ///
  /// In fr, this message translates to:
  /// **'URL'**
  String get url;

  /// No description provided for @text.
  ///
  /// In fr, this message translates to:
  /// **'Texte'**
  String get text;

  /// No description provided for @contact.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @wifi.
  ///
  /// In fr, this message translates to:
  /// **'WiFi'**
  String get wifi;

  /// No description provided for @bluetooth.
  ///
  /// In fr, this message translates to:
  /// **'Bluetooth'**
  String get bluetooth;

  /// No description provided for @location.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get location;

  /// No description provided for @launchApp.
  ///
  /// In fr, this message translates to:
  /// **'Lancer une app'**
  String get launchApp;

  /// No description provided for @networkName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du réseau'**
  String get networkName;

  /// No description provided for @networkPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get networkPassword;

  /// No description provided for @networkType.
  ///
  /// In fr, this message translates to:
  /// **'Type de sécurité'**
  String get networkType;

  /// No description provided for @photoUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Photo mise à jour'**
  String get photoUpdated;

  /// No description provided for @photoDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Photo supprimée'**
  String get photoDeleted;

  /// No description provided for @updateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour'**
  String get updateError;

  /// No description provided for @takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir depuis la galerie'**
  String get chooseFromGallery;

  /// No description provided for @deletePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get deletePhoto;

  /// No description provided for @syncError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de synchronisation. Vérifiez votre connexion internet.'**
  String get syncError;

  /// No description provided for @syncSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation réussie'**
  String get syncSuccess;

  /// No description provided for @quickActionsSection.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get quickActionsSection;

  /// No description provided for @nfcEmulation.
  ///
  /// In fr, this message translates to:
  /// **'Émulation NFC'**
  String get nfcEmulation;

  /// No description provided for @emulateCardFor10Seconds.
  ///
  /// In fr, this message translates to:
  /// **'Émuler cette carte pendant 10 secondes'**
  String get emulateCardFor10Seconds;

  /// No description provided for @createShortcut.
  ///
  /// In fr, this message translates to:
  /// **'Créer un raccourci'**
  String get createShortcut;

  /// No description provided for @addToHomeScreen.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter sur l\'écran d\'accueil'**
  String get addToHomeScreen;

  /// No description provided for @shortcutsNotSupported.
  ///
  /// In fr, this message translates to:
  /// **'Les raccourcis ne sont pas supportés sur cet appareil'**
  String get shortcutsNotSupported;

  /// No description provided for @shortcutAdded.
  ///
  /// In fr, this message translates to:
  /// **'Raccourci ajouté à l\'écran d\'accueil'**
  String get shortcutAdded;

  /// No description provided for @shortcutError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer le raccourci'**
  String get shortcutError;

  /// No description provided for @quickEmulation.
  ///
  /// In fr, this message translates to:
  /// **'Émulation rapide'**
  String get quickEmulation;

  /// No description provided for @emulationInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Émulation en cours'**
  String get emulationInProgress;

  /// No description provided for @readyToEmulate.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à émuler'**
  String get readyToEmulate;

  /// No description provided for @approachNfcDevice.
  ///
  /// In fr, this message translates to:
  /// **'Approchez un autre appareil NFC'**
  String get approachNfcDevice;

  /// No description provided for @pressStartToEmulate.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur Démarrer pour émuler votre carte'**
  String get pressStartToEmulate;

  /// No description provided for @startEmulation.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer l\'émulation'**
  String get startEmulation;

  /// No description provided for @stopEmulation.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get stopEmulation;

  /// No description provided for @restartEmulation.
  ///
  /// In fr, this message translates to:
  /// **'Relancer'**
  String get restartEmulation;

  /// No description provided for @seconds.
  ///
  /// In fr, this message translates to:
  /// **'secondes'**
  String get seconds;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @initialization.
  ///
  /// In fr, this message translates to:
  /// **'Initialisation...'**
  String get initialization;

  /// No description provided for @hceOnlyAndroid.
  ///
  /// In fr, this message translates to:
  /// **'L\'émulation HCE n\'est disponible que sur Android'**
  String get hceOnlyAndroid;

  /// No description provided for @hceNotSupported.
  ///
  /// In fr, this message translates to:
  /// **'Votre appareil ne supporte pas l\'émulation HCE'**
  String get hceNotSupported;

  /// No description provided for @enableNfcInSettings.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez activer le NFC dans les paramètres'**
  String get enableNfcInSettings;

  /// No description provided for @startError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du démarrage'**
  String get startError;

  /// No description provided for @nfcGuide.
  ///
  /// In fr, this message translates to:
  /// **'Guide NFC'**
  String get nfcGuide;

  /// No description provided for @nfcGuideSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Possibilités et limites'**
  String get nfcGuideSubtitle;

  /// No description provided for @aboutNfcGuide.
  ///
  /// In fr, this message translates to:
  /// **'À propos de ce guide'**
  String get aboutNfcGuide;

  /// No description provided for @nfcGuideIntro.
  ///
  /// In fr, this message translates to:
  /// **'Ce guide détaille les capacités de lecture, écriture, copie et émulation NFC de Cards Control, ainsi que les limites techniques et légales à connaître.'**
  String get nfcGuideIntro;

  /// No description provided for @readCapabilities.
  ///
  /// In fr, this message translates to:
  /// **'Lecture'**
  String get readCapabilities;

  /// No description provided for @writeCapabilities.
  ///
  /// In fr, this message translates to:
  /// **'Écriture'**
  String get writeCapabilities;

  /// No description provided for @copyCapabilities.
  ///
  /// In fr, this message translates to:
  /// **'Copie'**
  String get copyCapabilities;

  /// No description provided for @emulationCapabilities.
  ///
  /// In fr, this message translates to:
  /// **'Émulation HCE'**
  String get emulationCapabilities;

  /// No description provided for @technicalLimits.
  ///
  /// In fr, this message translates to:
  /// **'Limites techniques'**
  String get technicalLimits;

  /// No description provided for @legalLimits.
  ///
  /// In fr, this message translates to:
  /// **'Limites légales'**
  String get legalLimits;

  /// No description provided for @supportedTechnologies.
  ///
  /// In fr, this message translates to:
  /// **'Technologies supportées'**
  String get supportedTechnologies;

  /// No description provided for @readNdef.
  ///
  /// In fr, this message translates to:
  /// **'Messages NDEF'**
  String get readNdef;

  /// No description provided for @readNdefDesc.
  ///
  /// In fr, this message translates to:
  /// **'URL, texte, contacts, WiFi et tous les types NDEF standard'**
  String get readNdefDesc;

  /// No description provided for @readTagInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations du tag'**
  String get readTagInfo;

  /// No description provided for @readTagInfoDesc.
  ///
  /// In fr, this message translates to:
  /// **'UID, type, taille mémoire, technologies supportées'**
  String get readTagInfoDesc;

  /// No description provided for @readMifare.
  ///
  /// In fr, this message translates to:
  /// **'MIFARE Classic/Ultralight'**
  String get readMifare;

  /// No description provided for @readMifareDesc.
  ///
  /// In fr, this message translates to:
  /// **'Lecture des secteurs avec clés par défaut'**
  String get readMifareDesc;

  /// No description provided for @readProtectedTags.
  ///
  /// In fr, this message translates to:
  /// **'Tags protégés par mot de passe'**
  String get readProtectedTags;

  /// No description provided for @readProtectedTagsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Impossible sans connaître le mot de passe ou la clé de chiffrement'**
  String get readProtectedTagsDesc;

  /// No description provided for @readBankCards.
  ///
  /// In fr, this message translates to:
  /// **'Cartes bancaires EMV'**
  String get readBankCards;

  /// No description provided for @readBankCardsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Données sensibles protégées par chiffrement matériel'**
  String get readBankCardsDesc;

  /// No description provided for @writeNdef.
  ///
  /// In fr, this message translates to:
  /// **'Messages NDEF'**
  String get writeNdef;

  /// No description provided for @writeNdefDesc.
  ///
  /// In fr, this message translates to:
  /// **'Écriture de tous les formats NDEF sur tags compatibles'**
  String get writeNdefDesc;

  /// No description provided for @writeUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL / Liens'**
  String get writeUrl;

  /// No description provided for @writeUrlDesc.
  ///
  /// In fr, this message translates to:
  /// **'Sites web, liens profonds vers applications'**
  String get writeUrlDesc;

  /// No description provided for @writeText.
  ///
  /// In fr, this message translates to:
  /// **'Texte brut'**
  String get writeText;

  /// No description provided for @writeTextDesc.
  ///
  /// In fr, this message translates to:
  /// **'Messages, notes, identifiants'**
  String get writeTextDesc;

  /// No description provided for @writeVcard.
  ///
  /// In fr, this message translates to:
  /// **'Cartes de visite (vCard)'**
  String get writeVcard;

  /// No description provided for @writeVcardDesc.
  ///
  /// In fr, this message translates to:
  /// **'Contacts avec nom, téléphone, email, etc.'**
  String get writeVcardDesc;

  /// No description provided for @writeWifi.
  ///
  /// In fr, this message translates to:
  /// **'Configuration WiFi'**
  String get writeWifi;

  /// No description provided for @writeWifiDesc.
  ///
  /// In fr, this message translates to:
  /// **'SSID, mot de passe et type de sécurité'**
  String get writeWifiDesc;

  /// No description provided for @writeLock.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage de tag'**
  String get writeLock;

  /// No description provided for @writeLockDesc.
  ///
  /// In fr, this message translates to:
  /// **'Protection en écriture permanente ou réversible'**
  String get writeLockDesc;

  /// No description provided for @writeProtectedTags.
  ///
  /// In fr, this message translates to:
  /// **'Tags verrouillés'**
  String get writeProtectedTags;

  /// No description provided for @writeProtectedTagsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier un tag verrouillé de manière permanente'**
  String get writeProtectedTagsDesc;

  /// No description provided for @copyNdef.
  ///
  /// In fr, this message translates to:
  /// **'Contenu NDEF'**
  String get copyNdef;

  /// No description provided for @copyNdefDesc.
  ///
  /// In fr, this message translates to:
  /// **'Copie complète des données NDEF vers un autre tag'**
  String get copyNdefDesc;

  /// No description provided for @copyUid.
  ///
  /// In fr, this message translates to:
  /// **'UID du tag'**
  String get copyUid;

  /// No description provided for @copyUidDesc.
  ///
  /// In fr, this message translates to:
  /// **'L\'UID est gravé en usine et ne peut pas être copié sur un tag standard'**
  String get copyUidDesc;

  /// No description provided for @copyProtected.
  ///
  /// In fr, this message translates to:
  /// **'Données protégées'**
  String get copyProtected;

  /// No description provided for @copyProtectedDesc.
  ///
  /// In fr, this message translates to:
  /// **'Les secteurs chiffrés MIFARE ne peuvent pas être copiés sans les clés'**
  String get copyProtectedDesc;

  /// No description provided for @emulateCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte de visite virtuelle'**
  String get emulateCard;

  /// No description provided for @emulateCardDesc.
  ///
  /// In fr, this message translates to:
  /// **'Votre téléphone devient un tag NFC lisible par d\'autres appareils'**
  String get emulateCardDesc;

  /// No description provided for @emulateNdef.
  ///
  /// In fr, this message translates to:
  /// **'Messages NDEF'**
  String get emulateNdef;

  /// No description provided for @emulateNdefDesc.
  ///
  /// In fr, this message translates to:
  /// **'Émulation de données NDEF (URL, texte, vCard)'**
  String get emulateNdefDesc;

  /// No description provided for @emulateUid.
  ///
  /// In fr, this message translates to:
  /// **'UID personnalisé'**
  String get emulateUid;

  /// No description provided for @emulateUidDesc.
  ///
  /// In fr, this message translates to:
  /// **'Android ne permet pas de modifier l\'UID émulé (imposé par le système)'**
  String get emulateUidDesc;

  /// No description provided for @emulateBank.
  ///
  /// In fr, this message translates to:
  /// **'Cartes bancaires'**
  String get emulateBank;

  /// No description provided for @emulateBankDesc.
  ///
  /// In fr, this message translates to:
  /// **'Interdit par les restrictions de sécurité Android et la législation'**
  String get emulateBankDesc;

  /// No description provided for @limitUid.
  ///
  /// In fr, this message translates to:
  /// **'UID non modifiable'**
  String get limitUid;

  /// No description provided for @limitUidDesc.
  ///
  /// In fr, this message translates to:
  /// **'L\'identifiant unique d\'un tag est gravé en usine. Les tags à UID modifiable (magic cards) sont rares et souvent utilisés frauduleusement.'**
  String get limitUidDesc;

  /// No description provided for @limitCrypto.
  ///
  /// In fr, this message translates to:
  /// **'Chiffrement matériel'**
  String get limitCrypto;

  /// No description provided for @limitCryptoDesc.
  ///
  /// In fr, this message translates to:
  /// **'Les clés de chiffrement des cartes bancaires et badges sécurisés sont protégées par des puces cryptographiques inviolables.'**
  String get limitCryptoDesc;

  /// No description provided for @limitHce.
  ///
  /// In fr, this message translates to:
  /// **'Limitations HCE Android'**
  String get limitHce;

  /// No description provided for @limitHceDesc.
  ///
  /// In fr, this message translates to:
  /// **'L\'émulation est limitée au protocole ISO-DEP. L\'UID est attribué par Android et ne peut pas être choisi. L\'émulation s\'arrête quand l\'écran est éteint.'**
  String get limitHceDesc;

  /// No description provided for @limitRange.
  ///
  /// In fr, this message translates to:
  /// **'Portée NFC'**
  String get limitRange;

  /// No description provided for @limitRangeDesc.
  ///
  /// In fr, this message translates to:
  /// **'La communication NFC nécessite une proximité de quelques centimètres (< 4 cm typiquement).'**
  String get limitRangeDesc;

  /// No description provided for @legalWarning.
  ///
  /// In fr, this message translates to:
  /// **'Avertissement légal important'**
  String get legalWarning;

  /// No description provided for @legalCopyAccess.
  ///
  /// In fr, this message translates to:
  /// **'Copie de badges d\'accès'**
  String get legalCopyAccess;

  /// No description provided for @legalCopyAccessDesc.
  ///
  /// In fr, this message translates to:
  /// **'La duplication de badges d\'accès sans autorisation du propriétaire ou gestionnaire constitue une infraction pénale.'**
  String get legalCopyAccessDesc;

  /// No description provided for @legalFraud.
  ///
  /// In fr, this message translates to:
  /// **'Fraude et usurpation'**
  String get legalFraud;

  /// No description provided for @legalFraudDesc.
  ///
  /// In fr, this message translates to:
  /// **'L\'utilisation de tags NFC pour usurper une identité ou contourner des systèmes de sécurité est un délit pénal.'**
  String get legalFraudDesc;

  /// No description provided for @legalPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Données personnelles'**
  String get legalPrivacy;

  /// No description provided for @legalPrivacyDesc.
  ///
  /// In fr, this message translates to:
  /// **'La lecture de tags contenant des données personnelles sans consentement peut violer le RGPD et les lois sur la vie privée.'**
  String get legalPrivacyDesc;

  /// No description provided for @legalAuthorization.
  ///
  /// In fr, this message translates to:
  /// **'Usage autorisé uniquement'**
  String get legalAuthorization;

  /// No description provided for @legalAuthorizationDesc.
  ///
  /// In fr, this message translates to:
  /// **'N\'utilisez les fonctions de copie et d\'émulation que sur vos propres tags ou avec l\'autorisation explicite du propriétaire.'**
  String get legalAuthorizationDesc;

  /// No description provided for @techNfcA.
  ///
  /// In fr, this message translates to:
  /// **'Tags MIFARE, NFC Forum Type 1/2/4'**
  String get techNfcA;

  /// No description provided for @techNfcB.
  ///
  /// In fr, this message translates to:
  /// **'Cartes à puce, passeports biométriques'**
  String get techNfcB;

  /// No description provided for @techNfcF.
  ///
  /// In fr, this message translates to:
  /// **'Sony FeliCa (principalement au Japon)'**
  String get techNfcF;

  /// No description provided for @techNfcV.
  ///
  /// In fr, this message translates to:
  /// **'Tags industriels longue portée'**
  String get techNfcV;

  /// No description provided for @techIsoDep.
  ///
  /// In fr, this message translates to:
  /// **'Cartes à puce avancées, EMV'**
  String get techIsoDep;

  /// No description provided for @techNdef.
  ///
  /// In fr, this message translates to:
  /// **'Format standard NFC Forum pour données structurées'**
  String get techNdef;

  /// No description provided for @techMifareClassic.
  ///
  /// In fr, this message translates to:
  /// **'Tags 1K/4K avec secteurs et clés d\'authentification'**
  String get techMifareClassic;

  /// No description provided for @techMifareUltralight.
  ///
  /// In fr, this message translates to:
  /// **'Tags légers à faible coût, 64-192 octets'**
  String get techMifareUltralight;

  /// No description provided for @templates.
  ///
  /// In fr, this message translates to:
  /// **'Modèles'**
  String get templates;

  /// No description provided for @myTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Mes modèles'**
  String get myTemplates;

  /// No description provided for @noTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Aucun modèle'**
  String get noTemplates;

  /// No description provided for @createTemplatesHint.
  ///
  /// In fr, this message translates to:
  /// **'Partagez facilement un événement, une adresse, un site internet, une recette de cuisine, un code WiFi...'**
  String get createTemplatesHint;

  /// No description provided for @manageTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les modèles'**
  String get manageTemplates;

  /// No description provided for @templateDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Modèle supprimé'**
  String get templateDeleted;

  /// No description provided for @templateSelected.
  ///
  /// In fr, this message translates to:
  /// **'Modèle sélectionné'**
  String get templateSelected;

  /// No description provided for @templateConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Modèle configuré'**
  String get templateConfigured;

  /// No description provided for @saveAsTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un modèle de tag'**
  String get saveAsTemplate;

  /// No description provided for @templateName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du modèle'**
  String get templateName;

  /// No description provided for @enterTemplateName.
  ///
  /// In fr, this message translates to:
  /// **'Entrez un nom pour ce modèle'**
  String get enterTemplateName;

  /// No description provided for @templateSaved.
  ///
  /// In fr, this message translates to:
  /// **'Modèle sauvegardé'**
  String get templateSaved;

  /// No description provided for @emulateTemplatesHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez des modèles dans \"Écrire un tag\" pour les émuler ici'**
  String get emulateTemplatesHint;

  /// No description provided for @tags.
  ///
  /// In fr, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tagOperations.
  ///
  /// In fr, this message translates to:
  /// **'Opérations sur les tags'**
  String get tagOperations;

  /// No description provided for @modify.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get modify;

  /// No description provided for @modifyTagContent.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le contenu'**
  String get modifyTagContent;

  /// No description provided for @format.
  ///
  /// In fr, this message translates to:
  /// **'Formater'**
  String get format;

  /// No description provided for @eraseTag.
  ///
  /// In fr, this message translates to:
  /// **'Effacer un tag'**
  String get eraseTag;

  /// No description provided for @moreActions.
  ///
  /// In fr, this message translates to:
  /// **'Autres actions'**
  String get moreActions;

  /// No description provided for @viewScannedTags.
  ///
  /// In fr, this message translates to:
  /// **'Voir les tags scannés'**
  String get viewScannedTags;

  /// No description provided for @formatTag.
  ///
  /// In fr, this message translates to:
  /// **'Formater un tag'**
  String get formatTag;

  /// No description provided for @formatWarningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get formatWarningTitle;

  /// No description provided for @formatWarningMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette opération va effacer définitivement toutes les données du tag.'**
  String get formatWarningMessage;

  /// No description provided for @formattingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Formatage en cours...'**
  String get formattingInProgress;

  /// No description provided for @formatSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Tag formaté !'**
  String get formatSuccess;

  /// No description provided for @tagErased.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les données ont été effacées du tag'**
  String get tagErased;

  /// No description provided for @formatFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec du formatage'**
  String get formatFailed;

  /// No description provided for @formatTagInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Formater un tag NFC'**
  String get formatTagInstruction;

  /// No description provided for @formatTagDescription.
  ///
  /// In fr, this message translates to:
  /// **'Effacer toutes les données d\'un tag pour repartir à zéro'**
  String get formatTagDescription;

  /// No description provided for @formatAnother.
  ///
  /// In fr, this message translates to:
  /// **'Formater un autre tag'**
  String get formatAnother;

  /// No description provided for @startFormat.
  ///
  /// In fr, this message translates to:
  /// **'Lancer le formatage'**
  String get startFormat;

  /// No description provided for @modifyTag.
  ///
  /// In fr, this message translates to:
  /// **'Modifier un tag'**
  String get modifyTag;

  /// No description provided for @modifyTagInfoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche'**
  String get modifyTagInfoTitle;

  /// No description provided for @modifyTagInfoMessage.
  ///
  /// In fr, this message translates to:
  /// **'Scannez d\'abord le tag pour lire son contenu actuel, puis modifiez-le.'**
  String get modifyTagInfoMessage;

  /// No description provided for @scanningToModify.
  ///
  /// In fr, this message translates to:
  /// **'Lecture du contenu actuel...'**
  String get scanningToModify;

  /// No description provided for @scanAnother.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un autre'**
  String get scanAnother;

  /// No description provided for @editContent.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editContent;

  /// No description provided for @modifyTagInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Modifier un tag existant'**
  String get modifyTagInstruction;

  /// No description provided for @modifyTagDescription.
  ///
  /// In fr, this message translates to:
  /// **'Lire le contenu actuel et le modifier'**
  String get modifyTagDescription;

  /// No description provided for @scanTagToModify.
  ///
  /// In fr, this message translates to:
  /// **'Scanner le tag à modifier'**
  String get scanTagToModify;

  /// No description provided for @tagDetected.
  ///
  /// In fr, this message translates to:
  /// **'Tag détecté'**
  String get tagDetected;

  /// No description provided for @currentContent.
  ///
  /// In fr, this message translates to:
  /// **'Contenu actuel'**
  String get currentContent;

  /// No description provided for @noNdefContent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contenu NDEF sur ce tag'**
  String get noNdefContent;

  /// No description provided for @tagState.
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get tagState;

  /// No description provided for @writingState.
  ///
  /// In fr, this message translates to:
  /// **'Écriture'**
  String get writingState;

  /// No description provided for @allowed.
  ///
  /// In fr, this message translates to:
  /// **'Autorisée'**
  String get allowed;

  /// No description provided for @blocked.
  ///
  /// In fr, this message translates to:
  /// **'Bloquée'**
  String get blocked;

  /// No description provided for @lockState.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage'**
  String get lockState;

  /// No description provided for @locked.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillé'**
  String get locked;

  /// No description provided for @notLocked.
  ///
  /// In fr, this message translates to:
  /// **'Non verrouillé'**
  String get notLocked;

  /// No description provided for @tagNotModifiable.
  ///
  /// In fr, this message translates to:
  /// **'Non modifiable'**
  String get tagNotModifiable;

  /// No description provided for @tagLockedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ce tag est verrouillé et ne peut pas être modifié.'**
  String get tagLockedMessage;

  /// No description provided for @tagNotWritableMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ce tag est en lecture seule et ne peut pas être modifié.'**
  String get tagNotWritableMessage;

  /// No description provided for @emulate.
  ///
  /// In fr, this message translates to:
  /// **'Émuler'**
  String get emulate;

  /// No description provided for @emulateDescription.
  ///
  /// In fr, this message translates to:
  /// **'Émuler un tag NFC'**
  String get emulateDescription;

  /// No description provided for @miuiShortcutWarning.
  ///
  /// In fr, this message translates to:
  /// **'Sur les appareils Xiaomi, vous devez autoriser la création de raccourcis dans les paramètres.'**
  String get miuiShortcutWarning;

  /// No description provided for @miuiStep1.
  ///
  /// In fr, this message translates to:
  /// **'1. Allez dans Paramètres > Applications'**
  String get miuiStep1;

  /// No description provided for @miuiStep2.
  ///
  /// In fr, this message translates to:
  /// **'2. Trouvez \"Cards Control\"'**
  String get miuiStep2;

  /// No description provided for @miuiStep3.
  ///
  /// In fr, this message translates to:
  /// **'3. Autorisations > \"Créer des raccourcis\"'**
  String get miuiStep3;

  /// No description provided for @miuiStep4.
  ///
  /// In fr, this message translates to:
  /// **'4. Activez cette permission'**
  String get miuiStep4;

  /// No description provided for @tryAnyway.
  ///
  /// In fr, this message translates to:
  /// **'Essayer quand même'**
  String get tryAnyway;

  /// No description provided for @shortcutRequested.
  ///
  /// In fr, this message translates to:
  /// **'Raccourci demandé'**
  String get shortcutRequested;

  /// No description provided for @miuiShortcutHelp.
  ///
  /// In fr, this message translates to:
  /// **'Sur Xiaomi/MIUI, vérifiez votre écran d\'accueil. Si le raccourci n\'apparaît pas, activez la permission \"Créer des raccourcis\" dans les paramètres de l\'application.'**
  String get miuiShortcutHelp;

  /// No description provided for @shortcutRequestSent.
  ///
  /// In fr, this message translates to:
  /// **'La demande de création de raccourci a été envoyée.'**
  String get shortcutRequestSent;

  /// No description provided for @openSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir Paramètres'**
  String get openSettings;

  /// No description provided for @shortcutFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer le raccourci'**
  String get shortcutFailed;

  /// No description provided for @myBusinessCards.
  ///
  /// In fr, this message translates to:
  /// **'Mes cartes'**
  String get myBusinessCards;

  /// No description provided for @readCardNfc.
  ///
  /// In fr, this message translates to:
  /// **'Lire une carte'**
  String get readCardNfc;

  /// No description provided for @scanCardPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Scanner une carte'**
  String get scanCardPhoto;

  /// No description provided for @myContacts.
  ///
  /// In fr, this message translates to:
  /// **'Mes contacts'**
  String get myContacts;

  /// No description provided for @noContacts.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contact'**
  String get noContacts;

  /// No description provided for @noContactsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des contacts manuellement, scannez une carte de visite ou lisez-la via NFC'**
  String get noContactsDescription;

  /// No description provided for @addContact.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un contact'**
  String get addContact;

  /// No description provided for @editContact.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le contact'**
  String get editContact;

  /// No description provided for @deleteConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer'**
  String get deleteConfirmation;

  /// No description provided for @contactDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Contact supprimé'**
  String get contactDeleted;

  /// No description provided for @contactAdded.
  ///
  /// In fr, this message translates to:
  /// **'Contact ajouté'**
  String get contactAdded;

  /// No description provided for @contactUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Contact mis à jour'**
  String get contactUpdated;

  /// No description provided for @nameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le prénom ou le nom est requis'**
  String get nameRequired;

  /// No description provided for @notes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @searchContacts.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher des contacts'**
  String get searchContacts;

  /// No description provided for @camera.
  ///
  /// In fr, this message translates to:
  /// **'Appareil photo'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get gallery;

  /// No description provided for @contactPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get contactPhoto;

  /// No description provided for @companyLogo.
  ///
  /// In fr, this message translates to:
  /// **'Logo entreprise'**
  String get companyLogo;

  /// No description provided for @personalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfo;

  /// No description provided for @professionalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations professionnelles'**
  String get professionalInfo;

  /// No description provided for @contactInfo.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées'**
  String get contactInfo;

  /// No description provided for @faq.
  ///
  /// In fr, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @tutorials.
  ///
  /// In fr, this message translates to:
  /// **'Tutoriels'**
  String get tutorials;

  /// No description provided for @faqGeneralTitle.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get faqGeneralTitle;

  /// No description provided for @faqWhatIsNfc.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce que le NFC ?'**
  String get faqWhatIsNfc;

  /// No description provided for @faqWhatIsNfcAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Le NFC (Near Field Communication) est une technologie sans fil à courte portée permettant l\'échange de données entre appareils à quelques centimètres de distance. Elle est utilisée pour les paiements sans contact, les badges d\'accès, et le partage d\'informations.'**
  String get faqWhatIsNfcAnswer;

  /// No description provided for @faqCompatibility.
  ///
  /// In fr, this message translates to:
  /// **'Mon téléphone est-il compatible ?'**
  String get faqCompatibility;

  /// No description provided for @faqCompatibilityAnswer.
  ///
  /// In fr, this message translates to:
  /// **'La plupart des smartphones modernes (Android 5.0+ et iPhone 7+) sont équipés de NFC. Vérifiez dans les paramètres de votre téléphone si le NFC est disponible et activé.'**
  String get faqCompatibilityAnswer;

  /// No description provided for @faqTagTypes.
  ///
  /// In fr, this message translates to:
  /// **'Quels types de tags sont supportés ?'**
  String get faqTagTypes;

  /// No description provided for @faqTagTypesAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Cards Control supporte les tags NFC Forum Type 1 à 5, MIFARE Classic, MIFARE Ultralight, NTAG, et la plupart des tags ISO 14443 et ISO 15693.'**
  String get faqTagTypesAnswer;

  /// No description provided for @faqReadWriteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lecture et Écriture'**
  String get faqReadWriteTitle;

  /// No description provided for @faqHowToRead.
  ///
  /// In fr, this message translates to:
  /// **'Comment lire un tag NFC ?'**
  String get faqHowToRead;

  /// No description provided for @faqHowToReadAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez l\'application, allez dans \'Lire\', puis approchez votre téléphone du tag NFC. Les données seront automatiquement lues et affichées.'**
  String get faqHowToReadAnswer;

  /// No description provided for @faqHowToWrite.
  ///
  /// In fr, this message translates to:
  /// **'Comment écrire sur un tag NFC ?'**
  String get faqHowToWrite;

  /// No description provided for @faqHowToWriteAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans \'Écrire\', choisissez le type de contenu (URL, texte, contact, etc.), remplissez les informations, puis approchez le tag de votre téléphone.'**
  String get faqHowToWriteAnswer;

  /// No description provided for @faqWriteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi l\'écriture échoue-t-elle ?'**
  String get faqWriteFailed;

  /// No description provided for @faqWriteFailedAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez que le tag n\'est pas verrouillé, qu\'il a assez de mémoire pour les données, et que votre téléphone reste immobile pendant l\'écriture.'**
  String get faqWriteFailedAnswer;

  /// No description provided for @faqLockTag.
  ///
  /// In fr, this message translates to:
  /// **'Comment verrouiller un tag ?'**
  String get faqLockTag;

  /// No description provided for @faqLockTagAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Après l\'écriture, vous pouvez verrouiller le tag pour empêcher toute modification. Attention : le verrouillage permanent est irréversible !'**
  String get faqLockTagAnswer;

  /// No description provided for @faqCardsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cartes de visite'**
  String get faqCardsTitle;

  /// No description provided for @faqCreateCard.
  ///
  /// In fr, this message translates to:
  /// **'Comment créer une carte de visite ?'**
  String get faqCreateCard;

  /// No description provided for @faqCreateCardAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans \'Cartes\', appuyez sur \'Créer\', remplissez vos informations (nom, téléphone, email, etc.), puis sauvegardez. Votre carte est prête à être partagée !'**
  String get faqCreateCardAnswer;

  /// No description provided for @faqShareCard.
  ///
  /// In fr, this message translates to:
  /// **'Comment partager ma carte ?'**
  String get faqShareCard;

  /// No description provided for @faqShareCardAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez votre carte et utilisez NFC (approchez les téléphones), QR Code (faites scanner), ou partagez le lien via messagerie.'**
  String get faqShareCardAnswer;

  /// No description provided for @faqScanBusinessCard.
  ///
  /// In fr, this message translates to:
  /// **'Comment scanner une carte papier ?'**
  String get faqScanBusinessCard;

  /// No description provided for @faqScanBusinessCardAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez \'Lire une carte\' pour photographier une carte de visite physique. L\'OCR extraira automatiquement les informations pour créer un contact.'**
  String get faqScanBusinessCardAnswer;

  /// No description provided for @faqEmulationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Émulation HCE'**
  String get faqEmulationTitle;

  /// No description provided for @faqWhatIsHce.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce que l\'émulation HCE ?'**
  String get faqWhatIsHce;

  /// No description provided for @faqWhatIsHceAnswer.
  ///
  /// In fr, this message translates to:
  /// **'L\'émulation HCE (Host Card Emulation) transforme votre téléphone en tag NFC virtuel. D\'autres appareils peuvent scanner votre téléphone comme un tag NFC classique.'**
  String get faqWhatIsHceAnswer;

  /// No description provided for @faqHceRequirements.
  ///
  /// In fr, this message translates to:
  /// **'Quelles sont les exigences ?'**
  String get faqHceRequirements;

  /// No description provided for @faqHceRequirementsAnswer.
  ///
  /// In fr, this message translates to:
  /// **'L\'émulation HCE nécessite Android 4.4+ avec NFC activé. L\'écran doit être allumé pendant l\'émulation. iOS ne supporte pas cette fonctionnalité.'**
  String get faqHceRequirementsAnswer;

  /// No description provided for @faqHceLimits.
  ///
  /// In fr, this message translates to:
  /// **'Quelles sont les limitations ?'**
  String get faqHceLimits;

  /// No description provided for @faqHceLimitsAnswer.
  ///
  /// In fr, this message translates to:
  /// **'L\'UID ne peut pas être personnalisé (imposé par Android), l\'émulation s\'arrête quand l\'écran s\'éteint, et elle ne fonctionne pas pour les cartes bancaires ou badges sécurisés.'**
  String get faqHceLimitsAnswer;

  /// No description provided for @faqTroubleshootingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dépannage'**
  String get faqTroubleshootingTitle;

  /// No description provided for @faqNfcNotWorking.
  ///
  /// In fr, this message translates to:
  /// **'Le NFC ne fonctionne pas'**
  String get faqNfcNotWorking;

  /// No description provided for @faqNfcNotWorkingAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez que le NFC est activé dans les paramètres, retirez toute coque épaisse, et assurez-vous que le tag est proche de l\'antenne NFC de votre téléphone (généralement au dos, vers le haut).'**
  String get faqNfcNotWorkingAnswer;

  /// No description provided for @faqTagNotDetected.
  ///
  /// In fr, this message translates to:
  /// **'Le tag n\'est pas détecté'**
  String get faqTagNotDetected;

  /// No description provided for @faqTagNotDetectedAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Essayez de déplacer lentement le téléphone sur le tag pour trouver le point optimal. Certains tags défectueux ou de mauvaise qualité peuvent ne pas fonctionner.'**
  String get faqTagNotDetectedAnswer;

  /// No description provided for @faqDataLoss.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai perdu mes données'**
  String get faqDataLoss;

  /// No description provided for @faqDataLossAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à votre compte pour synchroniser vos données sur tous vos appareils. Les données locales non synchronisées peuvent être perdues en cas de réinstallation.'**
  String get faqDataLossAnswer;

  /// No description provided for @tutorialGettingStarted.
  ///
  /// In fr, this message translates to:
  /// **'Premiers pas'**
  String get tutorialGettingStarted;

  /// No description provided for @tutorialGettingStartedDesc.
  ///
  /// In fr, this message translates to:
  /// **'Apprenez les bases de l\'utilisation de Cards Control'**
  String get tutorialGettingStartedDesc;

  /// No description provided for @tutorialStep1Enable.
  ///
  /// In fr, this message translates to:
  /// **'Activez le NFC dans les paramètres de votre téléphone'**
  String get tutorialStep1Enable;

  /// No description provided for @tutorialStep2Open.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez Cards Control et créez un compte'**
  String get tutorialStep2Open;

  /// No description provided for @tutorialStep3Place.
  ///
  /// In fr, this message translates to:
  /// **'Approchez un tag NFC à l\'arrière de votre téléphone'**
  String get tutorialStep3Place;

  /// No description provided for @tutorialStep4Read.
  ///
  /// In fr, this message translates to:
  /// **'Les informations du tag s\'affichent automatiquement'**
  String get tutorialStep4Read;

  /// No description provided for @tutorialReadTag.
  ///
  /// In fr, this message translates to:
  /// **'Lire un tag NFC'**
  String get tutorialReadTag;

  /// No description provided for @tutorialReadTagDesc.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez le contenu d\'un tag NFC en quelques secondes'**
  String get tutorialReadTagDesc;

  /// No description provided for @tutorialReadStep1.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur \'Lire\' dans le menu principal'**
  String get tutorialReadStep1;

  /// No description provided for @tutorialReadStep2.
  ///
  /// In fr, this message translates to:
  /// **'Approchez le tag NFC de votre téléphone'**
  String get tutorialReadStep2;

  /// No description provided for @tutorialReadStep3.
  ///
  /// In fr, this message translates to:
  /// **'Maintenez le tag immobile pendant la lecture'**
  String get tutorialReadStep3;

  /// No description provided for @tutorialReadStep4.
  ///
  /// In fr, this message translates to:
  /// **'Consultez les informations lues (type, UID, contenu)'**
  String get tutorialReadStep4;

  /// No description provided for @tutorialWriteTag.
  ///
  /// In fr, this message translates to:
  /// **'Écrire sur un tag'**
  String get tutorialWriteTag;

  /// No description provided for @tutorialWriteTagDesc.
  ///
  /// In fr, this message translates to:
  /// **'Programmez vos propres tags NFC'**
  String get tutorialWriteTagDesc;

  /// No description provided for @tutorialWriteStep1.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur \'Écrire\' dans le menu principal'**
  String get tutorialWriteStep1;

  /// No description provided for @tutorialWriteStep2.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le type de contenu à écrire'**
  String get tutorialWriteStep2;

  /// No description provided for @tutorialWriteStep3.
  ///
  /// In fr, this message translates to:
  /// **'Remplissez les informations nécessaires'**
  String get tutorialWriteStep3;

  /// No description provided for @tutorialWriteStep4.
  ///
  /// In fr, this message translates to:
  /// **'Approchez le tag vierge de votre téléphone'**
  String get tutorialWriteStep4;

  /// No description provided for @tutorialWriteStep5.
  ///
  /// In fr, this message translates to:
  /// **'Attendez la confirmation d\'écriture réussie'**
  String get tutorialWriteStep5;

  /// No description provided for @tutorialCreateCard.
  ///
  /// In fr, this message translates to:
  /// **'Créer une carte de visite'**
  String get tutorialCreateCard;

  /// No description provided for @tutorialCreateCardDesc.
  ///
  /// In fr, this message translates to:
  /// **'Créez et partagez votre carte de visite numérique'**
  String get tutorialCreateCardDesc;

  /// No description provided for @tutorialCardStep1.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans \'Cartes\' et appuyez sur \'Créer\''**
  String get tutorialCardStep1;

  /// No description provided for @tutorialCardStep2.
  ///
  /// In fr, this message translates to:
  /// **'Remplissez vos informations professionnelles'**
  String get tutorialCardStep2;

  /// No description provided for @tutorialCardStep3.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisez l\'apparence de votre carte'**
  String get tutorialCardStep3;

  /// No description provided for @tutorialCardStep4.
  ///
  /// In fr, this message translates to:
  /// **'Partagez via NFC, QR Code ou lien'**
  String get tutorialCardStep4;

  /// No description provided for @tutorialEmulation.
  ///
  /// In fr, this message translates to:
  /// **'Émuler un tag NFC'**
  String get tutorialEmulation;

  /// No description provided for @tutorialEmulationDesc.
  ///
  /// In fr, this message translates to:
  /// **'Transformez votre téléphone en tag NFC'**
  String get tutorialEmulationDesc;

  /// No description provided for @tutorialEmulateStep1.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une carte ou un template'**
  String get tutorialEmulateStep1;

  /// No description provided for @tutorialEmulateStep2.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur \'Émuler\''**
  String get tutorialEmulateStep2;

  /// No description provided for @tutorialEmulateStep3.
  ///
  /// In fr, this message translates to:
  /// **'Gardez l\'écran allumé et approchez un lecteur NFC'**
  String get tutorialEmulateStep3;

  /// No description provided for @tutorialEmulateStep4.
  ///
  /// In fr, this message translates to:
  /// **'L\'émulation s\'arrête automatiquement après le délai'**
  String get tutorialEmulateStep4;

  /// No description provided for @tutorialCopyTag.
  ///
  /// In fr, this message translates to:
  /// **'Copier un tag'**
  String get tutorialCopyTag;

  /// No description provided for @tutorialCopyTagDesc.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquez le contenu d\'un tag vers un autre'**
  String get tutorialCopyTagDesc;

  /// No description provided for @tutorialCopyStep1.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur \'Copier\' dans le menu'**
  String get tutorialCopyStep1;

  /// No description provided for @tutorialCopyStep2.
  ///
  /// In fr, this message translates to:
  /// **'Scannez d\'abord le tag source'**
  String get tutorialCopyStep2;

  /// No description provided for @tutorialCopyStep3.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez le contenu lu'**
  String get tutorialCopyStep3;

  /// No description provided for @tutorialCopyStep4.
  ///
  /// In fr, this message translates to:
  /// **'Scannez le tag de destination pour écrire'**
  String get tutorialCopyStep4;

  /// No description provided for @aiExtracting.
  ///
  /// In fr, this message translates to:
  /// **'Analyse IA en cours...'**
  String get aiExtracting;

  /// No description provided for @aiExtractingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Extraction des informations de contact'**
  String get aiExtractingSubtitle;

  /// No description provided for @extractContactWithAi.
  ///
  /// In fr, this message translates to:
  /// **'Extraire avec l\'IA'**
  String get extractContactWithAi;

  /// No description provided for @urlDetected.
  ///
  /// In fr, this message translates to:
  /// **'URL détectée'**
  String get urlDetected;

  /// No description provided for @createContactManually.
  ///
  /// In fr, this message translates to:
  /// **'Créer manuellement'**
  String get createContactManually;

  /// No description provided for @extractionIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Extraction incomplète'**
  String get extractionIncomplete;

  /// No description provided for @noContactInfoFound.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'extraire les informations de contact'**
  String get noContactInfoFound;

  /// No description provided for @createFirstCard.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre première carte'**
  String get createFirstCard;

  /// No description provided for @createFirstCardDesc.
  ///
  /// In fr, this message translates to:
  /// **'Partagez vos coordonnées professionnelles facilement via NFC, QR code ou lien'**
  String get createFirstCardDesc;

  /// No description provided for @createMyCard.
  ///
  /// In fr, this message translates to:
  /// **'Créer ma carte'**
  String get createMyCard;

  /// No description provided for @importFromContacts.
  ///
  /// In fr, this message translates to:
  /// **'Importer depuis les contacts'**
  String get importFromContacts;

  /// No description provided for @scanCard.
  ///
  /// In fr, this message translates to:
  /// **'Scan d\'une carte'**
  String get scanCard;

  /// No description provided for @permissionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Permission requise'**
  String get permissionRequired;

  /// No description provided for @contactPermissionDesc.
  ///
  /// In fr, this message translates to:
  /// **'L\'accès aux contacts est nécessaire pour importer un contact. Veuillez autoriser l\'accès dans les paramètres de l\'application.'**
  String get contactPermissionDesc;

  /// No description provided for @contactPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission refusée pour accéder aux contacts'**
  String get contactPermissionDenied;

  /// No description provided for @contactDetailsError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de récupérer les détails du contact'**
  String get contactDetailsError;

  /// No description provided for @firstNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Prénom *'**
  String get firstNameRequired;

  /// No description provided for @required.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get required;

  /// No description provided for @lastNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom *'**
  String get lastNameRequired;

  /// No description provided for @addLogo.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un logo'**
  String get addLogo;

  /// No description provided for @socialNetworks.
  ///
  /// In fr, this message translates to:
  /// **'Réseaux sociaux'**
  String get socialNetworks;

  /// No description provided for @uploading.
  ///
  /// In fr, this message translates to:
  /// **'Upload en cours...'**
  String get uploading;

  /// No description provided for @saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get saveChanges;

  /// No description provided for @createCard.
  ///
  /// In fr, this message translates to:
  /// **'Créer la carte'**
  String get createCard;

  /// No description provided for @photoUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur upload photo'**
  String get photoUploadError;

  /// No description provided for @logoUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur upload logo'**
  String get logoUploadError;

  /// No description provided for @contactImportSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Contact importé avec succès'**
  String get contactImportSuccess;

  /// No description provided for @cardSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Carte enregistrée avec succès'**
  String get cardSavedSuccess;

  /// No description provided for @enableNfc.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez activer le NFC'**
  String get enableNfc;

  /// No description provided for @preview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get preview;

  /// No description provided for @wallet.
  ///
  /// In fr, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @shortcut.
  ///
  /// In fr, this message translates to:
  /// **'Raccourci'**
  String get shortcut;

  /// No description provided for @information.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get information;

  /// No description provided for @views.
  ///
  /// In fr, this message translates to:
  /// **'Vues'**
  String get views;

  /// No description provided for @shares.
  ///
  /// In fr, this message translates to:
  /// **'Partages'**
  String get shares;

  /// No description provided for @scans.
  ///
  /// In fr, this message translates to:
  /// **'Scans'**
  String get scans;

  /// No description provided for @qrCodeOf.
  ///
  /// In fr, this message translates to:
  /// **'QR Code de {name}'**
  String qrCodeOf(Object name);

  /// No description provided for @scanToSeeCard.
  ///
  /// In fr, this message translates to:
  /// **'Scannez pour voir la carte'**
  String get scanToSeeCard;

  /// No description provided for @nfcNotAvailableIos.
  ///
  /// In fr, this message translates to:
  /// **'Le partage NFC n\'est pas disponible sur iOS. Utilisez le QR Code ou le lien.'**
  String get nfcNotAvailableIos;

  /// No description provided for @myBusinessCard.
  ///
  /// In fr, this message translates to:
  /// **'Ma carte de visite - {name}'**
  String myBusinessCard(Object name);

  /// No description provided for @appleWalletNotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Apple Wallet n\'est pas disponible'**
  String get appleWalletNotAvailable;

  /// No description provided for @googleWalletNotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Google Wallet n\'est pas disponible sur cet appareil'**
  String get googleWalletNotAvailable;

  /// No description provided for @writeToNfc.
  ///
  /// In fr, this message translates to:
  /// **'Écrire sur un tag NFC'**
  String get writeToNfc;

  /// No description provided for @myCards.
  ///
  /// In fr, this message translates to:
  /// **'Mes cartes'**
  String get myCards;

  /// No description provided for @viewManageCards.
  ///
  /// In fr, this message translates to:
  /// **'Voir et gérer mes cartes'**
  String get viewManageCards;

  /// No description provided for @create.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// No description provided for @newBusinessCard.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle carte de visite'**
  String get newBusinessCard;

  /// No description provided for @readCard.
  ///
  /// In fr, this message translates to:
  /// **'Lire une carte'**
  String get readCard;

  /// No description provided for @photoOrCamera.
  ///
  /// In fr, this message translates to:
  /// **'Photo ou caméra'**
  String get photoOrCamera;

  /// No description provided for @import.
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get import;

  /// No description provided for @fromContacts.
  ///
  /// In fr, this message translates to:
  /// **'Depuis les contacts'**
  String get fromContacts;

  /// No description provided for @manageContacts.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mes contacts'**
  String get manageContacts;

  /// No description provided for @scanNfcCard.
  ///
  /// In fr, this message translates to:
  /// **'Scan carte NFC'**
  String get scanNfcCard;

  /// No description provided for @scanBusinessCard.
  ///
  /// In fr, this message translates to:
  /// **'Scanner une carte de visite'**
  String get scanBusinessCard;

  /// No description provided for @templatesInfoDesc.
  ///
  /// In fr, this message translates to:
  /// **'Pour utiliser au quotidien ou partager facilement un événement, une adresse, un site internet, une recette de cuisine, un code WiFi...'**
  String get templatesInfoDesc;

  /// No description provided for @myTagTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Mes modèles de Tags'**
  String get myTagTemplates;

  /// No description provided for @viewManageTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Voir et gérer mes modèles'**
  String get viewManageTemplates;

  /// No description provided for @newTagTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau modèle de Tag'**
  String get newTagTemplate;

  /// No description provided for @fromExistingTag.
  ///
  /// In fr, this message translates to:
  /// **'Depuis un Tag existant'**
  String get fromExistingTag;

  /// No description provided for @emulateTag.
  ///
  /// In fr, this message translates to:
  /// **'Émuler un Tag'**
  String get emulateTag;

  /// No description provided for @shareNfc.
  ///
  /// In fr, this message translates to:
  /// **'Partager en NFC'**
  String get shareNfc;

  /// No description provided for @viaQrCode.
  ///
  /// In fr, this message translates to:
  /// **'Via QR Code'**
  String get viaQrCode;

  /// No description provided for @createTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un modèle'**
  String get createTemplate;

  /// No description provided for @whatTemplateType.
  ///
  /// In fr, this message translates to:
  /// **'Quel type de modèle ?'**
  String get whatTemplateType;

  /// No description provided for @chooseDataType.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le type de données pour votre modèle'**
  String get chooseDataType;

  /// No description provided for @commonTypes.
  ///
  /// In fr, this message translates to:
  /// **'Types courants'**
  String get commonTypes;

  /// No description provided for @otherTypes.
  ///
  /// In fr, this message translates to:
  /// **'Autres types'**
  String get otherTypes;

  /// No description provided for @specialTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Modèles spéciaux'**
  String get specialTemplates;

  /// No description provided for @idTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Modèles d\'identification'**
  String get idTemplates;

  /// No description provided for @websiteLink.
  ///
  /// In fr, this message translates to:
  /// **'Site web, lien'**
  String get websiteLink;

  /// No description provided for @textMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message texte'**
  String get textMessage;

  /// No description provided for @dateTimeLocation.
  ///
  /// In fr, this message translates to:
  /// **'Date, heure, lieu'**
  String get dateTimeLocation;

  /// No description provided for @networkConfig.
  ///
  /// In fr, this message translates to:
  /// **'Config. réseau'**
  String get networkConfig;

  /// No description provided for @phoneNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phoneNumber;

  /// No description provided for @directCall.
  ///
  /// In fr, this message translates to:
  /// **'Appel direct'**
  String get directCall;

  /// No description provided for @newMessage.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau message'**
  String get newMessage;

  /// No description provided for @gpsPosition.
  ///
  /// In fr, this message translates to:
  /// **'Position GPS'**
  String get gpsPosition;

  /// No description provided for @staticDataOnly.
  ///
  /// In fr, this message translates to:
  /// **'Données statiques uniquement'**
  String get staticDataOnly;

  /// No description provided for @forDynamicCard.
  ///
  /// In fr, this message translates to:
  /// **'Pour une carte de visite dynamique :'**
  String get forDynamicCard;

  /// No description provided for @businessCardsArrow.
  ///
  /// In fr, this message translates to:
  /// **'Cartes de visite →'**
  String get businessCardsArrow;

  /// No description provided for @googleReview.
  ///
  /// In fr, this message translates to:
  /// **'Avis Google'**
  String get googleReview;

  /// No description provided for @googleReviewLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien vers avis Google Business'**
  String get googleReviewLink;

  /// No description provided for @appDownload.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement App'**
  String get appDownload;

  /// No description provided for @appStoreLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien App Store / Play Store'**
  String get appStoreLink;

  /// No description provided for @tip.
  ///
  /// In fr, this message translates to:
  /// **'Pourboire'**
  String get tip;

  /// No description provided for @tipPlatforms.
  ///
  /// In fr, this message translates to:
  /// **'PayPal, Stripe ou lien personnalisé'**
  String get tipPlatforms;

  /// No description provided for @medicalId.
  ///
  /// In fr, this message translates to:
  /// **'ID Médical'**
  String get medicalId;

  /// No description provided for @emergencyInfo.
  ///
  /// In fr, this message translates to:
  /// **'Infos urgence, médecin traitant'**
  String get emergencyInfo;

  /// No description provided for @petId.
  ///
  /// In fr, this message translates to:
  /// **'ID Animal'**
  String get petId;

  /// No description provided for @petIdInfo.
  ///
  /// In fr, this message translates to:
  /// **'Identification animal de compagnie'**
  String get petIdInfo;

  /// No description provided for @luggageId.
  ///
  /// In fr, this message translates to:
  /// **'ID Bagages'**
  String get luggageId;

  /// No description provided for @luggageIdInfo.
  ///
  /// In fr, this message translates to:
  /// **'Identification bagages voyage'**
  String get luggageIdInfo;

  /// No description provided for @editTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le modèle'**
  String get editTemplate;

  /// No description provided for @newTemplateType.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau modèle {type}'**
  String newTemplateType(Object type);

  /// No description provided for @templateData.
  ///
  /// In fr, this message translates to:
  /// **'Données du modèle'**
  String get templateData;

  /// No description provided for @update.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get update;

  /// No description provided for @createTemplateBtn.
  ///
  /// In fr, this message translates to:
  /// **'Créer le modèle'**
  String get createTemplateBtn;

  /// No description provided for @enterUrl.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer une URL'**
  String get enterUrl;

  /// No description provided for @urlMustStartWith.
  ///
  /// In fr, this message translates to:
  /// **'L\'URL doit commencer par http:// ou https://'**
  String get urlMustStartWith;

  /// No description provided for @enterText.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer du texte'**
  String get enterText;

  /// No description provided for @ssidRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom du réseau (SSID) *'**
  String get ssidRequired;

  /// No description provided for @securityType.
  ///
  /// In fr, this message translates to:
  /// **'Type de sécurité'**
  String get securityType;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe *'**
  String get passwordRequired;

  /// No description provided for @hiddenNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Réseau masqué'**
  String get hiddenNetwork;

  /// No description provided for @phoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone *'**
  String get phoneRequired;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email *'**
  String get emailRequired;

  /// No description provided for @subjectOptional.
  ///
  /// In fr, this message translates to:
  /// **'Sujet (optionnel)'**
  String get subjectOptional;

  /// No description provided for @bodyOptional.
  ///
  /// In fr, this message translates to:
  /// **'Corps du message (optionnel)'**
  String get bodyOptional;

  /// No description provided for @messageOptional.
  ///
  /// In fr, this message translates to:
  /// **'Message (optionnel)'**
  String get messageOptional;

  /// No description provided for @latitudeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Latitude *'**
  String get latitudeRequired;

  /// No description provided for @longitudeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Longitude *'**
  String get longitudeRequired;

  /// No description provided for @eventTitleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Titre de l\'événement *'**
  String get eventTitleRequired;

  /// No description provided for @dateRequired.
  ///
  /// In fr, this message translates to:
  /// **'Date *'**
  String get dateRequired;

  /// No description provided for @time.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get time;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @linkOptional.
  ///
  /// In fr, this message translates to:
  /// **'Lien (optionnel)'**
  String get linkOptional;

  /// No description provided for @placeIdRequired.
  ///
  /// In fr, this message translates to:
  /// **'ID du lieu Google (Place ID) *'**
  String get placeIdRequired;

  /// No description provided for @googleReviewDesc.
  ///
  /// In fr, this message translates to:
  /// **'Le lien généré ouvrira directement la page d\'avis Google de votre établissement'**
  String get googleReviewDesc;

  /// No description provided for @appStore.
  ///
  /// In fr, this message translates to:
  /// **'App Store'**
  String get appStore;

  /// No description provided for @playStore.
  ///
  /// In fr, this message translates to:
  /// **'Play Store'**
  String get playStore;

  /// No description provided for @provider.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get provider;

  /// No description provided for @paypal.
  ///
  /// In fr, this message translates to:
  /// **'PayPal'**
  String get paypal;

  /// No description provided for @stripe.
  ///
  /// In fr, this message translates to:
  /// **'Stripe'**
  String get stripe;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @bloodType.
  ///
  /// In fr, this message translates to:
  /// **'Groupe sanguin'**
  String get bloodType;

  /// No description provided for @allergies.
  ///
  /// In fr, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @medications.
  ///
  /// In fr, this message translates to:
  /// **'Médicaments'**
  String get medications;

  /// No description provided for @conditions.
  ///
  /// In fr, this message translates to:
  /// **'Conditions'**
  String get conditions;

  /// No description provided for @emergencyContact.
  ///
  /// In fr, this message translates to:
  /// **'Contact urgence'**
  String get emergencyContact;

  /// No description provided for @doctor.
  ///
  /// In fr, this message translates to:
  /// **'Médecin'**
  String get doctor;

  /// No description provided for @doctorPhone.
  ///
  /// In fr, this message translates to:
  /// **'Tél. médecin'**
  String get doctorPhone;

  /// No description provided for @species.
  ///
  /// In fr, this message translates to:
  /// **'Espèce'**
  String get species;

  /// No description provided for @breed.
  ///
  /// In fr, this message translates to:
  /// **'Race'**
  String get breed;

  /// No description provided for @chipNumber.
  ///
  /// In fr, this message translates to:
  /// **'N° puce'**
  String get chipNumber;

  /// No description provided for @owner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get owner;

  /// No description provided for @vet.
  ///
  /// In fr, this message translates to:
  /// **'Vétérinaire'**
  String get vet;

  /// No description provided for @vetPhone.
  ///
  /// In fr, this message translates to:
  /// **'Tél. véto'**
  String get vetPhone;

  /// No description provided for @flightNumber.
  ///
  /// In fr, this message translates to:
  /// **'N° vol'**
  String get flightNumber;

  /// No description provided for @template.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get template;

  /// No description provided for @templateNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Modèle non trouvé'**
  String get templateNotFound;

  /// No description provided for @writeToNfcDesc.
  ///
  /// In fr, this message translates to:
  /// **'Gravez les données sur un tag'**
  String get writeToNfcDesc;

  /// No description provided for @scanQrCodeAbove.
  ///
  /// In fr, this message translates to:
  /// **'Faire scanner le code ci-dessus'**
  String get scanQrCodeAbove;

  /// No description provided for @copyContent.
  ///
  /// In fr, this message translates to:
  /// **'Copier le contenu'**
  String get copyContent;

  /// No description provided for @contentCopied.
  ///
  /// In fr, this message translates to:
  /// **'Contenu copié !'**
  String get contentCopied;

  /// No description provided for @publishOnline.
  ///
  /// In fr, this message translates to:
  /// **'Publier en ligne'**
  String get publishOnline;

  /// No description provided for @alreadyPublished.
  ///
  /// In fr, this message translates to:
  /// **'Déjà publié - {url}'**
  String alreadyPublished(Object url);

  /// No description provided for @createPublicLink.
  ///
  /// In fr, this message translates to:
  /// **'Créer un lien public partageable'**
  String get createPublicLink;

  /// No description provided for @writeNfc.
  ///
  /// In fr, this message translates to:
  /// **'Écrire NFC'**
  String get writeNfc;

  /// No description provided for @details.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get details;

  /// No description provided for @uses.
  ///
  /// In fr, this message translates to:
  /// **'Utilisations'**
  String get uses;

  /// No description provided for @createdOn.
  ///
  /// In fr, this message translates to:
  /// **'Créé le'**
  String get createdOn;

  /// No description provided for @lastUsedOn.
  ///
  /// In fr, this message translates to:
  /// **'Dernière utilisation : {date}'**
  String lastUsedOn(Object date);

  /// No description provided for @templatePublished.
  ///
  /// In fr, this message translates to:
  /// **'Modèle publié !'**
  String get templatePublished;

  /// No description provided for @unpublish.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la publication'**
  String get unpublish;

  /// No description provided for @templateUnpublished.
  ///
  /// In fr, this message translates to:
  /// **'Modèle retiré de la publication'**
  String get templateUnpublished;

  /// No description provided for @publishTemplateQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Publier ce modèle ?'**
  String get publishTemplateQuestion;

  /// No description provided for @publishTemplateDesc.
  ///
  /// In fr, this message translates to:
  /// **'Un lien public sera créé pour partager ce modèle.'**
  String get publishTemplateDesc;

  /// No description provided for @publishTemplateWarning.
  ///
  /// In fr, this message translates to:
  /// **'Toute personne ayant le lien pourra accéder aux données du modèle.'**
  String get publishTemplateWarning;

  /// No description provided for @publish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get publish;

  /// No description provided for @appDownloadDesc.
  ///
  /// In fr, this message translates to:
  /// **'L\'utilisateur sera redirigé vers le bon store selon son appareil'**
  String get appDownloadDesc;

  /// No description provided for @customLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien personnalisé'**
  String get customLink;

  /// No description provided for @paypalLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien PayPal.me *'**
  String get paypalLink;

  /// No description provided for @stripeLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien Stripe Payment *'**
  String get stripeLink;

  /// No description provided for @customUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL personnalisée *'**
  String get customUrl;

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet *'**
  String get fullName;

  /// No description provided for @petName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'animal *'**
  String get petName;

  /// No description provided for @ownerName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du propriétaire *'**
  String get ownerName;

  /// No description provided for @ownerPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone propriétaire *'**
  String get ownerPhone;

  /// No description provided for @vetClinic.
  ///
  /// In fr, this message translates to:
  /// **'Cabinet vétérinaire'**
  String get vetClinic;

  /// No description provided for @destinationAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de destination'**
  String get destinationAddress;

  /// No description provided for @flightNumberOptional.
  ///
  /// In fr, this message translates to:
  /// **'N° de vol (optionnel)'**
  String get flightNumberOptional;

  /// No description provided for @luggageDesc.
  ///
  /// In fr, this message translates to:
  /// **'En cas de perte, ces informations aideront à vous retrouver'**
  String get luggageDesc;

  /// No description provided for @webLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien web'**
  String get webLink;

  /// No description provided for @wifiConfig.
  ///
  /// In fr, this message translates to:
  /// **'Config WiFi'**
  String get wifiConfig;

  /// No description provided for @businessCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte de visite'**
  String get businessCard;

  /// No description provided for @phoneCall.
  ///
  /// In fr, this message translates to:
  /// **'Appel téléphonique'**
  String get phoneCall;

  /// No description provided for @templateUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Modèle \"{name}\" mis à jour'**
  String templateUpdated(Object name);

  /// No description provided for @templateCreated.
  ///
  /// In fr, this message translates to:
  /// **'Modèle \"{name}\" créé'**
  String templateCreated(Object name);

  /// No description provided for @sms.
  ///
  /// In fr, this message translates to:
  /// **'SMS'**
  String get sms;

  /// No description provided for @event.
  ///
  /// In fr, this message translates to:
  /// **'Événement'**
  String get event;

  /// No description provided for @select.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get select;

  /// No description provided for @optional.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel'**
  String get optional;

  /// No description provided for @data.
  ///
  /// In fr, this message translates to:
  /// **'Données'**
  String get data;

  /// No description provided for @network.
  ///
  /// In fr, this message translates to:
  /// **'Réseau'**
  String get network;

  /// No description provided for @security.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get security;

  /// No description provided for @hidden.
  ///
  /// In fr, this message translates to:
  /// **'Masqué'**
  String get hidden;

  /// No description provided for @subject.
  ///
  /// In fr, this message translates to:
  /// **'Sujet'**
  String get subject;

  /// No description provided for @message.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @latitude.
  ///
  /// In fr, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In fr, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @title.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get title;

  /// No description provided for @date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @link.
  ///
  /// In fr, this message translates to:
  /// **'Lien'**
  String get link;

  /// No description provided for @placeId.
  ///
  /// In fr, this message translates to:
  /// **'Place ID'**
  String get placeId;

  /// No description provided for @searchOnMap.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher sur la carte'**
  String get searchOnMap;

  /// No description provided for @cardsAndContactsPageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cartes de visite et contacts'**
  String get cardsAndContactsPageTitle;

  /// No description provided for @myCardsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes cartes de visite'**
  String get myCardsTitle;

  /// No description provided for @myCardsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voir et éditer mes cartes de visite'**
  String get myCardsSubtitle;

  /// No description provided for @createCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer une carte de visite'**
  String get createCardTitle;

  /// No description provided for @createCardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer une carte Pro, Personnelle ou Profil avec CV'**
  String get createCardSubtitle;

  /// No description provided for @readPaperCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lire une carte'**
  String get readPaperCardTitle;

  /// No description provided for @readPaperCardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Lire une carte papier avec la caméra'**
  String get readPaperCardSubtitle;

  /// No description provided for @scanNfcCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scanner une carte NFC'**
  String get scanNfcCardTitle;

  /// No description provided for @scanNfcCardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Scanner une carte physique ou émulée'**
  String get scanNfcCardSubtitle;

  /// No description provided for @aiBadge.
  ///
  /// In fr, this message translates to:
  /// **'IA'**
  String get aiBadge;

  /// No description provided for @aiPowered.
  ///
  /// In fr, this message translates to:
  /// **'Propulsé par IA'**
  String get aiPowered;

  /// No description provided for @aiUsage.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation IA'**
  String get aiUsage;

  /// No description provided for @errorLoadingData.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get errorLoadingData;

  /// No description provided for @usageByType.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation par type'**
  String get usageByType;

  /// No description provided for @aiCredits.
  ///
  /// In fr, this message translates to:
  /// **'Crédits IA'**
  String get aiCredits;

  /// No description provided for @monthlyUsage.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation mensuelle'**
  String get monthlyUsage;

  /// No description provided for @used.
  ///
  /// In fr, this message translates to:
  /// **'utilisé'**
  String get used;

  /// No description provided for @remaining.
  ///
  /// In fr, this message translates to:
  /// **'restant'**
  String get remaining;

  /// No description provided for @tokenLimitReached.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez atteint votre limite mensuelle de tokens. Attendez la prochaine période ou passez à un forfait supérieur.'**
  String get tokenLimitReached;

  /// No description provided for @businessCardReading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture carte de visite'**
  String get businessCardReading;

  /// No description provided for @tagAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de tag NFC'**
  String get tagAnalysis;

  /// No description provided for @templateGeneration.
  ///
  /// In fr, this message translates to:
  /// **'Génération de modèle'**
  String get templateGeneration;

  /// No description provided for @billingPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période de facturation'**
  String get billingPeriod;

  /// No description provided for @resetsMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialisation mensuelle'**
  String get resetsMonthly;

  /// No description provided for @needMoreCredits.
  ///
  /// In fr, this message translates to:
  /// **'Besoin de plus de crédits ?'**
  String get needMoreCredits;

  /// No description provided for @creditsComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'L\'option d\'achat de crédits supplémentaires sera bientôt disponible.'**
  String get creditsComingSoon;

  /// No description provided for @aiGenerationSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Description générée avec succès !'**
  String get aiGenerationSuccess;

  /// No description provided for @aiGenerationError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la génération de description'**
  String get aiGenerationError;

  /// No description provided for @generateWithAI.
  ///
  /// In fr, this message translates to:
  /// **'Générer avec l\'IA'**
  String get generateWithAI;

  /// No description provided for @aiEnhanceDescription.
  ///
  /// In fr, this message translates to:
  /// **'Améliorer avec l\'IA'**
  String get aiEnhanceDescription;

  /// No description provided for @eventPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo de l\'événement'**
  String get eventPhoto;

  /// No description provided for @addEventPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get addEventPhoto;

  /// No description provided for @generateImageWithAI.
  ///
  /// In fr, this message translates to:
  /// **'Générer avec l\'IA'**
  String get generateImageWithAI;

  /// No description provided for @aiImageComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Génération d\'image IA bientôt disponible'**
  String get aiImageComingSoon;

  /// No description provided for @aiImageGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Image générée avec succès !'**
  String get aiImageGenerated;

  /// No description provided for @generatingImage.
  ///
  /// In fr, this message translates to:
  /// **'Génération de l\'image...'**
  String get generatingImage;

  /// No description provided for @tagTypesExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Les types fixes sont prédéfinis. Vos modèles apparaissent dans la section \"Mes modèles\".'**
  String get tagTypesExplanation;

  /// No description provided for @fixedTypes.
  ///
  /// In fr, this message translates to:
  /// **'Types fixes'**
  String get fixedTypes;

  /// No description provided for @dynamicTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Vos modèles'**
  String get dynamicTemplates;

  /// No description provided for @buyMoreTokens.
  ///
  /// In fr, this message translates to:
  /// **'Acheter des tokens IA supplémentaires'**
  String get buyMoreTokens;

  /// No description provided for @upgradeToPro.
  ///
  /// In fr, this message translates to:
  /// **'Passez à Pro pour 5x plus de tokens et des fonctionnalités exclusives'**
  String get upgradeToPro;

  /// No description provided for @tokenPackagePrice1.
  ///
  /// In fr, this message translates to:
  /// **'2,99 €'**
  String get tokenPackagePrice1;

  /// No description provided for @tokenPackagePrice2.
  ///
  /// In fr, this message translates to:
  /// **'9,99 €'**
  String get tokenPackagePrice2;

  /// No description provided for @tokenPackagePrice3.
  ///
  /// In fr, this message translates to:
  /// **'14,99 €'**
  String get tokenPackagePrice3;

  /// No description provided for @purchaseComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalité d\'achat bientôt disponible'**
  String get purchaseComingSoon;

  /// No description provided for @resetsAnnually.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialisation annuelle'**
  String get resetsAnnually;

  /// No description provided for @faqTemplatesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modèles dynamiques'**
  String get faqTemplatesTitle;

  /// No description provided for @faqWhatAreTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce qu\'un modèle dynamique ?'**
  String get faqWhatAreTemplates;

  /// No description provided for @faqWhatAreTemplatesAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Un modèle dynamique permet de sauvegarder des données (URL, vCard, WiFi, etc.) pour les réutiliser facilement. Vous pouvez écrire le même contenu sur plusieurs tags sans ressaisir les informations.'**
  String get faqWhatAreTemplatesAnswer;

  /// No description provided for @faqCreateTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Comment créer un modèle ?'**
  String get faqCreateTemplate;

  /// No description provided for @faqCreateTemplateAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans \'Écrire\', créez votre contenu, puis appuyez sur \'Sauvegarder comme modèle\'. Vous pouvez aussi créer un modèle depuis un tag existant en le scannant.'**
  String get faqCreateTemplateAnswer;

  /// No description provided for @faqShareTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Comment partager un modèle ?'**
  String get faqShareTemplate;

  /// No description provided for @faqShareTemplateAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez un modèle, puis utilisez les options de partage : écrire sur un tag NFC, générer un QR Code, copier le lien, ou émuler avec HCE (Android).'**
  String get faqShareTemplateAnswer;

  /// No description provided for @faqAiTitle.
  ///
  /// In fr, this message translates to:
  /// **'Analyse IA'**
  String get faqAiTitle;

  /// No description provided for @faqWhatIsAi.
  ///
  /// In fr, this message translates to:
  /// **'Comment fonctionne l\'analyse IA ?'**
  String get faqWhatIsAi;

  /// No description provided for @faqWhatIsAiAnswer.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA Claude analyse automatiquement le contenu des tags scannés pour extraire des informations structurées, détecter le type de données, et proposer des actions pertinentes.'**
  String get faqWhatIsAiAnswer;

  /// No description provided for @faqAiCredits.
  ///
  /// In fr, this message translates to:
  /// **'Comment fonctionnent les crédits IA ?'**
  String get faqAiCredits;

  /// No description provided for @faqAiCreditsAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Chaque analyse IA consomme des tokens. Les utilisateurs gratuits ont une limite mensuelle, les abonnés Pro bénéficient de 5x plus de tokens avec réinitialisation annuelle.'**
  String get faqAiCreditsAnswer;

  /// No description provided for @faqAiExtractContact.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA peut-elle extraire des contacts ?'**
  String get faqAiExtractContact;

  /// No description provided for @faqAiExtractContactAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Oui ! L\'IA peut analyser une carte de visite scannée (photo ou NFC) pour extraire automatiquement le nom, téléphone, email et autres informations.'**
  String get faqAiExtractContactAnswer;

  /// No description provided for @faqFormatTitle.
  ///
  /// In fr, this message translates to:
  /// **'Formatage et gestion'**
  String get faqFormatTitle;

  /// No description provided for @faqWhatIsFormat.
  ///
  /// In fr, this message translates to:
  /// **'Que fait la fonction Formater ?'**
  String get faqWhatIsFormat;

  /// No description provided for @faqWhatIsFormatAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Le formatage efface complètement la mémoire du tag NFC. Contrairement à une simple réécriture, il remet à zéro toutes les pages de données utilisateur.'**
  String get faqWhatIsFormatAnswer;

  /// No description provided for @faqFormatVsWrite.
  ///
  /// In fr, this message translates to:
  /// **'Quelle différence entre Formater et Réécrire ?'**
  String get faqFormatVsWrite;

  /// No description provided for @faqFormatVsWriteAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Réécrire remplace uniquement les données NDEF visibles. Formater efface TOUTE la mémoire inscriptible du tag (pages 4+ sur Mifare Ultralight, secteurs sur Mifare Classic).'**
  String get faqFormatVsWriteAnswer;

  /// No description provided for @faqFormatSafe.
  ///
  /// In fr, this message translates to:
  /// **'Le formatage est-il sans danger ?'**
  String get faqFormatSafe;

  /// No description provided for @faqFormatSafeAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Oui, le formatage préserve les données système (UID, lock bits). Cependant, les données utilisateur seront définitivement perdues. Cette opération est irréversible.'**
  String get faqFormatSafeAnswer;

  /// No description provided for @tutorialTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser les modèles'**
  String get tutorialTemplates;

  /// No description provided for @tutorialTemplatesDesc.
  ///
  /// In fr, this message translates to:
  /// **'Créez et réutilisez des modèles de tags'**
  String get tutorialTemplatesDesc;

  /// No description provided for @tutorialTemplateStep1.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans \'Écrire\' puis \'Mes modèles dynamiques\''**
  String get tutorialTemplateStep1;

  /// No description provided for @tutorialTemplateStep2.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur \'+\' pour créer un nouveau modèle'**
  String get tutorialTemplateStep2;

  /// No description provided for @tutorialTemplateStep3.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le type (URL, WiFi, vCard, etc.)'**
  String get tutorialTemplateStep3;

  /// No description provided for @tutorialTemplateStep4.
  ///
  /// In fr, this message translates to:
  /// **'Remplissez les informations et sauvegardez'**
  String get tutorialTemplateStep4;

  /// No description provided for @tutorialTemplateStep5.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez le modèle pour écrire sur plusieurs tags'**
  String get tutorialTemplateStep5;

  /// No description provided for @tutorialAiAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Analyser avec l\'IA'**
  String get tutorialAiAnalysis;

  /// No description provided for @tutorialAiAnalysisDesc.
  ///
  /// In fr, this message translates to:
  /// **'Laissez l\'IA décrypter vos tags'**
  String get tutorialAiAnalysisDesc;

  /// No description provided for @tutorialAiStep1.
  ///
  /// In fr, this message translates to:
  /// **'Scannez un tag NFC normalement'**
  String get tutorialAiStep1;

  /// No description provided for @tutorialAiStep2.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA analyse automatiquement le contenu'**
  String get tutorialAiStep2;

  /// No description provided for @tutorialAiStep3.
  ///
  /// In fr, this message translates to:
  /// **'Consultez les informations extraites'**
  String get tutorialAiStep3;

  /// No description provided for @tutorialAiStep4.
  ///
  /// In fr, this message translates to:
  /// **'Créez un modèle ou un contact si proposé'**
  String get tutorialAiStep4;

  /// No description provided for @tutorialFormatTag.
  ///
  /// In fr, this message translates to:
  /// **'Formater un tag'**
  String get tutorialFormatTag;

  /// No description provided for @tutorialFormatTagDesc.
  ///
  /// In fr, this message translates to:
  /// **'Effacez complètement la mémoire d\'un tag'**
  String get tutorialFormatTagDesc;

  /// No description provided for @tutorialFormatStep1.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans le menu \'Lire\' puis \'Opérations\''**
  String get tutorialFormatStep1;

  /// No description provided for @tutorialFormatStep2.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez \'Formater le tag\''**
  String get tutorialFormatStep2;

  /// No description provided for @tutorialFormatStep3.
  ///
  /// In fr, this message translates to:
  /// **'Approchez le tag à effacer'**
  String get tutorialFormatStep3;

  /// No description provided for @tutorialFormatStep4.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez l\'opération (irréversible)'**
  String get tutorialFormatStep4;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'bn',
        'de',
        'el',
        'en',
        'es',
        'fr',
        'hi',
        'it',
        'ja',
        'ko',
        'nl',
        'pl',
        'pt',
        'ru',
        'th',
        'tr',
        'uk',
        'ur',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'ur':
      return AppLocalizationsUr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
