import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Catégorie de contact dynamique (synchronisée avec le web)
class ContactCategory {
  final String id;
  final String label;
  final Color color;
  final bool isDefault;

  const ContactCategory({
    required this.id,
    required this.label,
    required this.color,
    this.isDefault = false,
  });

  factory ContactCategory.fromJson(Map<String, dynamic> json) {
    return ContactCategory(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      color: _colorFromHex(json['color'] as String? ?? '#64748B'),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'color': '#${(color.a.toInt() << 24 | color.r.toInt() << 16 | color.g.toInt() << 8 | color.b.toInt()).toRadixString(16).substring(2).toUpperCase()}',
      'isDefault': isDefault,
    };
  }

  static Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Catégories par défaut (identiques au web-dashboard)
  static const List<ContactCategory> defaultCategories = [
    ContactCategory(id: 'friends', label: 'Amis', color: Color(0xFF10B981)),
    ContactCategory(id: 'family', label: 'Famille', color: Color(0xFFF59E0B)),
    ContactCategory(id: 'colleagues', label: 'Collègues', color: Color(0xFF3B82F6), isDefault: true),
    ContactCategory(id: 'association', label: 'Association', color: Color(0xFF8B5CF6)),
    ContactCategory(id: 'client', label: 'Client', color: Color(0xFFEC4899)),
    ContactCategory(id: 'supplier', label: 'Fournisseur', color: Color(0xFF6366F1)),
  ];

  /// Catégorie "Sans catégorie" pour les contacts sans catégorie
  static const ContactCategory none = ContactCategory(
    id: '',
    label: 'Sans catégorie',
    color: Color(0xFF64748B),
  );

  /// Trouve une catégorie par son ID dans une liste
  static ContactCategory findById(String? id, List<ContactCategory> categories) {
    if (id == null || id.isEmpty) return none;
    return categories.firstWhere(
      (c) => c.id == id,
      orElse: () => none,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Entité représentant un contact
class Contact {
  final String id;
  final String firstName;
  final String lastName;
  final String? company;
  final String? jobTitle;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? website;
  final String? address;
  final String? notes;
  final String? photoUrl;
  final String? companyLogoUrl;
  final Map<String, String> socialLinks;
  final String source; // 'nfc', 'scan', 'manual'
  final String category; // Catégorie du contact
  final DateTime createdAt;
  final DateTime updatedAt;

  const Contact({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.company,
    this.jobTitle,
    this.email,
    this.phone,
    this.mobile,
    this.website,
    this.address,
    this.notes,
    this.photoUrl,
    this.companyLogoUrl,
    this.socialLinks = const {},
    this.source = 'manual',
    this.category = 'none',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Obtient la catégorie du contact depuis une liste de catégories
  ContactCategory getCategory(List<ContactCategory> categories) {
    return ContactCategory.findById(category, categories);
  }

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  Contact copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? company,
    String? jobTitle,
    String? email,
    String? phone,
    String? mobile,
    String? website,
    String? address,
    String? notes,
    String? photoUrl,
    String? companyLogoUrl,
    Map<String, String>? socialLinks,
    String? source,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      website: website ?? this.website,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      socialLinks: socialLinks ?? this.socialLinks,
      source: source ?? this.source,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'company': company,
      'jobTitle': jobTitle,
      'email': email,
      'phone': phone,
      'mobile': mobile,
      'website': website,
      'address': address,
      'notes': notes,
      'photoUrl': photoUrl,
      'companyLogoUrl': companyLogoUrl,
      'socialLinks': socialLinks,
      'source': source,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      company: json['company'] as String?,
      jobTitle: json['jobTitle'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      mobile: json['mobile'] as String?,
      website: json['website'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      photoUrl: json['photoUrl'] as String?,
      companyLogoUrl: json['companyLogoUrl'] as String?,
      socialLinks: json['socialLinks'] != null
          ? Map<String, String>.from(json['socialLinks'] as Map)
          : {},
      source: json['source'] as String? ?? 'manual',
      category: json['category'] as String? ?? 'none',
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  factory Contact.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Contact(
      id: doc.id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      company: data['company'] as String?,
      jobTitle: data['jobTitle'] as String?,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      mobile: data['mobile'] as String?,
      website: data['website'] as String?,
      address: data['address'] as String?,
      notes: data['notes'] as String?,
      photoUrl: data['photoUrl'] as String?,
      companyLogoUrl: data['companyLogoUrl'] as String?,
      socialLinks: data['socialLinks'] != null
          ? Map<String, String>.from(data['socialLinks'] as Map)
          : {},
      source: data['source'] as String? ?? 'manual',
      category: data['category'] as String? ?? 'none',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
