import 'package:equatable/equatable.dart';

/// Types de données à écrire sur un tag NFC
enum WriteDataType {
  url('URL'),
  text('Texte'),
  vcard('Carte de visite'),
  wifi('Configuration WiFi'),
  bluetooth('Appairage Bluetooth'),
  phone('Numéro de téléphone'),
  email('Email'),
  sms('SMS'),
  location('Localisation'),
  event('Événement'),
  launchApp('Lancer une application'),
  custom('Données personnalisées'),
  // Nouveaux types
  googleReview('Avis Google'),
  appDownload('Téléchargement App'),
  tip('Pourboire'),
  medicalId('ID Médical'),
  petId('ID Animal'),
  luggageId('ID Bagages');

  final String displayName;

  const WriteDataType(this.displayName);
}

/// Données de base pour l'écriture NFC
abstract class WriteData extends Equatable {
  final WriteDataType type;
  final String? label;

  const WriteData({required this.type, this.label});

  /// Convertit en payload NDEF
  List<int> toNdefPayload();

  /// Taille estimée en bytes
  int get estimatedSize;
}

/// Données URL
class UrlWriteData extends WriteData {
  final String url;

  const UrlWriteData({
    required this.url,
    super.label,
  }) : super(type: WriteDataType.url);

  @override
  List<int> toNdefPayload() {
    // Préfixe URI + URL encodée
    int prefixCode = 0x00;
    String urlPart = url;

    if (url.startsWith('https://www.')) {
      prefixCode = 0x02;
      urlPart = url.substring(12);
    } else if (url.startsWith('http://www.')) {
      prefixCode = 0x01;
      urlPart = url.substring(11);
    } else if (url.startsWith('https://')) {
      prefixCode = 0x04;
      urlPart = url.substring(8);
    } else if (url.startsWith('http://')) {
      prefixCode = 0x03;
      urlPart = url.substring(7);
    }

    return [prefixCode, ...urlPart.codeUnits];
  }

  @override
  int get estimatedSize => url.length + 5;

  @override
  List<Object?> get props => [type, url, label];
}

/// Données texte
class TextWriteData extends WriteData {
  final String text;
  final String languageCode;

  const TextWriteData({
    required this.text,
    this.languageCode = 'fr',
    super.label,
  }) : super(type: WriteDataType.text);

  @override
  List<int> toNdefPayload() {
    final langBytes = languageCode.codeUnits;
    final textBytes = text.codeUnits;

    return [
      langBytes.length, // Status byte avec longueur du code langue
      ...langBytes,
      ...textBytes,
    ];
  }

  @override
  int get estimatedSize => text.length + languageCode.length + 5;

  @override
  List<Object?> get props => [type, text, languageCode, label];
}

/// Données vCard
class VCardWriteData extends WriteData {
  final String firstName;
  final String lastName;
  final String? organization;
  final String? title;
  final String? phone;
  final String? email;
  final String? website;
  final String? address;
  final String? note;

  const VCardWriteData({
    required this.firstName,
    required this.lastName,
    this.organization,
    this.title,
    this.phone,
    this.email,
    this.website,
    this.address,
    this.note,
    super.label,
  }) : super(type: WriteDataType.vcard);

  String toVCardString() {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('N:$lastName;$firstName;;;');
    buffer.writeln('FN:$firstName $lastName');

    if (organization != null) buffer.writeln('ORG:$organization');
    if (title != null) buffer.writeln('TITLE:$title');
    if (phone != null) buffer.writeln('TEL:$phone');
    if (email != null) buffer.writeln('EMAIL:$email');
    if (website != null) buffer.writeln('URL:$website');
    if (address != null) buffer.writeln('ADR:;;$address;;;;');
    if (note != null) buffer.writeln('NOTE:$note');

    buffer.writeln('END:VCARD');
    return buffer.toString();
  }

  @override
  List<int> toNdefPayload() {
    return toVCardString().codeUnits;
  }

  @override
  int get estimatedSize => toVCardString().length + 10;

  @override
  List<Object?> get props => [
        type,
        firstName,
        lastName,
        organization,
        title,
        phone,
        email,
        website,
        address,
        note,
        label,
      ];
}

/// Données WiFi
class WifiWriteData extends WriteData {
  final String ssid;
  final String password;
  final WifiAuthType authType;
  final bool isHidden;

  const WifiWriteData({
    required this.ssid,
    required this.password,
    this.authType = WifiAuthType.wpa2,
    this.isHidden = false,
    super.label,
  }) : super(type: WriteDataType.wifi);

  @override
  List<int> toNdefPayload() {
    // Format WiFi Simple Configuration
    final buffer = <int>[];

    // Credential
    buffer.addAll([0x10, 0x0E]); // Attribute: Credential
    // ... encodage complet WiFi

    return buffer;
  }

  @override
  int get estimatedSize => ssid.length + password.length + 50;

  @override
  List<Object?> get props => [type, ssid, password, authType, isHidden, label];
}

enum WifiAuthType {
  open('Ouvert'),
  wep('WEP'),
  wpa('WPA'),
  wpa2('WPA2'),
  wpa3('WPA3');

  final String displayName;

  const WifiAuthType(this.displayName);
}

/// Données téléphone
class PhoneWriteData extends WriteData {
  final String phoneNumber;

  const PhoneWriteData({
    required this.phoneNumber,
    super.label,
  }) : super(type: WriteDataType.phone);

  @override
  List<int> toNdefPayload() {
    // URI scheme: tel:
    return [0x05, ...phoneNumber.replaceAll(' ', '').codeUnits];
  }

  @override
  int get estimatedSize => phoneNumber.length + 10;

  @override
  List<Object?> get props => [type, phoneNumber, label];
}

/// Données email
class EmailWriteData extends WriteData {
  final String emailAddress;
  final String? subject;
  final String? body;

  const EmailWriteData({
    required this.emailAddress,
    this.subject,
    this.body,
    super.label,
  }) : super(type: WriteDataType.email);

  @override
  List<int> toNdefPayload() {
    // URI scheme: mailto:
    var mailto = emailAddress;
    if (subject != null || body != null) {
      mailto += '?';
      if (subject != null) mailto += 'subject=${Uri.encodeComponent(subject!)}';
      if (body != null) {
        if (subject != null) mailto += '&';
        mailto += 'body=${Uri.encodeComponent(body!)}';
      }
    }
    return [0x06, ...mailto.codeUnits];
  }

  @override
  int get estimatedSize =>
      emailAddress.length + (subject?.length ?? 0) + (body?.length ?? 0) + 20;

  @override
  List<Object?> get props => [type, emailAddress, subject, body, label];
}

/// Données SMS
class SmsWriteData extends WriteData {
  final String phoneNumber;
  final String? message;

  const SmsWriteData({
    required this.phoneNumber,
    this.message,
    super.label,
  }) : super(type: WriteDataType.sms);

  @override
  List<int> toNdefPayload() {
    var sms = phoneNumber;
    if (message != null) {
      sms += '?body=${Uri.encodeComponent(message!)}';
    }
    return [0x00, ...'sms:$sms'.codeUnits];
  }

  @override
  int get estimatedSize => phoneNumber.length + (message?.length ?? 0) + 15;

  @override
  List<Object?> get props => [type, phoneNumber, message, label];
}

/// Données localisation
class LocationWriteData extends WriteData {
  final double latitude;
  final double longitude;
  final String? label;

  const LocationWriteData({
    required this.latitude,
    required this.longitude,
    this.label,
  }) : super(type: WriteDataType.location, label: label);

  @override
  List<int> toNdefPayload() {
    // URI scheme: geo:
    final geo = 'geo:$latitude,$longitude';
    return [0x00, ...geo.codeUnits];
  }

  @override
  int get estimatedSize => 30;

  @override
  List<Object?> get props => [type, latitude, longitude, label];
}

/// Template d'écriture sauvegardé
class WriteTemplate extends Equatable {
  final String id;
  final String name;
  final WriteDataType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final int useCount;
  final String? userId;
  final String? publicUrl;
  final bool isPublic;

  const WriteTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.data,
    required this.createdAt,
    DateTime? updatedAt,
    this.lastUsedAt,
    this.useCount = 0,
    this.userId,
    this.publicUrl,
    this.isPublic = false,
  }) : updatedAt = updatedAt ?? createdAt;

  WriteTemplate copyWith({
    String? name,
    Map<String, dynamic>? data,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    int? useCount,
    String? userId,
    String? publicUrl,
    bool? isPublic,
  }) {
    return WriteTemplate(
      id: id,
      name: name ?? this.name,
      type: type,
      data: data ?? this.data,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      useCount: useCount ?? this.useCount,
      userId: userId ?? this.userId,
      publicUrl: publicUrl ?? this.publicUrl,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  /// Génère l'URL publique pour partage
  String get shareUrl => publicUrl ?? 'https://cards-control.app/template/$id';

  /// Convertit en JSON pour stockage/API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'useCount': useCount,
      'userId': userId,
      'publicUrl': publicUrl,
      'isPublic': isPublic,
    };
  }

  /// Crée un template depuis JSON
  factory WriteTemplate.fromJson(Map<String, dynamic> json) {
    return WriteTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      type: WriteDataType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => WriteDataType.text,
      ),
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      useCount: json['useCount'] as int? ?? 0,
      userId: json['userId'] as String?,
      publicUrl: json['publicUrl'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, type, data, createdAt, updatedAt, lastUsedAt, useCount, userId, publicUrl, isPublic];
}
