import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/business_cards/domain/entities/business_card.dart';

/// Résultat de l'ajout au wallet
class WalletResult {
  final bool success;
  final String? error;

  const WalletResult({required this.success, this.error});

  factory WalletResult.success() => const WalletResult(success: true);
  factory WalletResult.failure(String error) => WalletResult(success: false, error: error);
}

/// Service pour l'intégration avec Google Wallet et Apple Wallet
class WalletService {
  WalletService._();

  static final WalletService instance = WalletService._();

  // URL de base de l'API Firebase Functions
  static const String _apiBaseUrl = 'https://us-central1-lc-nfc-pro.cloudfunctions.net'; // Firebase Functions URL - separate from main domain

  // Configuration Google Wallet API
  static const String _googleWalletIssuerId = 'YOUR_ISSUER_ID'; // Sera configuré dans Firebase
  static const String _googleWalletClassSuffix = 'cards_control_business_card';

  /// Vérifie si Google Wallet est disponible sur l'appareil
  Future<bool> isGoogleWalletAvailable() async {
    if (!Platform.isAndroid) return false;

    // Vérifier si l'app Google Wallet est installée
    final uri = Uri.parse('https://pay.google.com');
    return await canLaunchUrl(uri);
  }

  /// Vérifie si Apple Wallet est disponible sur l'appareil
  Future<bool> isAppleWalletAvailable() async {
    return Platform.isIOS;
  }

  /// Génère un JWT pour Google Wallet Generic Pass
  /// Note: En production, ce JWT devrait être généré côté serveur
  String generateGoogleWalletJwt(BusinessCard card) {
    final classId = '$_googleWalletIssuerId.$_googleWalletClassSuffix';
    final objectId = '$_googleWalletIssuerId.${card.id}';

    // Structure du Generic Pass pour Google Wallet
    final genericObject = {
      'id': objectId,
      'classId': classId,
      'genericType': 'GENERIC_TYPE_UNSPECIFIED',
      'hexBackgroundColor': card.primaryColor,
      'logo': {
        'sourceUri': {
          'uri': card.logoUrl ?? 'https://cards-control.app/assets/logo.png',
        },
      },
      'cardTitle': {
        'defaultValue': {
          'language': 'fr',
          'value': card.company ?? 'Carte de visite',
        },
      },
      'subheader': {
        'defaultValue': {
          'language': 'fr',
          'value': card.jobTitle ?? '',
        },
      },
      'header': {
        'defaultValue': {
          'language': 'fr',
          'value': card.fullName,
        },
      },
      'barcode': {
        'type': 'QR_CODE',
        'value': 'https://cards-control.app/card/${card.id}',
      },
      'textModulesData': [
        if (card.email != null)
          {
            'id': 'email',
            'header': 'Email',
            'body': card.email,
          },
        if (card.phone != null)
          {
            'id': 'phone',
            'header': 'Téléphone',
            'body': card.phone,
          },
        if (card.website != null)
          {
            'id': 'website',
            'header': 'Site web',
            'body': card.website,
          },
      ],
      'linksModuleData': {
        'uris': [
          if (card.website != null)
            {
              'uri': card.website!.startsWith('http')
                  ? card.website
                  : 'https://${card.website}',
              'description': 'Site web',
            },
          {
            'uri': 'https://cards-control.app/card/${card.id}',
            'description': 'Voir la carte complète',
          },
        ],
      },
    };

    // En production, le JWT devrait être signé avec une clé privée
    // Pour le développement, on utilise l'URL Save to Google Wallet
    final payload = {
      'iss': 'cardscontrol@cardscontrol.iam.gserviceaccount.com', // Service account email
      'aud': 'google',
      'typ': 'savetowallet',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'payload': {
        'genericObjects': [genericObject],
      },
    };

    // Note: En production, ceci devrait être un vrai JWT signé
    return base64Url.encode(utf8.encode(jsonEncode(payload)));
  }

  /// Vérifie que la carte existe dans Firestore avant l'ajout au wallet
  Future<bool> _ensureCardInFirestore(BusinessCard card) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('public_cards')
          .doc(card.id)
          .get();

      if (doc.exists) {
        debugPrint('Carte ${card.id} trouvée dans Firestore');
        return true;
      }

      // La carte n'existe pas, on la synchronise
      debugPrint('Carte ${card.id} non trouvée, synchronisation...');
      await _syncCardToFirestore(card, user.uid);
      return true;
    } catch (e) {
      debugPrint('Erreur vérification Firestore: $e');
      return false;
    }
  }

  /// Synchronise une carte vers Firestore (backup dans le wallet service)
  Future<void> _syncCardToFirestore(BusinessCard card, String userId) async {
    final firestore = FirebaseFirestore.instance;
    final cardData = {
      'cardId': card.id,
      'userId': userId,
      'firstName': card.firstName,
      'lastName': card.lastName,
      'company': card.company ?? '',
      'jobTitle': card.jobTitle ?? '',
      'email': card.email ?? '',
      'phone': card.phone ?? '',
      'mobile': card.mobile ?? '',
      'website': card.website ?? '',
      'address': card.address ?? '',
      'bio': card.bio ?? '',
      'photoUrl': card.photoUrl ?? '',
      'logoUrl': card.logoUrl ?? '',
      'primaryColor': card.primaryColor,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await firestore.collection('public_cards').doc(card.id).set(
      cardData,
      SetOptions(merge: true),
    );
  }

  /// Ouvre Google Wallet pour ajouter la carte
  Future<WalletResult> addToGoogleWallet(BusinessCard card) async {
    try {
      // Vérifier que la carte est synchronisée dans Firestore
      final isSynced = await _ensureCardInFirestore(card);
      if (!isSynced) {
        return WalletResult.failure(
          'Impossible de synchroniser la carte. Vérifiez votre connexion internet.',
        );
      }

      // Appel à l'API Firebase Functions pour générer le pass
      final url = Uri.parse(
        '$_apiBaseUrl/generateGoogleWalletPass?cardId=${card.id}',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return WalletResult.success();
      }
      return WalletResult.failure('Impossible d\'ouvrir Google Wallet');
    } catch (e) {
      debugPrint('Erreur Google Wallet: $e');
      return WalletResult.failure('Erreur: ${e.toString()}');
    }
  }

  /// Génère les données pour un Apple Wallet Pass (.pkpass)
  /// Note: Les passes Apple Wallet doivent être générés côté serveur
  Map<String, dynamic> generateAppleWalletPassData(BusinessCard card) {
    return {
      'formatVersion': 1,
      'passTypeIdentifier': 'pass.com.cardscontrol.businesscard',
      'serialNumber': card.id,
      'teamIdentifier': 'YOUR_TEAM_ID', // À remplacer
      'organizationName': 'Cards Control',
      'description': 'Carte de visite - ${card.fullName}',
      'logoText': card.company ?? 'Cards Control',
      'foregroundColor': 'rgb(255, 255, 255)',
      'backgroundColor': _hexToRgb(card.primaryColor),
      'generic': {
        'primaryFields': [
          {
            'key': 'name',
            'label': 'NOM',
            'value': card.fullName,
          },
        ],
        'secondaryFields': [
          if (card.jobTitle != null)
            {
              'key': 'title',
              'label': 'FONCTION',
              'value': card.jobTitle,
            },
          if (card.company != null)
            {
              'key': 'company',
              'label': 'ENTREPRISE',
              'value': card.company,
            },
        ],
        'auxiliaryFields': [
          if (card.email != null)
            {
              'key': 'email',
              'label': 'EMAIL',
              'value': card.email,
            },
          if (card.phone != null)
            {
              'key': 'phone',
              'label': 'TÉLÉPHONE',
              'value': card.phone,
            },
        ],
        'backFields': [
          if (card.website != null)
            {
              'key': 'website',
              'label': 'Site web',
              'value': card.website,
            },
          if (card.address != null)
            {
              'key': 'address',
              'label': 'Adresse',
              'value': card.address,
            },
          if (card.bio != null)
            {
              'key': 'bio',
              'label': 'À propos',
              'value': card.bio,
            },
        ],
      },
      'barcode': {
        'format': 'PKBarcodeFormatQR',
        'message': 'https://cards-control.app/card/${card.id}',
        'messageEncoding': 'iso-8859-1',
      },
    };
  }

  /// Ouvre le lien pour télécharger le pass Apple Wallet
  Future<WalletResult> addToAppleWallet(BusinessCard card) async {
    try {
      // Vérifier que la carte est synchronisée dans Firestore
      final isSynced = await _ensureCardInFirestore(card);
      if (!isSynced) {
        return WalletResult.failure(
          'Impossible de synchroniser la carte. Vérifiez votre connexion internet.',
        );
      }

      // Le .pkpass est généré par Firebase Functions
      final url = Uri.parse(
        '$_apiBaseUrl/generateAppleWalletPass?cardId=${card.id}',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return WalletResult.success();
      }
      return WalletResult.failure('Impossible d\'ouvrir Apple Wallet');
    } catch (e) {
      debugPrint('Erreur Apple Wallet: $e');
      return WalletResult.failure('Erreur: ${e.toString()}');
    }
  }

  /// Ajoute au wallet approprié selon la plateforme
  Future<WalletResult> addToWallet(BusinessCard card) async {
    if (Platform.isAndroid) {
      return addToGoogleWallet(card);
    } else if (Platform.isIOS) {
      return addToAppleWallet(card);
    }
    return WalletResult.failure('Plateforme non supportée');
  }

  /// Convertit une couleur hex en format RGB pour Apple Wallet
  String _hexToRgb(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      return 'rgb($r, $g, $b)';
    }
    return 'rgb(99, 102, 241)'; // Couleur par défaut
  }
}
