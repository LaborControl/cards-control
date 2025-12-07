/// Modèle pour les données extraites d'une carte de visite scannée
class ScannedCardData {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? company;
  final String? jobTitle;
  final String? website;
  final String? address;
  final String rawText;
  final double confidence;

  const ScannedCardData({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.mobile,
    this.company,
    this.jobTitle,
    this.website,
    this.address,
    required this.rawText,
    this.confidence = 0.0,
  });

  /// Nom complet (pour compatibilité et affichage)
  String get fullName {
    final parts = [firstName, lastName].where((s) => s != null && s.isNotEmpty);
    return parts.join(' ');
  }

  /// Crée une copie avec les champs modifiés
  ScannedCardData copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? mobile,
    String? company,
    String? jobTitle,
    String? website,
    String? address,
    String? rawText,
    double? confidence,
  }) {
    return ScannedCardData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      website: website ?? this.website,
      address: address ?? this.address,
      rawText: rawText ?? this.rawText,
      confidence: confidence ?? this.confidence,
    );
  }

  /// Vérifie si au moins un champ a été détecté
  bool get hasDetectedFields {
    return firstName != null ||
        lastName != null ||
        email != null ||
        phone != null ||
        mobile != null ||
        company != null ||
        jobTitle != null ||
        website != null ||
        address != null;
  }

  /// Compte le nombre de champs détectés
  int get detectedFieldsCount {
    int count = 0;
    if (firstName != null) count++;
    if (lastName != null) count++;
    if (email != null) count++;
    if (phone != null) count++;
    if (mobile != null) count++;
    if (company != null) count++;
    if (jobTitle != null) count++;
    if (website != null) count++;
    if (address != null) count++;
    return count;
  }

  @override
  String toString() {
    return 'ScannedCardData(firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, mobile: $mobile, company: $company, jobTitle: $jobTitle, confidence: $confidence)';
  }
}
