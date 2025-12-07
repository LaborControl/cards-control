import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/business_card.dart';

/// État des cartes de visite
class BusinessCardsState {
  final List<BusinessCard> cards;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final String? syncError;
  final Set<String> pendingSyncIds;

  const BusinessCardsState({
    this.cards = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.syncError,
    this.pendingSyncIds = const {},
  });

  BusinessCardsState copyWith({
    List<BusinessCard>? cards,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    String? syncError,
    Set<String>? pendingSyncIds,
  }) {
    return BusinessCardsState(
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      syncError: syncError,
      pendingSyncIds: pendingSyncIds ?? this.pendingSyncIds,
    );
  }
}

/// Notifier pour gérer les cartes de visite
class BusinessCardsNotifier extends StateNotifier<BusinessCardsState> {
  final Box _box;
  final Uuid _uuid = const Uuid();

  BusinessCardsNotifier(this._box) : super(const BusinessCardsState()) {
    loadCards();
  }

  /// Charge les cartes locales puis synchronise avec Firestore
  Future<void> loadCards() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cardsJson = _box.get('business_cards', defaultValue: <dynamic>[]);
      final localCards = (cardsJson as List).map((json) {
        final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(json as Map);
        return BusinessCard.fromJson(jsonMap);
      }).toList();
      localCards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = state.copyWith(cards: localCards, isLoading: false);
      // Synchronisation bidirectionnelle avec Firestore
      await _syncWithFirestore();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur: $e');
    }
  }

  /// Synchronisation bidirectionnelle avec Firestore basee sur updatedAt
  Future<void> _syncWithFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('=== SYNC CARDS START ===');
    debugPrint('User: ${user?.uid ?? "null"} - Email: ${user?.email ?? "null"}');
    if (user == null) {
      debugPrint('Sync ignoree: utilisateur non connecte');
      return;
    }

    // Debug: vérifier le token
    try {
      final token = await user.getIdToken();
      debugPrint('Token obtenu: ${token?.substring(0, 50)}...');
      final tokenResult = await user.getIdTokenResult();
      debugPrint('Token claims: ${tokenResult.claims}');
      debugPrint('Token expiration: ${tokenResult.expirationTime}');
      debugPrint('Auth time: ${tokenResult.authTime}');
    } catch (e) {
      debugPrint('Erreur token: $e');
    }
    state = state.copyWith(isSyncing: true, syncError: null);
    try {
      final firestore = FirebaseFirestore.instance;
      debugPrint('Fetching cards from: users/${user.uid}/business_cards');
      final snapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('business_cards')
          .get();
      debugPrint('Firestore: ${snapshot.docs.length} cartes trouvees pour ${user.uid}');

      // Creer une map des cartes distantes par ID
      final remoteCardsMap = <String, BusinessCard>{};
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final card = BusinessCard(
            id: doc.id,
            cardType: BusinessCardType.fromString(data['cardType']),
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
            cvUrl: data['cvUrl'],
            linkedinUrl: data['linkedinUrl'],
            primaryColor: data['primaryColor'] ?? '#6366F1',
            headerBackgroundType: data['headerBackgroundType'] ?? 'color',
            headerBackgroundValue: data['headerBackgroundValue'],
            socialLinks: data['socialLinks'] != null
                ? Map<String, String>.from(data['socialLinks'] as Map)
                : {},
            isPrimary: data['isPrimary'] ?? false,
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
          remoteCardsMap[doc.id] = card;
        } catch (e) {
          debugPrint('Erreur parsing carte ${doc.id}: $e');
        }
      }

      final mergedCards = <BusinessCard>[];
      final processedIds = <String>{};

      // Comparer et fusionner les cartes
      for (final localCard in state.cards) {
        processedIds.add(localCard.id);
        final remoteCard = remoteCardsMap[localCard.id];

        if (remoteCard == null) {
          // Carte locale uniquement -> upload vers Firestore
          mergedCards.add(localCard);
          await syncCardToFirestore(localCard);
          debugPrint('Upload carte ${localCard.id} vers Firestore');
        } else if (localCard.updatedAt.isAfter(remoteCard.updatedAt)) {
          // Local plus recent -> garder local et upload
          mergedCards.add(localCard);
          await syncCardToFirestore(localCard);
          debugPrint('Local plus recent: ${localCard.id}');
        } else if (remoteCard.updatedAt.isAfter(localCard.updatedAt)) {
          // Remote plus recent -> garder remote
          mergedCards.add(remoteCard);
          debugPrint('Remote plus recent: ${remoteCard.id}');
        } else {
          // Meme date -> garder local
          mergedCards.add(localCard);
        }
      }

      // Ajouter les cartes qui n'existent que sur Firestore
      for (final entry in remoteCardsMap.entries) {
        if (!processedIds.contains(entry.key)) {
          mergedCards.add(entry.value);
          debugPrint('Nouvelle carte depuis Firestore: ${entry.key}');
        }
      }

      // Trier et sauvegarder
      mergedCards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      await _saveCards(mergedCards);
      state = state.copyWith(cards: mergedCards, isSyncing: false);
      debugPrint('Sync terminee: ${mergedCards.length} cartes');
    } catch (e) {
      debugPrint('Erreur sync Firestore: $e');
      state = state.copyWith(isSyncing: false, syncError: 'Erreur sync: $e');
    }
  }

  /// Force la synchronisation avec Firestore
  /// Synchronise TOUTES les cartes vers public_cards
  Future<void> forceSyncAllCards() async {
    await _syncWithFirestore();

    // Synchroniser toutes les cartes vers public_cards
    debugPrint('=== SYNC ALL TO PUBLIC_CARDS ===');
    for (final card in state.cards) {
      await syncCardToFirestore(card);
    }
    debugPrint('Toutes les cartes ont été synchronisées vers public_cards');
  }

  /// Force le rechargement depuis Firestore
  Future<void> refreshFromFirestore() async {
    await _syncWithFirestore();
  }

  /// Crée une nouvelle carte
  Future<BusinessCard> createCard({
    required String firstName,
    required String lastName,
    BusinessCardType cardType = BusinessCardType.professional,
    String? company,
    String? jobTitle,
    String? email,
    String? phone,
    String? mobile,
    String? website,
    String? address,
    String? bio,
    String? linkedinUrl,
    Map<String, String>? socialLinks,
    String? templateId,
    String? primaryColor,
    String? photoUrl,
    String? logoUrl,
    String? cvUrl,
    String? headerBackgroundType,
    String? headerBackgroundValue,
  }) async {
    final now = DateTime.now();
    final card = BusinessCard(
      id: _uuid.v4(),
      cardType: cardType,
      firstName: firstName,
      lastName: lastName,
      company: company,
      jobTitle: jobTitle,
      email: email,
      phone: phone,
      mobile: mobile,
      website: website,
      address: address,
      bio: bio,
      linkedinUrl: linkedinUrl,
      socialLinks: socialLinks ?? {},
      templateId: templateId,
      primaryColor: primaryColor ?? '#6366F1',
      photoUrl: photoUrl,
      logoUrl: logoUrl,
      cvUrl: cvUrl,
      headerBackgroundType: headerBackgroundType ?? 'color',
      headerBackgroundValue: headerBackgroundValue,
      createdAt: now,
      updatedAt: now,
    );

    final updatedCards = [...state.cards, card];
    await _saveCards(updatedCards);

    // Synchroniser avec Firestore pour le wallet
    syncCardToFirestore(card);

    state = state.copyWith(cards: updatedCards);

    return card;
  }

  /// Met à jour une carte existante
  Future<void> updateCard(BusinessCard card) async {
    final updatedCard = card.copyWith(updatedAt: DateTime.now());
    final updatedCards = state.cards.map((c) {
      return c.id == card.id ? updatedCard : c;
    }).toList();

    await _saveCards(updatedCards);

    // Synchroniser avec Firestore pour le wallet
    syncCardToFirestore(updatedCard);

    state = state.copyWith(cards: updatedCards);
  }

  /// Supprime une carte
  Future<void> deleteCard(String cardId) async {
    final updatedCards = state.cards.where((c) => c.id != cardId).toList();
    await _saveCards(updatedCards);

    // Supprimer de Firestore
    _deleteCardFromFirestore(cardId);

    state = state.copyWith(cards: updatedCards);
  }

  /// Duplique une carte
  Future<BusinessCard> duplicateCard(String cardId) async {
    final original = state.cards.firstWhere((c) => c.id == cardId);
    final now = DateTime.now();

    final duplicate = BusinessCard(
      id: _uuid.v4(),
      firstName: original.firstName,
      lastName: original.lastName,
      company: original.company,
      jobTitle: original.jobTitle,
      email: original.email,
      phone: original.phone,
      website: original.website,
      address: original.address,
      bio: original.bio,
      socialLinks: Map.from(original.socialLinks),
      templateId: original.templateId,
      primaryColor: original.primaryColor,
      photoUrl: original.photoUrl,
      createdAt: now,
      updatedAt: now,
    );

    final updatedCards = [...state.cards, duplicate];
    await _saveCards(updatedCards);

    // Synchroniser avec Firestore pour le wallet
    syncCardToFirestore(duplicate);

    state = state.copyWith(cards: updatedCards);

    return duplicate;
  }

  /// Définit une carte comme principale
  Future<void> setAsPrimary(String cardId) async {
    final updatedCards = state.cards.map((c) {
      return c.copyWith(isPrimary: c.id == cardId);
    }).toList();

    await _saveCards(updatedCards);
    state = state.copyWith(cards: updatedCards);
  }

  /// Enregistre un partage
  Future<void> recordShare(String cardId, String method) async {
    final card = state.cards.firstWhere((c) => c.id == cardId);
    final updatedAnalytics = card.analytics.copyWith(
      totalShares: card.analytics.totalShares + 1,
      lastSharedAt: DateTime.now(),
      sharesByMethod: {
        ...card.analytics.sharesByMethod,
        method: (card.analytics.sharesByMethod[method] ?? 0) + 1,
      },
    );

    final updatedCard = card.copyWith(analytics: updatedAnalytics);
    await updateCard(updatedCard);
  }

  /// Enregistre une vue
  Future<void> recordView(String cardId) async {
    final card = state.cards.firstWhere((c) => c.id == cardId);
    final updatedAnalytics = card.analytics.copyWith(
      totalViews: card.analytics.totalViews + 1,
    );

    final updatedCard = card.copyWith(analytics: updatedAnalytics);
    await updateCard(updatedCard);
  }

  /// Sauvegarde les cartes dans le stockage local
  Future<void> _saveCards(List<BusinessCard> cards) async {
    final cardsJson = cards.map((c) => c.toJson()).toList();
    await _box.put('business_cards', cardsJson);
  }

  /// Synchronise une carte avec Firestore pour le wallet
  /// Avec retry automatique en cas d'erreur réseau
  Future<bool> syncCardToFirestore(BusinessCard card, {int retryCount = 0}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('Sync ignorée: utilisateur non connecté');
      return false;
    }

    final firestore = FirebaseFirestore.instance;
    const maxRetries = 3;

    // Ajouter aux cartes en attente de sync
    state = state.copyWith(
      pendingSyncIds: {...state.pendingSyncIds, card.id},
    );

    try {
      final cardData = {
        'cardType': card.cardType.value,
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
        'cvUrl': card.cvUrl ?? '',
        'linkedinUrl': card.linkedinUrl ?? '',
        'primaryColor': card.primaryColor,
        'headerBackgroundType': card.headerBackgroundType,
        'headerBackgroundValue': card.headerBackgroundValue ?? '',
        'socialLinks': card.socialLinks,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Sauvegarder dans la collection de l'utilisateur
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('business_cards')
          .doc(card.id)
          .set(cardData, SetOptions(merge: true));

      // Aussi sauvegarder dans public_cards pour accès rapide
      await firestore.collection('public_cards').doc(card.id).set({
        'cardId': card.id,
        'userId': user.uid,
        ...cardData,
      }, SetOptions(merge: true));

      // Retirer des cartes en attente
      final updatedPending = Set<String>.from(state.pendingSyncIds)..remove(card.id);
      state = state.copyWith(
        pendingSyncIds: updatedPending,
        syncError: null,
      );

      debugPrint('Carte ${card.id} synchronisée avec succès');
      return true;
    } catch (e) {
      debugPrint('Erreur sync Firestore (tentative ${retryCount + 1}/$maxRetries): $e');

      // Retry avec délai exponentiel
      if (retryCount < maxRetries - 1) {
        final delay = Duration(seconds: (retryCount + 1) * 2);
        debugPrint('Nouvelle tentative dans ${delay.inSeconds}s...');
        await Future.delayed(delay);
        return syncCardToFirestore(card, retryCount: retryCount + 1);
      }

      // Après toutes les tentatives, garder en pending et afficher l'erreur
      state = state.copyWith(
        syncError: 'Erreur de synchronisation. Vérifiez votre connexion internet.',
      );
      return false;
    }
  }

  /// Supprime une carte de Firestore
  Future<void> _deleteCardFromFirestore(String cardId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('business_cards')
          .doc(cardId)
          .delete();

      await firestore.collection('public_cards').doc(cardId).delete();
    } catch (_) {
      // Ignore errors
    }
  }
}

/// Provider pour la box Hive des cartes
final businessCardsBoxProvider = Provider<Box>((ref) {
  return Hive.box('business_cards');
});

/// Provider principal pour les cartes de visite
final businessCardsProvider =
    StateNotifierProvider<BusinessCardsNotifier, BusinessCardsState>((ref) {
  final box = ref.watch(businessCardsBoxProvider);
  return BusinessCardsNotifier(box);
});

/// Provider pour la carte principale
final primaryCardProvider = Provider<BusinessCard?>((ref) {
  final state = ref.watch(businessCardsProvider);
  try {
    return state.cards.firstWhere((c) => c.isPrimary);
  } catch (_) {
    return state.cards.isNotEmpty ? state.cards.first : null;
  }
});

/// Provider pour une carte spécifique
final cardByIdProvider = Provider.family<BusinessCard?, String>((ref, id) {
  final state = ref.watch(businessCardsProvider);
  try {
    return state.cards.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});

/// Provider pour les statistiques globales
final cardsStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final state = ref.watch(businessCardsProvider);

  int totalShares = 0;
  int totalViews = 0;
  int totalContacts = 0;

  for (final card in state.cards) {
    totalShares += card.analytics.totalShares;
    totalViews += card.analytics.totalViews;
    totalContacts += card.analytics.contactsSaved;
  }

  return {
    'totalCards': state.cards.length,
    'totalShares': totalShares,
    'totalViews': totalViews,
    'totalContacts': totalContacts,
  };
});

/// Provider pour l'état de synchronisation
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final state = ref.watch(businessCardsProvider);
  return SyncStatus(
    isSyncing: state.isSyncing,
    hasPendingSync: state.pendingSyncIds.isNotEmpty,
    pendingCount: state.pendingSyncIds.length,
    error: state.syncError,
  );
});

/// État de synchronisation
class SyncStatus {
  final bool isSyncing;
  final bool hasPendingSync;
  final int pendingCount;
  final String? error;

  const SyncStatus({
    this.isSyncing = false,
    this.hasPendingSync = false,
    this.pendingCount = 0,
    this.error,
  });
}

/// Provider pour récupérer une carte publique par ID (sans authentification)
/// Utilisé pour lire les cartes partagées via NFC/QR
final publicCardProvider = FutureProvider.family<BusinessCard?, String>((ref, cardId) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore.collection('public_cards').doc(cardId).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    return BusinessCard(
      id: cardId,
      cardType: BusinessCardType.fromString(data['cardType']),
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
      cvUrl: data['cvUrl'],
      linkedinUrl: data['linkedinUrl'],
      primaryColor: data['primaryColor'] ?? '#6366F1',
      headerBackgroundType: data['headerBackgroundType'] ?? 'color',
      headerBackgroundValue: data['headerBackgroundValue'],
      socialLinks: data['socialLinks'] != null
          ? Map<String, String>.from(data['socialLinks'] as Map)
          : {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  } catch (e) {
    debugPrint('Erreur récupération carte publique $cardId: $e');
    return null;
  }
});
