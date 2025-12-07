import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../domain/entities/business_card.dart';

/// Repository Firebase pour les cartes de visite
///
/// Gère la persistance des cartes dans Firestore et le stockage
/// des images dans Firebase Storage.
class FirebaseCardsRepository {
  static final FirebaseCardsRepository instance = FirebaseCardsRepository._();
  FirebaseCardsRepository._();

  final FirestoreService _firestore = FirestoreService.instance;
  final FirebaseStorageService _storage = FirebaseStorageService.instance;
  final FirebaseAuthService _auth = FirebaseAuthService.instance;

  static const String _collection = 'business_cards';
  static const String _analyticsCollection = 'card_analytics';

  /// ID de l'utilisateur actuel
  String? get _userId => _auth.currentUser?.uid;

  /// Référence à la collection des cartes de l'utilisateur
  CollectionReference<Map<String, dynamic>> get _userCardsRef {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users/$_userId/$_collection');
  }

  // ==================== CRUD Operations ====================

  /// Crée une nouvelle carte
  Future<BusinessCard> createCard(BusinessCard card) async {
    if (_userId == null) throw Exception('User not authenticated');

    final data = card.toJson();
    data['userId'] = _userId;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    final docRef = await _userCardsRef.add(data);

    // Créer aussi un document public pour le partage
    await _firestore.set('public_cards', docRef.id, {
      'cardId': docRef.id,
      'userId': _userId,
      'firstName': card.firstName,
      'lastName': card.lastName,
      'company': card.company,
      'jobTitle': card.jobTitle,
      'email': card.email,
      'phone': card.phone,
      'website': card.website,
      'photoUrl': card.photoUrl,
      'primaryColor': card.primaryColor,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return card.copyWith();
  }

  /// Met à jour une carte existante
  Future<void> updateCard(BusinessCard card) async {
    if (_userId == null) throw Exception('User not authenticated');

    final data = card.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _userCardsRef.doc(card.id).update(data);

    // Mettre à jour aussi le document public
    await _firestore.set('public_cards', card.id, {
      'cardId': card.id,
      'userId': _userId,
      'firstName': card.firstName,
      'lastName': card.lastName,
      'company': card.company,
      'jobTitle': card.jobTitle,
      'email': card.email,
      'phone': card.phone,
      'website': card.website,
      'photoUrl': card.photoUrl,
      'primaryColor': card.primaryColor,
      'updatedAt': FieldValue.serverTimestamp(),
    }, merge: true);
  }

  /// Supprime une carte
  Future<void> deleteCard(String cardId) async {
    if (_userId == null) throw Exception('User not authenticated');

    // Supprimer les images associées
    try {
      await _storage.deleteFile('users/$_userId/cards/$cardId/photo');
    } catch (_) {}
    try {
      await _storage.deleteFile('users/$_userId/cards/$cardId/logo');
    } catch (_) {}

    // Supprimer le document public
    await _firestore.delete('public_cards', cardId);

    // Supprimer les analytics
    final analyticsSnapshot = await _firestore
        .collection('users/$_userId/$_analyticsCollection')
        .where('cardId', isEqualTo: cardId)
        .get();
    for (final doc in analyticsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Supprimer la carte
    await _userCardsRef.doc(cardId).delete();
  }

  /// Récupère une carte par ID
  Future<BusinessCard?> getCard(String cardId) async {
    if (_userId == null) throw Exception('User not authenticated');

    final doc = await _userCardsRef.doc(cardId).get();
    if (!doc.exists) return null;

    return _cardFromDoc(doc);
  }

  /// Récupère une carte publique par ID (sans authentification)
  Future<BusinessCard?> getPublicCard(String cardId) async {
    final doc = await _firestore.get('public_cards', cardId);
    if (!doc.exists) return null;

    final data = doc.data()!;
    final now = DateTime.now();
    return BusinessCard(
      id: cardId,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      company: data['company'],
      jobTitle: data['jobTitle'],
      email: data['email'],
      phone: data['phone'],
      website: data['website'],
      photoUrl: data['photoUrl'],
      primaryColor: data['primaryColor'] ?? '#6366F1',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Récupère toutes les cartes de l'utilisateur
  Future<List<BusinessCard>> getAllCards() async {
    if (_userId == null) return [];

    final snapshot = await _userCardsRef
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(_cardFromDoc).toList();
  }

  /// Stream des cartes de l'utilisateur
  Stream<List<BusinessCard>> watchCards() {
    if (_userId == null) return Stream.value([]);

    return _userCardsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_cardFromDoc).toList());
  }

  /// Stream d'une carte spécifique
  Stream<BusinessCard?> watchCard(String cardId) {
    if (_userId == null) return Stream.value(null);

    return _userCardsRef.doc(cardId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _cardFromDoc(doc);
    });
  }

  // ==================== Images ====================

  /// Upload une photo de profil
  Future<String> uploadPhoto(String cardId, File file) async {
    if (_userId == null) throw Exception('User not authenticated');

    return await _storage.uploadFile(
      path: 'users/$_userId/cards/$cardId/photo',
      file: file,
      metadata: {'contentType': 'image/jpeg'},
    );
  }

  /// Upload un logo
  Future<String> uploadLogo(String cardId, File file) async {
    if (_userId == null) throw Exception('User not authenticated');

    return await _storage.uploadFile(
      path: 'users/$_userId/cards/$cardId/logo',
      file: file,
      metadata: {'contentType': 'image/png'},
    );
  }

  // ==================== Analytics ====================

  /// Enregistre un partage
  Future<void> recordShare(String cardId, String method) async {
    if (_userId == null) return;

    await _firestore.create('users/$_userId/$_analyticsCollection', {
      'cardId': cardId,
      'type': 'share',
      'method': method,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Incrémenter le compteur de partages
    await _userCardsRef.doc(cardId).update({
      'analytics.shareCount': FieldValue.increment(1),
      'analytics.lastSharedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Enregistre une vue
  Future<void> recordView(String cardId, {String? source}) async {
    // Les vues peuvent être enregistrées sans authentification
    await _firestore.create('card_views', {
      'cardId': cardId,
      'source': source,
      'timestamp': FieldValue.serverTimestamp(),
      'userAgent': Platform.operatingSystem,
    });

    // Incrémenter le compteur de vues (via Cloud Function en production)
    try {
      await FirebaseFirestore.instance
          .collection('public_cards')
          .doc(cardId)
          .update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  /// Récupère les statistiques d'une carte
  Future<CardAnalytics> getCardAnalytics(String cardId) async {
    if (_userId == null) return const CardAnalytics();

    final doc = await _userCardsRef.doc(cardId).get();
    if (!doc.exists) return const CardAnalytics();

    final data = doc.data()!;
    final analyticsRaw = data['analytics'];
    final analyticsData = analyticsRaw != null
        ? Map<String, dynamic>.from(analyticsRaw as Map)
        : <String, dynamic>{};

    return CardAnalytics(
      totalViews: analyticsData['totalViews'] ?? analyticsData['viewCount'] ?? 0,
      totalShares: analyticsData['totalShares'] ?? analyticsData['shareCount'] ?? 0,
      contactsSaved: analyticsData['contactsSaved'] ?? analyticsData['saveCount'] ?? 0,
      lastSharedAt: (analyticsData['lastSharedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Stream des statistiques
  Stream<CardAnalytics> watchCardAnalytics(String cardId) {
    if (_userId == null) return Stream.value(const CardAnalytics());

    return _userCardsRef.doc(cardId).snapshots().map((doc) {
      if (!doc.exists) return const CardAnalytics();

      final data = doc.data()!;
      final analyticsRaw = data['analytics'];
      final analyticsData = analyticsRaw != null
          ? Map<String, dynamic>.from(analyticsRaw as Map)
          : <String, dynamic>{};

      return CardAnalytics(
        totalViews: analyticsData['totalViews'] ?? analyticsData['viewCount'] ?? 0,
        totalShares: analyticsData['totalShares'] ?? analyticsData['shareCount'] ?? 0,
        contactsSaved: analyticsData['contactsSaved'] ?? analyticsData['saveCount'] ?? 0,
        lastSharedAt: (analyticsData['lastSharedAt'] as Timestamp?)?.toDate(),
      );
    });
  }

  // ==================== Helpers ====================

  BusinessCard _cardFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final analyticsRaw = data['analytics'];
    final analyticsData = analyticsRaw != null
        ? Map<String, dynamic>.from(analyticsRaw as Map)
        : <String, dynamic>{};

    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.parse(data['createdAt'] as String);
    } else {
      createdAt = DateTime.now();
    }

    DateTime updatedAt;
    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    } else if (data['updatedAt'] is String) {
      updatedAt = DateTime.parse(data['updatedAt'] as String);
    } else {
      updatedAt = createdAt;
    }

    return BusinessCard(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      company: data['company'],
      jobTitle: data['jobTitle'],
      email: data['email'],
      phone: data['phone'],
      mobile: data['mobile'],
      website: data['website'],
      address: data['address'],
      bio: data['bio'],
      photoUrl: data['photoUrl'],
      logoUrl: data['logoUrl'],
      primaryColor: data['primaryColor'] ?? '#6366F1',
      socialLinks: data['socialLinks'] != null
          ? Map<String, String>.from(data['socialLinks'] as Map)
          : const {},
      isPrimary: data['isPrimary'] ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      analytics: CardAnalytics(
        totalViews: analyticsData['totalViews'] ?? analyticsData['viewCount'] ?? 0,
        totalShares: analyticsData['totalShares'] ?? analyticsData['shareCount'] ?? 0,
        contactsSaved: analyticsData['contactsSaved'] ?? analyticsData['saveCount'] ?? 0,
        lastSharedAt: (analyticsData['lastSharedAt'] as Timestamp?)?.toDate(),
      ),
    );
  }
}

/// Repository pour synchroniser les données locales et distantes
class SyncedCardsRepository {
  static final SyncedCardsRepository instance = SyncedCardsRepository._();
  SyncedCardsRepository._();

  final FirebaseCardsRepository _remote = FirebaseCardsRepository.instance;
  final FirebaseAuthService _auth = FirebaseAuthService.instance;

  bool get isOnline => _auth.isAuthenticated;

  /// Synchronise les cartes locales avec Firebase
  Future<void> sync(List<BusinessCard> localCards) async {
    if (!isOnline) return;

    final remoteCards = await _remote.getAllCards();
    final remoteCardIds = remoteCards.map((c) => c.id).toSet();

    // Upload les cartes locales qui n'existent pas sur Firebase
    for (final card in localCards) {
      if (!remoteCardIds.contains(card.id)) {
        await _remote.createCard(card);
      }
    }
  }

  /// Récupère les cartes (locales ou distantes selon la connexion)
  Future<List<BusinessCard>> getCards() async {
    if (!isOnline) return [];
    return await _remote.getAllCards();
  }
}
