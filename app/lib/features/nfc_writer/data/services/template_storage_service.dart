import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/write_data.dart';
import '../repositories/firebase_templates_repository.dart';

class TemplateStorageService {
  static const _boxName = 'nfc_write_templates';
  static TemplateStorageService? _instance;
  Box<String>? _box;
  final FirebaseTemplatesRepository _firebaseRepo = FirebaseTemplatesRepository.instance;

  /// IDs des templates en attente de synchronisation
  final Set<String> _pendingSyncIds = {};

  /// Indique si une synchronisation est en cours
  bool _isSyncing = false;

  TemplateStorageService._();

  static TemplateStorageService get instance {
    _instance ??= TemplateStorageService._();
    return _instance!;
  }

  /// Vérifie si un template est en attente de sync
  bool isPendingSync(String templateId) => _pendingSyncIds.contains(templateId);

  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_boxName);
    return _box!;
  }

  Future<List<WriteTemplate>> loadTemplates() async {
    final box = await _getBox();
    final templates = <WriteTemplate>[];

    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          templates.add(WriteTemplate.fromJson(json.decode(jsonStr)));
        } catch (_) {}
      }
    }

    // Trier par date de mise à jour décroissante
    templates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return templates;
  }

  Future<void> saveTemplates(List<WriteTemplate> templates) async {
    final box = await _getBox();
    await box.clear();
    for (final template in templates) {
      await box.put(template.id, json.encode(template.toJson()));
    }
  }

  Future<WriteTemplate> addTemplate({
    required String name,
    required WriteDataType type,
    required Map<String, dynamic> data,
  }) async {
    final now = DateTime.now();
    final templates = await loadTemplates();
    final template = WriteTemplate(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      data: data,
      createdAt: now,
      updatedAt: now,
      userId: _firebaseRepo.userId,
      isPublic: true, // Publié par défaut
      publicUrl: 'https://cards-control.app/template/${now.millisecondsSinceEpoch}',
    );
    templates.insert(0, template);
    await saveTemplates(templates);

    // Synchroniser avec Firebase ET publier automatiquement
    _syncAndPublishToFirebase(template);

    return template;
  }

  Future<void> updateTemplate(WriteTemplate template) async {
    final templates = await loadTemplates();
    final index = templates.indexWhere((t) => t.id == template.id);
    if (index >= 0) {
      final updatedTemplate = template.copyWith(updatedAt: DateTime.now());
      templates[index] = updatedTemplate;
      await saveTemplates(templates);

      // Synchroniser avec Firebase
      _syncToFirebaseWithRetry(updatedTemplate);
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    final templates = await loadTemplates();
    templates.removeWhere((t) => t.id == templateId);
    await saveTemplates(templates);

    // Supprimer de Firebase
    _syncDeleteToFirebase(templateId);
  }

  Future<void> incrementUseCount(String templateId) async {
    final templates = await loadTemplates();
    final index = templates.indexWhere((t) => t.id == templateId);
    if (index >= 0) {
      final updatedTemplate = templates[index].copyWith(
        lastUsedAt: DateTime.now(),
        useCount: templates[index].useCount + 1,
      );
      templates[index] = updatedTemplate;
      await saveTemplates(templates);

      // Synchroniser avec Firebase
      _syncToFirebaseWithRetry(updatedTemplate);
    }
  }

  // ==================== Firebase Sync avec LWW ====================

  /// Synchronise un template vers Firebase avec retry (en arrière-plan)
  void _syncToFirebaseWithRetry(WriteTemplate template, {int attempt = 0}) async {
    if (!_firebaseRepo.isAuthenticated) return;

    _pendingSyncIds.add(template.id);

    try {
      await _firebaseRepo.syncTemplateWithLWW(template);
      _pendingSyncIds.remove(template.id);
    } catch (e) {
      print('Failed to sync template to Firebase (attempt $attempt): $e');
      // Retry avec backoff exponentiel (max 3 tentatives)
      if (attempt < 3) {
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
        _syncToFirebaseWithRetry(template, attempt: attempt + 1);
      } else {
        print('Giving up sync for template ${template.id}');
        _pendingSyncIds.remove(template.id);
      }
    }
  }

  /// Synchronise ET publie un nouveau template (en arrière-plan)
  void _syncAndPublishToFirebase(WriteTemplate template, {int attempt = 0}) async {
    if (!_firebaseRepo.isAuthenticated) return;

    _pendingSyncIds.add(template.id);

    try {
      // 1. Sync vers collection privée
      await _firebaseRepo.syncTemplateWithLWW(template);
      // 2. Publier vers collection publique
      await _firebaseRepo.publishTemplate(template);
      _pendingSyncIds.remove(template.id);
    } catch (e) {
      print('Failed to sync and publish template (attempt $attempt): $e');
      if (attempt < 3) {
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
        _syncAndPublishToFirebase(template, attempt: attempt + 1);
      } else {
        print('Giving up sync for template ${template.id}');
        _pendingSyncIds.remove(template.id);
      }
    }
  }

  /// Supprime un modèle de Firebase (en arrière-plan)
  void _syncDeleteToFirebase(String templateId) async {
    if (!_firebaseRepo.isAuthenticated) return;

    try {
      await _firebaseRepo.deleteTemplate(templateId);
    } catch (e) {
      print('Failed to delete template from Firebase: $e');
    }
  }

  /// Synchronisation bidirectionnelle complète avec stratégie LWW
  Future<List<WriteTemplate>> syncWithFirebase() async {
    if (!_firebaseRepo.isAuthenticated || _isSyncing) {
      return await loadTemplates();
    }

    _isSyncing = true;

    try {
      final localTemplates = await loadTemplates();
      final remoteTemplates = await _firebaseRepo.getAllTemplates();

      // Créer des maps pour accès rapide
      final localMap = {for (var t in localTemplates) t.id: t};
      final remoteMap = {for (var t in remoteTemplates) t.id: t};

      final mergedTemplates = <WriteTemplate>[];
      final templatesToUpload = <WriteTemplate>[];

      // Parcourir les templates locaux
      for (final localTemplate in localTemplates) {
        final remoteTemplate = remoteMap[localTemplate.id];

        if (remoteTemplate == null) {
          // Template local uniquement → uploader
          mergedTemplates.add(localTemplate);
          templatesToUpload.add(localTemplate);
        } else if (localTemplate.updatedAt.isAfter(remoteTemplate.updatedAt)) {
          // Local plus récent → garder local, uploader
          mergedTemplates.add(localTemplate);
          templatesToUpload.add(localTemplate);
        } else if (remoteTemplate.updatedAt.isAfter(localTemplate.updatedAt)) {
          // Remote plus récent → utiliser remote
          mergedTemplates.add(remoteTemplate);
        } else {
          // Même timestamp → garder local (arbitraire mais cohérent)
          mergedTemplates.add(localTemplate);
        }
      }

      // Ajouter les templates remote-only
      for (final remoteTemplate in remoteTemplates) {
        if (!localMap.containsKey(remoteTemplate.id)) {
          mergedTemplates.add(remoteTemplate);
        }
      }

      // Trier par date de mise à jour
      mergedTemplates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      // Sauvegarder localement
      await saveTemplates(mergedTemplates);

      // Uploader les templates modifiés
      for (final template in templatesToUpload) {
        _syncToFirebaseWithRetry(template);
      }

      return mergedTemplates;
    } catch (e) {
      print('Failed to sync with Firebase: $e');
      return await loadTemplates();
    } finally {
      _isSyncing = false;
    }
  }

  /// Publie un template pour le partage public
  Future<WriteTemplate?> publishTemplate(String templateId) async {
    if (!_firebaseRepo.isAuthenticated) return null;

    try {
      final templates = await loadTemplates();
      final index = templates.indexWhere((t) => t.id == templateId);
      if (index < 0) return null;

      final publicUrl = await _firebaseRepo.publishTemplate(templates[index]);

      final updatedTemplate = templates[index].copyWith(
        isPublic: true,
        publicUrl: publicUrl,
      );
      templates[index] = updatedTemplate;
      await saveTemplates(templates);

      return updatedTemplate;
    } catch (e) {
      print('Failed to publish template: $e');
      return null;
    }
  }

  /// Retire un template du partage public
  Future<void> unpublishTemplate(String templateId) async {
    if (!_firebaseRepo.isAuthenticated) return;

    try {
      await _firebaseRepo.unpublishTemplate(templateId);

      final templates = await loadTemplates();
      final index = templates.indexWhere((t) => t.id == templateId);
      if (index >= 0) {
        templates[index] = templates[index].copyWith(
          isPublic: false,
          publicUrl: null,
        );
        await saveTemplates(templates);
      }
    } catch (e) {
      print('Failed to unpublish template: $e');
    }
  }

  /// Génère le contenu NDEF à partir d'un template
  String generateNdefContent(WriteTemplate template) {
    switch (template.type) {
      case WriteDataType.url:
        return template.data['url'] as String? ?? '';
      case WriteDataType.text:
        return template.data['text'] as String? ?? '';
      case WriteDataType.wifi:
        final ssid = template.data['ssid'] as String? ?? '';
        final password = template.data['password'] as String? ?? '';
        final authType = template.data['authType'] as String? ?? 'WPA2';
        return 'WIFI:T:$authType;S:$ssid;P:$password;;';
      case WriteDataType.vcard:
        return _generateVCard(template.data);
      case WriteDataType.phone:
        return 'tel:${template.data['phone'] ?? ''}';
      case WriteDataType.email:
        final email = template.data['email'] as String? ?? '';
        final subject = template.data['subject'] as String? ?? '';
        final body = template.data['body'] as String? ?? '';
        var mailto = 'mailto:$email';
        if (subject.isNotEmpty || body.isNotEmpty) {
          mailto += '?';
          if (subject.isNotEmpty) mailto += 'subject=${Uri.encodeComponent(subject)}';
          if (body.isNotEmpty) {
            if (subject.isNotEmpty) mailto += '&';
            mailto += 'body=${Uri.encodeComponent(body)}';
          }
        }
        return mailto;
      case WriteDataType.sms:
        final phone = template.data['phone'] as String? ?? '';
        final message = template.data['message'] as String? ?? '';
        return message.isNotEmpty
            ? 'sms:$phone?body=${Uri.encodeComponent(message)}'
            : 'sms:$phone';
      case WriteDataType.location:
        final lat = template.data['latitude'] ?? 0.0;
        final lng = template.data['longitude'] ?? 0.0;
        final label = template.data['label'] as String? ?? '';
        return label.isNotEmpty
            ? 'geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(label)})'
            : 'geo:$lat,$lng';
      case WriteDataType.event:
        return _generateEventContent(template.data);
      case WriteDataType.googleReview:
        final placeId = template.data['placeId'] as String? ?? '';
        return 'https://search.google.com/local/writereview?placeid=$placeId';
      case WriteDataType.appDownload:
        final appStoreUrl = template.data['appStoreUrl'] as String? ?? '';
        final playStoreUrl = template.data['playStoreUrl'] as String? ?? '';
        return playStoreUrl.isNotEmpty ? playStoreUrl : appStoreUrl;
      case WriteDataType.tip:
        final provider = template.data['provider'] as String? ?? 'paypal';
        if (provider == 'paypal') {
          return template.data['paypalUrl'] as String? ?? '';
        } else if (provider == 'stripe') {
          return template.data['stripeUrl'] as String? ?? '';
        } else {
          return template.data['customUrl'] as String? ?? '';
        }
      case WriteDataType.medicalId:
        return _generateMedicalIdContent(template.data);
      case WriteDataType.petId:
        return _generatePetIdContent(template.data);
      case WriteDataType.luggageId:
        return _generateLuggageIdContent(template.data);
      default:
        return template.data['content'] as String? ?? '';
    }
  }

  String _generateMedicalIdContent(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('=== ID MÉDICAL ===');
    if (data['name'] != null) buffer.writeln('Nom: ${data['name']}');
    if (data['bloodType'] != null && (data['bloodType'] as String).isNotEmpty) {
      buffer.writeln('Groupe sanguin: ${data['bloodType']}');
    }
    if (data['allergies'] != null && (data['allergies'] as String).isNotEmpty) {
      buffer.writeln('Allergies: ${data['allergies']}');
    }
    if (data['medications'] != null && (data['medications'] as String).isNotEmpty) {
      buffer.writeln('Médicaments: ${data['medications']}');
    }
    if (data['conditions'] != null && (data['conditions'] as String).isNotEmpty) {
      buffer.writeln('Conditions: ${data['conditions']}');
    }
    if (data['emergencyContact'] != null && (data['emergencyContact'] as String).isNotEmpty) {
      buffer.writeln('Contact urgence: ${data['emergencyContact']}');
    }
    if (data['doctorName'] != null && (data['doctorName'] as String).isNotEmpty) {
      buffer.writeln('Médecin: ${data['doctorName']}');
    }
    if (data['doctorPhone'] != null && (data['doctorPhone'] as String).isNotEmpty) {
      buffer.writeln('Tél. médecin: ${data['doctorPhone']}');
    }
    return buffer.toString();
  }

  String _generatePetIdContent(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('=== ID ANIMAL ===');
    if (data['petName'] != null) buffer.writeln('Nom: ${data['petName']}');
    if (data['species'] != null && (data['species'] as String).isNotEmpty) {
      buffer.writeln('Espèce: ${data['species']}');
    }
    if (data['breed'] != null && (data['breed'] as String).isNotEmpty) {
      buffer.writeln('Race: ${data['breed']}');
    }
    if (data['chipNumber'] != null && (data['chipNumber'] as String).isNotEmpty) {
      buffer.writeln('N° puce: ${data['chipNumber']}');
    }
    buffer.writeln('--- Propriétaire ---');
    if (data['ownerName'] != null) buffer.writeln('Nom: ${data['ownerName']}');
    if (data['ownerPhone'] != null) buffer.writeln('Tél: ${data['ownerPhone']}');
    if (data['vetName'] != null && (data['vetName'] as String).isNotEmpty) {
      buffer.writeln('--- Vétérinaire ---');
      buffer.writeln('Cabinet: ${data['vetName']}');
    }
    if (data['vetPhone'] != null && (data['vetPhone'] as String).isNotEmpty) {
      buffer.writeln('Tél: ${data['vetPhone']}');
    }
    return buffer.toString();
  }

  String _generateLuggageIdContent(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('=== ID BAGAGES ===');
    if (data['ownerName'] != null) buffer.writeln('Propriétaire: ${data['ownerName']}');
    if (data['ownerPhone'] != null) buffer.writeln('Tél: ${data['ownerPhone']}');
    if (data['ownerEmail'] != null && (data['ownerEmail'] as String).isNotEmpty) {
      buffer.writeln('Email: ${data['ownerEmail']}');
    }
    if (data['address'] != null && (data['address'] as String).isNotEmpty) {
      buffer.writeln('Adresse: ${data['address']}');
    }
    if (data['flightNumber'] != null && (data['flightNumber'] as String).isNotEmpty) {
      buffer.writeln('Vol: ${data['flightNumber']}');
    }
    return buffer.toString();
  }

  String _generateEventContent(Map<String, dynamic> data) {
    // Format iCalendar (VCALENDAR) pour les événements
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('BEGIN:VEVENT');

    final title = data['title'] as String? ?? 'Événement';
    buffer.writeln('SUMMARY:$title');

    if (data['date'] != null) {
      final date = DateTime.tryParse(data['date'] as String);
      if (date != null) {
        final dateStr = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
        if (data['time'] != null && (data['time'] as String).isNotEmpty) {
          final timeParts = (data['time'] as String).split(':');
          final timeStr = '${timeParts[0].padLeft(2, '0')}${timeParts.length > 1 ? timeParts[1].padLeft(2, '0') : '00'}00';
          buffer.writeln('DTSTART:${dateStr}T$timeStr');
        } else {
          buffer.writeln('DTSTART;VALUE=DATE:$dateStr');
        }
      }
    }

    // Combiner lieu et adresse pour LOCATION iCalendar
    final location = data['location'] as String? ?? '';
    final address = data['address'] as String? ?? '';
    final fullLocation = [location, address].where((s) => s.isNotEmpty).join(' - ');
    if (fullLocation.isNotEmpty) {
      buffer.writeln('LOCATION:$fullLocation');
    }

    if (data['description'] != null && (data['description'] as String).isNotEmpty) {
      buffer.writeln('DESCRIPTION:${data['description']}');
    }

    if (data['url'] != null && (data['url'] as String).isNotEmpty) {
      buffer.writeln('URL:${data['url']}');
    }

    buffer.writeln('END:VEVENT');
    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  String _generateVCard(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');

    final firstName = data['firstName'] as String? ?? '';
    final lastName = data['lastName'] as String? ?? '';
    buffer.writeln('N:$lastName;$firstName;;;');
    buffer.writeln('FN:$firstName $lastName');

    if (data['organization'] != null) buffer.writeln('ORG:${data['organization']}');
    if (data['title'] != null) buffer.writeln('TITLE:${data['title']}');
    if (data['phone'] != null) buffer.writeln('TEL:${data['phone']}');
    if (data['email'] != null) buffer.writeln('EMAIL:${data['email']}');
    if (data['website'] != null) buffer.writeln('URL:${data['website']}');

    buffer.writeln('END:VCARD');
    return buffer.toString();
  }

  /// Retourne une description courte du template
  String getTemplateDescription(WriteTemplate template) {
    switch (template.type) {
      case WriteDataType.url:
        return template.data['url'] as String? ?? 'URL';
      case WriteDataType.text:
        final text = template.data['text'] as String? ?? '';
        return text.length > 50 ? '${text.substring(0, 50)}...' : text;
      case WriteDataType.wifi:
        return 'WiFi: ${template.data['ssid'] ?? ''}';
      case WriteDataType.vcard:
        return '${template.data['firstName'] ?? ''} ${template.data['lastName'] ?? ''}'.trim();
      case WriteDataType.phone:
        return template.data['phone'] as String? ?? 'Téléphone';
      case WriteDataType.email:
        return template.data['email'] as String? ?? 'Email';
      case WriteDataType.sms:
        return 'SMS: ${template.data['phone'] ?? ''}';
      case WriteDataType.location:
        return template.data['label'] as String? ?? 'Position GPS';
      case WriteDataType.event:
        final title = template.data['title'] as String? ?? '';
        final date = template.data['date'] as String?;
        if (date != null) {
          final parsedDate = DateTime.tryParse(date);
          if (parsedDate != null) {
            return '$title - ${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
          }
        }
        return title.isNotEmpty ? title : 'Événement';
      case WriteDataType.googleReview:
        return 'Avis Google';
      case WriteDataType.appDownload:
        return 'Téléchargement App';
      case WriteDataType.tip:
        final provider = template.data['provider'] as String? ?? 'paypal';
        return 'Pourboire ($provider)';
      case WriteDataType.medicalId:
        final name = template.data['name'] as String? ?? '';
        return name.isNotEmpty ? 'ID Médical: $name' : 'ID Médical';
      case WriteDataType.petId:
        final petName = template.data['petName'] as String? ?? '';
        return petName.isNotEmpty ? 'ID Animal: $petName' : 'ID Animal';
      case WriteDataType.luggageId:
        final ownerName = template.data['ownerName'] as String? ?? '';
        return ownerName.isNotEmpty ? 'Bagages: $ownerName' : 'ID Bagages';
      default:
        return template.name;
    }
  }

  /// Retourne l'icône appropriée pour le type
  static String getTypeIcon(WriteDataType type) {
    switch (type) {
      case WriteDataType.url:
        return 'link';
      case WriteDataType.text:
        return 'text_fields';
      case WriteDataType.wifi:
        return 'wifi';
      case WriteDataType.vcard:
        return 'contact_page';
      case WriteDataType.phone:
        return 'phone';
      case WriteDataType.email:
        return 'email';
      case WriteDataType.sms:
        return 'sms';
      case WriteDataType.location:
        return 'location_on';
      case WriteDataType.event:
        return 'event';
      case WriteDataType.launchApp:
        return 'apps';
      case WriteDataType.bluetooth:
        return 'bluetooth';
      case WriteDataType.googleReview:
        return 'star_rate';
      case WriteDataType.appDownload:
        return 'download';
      case WriteDataType.tip:
        return 'attach_money';
      case WriteDataType.medicalId:
        return 'medical_services';
      case WriteDataType.petId:
        return 'pets';
      case WriteDataType.luggageId:
        return 'luggage';
      default:
        return 'nfc';
    }
  }

  /// Crée un template à partir d'un enregistrement NDEF lu
  /// Retourne null si l'enregistrement n'est pas exploitable
  Future<WriteTemplate?> createTemplateFromNdef({
    required String name,
    required String ndefType,
    required String? decodedPayload,
    required List<int> payload,
  }) async {
    if (decodedPayload == null || decodedPayload.isEmpty) {
      return null;
    }

    WriteDataType? type;
    Map<String, dynamic> data = {};

    // Déterminer le type et extraire les données
    if (ndefType == 'uri' || ndefType == 'URI') {
      final content = decodedPayload;

      // Vérifier les différents schémas URI
      if (content.startsWith('tel:')) {
        type = WriteDataType.phone;
        data = {'phone': content.substring(4)};
      } else if (content.startsWith('mailto:')) {
        type = WriteDataType.email;
        final mailtoData = _parseMailto(content);
        data = mailtoData;
      } else if (content.startsWith('sms:')) {
        type = WriteDataType.sms;
        final smsData = _parseSms(content);
        data = smsData;
      } else if (content.startsWith('geo:')) {
        type = WriteDataType.location;
        final geoData = _parseGeo(content);
        data = geoData;
      } else if (content.startsWith('http://') || content.startsWith('https://')) {
        type = WriteDataType.url;
        data = {'url': content};
      } else {
        // URL générique
        type = WriteDataType.url;
        data = {'url': content};
      }
    } else if (ndefType == 'text' || ndefType == 'Text') {
      type = WriteDataType.text;
      data = {'text': decodedPayload};
    } else if (ndefType == 'wifi' || ndefType == 'WiFi') {
      type = WriteDataType.wifi;
      final wifiData = _parseWifi(decodedPayload);
      if (wifiData != null) {
        data = wifiData;
      } else {
        return null;
      }
    } else if (ndefType == 'vcard' || ndefType == 'vCard') {
      type = WriteDataType.vcard;
      final vcardData = _parseVCard(decodedPayload);
      if (vcardData != null) {
        data = vcardData;
      } else {
        return null;
      }
    } else if (ndefType == 'mimeMedia' || ndefType == 'MIME Media') {
      // Essayer de détecter le contenu
      if (decodedPayload.contains('WIFI:') || decodedPayload.contains('wifi:')) {
        type = WriteDataType.wifi;
        final wifiData = _parseWifi(decodedPayload);
        if (wifiData != null) {
          data = wifiData;
        } else {
          return null;
        }
      } else if (decodedPayload.contains('BEGIN:VCARD')) {
        type = WriteDataType.vcard;
        final vcardData = _parseVCard(decodedPayload);
        if (vcardData != null) {
          data = vcardData;
        } else {
          return null;
        }
      } else {
        // Contenu texte générique
        type = WriteDataType.text;
        data = {'text': decodedPayload};
      }
    } else {
      // Type non reconnu mais avec du contenu
      type = WriteDataType.text;
      data = {'text': decodedPayload};
    }

    return addTemplate(name: name, type: type, data: data);
  }

  /// Parse une URL mailto
  Map<String, dynamic> _parseMailto(String mailto) {
    final result = <String, dynamic>{};

    // Supprimer le préfixe mailto:
    var content = mailto.substring(7);

    // Séparer l'email des paramètres
    final questionIndex = content.indexOf('?');
    if (questionIndex > 0) {
      result['email'] = content.substring(0, questionIndex);
      final params = content.substring(questionIndex + 1).split('&');
      for (final param in params) {
        final parts = param.split('=');
        if (parts.length == 2) {
          final key = parts[0].toLowerCase();
          final value = Uri.decodeComponent(parts[1]);
          if (key == 'subject') result['subject'] = value;
          if (key == 'body') result['body'] = value;
        }
      }
    } else {
      result['email'] = content;
    }

    return result;
  }

  /// Parse une URL sms
  Map<String, dynamic> _parseSms(String sms) {
    final result = <String, dynamic>{};

    // Supprimer le préfixe sms:
    var content = sms.substring(4);

    // Séparer le numéro des paramètres
    final questionIndex = content.indexOf('?');
    if (questionIndex > 0) {
      result['phone'] = content.substring(0, questionIndex);
      final params = content.substring(questionIndex + 1).split('&');
      for (final param in params) {
        final parts = param.split('=');
        if (parts.length == 2 && parts[0].toLowerCase() == 'body') {
          result['message'] = Uri.decodeComponent(parts[1]);
        }
      }
    } else {
      result['phone'] = content;
    }

    return result;
  }

  /// Parse une URL geo
  Map<String, dynamic> _parseGeo(String geo) {
    final result = <String, dynamic>{};

    // Supprimer le préfixe geo:
    var content = geo.substring(4);

    // Format: geo:lat,lng ou geo:lat,lng?q=lat,lng(label)
    final questionIndex = content.indexOf('?');
    String coords;
    if (questionIndex > 0) {
      coords = content.substring(0, questionIndex);
      // Extraire le label si présent
      final queryPart = content.substring(questionIndex + 1);
      final labelMatch = RegExp(r'\((.+)\)').firstMatch(queryPart);
      if (labelMatch != null) {
        result['label'] = Uri.decodeComponent(labelMatch.group(1)!);
      }
    } else {
      coords = content;
    }

    final parts = coords.split(',');
    if (parts.length >= 2) {
      result['latitude'] = double.tryParse(parts[0]) ?? 0.0;
      result['longitude'] = double.tryParse(parts[1]) ?? 0.0;
    }

    return result;
  }

  /// Parse une configuration WiFi
  Map<String, dynamic>? _parseWifi(String wifi) {
    // Format: WIFI:T:WPA;S:ssid;P:password;;
    final result = <String, dynamic>{};

    final content = wifi.toUpperCase();
    if (!content.contains('WIFI:')) return null;

    // Extraire SSID
    final ssidMatch = RegExp(r'S:([^;]+)').firstMatch(wifi);
    if (ssidMatch != null) {
      result['ssid'] = ssidMatch.group(1);
    } else {
      return null;
    }

    // Extraire mot de passe
    final passMatch = RegExp(r'P:([^;]*)').firstMatch(wifi);
    if (passMatch != null) {
      result['password'] = passMatch.group(1);
    }

    // Extraire type d'auth
    final typeMatch = RegExp(r'T:([^;]+)').firstMatch(wifi);
    if (typeMatch != null) {
      result['authType'] = typeMatch.group(1);
    } else {
      result['authType'] = 'WPA2';
    }

    // Réseau caché
    final hiddenMatch = RegExp(r'H:(true|false)', caseSensitive: false).firstMatch(wifi);
    result['isHidden'] = hiddenMatch?.group(1)?.toLowerCase() == 'true';

    return result;
  }

  /// Parse une vCard
  Map<String, dynamic>? _parseVCard(String vcard) {
    if (!vcard.contains('BEGIN:VCARD')) return null;

    final result = <String, dynamic>{};
    final lines = vcard.split(RegExp(r'\r?\n'));

    for (final line in lines) {
      if (line.startsWith('N:')) {
        final parts = line.substring(2).split(';');
        if (parts.isNotEmpty) result['lastName'] = parts[0];
        if (parts.length > 1) result['firstName'] = parts[1];
      } else if (line.startsWith('FN:') && result['firstName'] == null) {
        final fullName = line.substring(3).trim();
        final parts = fullName.split(' ');
        if (parts.isNotEmpty) result['firstName'] = parts[0];
        if (parts.length > 1) result['lastName'] = parts.sublist(1).join(' ');
      } else if (line.startsWith('ORG:')) {
        result['organization'] = line.substring(4);
      } else if (line.startsWith('TITLE:')) {
        result['title'] = line.substring(6);
      } else if (line.startsWith('TEL')) {
        // TEL ou TEL;TYPE=xxx:
        final colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
          result['phone'] = line.substring(colonIndex + 1);
        }
      } else if (line.startsWith('EMAIL')) {
        final colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
          result['email'] = line.substring(colonIndex + 1);
        }
      } else if (line.startsWith('URL:')) {
        result['website'] = line.substring(4);
      } else if (line.startsWith('ADR')) {
        final colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
          // Format ADR: ;;street;city;state;zip;country
          final parts = line.substring(colonIndex + 1).split(';');
          final addressParts = parts.where((p) => p.isNotEmpty).toList();
          result['address'] = addressParts.join(', ');
        }
      } else if (line.startsWith('NOTE:')) {
        result['note'] = line.substring(5);
      }
    }

    // Vérifier qu'on a au moins un nom
    if (result['firstName'] == null && result['lastName'] == null) {
      return null;
    }

    result['firstName'] ??= '';
    result['lastName'] ??= '';

    return result;
  }

  /// Vérifie si un enregistrement NDEF peut être converti en template
  static bool canConvertToTemplate(String ndefType, String? decodedPayload) {
    if (decodedPayload == null || decodedPayload.isEmpty) {
      return false;
    }

    // Types directement exploitables
    const exploitableTypes = ['uri', 'URI', 'text', 'Text', 'wifi', 'WiFi', 'vcard', 'vCard'];
    if (exploitableTypes.contains(ndefType)) {
      return true;
    }

    // MIME Media peut contenir du contenu exploitable
    if (ndefType == 'mimeMedia' || ndefType == 'MIME Media') {
      return decodedPayload.contains('WIFI:') ||
          decodedPayload.contains('wifi:') ||
          decodedPayload.contains('BEGIN:VCARD') ||
          decodedPayload.isNotEmpty;
    }

    return false;
  }
}
