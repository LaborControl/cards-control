import 'package:equatable/equatable.dart';

/// Types de cartes de visite disponibles
enum BusinessCardType {
  professional('professional', 'Professionnelle'),
  personal('personal', 'Personnelle'),
  profile('profile', 'Profil avec CV');

  final String value;
  final String displayName;

  const BusinessCardType(this.value, this.displayName);

  static BusinessCardType fromString(String? value) {
    return BusinessCardType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => BusinessCardType.professional,
    );
  }
}

/// Représente une carte de visite numérique
class BusinessCard extends Equatable {
  final String id;
  final String userId;
  final BusinessCardType cardType; // Type de carte: professional, personal, profile
  final String firstName;
  final String lastName;
  final String? jobTitle;
  final String? company; // Pour Pro: Entreprise, Pour Perso: Club ou Association
  final String? email;
  final String? phone;
  final String? mobile;
  final String? website;
  final String? address;
  final String? bio; // Pour Profil: Ma Bio
  final String? photoUrl;
  final String? logoUrl;
  final String? cvUrl; // Uniquement pour Profil
  final String? linkedinUrl; // Uniquement pour Profil (sur la première page)
  final String primaryColor;
  final String headerBackgroundType; // 'color', 'image', 'preset'
  final String? headerBackgroundValue; // URL image, code couleur, ou ID preset
  final Map<String, String> socialLinks;
  final Map<String, String> customFields;
  final String? templateId;
  final String? publicUrl;
  final String? qrCodeUrl;
  final bool isActive;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CardAnalytics analytics;

  const BusinessCard({
    required this.id,
    this.userId = '',
    this.cardType = BusinessCardType.professional,
    required this.firstName,
    required this.lastName,
    this.jobTitle,
    this.company,
    this.email,
    this.phone,
    this.mobile,
    this.website,
    this.address,
    this.bio,
    this.photoUrl,
    this.logoUrl,
    this.cvUrl,
    this.linkedinUrl,
    this.primaryColor = '#6366F1',
    this.headerBackgroundType = 'color',
    this.headerBackgroundValue,
    this.socialLinks = const {},
    this.customFields = const {},
    this.templateId,
    this.publicUrl,
    this.qrCodeUrl,
    this.isActive = true,
    this.isPrimary = false,
    required this.createdAt,
    required this.updatedAt,
    this.analytics = const CardAnalytics(),
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  BusinessCard copyWith({
    BusinessCardType? cardType,
    String? firstName,
    String? lastName,
    String? jobTitle,
    String? company,
    String? email,
    String? phone,
    String? mobile,
    String? website,
    String? address,
    String? bio,
    String? photoUrl,
    String? logoUrl,
    String? cvUrl,
    String? linkedinUrl,
    String? primaryColor,
    String? headerBackgroundType,
    String? headerBackgroundValue,
    Map<String, String>? socialLinks,
    Map<String, String>? customFields,
    String? templateId,
    String? publicUrl,
    String? qrCodeUrl,
    bool? isActive,
    bool? isPrimary,
    DateTime? updatedAt,
    CardAnalytics? analytics,
  }) {
    return BusinessCard(
      id: id,
      userId: userId,
      cardType: cardType ?? this.cardType,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      website: website ?? this.website,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      cvUrl: cvUrl ?? this.cvUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      headerBackgroundType: headerBackgroundType ?? this.headerBackgroundType,
      headerBackgroundValue: headerBackgroundValue ?? this.headerBackgroundValue,
      socialLinks: socialLinks ?? this.socialLinks,
      customFields: customFields ?? this.customFields,
      templateId: templateId ?? this.templateId,
      publicUrl: publicUrl ?? this.publicUrl,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      isActive: isActive ?? this.isActive,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      analytics: analytics ?? this.analytics,
    );
  }

  factory BusinessCard.fromJson(Map<String, dynamic> json) {
    final socialLinksRaw = json['socialLinks'];
    final customFieldsRaw = json['customFields'];
    final analyticsRaw = json['analytics'];

    return BusinessCard(
      id: json['id'],
      userId: json['userId'] ?? '',
      cardType: BusinessCardType.fromString(json['cardType']),
      firstName: json['firstName'],
      lastName: json['lastName'],
      jobTitle: json['jobTitle'],
      company: json['company'],
      email: json['email'],
      phone: json['phone'],
      mobile: json['mobile'],
      website: json['website'],
      address: json['address'],
      bio: json['bio'],
      photoUrl: json['photoUrl'],
      logoUrl: json['logoUrl'],
      cvUrl: json['cvUrl'],
      linkedinUrl: json['linkedinUrl'],
      primaryColor: json['primaryColor'] ?? '#6366F1',
      headerBackgroundType: json['headerBackgroundType'] ?? 'color',
      headerBackgroundValue: json['headerBackgroundValue'],
      socialLinks: socialLinksRaw != null
          ? Map<String, String>.from(socialLinksRaw as Map)
          : {},
      customFields: customFieldsRaw != null
          ? Map<String, String>.from(customFieldsRaw as Map)
          : {},
      templateId: json['templateId'],
      publicUrl: json['publicUrl'],
      qrCodeUrl: json['qrCodeUrl'],
      isActive: json['isActive'] ?? true,
      isPrimary: json['isPrimary'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      analytics: analyticsRaw != null
          ? CardAnalytics.fromJson(Map<String, dynamic>.from(analyticsRaw as Map))
          : const CardAnalytics(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'cardType': cardType.value,
      'firstName': firstName,
      'lastName': lastName,
      'jobTitle': jobTitle,
      'company': company,
      'email': email,
      'phone': phone,
      'mobile': mobile,
      'website': website,
      'address': address,
      'bio': bio,
      'photoUrl': photoUrl,
      'logoUrl': logoUrl,
      'cvUrl': cvUrl,
      'linkedinUrl': linkedinUrl,
      'primaryColor': primaryColor,
      'headerBackgroundType': headerBackgroundType,
      'headerBackgroundValue': headerBackgroundValue,
      'socialLinks': socialLinks,
      'customFields': customFields,
      'templateId': templateId,
      'publicUrl': publicUrl,
      'qrCodeUrl': qrCodeUrl,
      'isActive': isActive,
      'isPrimary': isPrimary,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'analytics': analytics.toJson(),
    };
  }

  /// Génère une vCard
  String toVCard() {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('N:$lastName;$firstName;;;');
    buffer.writeln('FN:$fullName');

    if (company != null && company!.isNotEmpty) {
      buffer.writeln('ORG:$company');
    }
    if (jobTitle != null && jobTitle!.isNotEmpty) {
      buffer.writeln('TITLE:$jobTitle');
    }
    if (email != null && email!.isNotEmpty) {
      buffer.writeln('EMAIL:$email');
    }
    if (phone != null && phone!.isNotEmpty) {
      buffer.writeln('TEL;TYPE=WORK:$phone');
    }
    if (mobile != null && mobile!.isNotEmpty) {
      buffer.writeln('TEL;TYPE=CELL:$mobile');
    }
    if (website != null && website!.isNotEmpty) {
      buffer.writeln('URL:$website');
    }
    if (address != null && address!.isNotEmpty) {
      buffer.writeln('ADR:;;$address;;;;');
    }
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      buffer.writeln('PHOTO;VALUE=URI:$photoUrl');
    }
    if (bio != null && bio!.isNotEmpty) {
      buffer.writeln('NOTE:$bio');
    }

    // Réseaux sociaux
    socialLinks.forEach((network, url) {
      buffer.writeln('X-SOCIALPROFILE;TYPE=$network:$url');
    });

    buffer.writeln('END:VCARD');
    return buffer.toString();
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        cardType,
        firstName,
        lastName,
        jobTitle,
        company,
        email,
        phone,
        mobile,
        website,
        address,
        bio,
        photoUrl,
        logoUrl,
        cvUrl,
        linkedinUrl,
        primaryColor,
        headerBackgroundType,
        headerBackgroundValue,
        socialLinks,
        customFields,
        templateId,
        publicUrl,
        qrCodeUrl,
        isActive,
        isPrimary,
        createdAt,
        updatedAt,
        analytics,
      ];
}

/// Analytics d'une carte de visite
class CardAnalytics extends Equatable {
  final int totalViews;
  final int totalScans;
  final int totalShares;
  final int contactsSaved;
  final DateTime? lastSharedAt;
  final Map<String, int> sharesByMethod;
  final List<ViewRecord> recentViews;

  const CardAnalytics({
    this.totalViews = 0,
    this.totalScans = 0,
    this.totalShares = 0,
    this.contactsSaved = 0,
    this.lastSharedAt,
    this.sharesByMethod = const {},
    this.recentViews = const [],
  });

  CardAnalytics copyWith({
    int? totalViews,
    int? totalScans,
    int? totalShares,
    int? contactsSaved,
    DateTime? lastSharedAt,
    Map<String, int>? sharesByMethod,
    List<ViewRecord>? recentViews,
  }) {
    return CardAnalytics(
      totalViews: totalViews ?? this.totalViews,
      totalScans: totalScans ?? this.totalScans,
      totalShares: totalShares ?? this.totalShares,
      contactsSaved: contactsSaved ?? this.contactsSaved,
      lastSharedAt: lastSharedAt ?? this.lastSharedAt,
      sharesByMethod: sharesByMethod ?? this.sharesByMethod,
      recentViews: recentViews ?? this.recentViews,
    );
  }

  factory CardAnalytics.fromJson(Map<String, dynamic> json) {
    final sharesByMethodRaw = json['sharesByMethod'];
    final recentViewsRaw = json['recentViews'];

    return CardAnalytics(
      totalViews: json['totalViews'] ?? 0,
      totalScans: json['totalScans'] ?? 0,
      totalShares: json['totalShares'] ?? 0,
      contactsSaved: json['contactsSaved'] ?? 0,
      lastSharedAt: json['lastSharedAt'] != null
          ? DateTime.parse(json['lastSharedAt'])
          : null,
      sharesByMethod: sharesByMethodRaw != null
          ? Map<String, int>.from(sharesByMethodRaw as Map)
          : {},
      recentViews: recentViewsRaw != null
          ? (recentViewsRaw as List)
              .map((e) => ViewRecord.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalViews': totalViews,
      'totalScans': totalScans,
      'totalShares': totalShares,
      'contactsSaved': contactsSaved,
      'lastSharedAt': lastSharedAt?.toIso8601String(),
      'sharesByMethod': sharesByMethod,
      'recentViews': recentViews.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        totalViews,
        totalScans,
        totalShares,
        contactsSaved,
        lastSharedAt,
        sharesByMethod,
        recentViews,
      ];
}

/// Enregistrement d'une vue
class ViewRecord extends Equatable {
  final DateTime timestamp;
  final String? source;
  final String? location;

  const ViewRecord({
    required this.timestamp,
    this.source,
    this.location,
  });

  factory ViewRecord.fromJson(Map<String, dynamic> json) {
    return ViewRecord(
      timestamp: DateTime.parse(json['timestamp']),
      source: json['source'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'location': location,
    };
  }

  @override
  List<Object?> get props => [timestamp, source, location];
}

/// Template de carte de visite
class CardTemplate extends Equatable {
  final String id;
  final String name;
  final String category;
  final String thumbnailUrl;
  final Map<String, dynamic> config;
  final bool isPremium;

  const CardTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.thumbnailUrl,
    required this.config,
    this.isPremium = false,
  });

  @override
  List<Object?> get props => [id, name, category, thumbnailUrl, config, isPremium];
}

/// Réseaux sociaux supportés
enum SocialNetwork {
  linkedin('LinkedIn', 'linkedin'),
  twitter('Twitter/X', 'twitter'),
  facebook('Facebook', 'facebook'),
  instagram('Instagram', 'instagram'),
  github('GitHub', 'github'),
  youtube('YouTube', 'youtube'),
  tiktok('TikTok', 'tiktok'),
  whatsapp('WhatsApp', 'whatsapp'),
  telegram('Telegram', 'telegram');

  final String displayName;
  final String key;

  const SocialNetwork(this.displayName, this.key);
}
