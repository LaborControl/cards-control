import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/nfc_tag.dart';
import '../models/tag_model.dart';

/// Datasource pour le stockage local des tags NFC
class NfcLocalDatasource {
  final Box _tagsBox;
  static const String _tagsKey = 'tags';
  static const String _favoritesKey = 'favorites';

  NfcLocalDatasource(this._tagsBox);

  /// Sauvegarde un tag dans l'historique et retourne le tag avec l'ID correct
  Future<NfcTag> saveTag(NfcTag tag) async {
    final tags = await getTags();

    // Vérifie si le tag existe déjà (par UID)
    final existingIndex = tags.indexWhere((t) => t.uid == tag.uid);

    NfcTag savedTag;
    if (existingIndex >= 0) {
      // Met à jour le tag existant mais garde l'ID original
      savedTag = tag.copyWith(
        id: tags[existingIndex].id,
        isFavorite: tags[existingIndex].isFavorite,
        notes: tags[existingIndex].notes,
      );
      tags[existingIndex] = savedTag;
    } else {
      // Ajoute le nouveau tag
      savedTag = tag;
      tags.insert(0, tag);
    }

    await _saveTags(tags);
    return savedTag;
  }

  /// Récupère tous les tags de l'historique
  Future<List<NfcTag>> getTags() async {
    final tagsJson = _tagsBox.get(_tagsKey) as String?;

    if (tagsJson == null || tagsJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> tagsList = json.decode(tagsJson);
      return tagsList
          .map((t) => TagModel.fromJson(t as Map<String, dynamic>).toEntity())
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Récupère un tag par ID
  Future<NfcTag?> getTagById(String id) async {
    final tags = await getTags();
    try {
      return tags.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Récupère un tag par UID
  Future<NfcTag?> getTagByUid(String uid) async {
    final tags = await getTags();
    try {
      return tags.firstWhere((t) => t.uid == uid);
    } catch (e) {
      return null;
    }
  }

  /// Supprime un tag de l'historique
  Future<void> deleteTag(String id) async {
    final tags = await getTags();
    tags.removeWhere((t) => t.id == id);
    await _saveTags(tags);
  }

  /// Met à jour les notes d'un tag
  Future<void> updateNotes(String id, String notes) async {
    final tags = await getTags();
    final index = tags.indexWhere((t) => t.id == id);

    if (index >= 0) {
      tags[index] = tags[index].copyWith(notes: notes);
      await _saveTags(tags);
    }
  }

  /// Bascule le statut favori d'un tag
  Future<void> toggleFavorite(String id) async {
    final tags = await getTags();
    final index = tags.indexWhere((t) => t.id == id);

    if (index >= 0) {
      tags[index] = tags[index].copyWith(isFavorite: !tags[index].isFavorite);
      await _saveTags(tags);
    }
  }

  /// Met à jour les données brutes d'un tag
  Future<void> updateTagRawData(String id, List<int> rawData) async {
    final tags = await getTags();
    final index = tags.indexWhere((t) => t.id == id);

    if (index >= 0) {
      tags[index] = tags[index].copyWith(rawData: rawData);
      await _saveTags(tags);
    }
  }

  /// Récupère les tags favoris
  Future<List<NfcTag>> getFavorites() async {
    final tags = await getTags();
    return tags.where((t) => t.isFavorite).toList();
  }

  /// Efface tout l'historique
  Future<void> clearAll() async {
    await _tagsBox.delete(_tagsKey);
  }

  /// Exporte un tag au format JSON
  Future<String> exportAsJson(String id) async {
    final tag = await getTagById(id);
    if (tag == null) throw Exception('Tag not found');

    final model = TagModel.fromEntity(tag);
    return const JsonEncoder.withIndent('  ').convert(model.toJson());
  }

  /// Exporte un tag au format XML
  Future<String> exportAsXml(String id) async {
    final tag = await getTagById(id);
    if (tag == null) throw Exception('Tag not found');

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<nfc_tag>');
    buffer.writeln('  <id>${tag.id}</id>');
    buffer.writeln('  <uid>${tag.uid}</uid>');
    buffer.writeln('  <type>${tag.type.displayName}</type>');
    buffer.writeln('  <technology>${tag.technology.displayName}</technology>');
    buffer.writeln('  <memory_size>${tag.memorySize}</memory_size>');
    buffer.writeln('  <used_memory>${tag.usedMemory}</used_memory>');
    buffer.writeln('  <is_writable>${tag.isWritable}</is_writable>');
    buffer.writeln('  <is_locked>${tag.isLocked}</is_locked>');
    buffer.writeln('  <scanned_at>${tag.scannedAt.toIso8601String()}</scanned_at>');

    if (tag.ndefRecords.isNotEmpty) {
      buffer.writeln('  <ndef_records>');
      for (final record in tag.ndefRecords) {
        buffer.writeln('    <record>');
        buffer.writeln('      <type>${record.type.displayName}</type>');
        buffer.writeln('      <payload_hex>${record.payloadHex}</payload_hex>');
        if (record.decodedPayload != null) {
          buffer.writeln('      <decoded_payload><![CDATA[${record.decodedPayload}]]></decoded_payload>');
        }
        buffer.writeln('    </record>');
      }
      buffer.writeln('  </ndef_records>');
    }

    if (tag.rawData != null) {
      buffer.writeln('  <raw_data>');
      buffer.writeln('    ${tag.rawData!.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ').toUpperCase()}');
      buffer.writeln('  </raw_data>');
    }

    buffer.writeln('</nfc_tag>');
    return buffer.toString();
  }

  /// Exporte un tag au format hexadécimal
  Future<String> exportAsHex(String id) async {
    final tag = await getTagById(id);
    if (tag == null) throw Exception('Tag not found');

    final buffer = StringBuffer();
    buffer.writeln('NFC Tag Dump');
    buffer.writeln('============');
    buffer.writeln('');
    buffer.writeln('UID: ${tag.formattedUid}');
    buffer.writeln('Type: ${tag.type.displayName}');
    buffer.writeln('Technology: ${tag.technology.displayName}');
    buffer.writeln('');

    if (tag.rawData != null && tag.rawData!.isNotEmpty) {
      buffer.writeln('Memory Dump:');
      buffer.writeln('------------');

      for (var i = 0; i < tag.rawData!.length; i += 16) {
        // Adresse
        buffer.write('${i.toRadixString(16).padLeft(4, '0').toUpperCase()}: ');

        // Bytes hex
        for (var j = 0; j < 16; j++) {
          if (i + j < tag.rawData!.length) {
            buffer.write('${tag.rawData![i + j].toRadixString(16).padLeft(2, '0').toUpperCase()} ');
          } else {
            buffer.write('   ');
          }
          if (j == 7) buffer.write(' ');
        }

        buffer.write(' |');

        // ASCII
        for (var j = 0; j < 16; j++) {
          if (i + j < tag.rawData!.length) {
            final byte = tag.rawData![i + j];
            if (byte >= 32 && byte <= 126) {
              buffer.write(String.fromCharCode(byte));
            } else {
              buffer.write('.');
            }
          }
        }

        buffer.writeln('|');
      }
    }

    return buffer.toString();
  }

  /// Sauvegarde la liste des tags
  Future<void> _saveTags(List<NfcTag> tags) async {
    final models = tags.map((t) => TagModel.fromEntity(t).toJson()).toList();
    await _tagsBox.put(_tagsKey, json.encode(models));
  }

  /// Obtient le nombre de tags dans l'historique
  Future<int> getTagCount() async {
    final tags = await getTags();
    return tags.length;
  }

  /// Recherche des tags par critères
  Future<List<NfcTag>> searchTags({
    String? query,
    NfcTagType? type,
    DateTime? fromDate,
    DateTime? toDate,
    bool? favoritesOnly,
  }) async {
    var tags = await getTags();

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      tags = tags.where((t) =>
        t.uid.toLowerCase().contains(lowerQuery) ||
        t.type.displayName.toLowerCase().contains(lowerQuery) ||
        (t.notes?.toLowerCase().contains(lowerQuery) ?? false) ||
        t.ndefRecords.any((r) =>
          r.decodedPayload?.toLowerCase().contains(lowerQuery) ?? false
        )
      ).toList();
    }

    if (type != null) {
      tags = tags.where((t) => t.type == type).toList();
    }

    if (fromDate != null) {
      tags = tags.where((t) => t.scannedAt.isAfter(fromDate)).toList();
    }

    if (toDate != null) {
      tags = tags.where((t) => t.scannedAt.isBefore(toDate)).toList();
    }

    if (favoritesOnly == true) {
      tags = tags.where((t) => t.isFavorite).toList();
    }

    return tags;
  }
}
