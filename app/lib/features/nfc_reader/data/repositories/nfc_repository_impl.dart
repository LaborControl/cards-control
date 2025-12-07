import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/nfc_tag.dart';
import '../../domain/repositories/nfc_repository.dart';
import '../datasources/nfc_local_datasource.dart';
import '../datasources/nfc_native_datasource.dart';

/// Implémentation du repository NFC
class NfcRepositoryImpl implements NfcRepository {
  final NfcNativeDatasource _nativeDatasource;
  final NfcLocalDatasource _localDatasource;

  NfcRepositoryImpl({
    required NfcNativeDatasource nativeDatasource,
    required NfcLocalDatasource localDatasource,
  })  : _nativeDatasource = nativeDatasource,
        _localDatasource = localDatasource;

  @override
  Future<Either<Failure, bool>> isNfcAvailable() async {
    try {
      final isAvailable = await _nativeDatasource.isNfcAvailable();
      return Right(isAvailable);
    } catch (e) {
      return Left(NfcFailure('Unable to check NFC availability: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isNfcEnabled() async {
    try {
      // NFC Manager doesn't distinguish between available and enabled
      // On most devices, if NFC is available, we assume it can be enabled
      final isAvailable = await _nativeDatasource.isNfcAvailable();
      return Right(isAvailable);
    } catch (e) {
      return Left(NfcFailure('Unable to check NFC status: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> startReading() async {
    try {
      await _nativeDatasource.startReading();
      return const Right(null);
    } catch (e) {
      return Left(NfcFailure('Failed to start NFC reading: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> stopReading() async {
    try {
      await _nativeDatasource.stopReading();
      return const Right(null);
    } catch (e) {
      return Left(NfcFailure('Failed to stop NFC reading: $e'));
    }
  }

  @override
  Stream<Either<Failure, NfcTag>> readTag() {
    return _nativeDatasource.tagStream.map((tag) => Right<Failure, NfcTag>(tag)).handleError(
      (error) => Left<Failure, NfcTag>(NfcFailure('Error reading tag: $error')),
    );
  }

  @override
  Future<Either<Failure, List<int>>> readRawData(String tagId) async {
    try {
      // This would require keeping a reference to the tag
      // For now, return empty list
      return const Right([]);
    } catch (e) {
      return Left(NfcFailure('Failed to read raw data: $e'));
    }
  }

  @override
  Future<Either<Failure, NfcTag>> getTagDetails(String uid) async {
    try {
      final tag = await _localDatasource.getTagByUid(uid);
      if (tag != null) {
        return Right(tag);
      }
      return Left(NotFoundFailure('Tag not found'));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get tag details: $e'));
    }
  }

  @override
  Future<Either<Failure, NfcTag>> saveTagToHistory(NfcTag tag) async {
    try {
      final savedTag = await _localDatasource.saveTag(tag);
      return Right(savedTag);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save tag: $e'));
    }
  }

  @override
  Future<Either<Failure, List<NfcTag>>> getTagHistory() async {
    try {
      final tags = await _localDatasource.getTags();
      return Right(tags);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get history: $e'));
    }
  }

  @override
  Future<Either<Failure, NfcTag>> getTagFromHistory(String id) async {
    try {
      final tag = await _localDatasource.getTagById(id);
      if (tag != null) {
        return Right(tag);
      }
      return Left(NotFoundFailure('Tag not found'));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get tag: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTagFromHistory(String id) async {
    try {
      await _localDatasource.deleteTag(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to delete tag: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTagNotes(String id, String notes) async {
    try {
      await _localDatasource.updateNotes(id, notes);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to update notes: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFavorite(String id) async {
    try {
      await _localDatasource.toggleFavorite(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to toggle favorite: $e'));
    }
  }

  @override
  Future<Either<Failure, List<NfcTag>>> getFavoriteTags() async {
    try {
      final tags = await _localDatasource.getFavorites();
      return Right(tags);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get favorites: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> exportTagData(String id, ExportFormat format) async {
    try {
      String exported;
      switch (format) {
        case ExportFormat.json:
          exported = await _localDatasource.exportAsJson(id);
          break;
        case ExportFormat.xml:
          exported = await _localDatasource.exportAsXml(id);
          break;
        case ExportFormat.hex:
          exported = await _localDatasource.exportAsHex(id);
          break;
        case ExportFormat.csv:
          exported = await _exportAsCsv(id);
          break;
      }
      return Right(exported);
    } catch (e) {
      return Left(ExportFailure('Failed to export tag: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearHistory() async {
    try {
      await _localDatasource.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear history: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> startMemoryReadSession({
    required Function(List<int> data, int progress, int total) onProgress,
    required Function(List<int> fullData) onComplete,
    required Function(String error) onError,
  }) async {
    try {
      await _nativeDatasource.startMemoryReadSession(
        onProgress: onProgress,
        onComplete: onComplete,
        onError: onError,
      );
      return const Right(null);
    } catch (e) {
      return Left(NfcFailure('Failed to start memory read session: $e'));
    }
  }

  @override
  Future<Either<Failure, NfcTag>> updateTagRawData(String id, List<int> rawData) async {
    try {
      final tag = await _localDatasource.getTagById(id);
      if (tag == null) {
        return Left(NotFoundFailure('Tag not found'));
      }
      final updatedTag = tag.copyWith(rawData: rawData);
      await _localDatasource.updateTagRawData(id, rawData);
      return Right(updatedTag);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to update raw data: $e'));
    }
  }

  /// Export au format CSV
  Future<String> _exportAsCsv(String id) async {
    final tag = await _localDatasource.getTagById(id);
    if (tag == null) throw Exception('Tag not found');

    final buffer = StringBuffer();
    buffer.writeln('Field,Value');
    buffer.writeln('ID,"${tag.id}"');
    buffer.writeln('UID,"${tag.uid}"');
    buffer.writeln('Type,"${tag.type.displayName}"');
    buffer.writeln('Technology,"${tag.technology.displayName}"');
    buffer.writeln('Memory Size,"${tag.memorySize}"');
    buffer.writeln('Used Memory,"${tag.usedMemory}"');
    buffer.writeln('Is Writable,"${tag.isWritable}"');
    buffer.writeln('Is Locked,"${tag.isLocked}"');
    buffer.writeln('Scanned At,"${tag.scannedAt.toIso8601String()}"');
    buffer.writeln('Notes,"${tag.notes ?? ''}"');
    buffer.writeln('Is Favorite,"${tag.isFavorite}"');

    for (var i = 0; i < tag.ndefRecords.length; i++) {
      final record = tag.ndefRecords[i];
      buffer.writeln('NDEF Record ${i + 1} Type,"${record.type.displayName}"');
      buffer.writeln('NDEF Record ${i + 1} Payload,"${record.decodedPayload ?? record.payloadHex}"');
    }

    return buffer.toString();
  }
}
