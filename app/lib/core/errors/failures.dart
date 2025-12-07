import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

// General Failures
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Erreur serveur', super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Erreur de connexion. Vérifiez votre connexion internet.',
    super.code,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Erreur de cache local', super.code});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Session expirée. Veuillez vous reconnecter.',
    super.code,
  });
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? fieldErrors;

  const ValidationFailure({
    super.message = 'Erreur de validation',
    super.code,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

// Auth Failures
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({
    super.message = 'Email ou mot de passe incorrect',
    super.code,
  });
}

class EmailAlreadyExistsFailure extends Failure {
  const EmailAlreadyExistsFailure({
    super.message = 'Cet email est déjà utilisé',
    super.code,
  });
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure({
    super.message = 'Le mot de passe est trop faible',
    super.code,
  });
}

class EmailNotVerifiedFailure extends Failure {
  const EmailNotVerifiedFailure({
    super.message = 'Veuillez vérifier votre email avant de vous connecter',
    super.code,
  });
}

// NFC Failures
class NfcNotAvailableFailure extends Failure {
  const NfcNotAvailableFailure({
    super.message = 'NFC non disponible sur cet appareil',
    super.code,
  });
}

class NfcDisabledFailure extends Failure {
  const NfcDisabledFailure({
    super.message = 'Le NFC est désactivé. Veuillez l\'activer dans les paramètres.',
    super.code,
  });
}

class NfcTagNotFoundFailure extends Failure {
  const NfcTagNotFoundFailure({
    super.message = 'Aucun tag NFC détecté',
    super.code,
  });
}

class NfcTagLostFailure extends Failure {
  const NfcTagLostFailure({
    super.message = 'Tag perdu. Veuillez réessayer.',
    super.code,
  });
}

class NfcReadFailure extends Failure {
  const NfcReadFailure({
    super.message = 'Échec de la lecture du tag',
    super.code,
  });
}

class NfcWriteFailure extends Failure {
  const NfcWriteFailure({
    super.message = 'Échec de l\'écriture sur le tag',
    super.code,
  });
}

class NfcTagReadOnlyFailure extends Failure {
  const NfcTagReadOnlyFailure({
    super.message = 'Ce tag est en lecture seule',
    super.code,
  });
}

class NfcTagFullFailure extends Failure {
  const NfcTagFullFailure({
    super.message = 'Pas assez d\'espace sur le tag',
    super.code,
  });
}

class NfcAuthenticationFailure extends Failure {
  const NfcAuthenticationFailure({
    super.message = 'Authentification avec le tag échouée',
    super.code,
  });
}

class NfcUnsupportedTagFailure extends Failure {
  const NfcUnsupportedTagFailure({
    super.message = 'Type de tag non supporté',
    super.code,
  });
}

// Subscription Failures
class SubscriptionRequiredFailure extends Failure {
  const SubscriptionRequiredFailure({
    super.message = 'Cette fonctionnalité nécessite un abonnement Pro',
    super.code,
  });
}

class SubscriptionExpiredFailure extends Failure {
  const SubscriptionExpiredFailure({
    super.message = 'Votre abonnement a expiré',
    super.code,
  });
}

class PurchaseFailedFailure extends Failure {
  const PurchaseFailedFailure({
    super.message = 'L\'achat a échoué. Veuillez réessayer.',
    super.code,
  });
}

class PurchaseCancelledFailure extends Failure {
  const PurchaseCancelledFailure({
    super.message = 'Achat annulé',
    super.code,
  });
}

// Business Card Failures
class CardNotFoundFailure extends Failure {
  const CardNotFoundFailure({
    super.message = 'Carte de visite non trouvée',
    super.code,
  });
}

class CardLimitReachedFailure extends Failure {
  const CardLimitReachedFailure({
    super.message = 'Vous avez atteint la limite de cartes. Passez à Pro pour en créer plus.',
    super.code,
  });
}

// Permission Failures
class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure({
    super.message = 'Permission refusée',
    super.code,
  });
}

class CameraPermissionFailure extends Failure {
  const CameraPermissionFailure({
    super.message = 'Accès à la caméra refusé',
    super.code,
  });
}

class ContactsPermissionFailure extends Failure {
  const ContactsPermissionFailure({
    super.message = 'Accès aux contacts refusé',
    super.code,
  });
}

// Generic NFC Failure
class NfcFailure extends Failure {
  const NfcFailure(String message, {super.code}) : super(message: message);
}

// Not Found Failure
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message, {super.code}) : super(message: message);
}

// Export Failure
class ExportFailure extends Failure {
  const ExportFailure(String message, {super.code}) : super(message: message);
}
