import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/nfc_tag.dart';

part 'tag_model.g.dart';

@JsonSerializable(explicitToJson: true)
class TagModel {
  final String id;
  final String uid;
  final String type;
  final String technology;
  final int memorySize;
  final int usedMemory;
  final bool isWritable;
  final bool isLocked;
  final List<NdefRecordModel> ndefRecords;
  final List<int>? rawData;
  final DateTime scannedAt;
  final String? notes;
  final bool isFavorite;
  final GeoLocationModel? location;

  const TagModel({
    required this.id,
    required this.uid,
    required this.type,
    required this.technology,
    required this.memorySize,
    this.usedMemory = 0,
    this.isWritable = true,
    this.isLocked = false,
    this.ndefRecords = const [],
    this.rawData,
    required this.scannedAt,
    this.notes,
    this.isFavorite = false,
    this.location,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) => _$TagModelFromJson(json);

  Map<String, dynamic> toJson() => _$TagModelToJson(this);

  factory TagModel.fromEntity(NfcTag entity) {
    return TagModel(
      id: entity.id,
      uid: entity.uid,
      type: entity.type.name,
      technology: entity.technology.name,
      memorySize: entity.memorySize,
      usedMemory: entity.usedMemory,
      isWritable: entity.isWritable,
      isLocked: entity.isLocked,
      ndefRecords: entity.ndefRecords.map((r) => NdefRecordModel.fromEntity(r)).toList(),
      rawData: entity.rawData,
      scannedAt: entity.scannedAt,
      notes: entity.notes,
      isFavorite: entity.isFavorite,
      location: entity.location != null ? GeoLocationModel.fromEntity(entity.location!) : null,
    );
  }

  NfcTag toEntity() {
    return NfcTag(
      id: id,
      uid: uid,
      type: NfcTagType.fromString(type),
      technology: NfcTechnology.fromString(technology),
      memorySize: memorySize,
      usedMemory: usedMemory,
      isWritable: isWritable,
      isLocked: isLocked,
      ndefRecords: ndefRecords.map((r) => r.toEntity()).toList(),
      rawData: rawData,
      scannedAt: scannedAt,
      notes: notes,
      isFavorite: isFavorite,
      location: location?.toEntity(),
    );
  }
}

@JsonSerializable()
class NdefRecordModel {
  final String type;
  final String? typeNameFormat;
  final List<int> payload;
  final String? identifier;
  final String? decodedPayload;

  const NdefRecordModel({
    required this.type,
    this.typeNameFormat,
    required this.payload,
    this.identifier,
    this.decodedPayload,
  });

  factory NdefRecordModel.fromJson(Map<String, dynamic> json) => _$NdefRecordModelFromJson(json);

  Map<String, dynamic> toJson() => _$NdefRecordModelToJson(this);

  factory NdefRecordModel.fromEntity(NdefRecord entity) {
    return NdefRecordModel(
      type: entity.type.name,
      typeNameFormat: entity.typeNameFormat,
      payload: entity.payload,
      identifier: entity.identifier,
      decodedPayload: entity.decodedPayload,
    );
  }

  NdefRecord toEntity() {
    return NdefRecord(
      type: NdefRecordType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => NdefRecordType.unknown,
      ),
      typeNameFormat: typeNameFormat,
      payload: payload,
      identifier: identifier,
      decodedPayload: decodedPayload,
    );
  }
}

@JsonSerializable()
class GeoLocationModel {
  final double latitude;
  final double longitude;
  final String? address;

  const GeoLocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory GeoLocationModel.fromJson(Map<String, dynamic> json) => _$GeoLocationModelFromJson(json);

  Map<String, dynamic> toJson() => _$GeoLocationModelToJson(this);

  factory GeoLocationModel.fromEntity(GeoLocation entity) {
    return GeoLocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      address: entity.address,
    );
  }

  GeoLocation toEntity() {
    return GeoLocation(
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  }
}
