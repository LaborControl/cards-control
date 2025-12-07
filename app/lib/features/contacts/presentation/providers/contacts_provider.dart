import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/contact.dart';

/// État des contacts
class ContactsState {
  final List<Contact> contacts;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final String? syncError;
  final Set<String> pendingSyncIds;

  const ContactsState({
    this.contacts = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.syncError,
    this.pendingSyncIds = const {},
  });

  ContactsState copyWith({
    List<Contact>? contacts,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    String? syncError,
    Set<String>? pendingSyncIds,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      syncError: syncError,
      pendingSyncIds: pendingSyncIds ?? this.pendingSyncIds,
    );
  }
}

/// Notifier pour gérer les contacts
class ContactsNotifier extends StateNotifier<ContactsState> {
  final Box _box;
  final Uuid _uuid = const Uuid();

  ContactsNotifier(this._box) : super(const ContactsState()) {
    loadContacts();
  }

  /// Charge les contacts locaux puis synchronise avec Firestore
  Future<void> loadContacts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final contactsJson = _box.get('contacts', defaultValue: <dynamic>[]);
      final localContacts = (contactsJson as List).map((json) {
        final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(json as Map);
        return Contact.fromJson(jsonMap);
      }).toList();
      localContacts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = state.copyWith(contacts: localContacts, isLoading: false);
      // Synchronisation bidirectionnelle avec Firestore
      await _syncWithFirestore();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur: $e');
    }
  }

  /// Synchronisation bidirectionnelle avec Firestore basée sur updatedAt
  Future<void> _syncWithFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('=== SYNC CONTACTS START ===');
    debugPrint('User: ${user?.uid ?? "null"} - Email: ${user?.email ?? "null"}');
    if (user == null) {
      debugPrint('Sync contacts ignorée: utilisateur non connecté');
      return;
    }
    state = state.copyWith(isSyncing: true, syncError: null);
    try {
      final firestore = FirebaseFirestore.instance;
      debugPrint('Fetching contacts from: users/${user.uid}/scanned_contacts');
      // Force fetch from server to avoid cached permission denied errors
      final snapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('scanned_contacts')
          .get(const GetOptions(source: Source.server));
      debugPrint('Firestore: ${snapshot.docs.length} contacts trouvés pour ${user.uid}');

      // Créer une map des contacts distants par ID
      final remoteContactsMap = <String, Contact>{};
      for (final doc in snapshot.docs) {
        try {
          final contact = Contact.fromFirestore(doc);
          remoteContactsMap[doc.id] = contact;
        } catch (e) {
          debugPrint('Erreur parsing contact ${doc.id}: $e');
        }
      }

      final mergedContacts = <Contact>[];
      final processedIds = <String>{};

      // Comparer et fusionner les contacts
      for (final localContact in state.contacts) {
        processedIds.add(localContact.id);
        final remoteContact = remoteContactsMap[localContact.id];

        if (remoteContact == null) {
          // Contact local uniquement -> upload vers Firestore
          mergedContacts.add(localContact);
          await syncContactToFirestore(localContact);
          debugPrint('Upload contact ${localContact.id} vers Firestore');
        } else if (localContact.updatedAt.isAfter(remoteContact.updatedAt)) {
          // Local plus récent -> garder local et upload
          mergedContacts.add(localContact);
          await syncContactToFirestore(localContact);
          debugPrint('Local plus récent: ${localContact.id}');
        } else if (remoteContact.updatedAt.isAfter(localContact.updatedAt)) {
          // Remote plus récent -> garder remote
          mergedContacts.add(remoteContact);
          debugPrint('Remote plus récent: ${remoteContact.id}');
        } else {
          // Même date -> garder local
          mergedContacts.add(localContact);
        }
      }

      // Ajouter les contacts qui n'existent que sur Firestore
      for (final entry in remoteContactsMap.entries) {
        if (!processedIds.contains(entry.key)) {
          mergedContacts.add(entry.value);
          debugPrint('Nouveau contact depuis Firestore: ${entry.key}');
        }
      }

      // Trier et sauvegarder
      mergedContacts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      await _saveContacts(mergedContacts);
      state = state.copyWith(contacts: mergedContacts, isSyncing: false);
      debugPrint('Sync contacts terminée: ${mergedContacts.length} contacts');
    } catch (e) {
      debugPrint('Erreur sync contacts Firestore: $e');
      state = state.copyWith(isSyncing: false, syncError: 'Erreur sync: $e');
    }
  }

  /// Force la synchronisation avec Firestore
  Future<void> forceSyncAllContacts() async {
    await _syncWithFirestore();
  }

  /// Crée un nouveau contact
  Future<Contact> createContact({
    required String firstName,
    required String lastName,
    String? company,
    String? jobTitle,
    String? email,
    String? phone,
    String? mobile,
    String? website,
    String? address,
    String? notes,
    String? photoUrl,
    String? companyLogoUrl,
    Map<String, String>? socialLinks,
    String source = 'manual',
    String category = 'none',
  }) async {
    final now = DateTime.now();
    final contact = Contact(
      id: _uuid.v4(),
      firstName: firstName,
      lastName: lastName,
      company: company,
      jobTitle: jobTitle,
      email: email,
      phone: phone,
      mobile: mobile,
      website: website,
      address: address,
      notes: notes,
      photoUrl: photoUrl,
      companyLogoUrl: companyLogoUrl,
      socialLinks: socialLinks ?? {},
      source: source,
      category: category,
      createdAt: now,
      updatedAt: now,
    );

    final updatedContacts = [...state.contacts, contact];
    await _saveContacts(updatedContacts);
    syncContactToFirestore(contact);
    state = state.copyWith(contacts: updatedContacts);

    return contact;
  }

  /// Met à jour un contact existant
  Future<void> updateContact(Contact contact) async {
    final updatedContact = contact.copyWith(updatedAt: DateTime.now());
    final updatedContacts = state.contacts.map((c) {
      return c.id == contact.id ? updatedContact : c;
    }).toList();

    await _saveContacts(updatedContacts);
    syncContactToFirestore(updatedContact);
    state = state.copyWith(contacts: updatedContacts);
  }

  /// Supprime un contact
  Future<void> deleteContact(String contactId) async {
    final updatedContacts = state.contacts.where((c) => c.id != contactId).toList();
    await _saveContacts(updatedContacts);
    _deleteContactFromFirestore(contactId);
    state = state.copyWith(contacts: updatedContacts);
  }

  /// Sauvegarde les contacts dans le stockage local
  Future<void> _saveContacts(List<Contact> contacts) async {
    final contactsJson = contacts.map((c) => c.toJson()).toList();
    await _box.put('contacts', contactsJson);
  }

  /// Synchronise un contact avec Firestore
  Future<bool> syncContactToFirestore(Contact contact, {int retryCount = 0}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('Sync ignorée: utilisateur non connecté');
      return false;
    }

    final firestore = FirebaseFirestore.instance;
    const maxRetries = 3;

    state = state.copyWith(
      pendingSyncIds: {...state.pendingSyncIds, contact.id},
    );

    try {
      final contactData = {
        'firstName': contact.firstName,
        'lastName': contact.lastName,
        'company': contact.company ?? '',
        'jobTitle': contact.jobTitle ?? '',
        'email': contact.email ?? '',
        'phone': contact.phone ?? '',
        'mobile': contact.mobile ?? '',
        'website': contact.website ?? '',
        'address': contact.address ?? '',
        'notes': contact.notes ?? '',
        'photoUrl': contact.photoUrl ?? '',
        'companyLogoUrl': contact.companyLogoUrl ?? '',
        'socialLinks': contact.socialLinks,
        'source': contact.source,
        'category': contact.category,
        'createdAt': Timestamp.fromDate(contact.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('scanned_contacts')
          .doc(contact.id)
          .set(contactData, SetOptions(merge: true));

      final updatedPending = Set<String>.from(state.pendingSyncIds)..remove(contact.id);
      state = state.copyWith(
        pendingSyncIds: updatedPending,
        syncError: null,
      );

      debugPrint('Contact ${contact.id} synchronisé avec succès');
      return true;
    } catch (e) {
      debugPrint('Erreur sync contact (tentative ${retryCount + 1}/$maxRetries): $e');

      if (retryCount < maxRetries - 1) {
        final delay = Duration(seconds: (retryCount + 1) * 2);
        await Future.delayed(delay);
        return syncContactToFirestore(contact, retryCount: retryCount + 1);
      }

      state = state.copyWith(
        syncError: 'Erreur de synchronisation. Vérifiez votre connexion internet.',
      );
      return false;
    }
  }

  /// Supprime un contact de Firestore
  Future<void> _deleteContactFromFirestore(String contactId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('scanned_contacts')
          .doc(contactId)
          .delete();
    } catch (_) {
      // Ignore errors
    }
  }
}

/// Provider pour la box Hive des contacts
final contactsBoxProvider = Provider<Box>((ref) {
  return Hive.box('contacts');
});

/// Provider principal pour les contacts
final contactsProvider =
    StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  final box = ref.watch(contactsBoxProvider);
  return ContactsNotifier(box);
});

/// Provider pour un contact spécifique
final contactByIdProvider = Provider.family<Contact?, String>((ref, id) {
  final state = ref.watch(contactsProvider);
  try {
    return state.contacts.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});

/// Provider pour l'état de synchronisation des contacts
final contactsSyncStatusProvider = Provider<ContactsSyncStatus>((ref) {
  final state = ref.watch(contactsProvider);
  return ContactsSyncStatus(
    isSyncing: state.isSyncing,
    hasPendingSync: state.pendingSyncIds.isNotEmpty,
    pendingCount: state.pendingSyncIds.length,
    error: state.syncError,
  );
});

/// État de synchronisation des contacts
class ContactsSyncStatus {
  final bool isSyncing;
  final bool hasPendingSync;
  final int pendingCount;
  final String? error;

  const ContactsSyncStatus({
    this.isSyncing = false,
    this.hasPendingSync = false,
    this.pendingCount = 0,
    this.error,
  });
}

/// Provider pour les catégories de contacts (chargées depuis Firestore)
final contactCategoriesProvider = StateNotifierProvider<ContactCategoriesNotifier, List<ContactCategory>>((ref) {
  return ContactCategoriesNotifier();
});

/// Notifier pour gérer les catégories de contacts
class ContactCategoriesNotifier extends StateNotifier<List<ContactCategory>> {
  ContactCategoriesNotifier() : super(ContactCategory.defaultCategories) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = ContactCategory.defaultCategories;
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final settingsDoc = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('preferences')
          .get();

      if (settingsDoc.exists && settingsDoc.data()?['contactCategories'] != null) {
        final categoriesData = settingsDoc.data()!['contactCategories'] as List<dynamic>;
        state = categoriesData
            .map((c) => ContactCategory.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList();
        debugPrint('Catégories chargées depuis Firestore: ${state.length}');
      } else {
        state = ContactCategory.defaultCategories;
        debugPrint('Utilisation des catégories par défaut');
      }
    } catch (e) {
      debugPrint('Erreur chargement catégories: $e');
      state = ContactCategory.defaultCategories;
    }
  }

  /// Recharge les catégories depuis Firestore
  Future<void> refresh() async {
    await _loadCategories();
  }
}

/// Provider pour le filtre de catégorie sélectionné
final selectedCategoryFilterProvider = StateProvider<ContactCategory?>((ref) => null);

/// Provider pour les contacts filtrés par catégorie
final filteredContactsProvider = Provider<List<Contact>>((ref) {
  final state = ref.watch(contactsProvider);
  final selectedCategory = ref.watch(selectedCategoryFilterProvider);

  if (selectedCategory == null || selectedCategory == ContactCategory.none) {
    return state.contacts;
  }

  return state.contacts.where((c) => c.category == selectedCategory.id).toList();
});

/// Provider pour le nombre de contacts par catégorie
final contactsCountByCategoryProvider = Provider<Map<ContactCategory, int>>((ref) {
  final state = ref.watch(contactsProvider);
  final categories = ref.watch(contactCategoriesProvider);
  final counts = <ContactCategory, int>{};

  // "Tous" les contacts
  counts[ContactCategory.none] = state.contacts.length;

  for (final category in categories) {
    counts[category] = state.contacts.where((c) => c.category == category.id).length;
  }

  return counts;
});
