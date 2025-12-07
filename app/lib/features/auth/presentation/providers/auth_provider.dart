import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/firebase_service.dart';
import '../../domain/entities/user.dart';

/// État d'authentification
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// État global de l'authentification
class AuthState {
  final AuthStatus status;
  final User? user;
  final fb.User? firebaseUser;
  final String? errorMessage;
  final bool isOnboardingComplete;
  final bool isLoading;
  final bool isBiometricAvailable;
  final bool isBiometricEnabled;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.firebaseUser,
    this.errorMessage,
    this.isOnboardingComplete = false,
    this.isLoading = false,
    this.isBiometricAvailable = false,
    this.isBiometricEnabled = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isAnonymous => firebaseUser?.isAnonymous ?? false;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    fb.User? firebaseUser,
    String? errorMessage,
    bool? isOnboardingComplete,
    bool? isLoading,
    bool? isBiometricAvailable,
    bool? isBiometricEnabled,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      errorMessage: errorMessage,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      isLoading: isLoading ?? this.isLoading,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    );
  }
}

/// Notifier pour la gestion de l'authentification avec Firebase
class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _secureStorage;
  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final LocalAuthentication _localAuth;

  static const _onboardingKey = 'onboarding_complete';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _userEmailKey = 'user_email';
  static const _userUidKey = 'user_uid';  // Stocke l'UID au lieu du mot de passe (sécurité)

  // SÉCURITÉ: On ne stocke plus le mot de passe en clair
  // L'authentification biométrique vérifie simplement que:
  // 1. L'utilisateur peut s'authentifier localement (empreinte/face)
  // 2. Une session Firebase valide existe toujours
  @Deprecated('Ne plus utiliser - remplacé par _userUidKey pour la sécurité')
  static const _userCredentialKey = 'user_credential';

  // Web Client ID from Firebase Console (required for Android to get idToken)
  static const _webClientId = '245650933256-eb40vg6mthk7f9hvcuk5fquoli7huu9h.apps.googleusercontent.com';

  AuthNotifier(this._secureStorage)
      : _firebaseAuth = fb.FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: _webClientId,
        ),
        _localAuth = LocalAuthentication(),
        super(const AuthState()) {
    _init();
  }

  void _init() async {
    // Vérifier si la biométrie est disponible
    await _checkBiometricAvailability();

    // Vérifier si la biométrie est activée par l'utilisateur
    final biometricEnabled = await _secureStorage.read(key: _biometricEnabledKey);

    // Mettre à jour l'état de biométrie immédiatement
    state = state.copyWith(
      isBiometricEnabled: biometricEnabled == 'true',
    );

    // Écouter les changements d'état d'authentification Firebase
    _firebaseAuth.authStateChanges().listen((fbUser) async {
      final onboardingComplete = await _secureStorage.read(key: _onboardingKey);
      // Relire l'état de biométrie à chaque changement d'auth
      final currentBiometricEnabled = await _secureStorage.read(key: _biometricEnabledKey);

      if (fbUser != null) {
        final user = _convertFirebaseUser(fbUser);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          firebaseUser: fbUser,
          isOnboardingComplete: onboardingComplete == 'true',
          isBiometricEnabled: currentBiometricEnabled == 'true',
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          firebaseUser: null,
          isOnboardingComplete: onboardingComplete == 'true',
          isBiometricEnabled: currentBiometricEnabled == 'true',
          isLoading: false,
        );
      }
    });
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canCheck && isDeviceSupported) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        state = state.copyWith(
          isBiometricAvailable: availableBiometrics.isNotEmpty,
        );
      }
    } catch (e) {
      state = state.copyWith(isBiometricAvailable: false);
    }
  }

  User _convertFirebaseUser(fb.User fbUser) {
    return User(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'Utilisateur',
      photoUrl: fbUser.photoURL,
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: fbUser.metadata.lastSignInTime,
      isEmailVerified: fbUser.emailVerified,
      isAnonymous: fbUser.isAnonymous,
    );
  }

  /// Vérifie si des credentials sont stockés pour la biométrie
  /// SÉCURITÉ: Vérifie l'UID stocké + session Firebase active (pas de mot de passe)
  Future<bool> hasStoredCredentials() async {
    final email = await _secureStorage.read(key: _userEmailKey);
    final uid = await _secureStorage.read(key: _userUidKey);
    // Vérifie aussi qu'une session Firebase existe
    final currentUser = _firebaseAuth.currentUser;
    return email != null && uid != null && currentUser != null;
  }

  /// Connexion avec biométrie
  /// SÉCURITÉ: Ne stocke plus le mot de passe - vérifie uniquement:
  /// 1. Authentification biométrique locale (empreinte/face)
  /// 2. Session Firebase toujours valide (refresh token automatique)
  Future<bool> signInWithBiometrics() async {
    if (!state.isBiometricAvailable) {
      state = state.copyWith(errorMessage: 'Biométrie non disponible sur cet appareil');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Authentifier avec biométrie locale
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour accéder à Cards Control',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!didAuthenticate) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      // Vérifier que l'UID stocké correspond à l'utilisateur Firebase actuel
      final storedUid = await _secureStorage.read(key: _userUidKey);
      final currentUser = _firebaseAuth.currentUser;

      if (storedUid == null || currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Aucun compte enregistré pour la biométrie. Veuillez vous reconnecter.',
        );
        return false;
      }

      // Vérifier que c'est bien le même utilisateur
      if (currentUser.uid != storedUid) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Session expirée. Veuillez vous reconnecter.',
        );
        return false;
      }

      // Rafraîchir le token pour s'assurer que la session est valide
      await currentUser.reload();
      await currentUser.getIdToken(true);

      // La session Firebase est valide, l'utilisateur est authentifié
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: _convertFirebaseUser(currentUser),
        firebaseUser: currentUser,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Session expirée. Veuillez vous reconnecter avec votre mot de passe.',
        isLoading: false,
      );
      return false;
    }
  }

  /// Active/désactive la biométrie
  /// SÉCURITÉ: Stocke uniquement l'email et l'UID (jamais le mot de passe)
  Future<void> setBiometricEnabled(bool enabled, {String? email, String? uid}) async {
    if (enabled) {
      // Utiliser les infos de l'utilisateur connecté si non fournies
      final currentUser = _firebaseAuth.currentUser;
      final userEmail = email ?? currentUser?.email;
      final userUid = uid ?? currentUser?.uid;

      if (userEmail != null && userUid != null) {
        // Stocker uniquement email et UID (pas de mot de passe!)
        await _secureStorage.write(key: _userEmailKey, value: userEmail);
        await _secureStorage.write(key: _userUidKey, value: userUid);
      }
    } else {
      // Supprimer les données stockées
      await _secureStorage.delete(key: _userEmailKey);
      await _secureStorage.delete(key: _userUidKey);
      // Nettoyer aussi l'ancienne clé de mot de passe si elle existe (migration)
      await _secureStorage.delete(key: _userCredentialKey);
    }

    await _secureStorage.write(key: _biometricEnabledKey, value: enabled.toString());
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  /// Vérifie le mot de passe et active la biométrie si correct
  Future<bool> verifyPasswordAndEnableBiometric(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Ré-authentifier l'utilisateur pour vérifier le mot de passe
      final credential = fb.EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await state.firebaseUser?.reauthenticateWithCredential(credential);

      // Mot de passe vérifié, activer la biométrie (stocke l'UID, pas le mot de passe)
      await setBiometricEnabled(true, email: email, uid: state.firebaseUser?.uid);

      state = state.copyWith(isLoading: false);
      return true;
    } on fb.FirebaseAuthException catch (e) {
      state = state.copyWith(
        errorMessage: _getErrorMessage(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  /// Connexion avec email/mot de passe
  Future<bool> signInWithEmail(String email, String password, {bool enableBiometric = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Si biométrie activée, stocker l'UID (pas le mot de passe!)
      if (enableBiometric && state.isBiometricAvailable) {
        final currentUser = _firebaseAuth.currentUser;
        await setBiometricEnabled(true, email: email, uid: currentUser?.uid);
      }

      return true;
    } on fb.FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getErrorMessage(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  /// Inscription avec email/mot de passe
  Future<bool> signUpWithEmail(String email, String password, String? displayName, {bool enableBiometric = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Mettre à jour le nom d'affichage
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      // Créer le profil utilisateur dans Firestore
      await _createUserProfile(credential.user!);

      // Si biométrie activée, stocker l'UID (pas le mot de passe!)
      if (enableBiometric && state.isBiometricAvailable) {
        await setBiometricEnabled(true, email: email, uid: credential.user?.uid);
      }

      return true;
    } on fb.FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getErrorMessage(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  /// Connexion anonyme
  Future<bool> signInAnonymously() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _firebaseAuth.signInAnonymously();
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  /// Connexion avec Google
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Déclencher le flux d'authentification Google
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Connexion annulée ou erreur Google Sign-In',
        );
        return false; // L'utilisateur a annulé
      }

      // Obtenir les détails d'authentification
      final googleAuth = await googleUser.authentication;

      // Créer les credentials Firebase
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Se connecter à Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      // Créer/mettre à jour le profil dans Firestore
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(userCredential.user!);
      }

      return true;
    } on fb.FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getErrorMessage(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Erreur Google: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Génère un nonce aléatoire pour Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Hash SHA256 pour le nonce
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Connexion avec Apple
  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Générer un nonce pour la sécurité
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Demander les credentials Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Créer les credentials OAuth pour Firebase
      final oauthCredential = fb.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Se connecter à Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);

      // Apple ne renvoie le nom que la première fois
      // Mettre à jour le profil si c'est un nouvel utilisateur
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final displayName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].where((n) => n != null).join(' ');

        if (displayName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(displayName);
          await userCredential.user?.reload();
        }

        await _createUserProfile(userCredential.user!);
      }

      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Erreur Apple Sign In: ${e.message}',
        isLoading: false,
      );
      return false;
    } on fb.FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getErrorMessage(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  /// Crée le profil utilisateur dans Firestore
  Future<void> _createUserProfile(fb.User user) async {
    try {
      await FirestoreService.instance.set('users', user.uid, {
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'isAnonymous': user.isAnonymous,
        'isPremium': false,
        'subscriptionTier': 'free',
        'createdAt': DateTime.now().toIso8601String(),
      }, merge: true);
    } catch (_) {
      // Silently ignore - don't fail authentication for profile creation errors
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Marquer l'onboarding comme terminé
  Future<void> completeOnboarding() async {
    await _secureStorage.write(key: _onboardingKey, value: 'true');
    state = state.copyWith(isOnboardingComplete: true);
  }

  /// Réinitialiser le mot de passe
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } on fb.FirebaseAuthException catch (e) {
      state = state.copyWith(
        errorMessage: _getErrorMessage(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  /// Mettre à jour le profil
  Future<bool> updateProfile({String? displayName, String? photoUrl}) async {
    if (state.firebaseUser == null) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      if (displayName != null) {
        await state.firebaseUser!.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await state.firebaseUser!.updatePhotoURL(photoUrl);
      }

      await state.firebaseUser!.reload();
      final updatedUser = _firebaseAuth.currentUser;

      if (updatedUser != null) {
        // Mettre à jour aussi dans Firestore
        await FirestoreService.instance.update('users', updatedUser.uid, {
          if (displayName != null) 'displayName': displayName,
          if (photoUrl != null) 'photoUrl': photoUrl,
        });

        state = state.copyWith(
          user: _convertFirebaseUser(updatedUser),
          firebaseUser: updatedUser,
          isLoading: false,
        );
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  /// Supprimer le compte
  Future<bool> deleteAccount() async {
    if (state.firebaseUser == null) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final uid = state.firebaseUser!.uid;

      // Supprimer les données Firestore
      await FirestoreService.instance.delete('users', uid);

      // Supprimer les credentials biométriques
      await setBiometricEnabled(false);

      // Supprimer le compte Firebase Auth
      await state.firebaseUser!.delete();

      return true;
    } on fb.FirebaseAuthException catch (e) {
      state = state.copyWith(
        errorMessage: _getErrorMessage(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  /// Convertir un compte anonyme en compte permanent
  Future<bool> linkWithEmail(String email, String password) async {
    if (state.firebaseUser == null || !state.firebaseUser!.isAnonymous) {
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final credential = fb.EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await state.firebaseUser!.linkWithCredential(credential);
      return true;
    } on fb.FirebaseAuthException catch (e) {
      state = state.copyWith(
        errorMessage: _getErrorMessage(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  /// Effacer l'erreur
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email';
      case 'invalid-email':
        return 'Adresse email invalide';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'operation-not-allowed':
        return 'Cette méthode de connexion n\'est pas activée';
      case 'network-request-failed':
        return 'Erreur de connexion. Vérifiez votre connexion internet';
      case 'requires-recent-login':
        return 'Veuillez vous reconnecter pour effectuer cette action';
      case 'credential-already-in-use':
        return 'Ces identifiants sont déjà associés à un autre compte';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec un autre mode de connexion';
      default:
        return 'Une erreur est survenue: $code';
    }
  }
}

/// Provider principal d'authentification
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(secureStorage);
});

/// Provider pour vérifier si l'utilisateur est connecté
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Provider pour l'utilisateur courant
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Provider pour vérifier si l'utilisateur est premium
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isPremium ?? false;
});

/// Provider pour le stream d'authentification Firebase
final authStateStreamProvider = StreamProvider<fb.User?>((ref) {
  return fb.FirebaseAuth.instance.authStateChanges();
});

/// Provider pour vérifier si la biométrie est disponible
final isBiometricAvailableProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isBiometricAvailable;
});

/// Provider pour vérifier si la biométrie est activée
final isBiometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isBiometricEnabled;
});
