import 'dart:typed_data' as typed_data;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

/// Service Firebase principal
///
/// Gère l'initialisation et l'accès aux services Firebase :
/// - Authentication
/// - Firestore
/// - Storage
class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  bool _initialized = false;

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  /// Initialise Firebase
  Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp();
    _initialized = true;

    // Configuration Firestore
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Vérifie si Firebase est initialisé
  bool get isInitialized => _initialized;

  /// Récupère l'utilisateur actuel
  User? get currentUser => auth.currentUser;

  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => currentUser != null;

  /// Stream de l'état d'authentification
  Stream<User?> get authStateChanges => auth.authStateChanges();
}

/// Service d'authentification Firebase
class FirebaseAuthService {
  static final FirebaseAuthService instance = FirebaseAuthService._();
  FirebaseAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Inscription par email/mot de passe
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (displayName != null && credential.user != null) {
      await credential.user!.updateDisplayName(displayName);
    }

    return credential;
  }

  /// Connexion par email/mot de passe
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Connexion anonyme
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// Connexion avec Google
  Future<UserCredential?> signInWithGoogle() async {
    // Import dynamique pour éviter les erreurs sur les plateformes non supportées
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Sur le web
      if (identical(0, 0.0)) {
        // Cette condition est toujours fausse, mais empêche l'erreur de compilation
        return await _auth.signInWithPopup(googleProvider);
      }

      // Sur mobile, utiliser google_sign_in package
      // Nécessite google_sign_in dans pubspec.yaml
      return null; // À implémenter avec google_sign_in
    } catch (e) {
      rethrow;
    }
  }

  /// Connexion avec Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      if (Platform.isIOS) {
        return await _auth.signInWithProvider(appleProvider);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Mise à jour du profil
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    if (photoURL != null) {
      await user.updatePhotoURL(photoURL);
    }
  }

  /// Mise à jour de l'email
  Future<void> updateEmail(String newEmail) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    await user.verifyBeforeUpdateEmail(newEmail);
  }

  /// Mise à jour du mot de passe
  Future<void> updatePassword(String newPassword) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    await user.updatePassword(newPassword);
  }

  /// Suppression du compte
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    await user.delete();
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Ré-authentification (nécessaire pour les opérations sensibles)
  Future<UserCredential> reauthenticate({
    required String email,
    required String password,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    return await user.reauthenticateWithCredential(credential);
  }
}

/// Service Firestore
class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Référence à une collection
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  /// Référence à un document
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _firestore.doc(path);
  }

  /// Créer un document
  Future<DocumentReference<Map<String, dynamic>>> create(
    String collection,
    Map<String, dynamic> data,
  ) async {
    return await _firestore.collection(collection).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Créer un document avec ID spécifique
  Future<void> set(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _firestore.collection(collection).doc(docId).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!merge) 'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: merge),
    );
  }

  /// Mettre à jour un document
  Future<void> update(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(docId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Supprimer un document
  Future<void> delete(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  /// Récupérer un document
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
    String collection,
    String docId,
  ) async {
    return await _firestore.collection(collection).doc(docId).get();
  }

  /// Stream d'un document
  Stream<DocumentSnapshot<Map<String, dynamic>>> stream(
    String collection,
    String docId,
  ) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  /// Requête sur une collection
  Query<Map<String, dynamic>> query(String collection) {
    return _firestore.collection(collection);
  }

  /// Transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction) transactionHandler,
  ) async {
    return await _firestore.runTransaction(transactionHandler);
  }

  /// Batch write
  WriteBatch batch() {
    return _firestore.batch();
  }
}

/// Service Firebase Storage
class FirebaseStorageService {
  static final FirebaseStorageService instance = FirebaseStorageService._();
  FirebaseStorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload un fichier
  Future<String> uploadFile({
    required String path,
    required File file,
    Map<String, String>? metadata,
  }) async {
    final ref = _storage.ref(path);

    SettableMetadata? settableMetadata;
    if (metadata != null) {
      settableMetadata = SettableMetadata(
        contentType: metadata['contentType'],
        customMetadata: metadata,
      );
    }

    final uploadTask = ref.putFile(file, settableMetadata);
    final snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  /// Upload des données en bytes
  Future<String> uploadData({
    required String path,
    required List<int> data,
    String? contentType,
  }) async {
    final ref = _storage.ref(path);

    final metadata = contentType != null
        ? SettableMetadata(contentType: contentType)
        : null;

    final bytes = typed_data.Uint8List.fromList(data);
    final uploadTask = ref.putData(
      bytes,
      metadata,
    );
    final snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  /// Télécharger un fichier
  Future<List<int>?> downloadData(String path) async {
    try {
      final ref = _storage.ref(path);
      return await ref.getData();
    } catch (e) {
      return null;
    }
  }

  /// Récupérer l'URL de téléchargement
  Future<String> getDownloadUrl(String path) async {
    final ref = _storage.ref(path);
    return await ref.getDownloadURL();
  }

  /// Supprimer un fichier
  Future<void> deleteFile(String path) async {
    final ref = _storage.ref(path);
    await ref.delete();
  }

  /// Lister les fichiers d'un dossier
  Future<ListResult> listFiles(String path) async {
    final ref = _storage.ref(path);
    return await ref.listAll();
  }
}

/// Extension pour Uint8List
typedef Uint8List = List<int>;
