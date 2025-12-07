import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/nfc_tag.dart';
import '../repositories/nfc_repository.dart';

/// Use case pour lire un tag NFC
class ReadTagUseCase {
  final NfcRepository _repository;

  ReadTagUseCase(this._repository);

  /// Démarre la lecture NFC
  Future<Either<Failure, void>> startReading() {
    return _repository.startReading();
  }

  /// Arrête la lecture NFC
  Future<Either<Failure, void>> stopReading() {
    return _repository.stopReading();
  }

  /// Stream des tags lus
  Stream<Either<Failure, NfcTag>> call() {
    return _repository.readTag();
  }

  /// Vérifie si le NFC est disponible
  Future<Either<Failure, bool>> isNfcAvailable() {
    return _repository.isNfcAvailable();
  }

  /// Sauvegarde le tag dans l'historique et retourne le tag avec l'ID correct
  Future<Either<Failure, NfcTag>> saveTag(NfcTag tag) {
    return _repository.saveTagToHistory(tag);
  }
}

/// Use case pour obtenir les détails d'un tag
class GetTagDetailsUseCase {
  final NfcRepository _repository;

  GetTagDetailsUseCase(this._repository);

  Future<Either<Failure, NfcTag>> call(String id) {
    return _repository.getTagFromHistory(id);
  }
}

/// Use case pour gérer l'historique
class TagHistoryUseCase {
  final NfcRepository _repository;

  TagHistoryUseCase(this._repository);

  Future<Either<Failure, List<NfcTag>>> getHistory() {
    return _repository.getTagHistory();
  }

  Future<Either<Failure, List<NfcTag>>> getFavorites() {
    return _repository.getFavoriteTags();
  }

  Future<Either<Failure, void>> deleteTag(String id) {
    return _repository.deleteTagFromHistory(id);
  }

  Future<Either<Failure, void>> toggleFavorite(String id) {
    return _repository.toggleFavorite(id);
  }

  Future<Either<Failure, void>> updateNotes(String id, String notes) {
    return _repository.updateTagNotes(id, notes);
  }

  Future<Either<Failure, void>> clearHistory() {
    return _repository.clearHistory();
  }
}

/// Use case pour exporter les données d'un tag
class ExportTagUseCase {
  final NfcRepository _repository;

  ExportTagUseCase(this._repository);

  Future<Either<Failure, String>> call(String id, ExportFormat format) {
    return _repository.exportTagData(id, format);
  }
}

/// Use case pour lire la mémoire d'un tag NFC
class ReadMemoryUseCase {
  final NfcRepository _repository;

  ReadMemoryUseCase(this._repository);

  /// Démarre une session de lecture mémoire
  Future<Either<Failure, void>> startSession({
    required Function(List<int> data, int progress, int total) onProgress,
    required Function(List<int> fullData) onComplete,
    required Function(String error) onError,
  }) {
    return _repository.startMemoryReadSession(
      onProgress: onProgress,
      onComplete: onComplete,
      onError: onError,
    );
  }

  /// Met à jour les données brutes d'un tag
  Future<Either<Failure, NfcTag>> updateRawData(String id, List<int> rawData) {
    return _repository.updateTagRawData(id, rawData);
  }
}
