import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/nfc_tag.dart';

/// Repository abstrait pour les opérations NFC
abstract class NfcRepository {
  /// Vérifie si le NFC est disponible sur l'appareil
  Future<Either<Failure, bool>> isNfcAvailable();

  /// Vérifie si le NFC est activé
  Future<Either<Failure, bool>> isNfcEnabled();

  /// Démarre la session de lecture NFC
  Future<Either<Failure, void>> startReading();

  /// Arrête la session de lecture NFC
  Future<Either<Failure, void>> stopReading();

  /// Lit un tag NFC
  Stream<Either<Failure, NfcTag>> readTag();

  /// Lit les données brutes d'un tag
  Future<Either<Failure, List<int>>> readRawData(String tagId);

  /// Obtient les détails complets d'un tag
  Future<Either<Failure, NfcTag>> getTagDetails(String uid);

  /// Sauvegarde un tag dans l'historique local et retourne le tag avec l'ID correct
  Future<Either<Failure, NfcTag>> saveTagToHistory(NfcTag tag);

  /// Récupère l'historique des tags scannés
  Future<Either<Failure, List<NfcTag>>> getTagHistory();

  /// Récupère un tag de l'historique par ID
  Future<Either<Failure, NfcTag>> getTagFromHistory(String id);

  /// Supprime un tag de l'historique
  Future<Either<Failure, void>> deleteTagFromHistory(String id);

  /// Met à jour les notes d'un tag
  Future<Either<Failure, void>> updateTagNotes(String id, String notes);

  /// Ajoute/retire un tag des favoris
  Future<Either<Failure, void>> toggleFavorite(String id);

  /// Récupère les tags favoris
  Future<Either<Failure, List<NfcTag>>> getFavoriteTags();

  /// Exporte les données d'un tag
  Future<Either<Failure, String>> exportTagData(String id, ExportFormat format);

  /// Efface tout l'historique
  Future<Either<Failure, void>> clearHistory();

  /// Démarre une session de lecture mémoire
  /// Retourne un Stream de progression avec les données lues
  Future<Either<Failure, void>> startMemoryReadSession({
    required Function(List<int> data, int progress, int total) onProgress,
    required Function(List<int> fullData) onComplete,
    required Function(String error) onError,
  });

  /// Met à jour les données brutes d'un tag dans l'historique
  Future<Either<Failure, NfcTag>> updateTagRawData(String id, List<int> rawData);
}

/// Formats d'export supportés
enum ExportFormat {
  json,
  xml,
  hex,
  csv,
}
