import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../domain/entities/write_data.dart';

/// Repository Firebase pour les modèles de tags NFC
class FirebaseTemplatesRepository {
  static final FirebaseTemplatesRepository instance = FirebaseTemplatesRepository._();
  FirebaseTemplatesRepository._();

  final FirestoreService _firestore = FirestoreService.instance;
  final FirebaseAuthService _auth = FirebaseAuthService.instance;

  static const String _collection = 'nfc_templates';
  static const String _publicCollection = 'public_templates';

  /// ID de l'utilisateur actuel (accessible publiquement)
  String? get userId => _auth.currentUser?.uid;

  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => userId != null;

  /// Référence à la collection des modèles de l'utilisateur
  CollectionReference<Map<String, dynamic>> get _userTemplatesRef {
    if (userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users/$userId/$_collection');
  }

  /// Référence à la collection publique des modèles
  CollectionReference<Map<String, dynamic>> get _publicTemplatesRef {
    return FirebaseFirestore.instance.collection(_publicCollection);
  }

  // ==================== CRUD Operations ====================

  /// Crée un nouveau modèle dans Firebase
  Future<WriteTemplate> createTemplate(WriteTemplate template) async {
    if (userId == null) throw Exception('User not authenticated');

    final data = _templateToJson(template);
    data['userId'] = userId;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    // Utiliser l'ID local comme ID Firebase pour garder la cohérence
    await _userTemplatesRef.doc(template.id).set(data);

    return template;
  }

  /// Met à jour un modèle existant
  Future<void> updateTemplate(WriteTemplate template) async {
    if (userId == null) throw Exception('User not authenticated');

    final data = _templateToJson(template);
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _userTemplatesRef.doc(template.id).set(data, SetOptions(merge: true));
  }

  /// Supprime un modèle (privé et public)
  Future<void> deleteTemplate(String templateId) async {
    if (userId == null) throw Exception('User not authenticated');

    // Supprimer le modèle privé
    await _userTemplatesRef.doc(templateId).delete();

    // Supprimer aussi de la collection publique si présent
    try {
      await _publicTemplatesRef.doc(templateId).delete();
    } catch (_) {
      // Ignorer si le template public n'existe pas
    }
  }

  /// Récupère tous les modèles de l'utilisateur
  Future<List<WriteTemplate>> getAllTemplates() async {
    if (userId == null) return [];

    final snapshot = await _userTemplatesRef
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map(_templateFromDoc).toList();
  }

  /// Stream des modèles de l'utilisateur
  Stream<List<WriteTemplate>> watchTemplates() {
    if (userId == null) return Stream.value([]);

    return _userTemplatesRef
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_templateFromDoc).toList());
  }

  // ==================== Sync avec LWW ====================

  /// Synchronise un template avec stratégie Last-Write-Wins
  Future<void> syncTemplateWithLWW(WriteTemplate template) async {
    if (userId == null) throw Exception('User not authenticated');

    final docRef = _userTemplatesRef.doc(template.id);
    final data = _templateToJson(template);
    data['userId'] = userId;

    // Utiliser merge pour ne pas écraser les données serveur plus récentes
    await docRef.set(data, SetOptions(merge: true));

    // Si le template est public, mettre à jour aussi la collection publique
    if (template.isPublic) {
      await _syncToPublicCollection(template);
    }
  }

  /// Synchronise les modèles locaux vers Firebase
  Future<void> syncToFirebase(List<WriteTemplate> localTemplates) async {
    if (userId == null) return;

    try {
      // Récupérer les modèles distants
      final remoteTemplates = await getAllTemplates();
      final remoteIds = remoteTemplates.map((t) => t.id).toSet();

      // Batch write pour optimiser
      final batch = FirebaseFirestore.instance.batch();

      for (final template in localTemplates) {
        final docRef = _userTemplatesRef.doc(template.id);
        final data = _templateToJson(template);
        data['userId'] = userId;

        if (!remoteIds.contains(template.id)) {
          // Nouveau modèle - créer
          data['createdAt'] = FieldValue.serverTimestamp();
          data['updatedAt'] = FieldValue.serverTimestamp();
          batch.set(docRef, data);
        } else {
          // Modèle existant - mettre à jour
          data['updatedAt'] = FieldValue.serverTimestamp();
          batch.set(docRef, data, SetOptions(merge: true));
        }
      }

      await batch.commit();
    } catch (e) {
      // Ignorer les erreurs de synchro (offline, etc.)
      print('Sync to Firebase failed: $e');
    }
  }

  /// Synchronise les modèles Firebase vers local
  Future<List<WriteTemplate>> syncFromFirebase() async {
    if (userId == null) return [];

    try {
      return await getAllTemplates();
    } catch (e) {
      print('Sync from Firebase failed: $e');
      return [];
    }
  }

  // ==================== Publication publique ====================

  /// Publie un template pour le partage public
  /// Retourne l'URL publique du template
  Future<String> publishTemplate(WriteTemplate template) async {
    if (userId == null) throw Exception('User not authenticated');

    await _syncToPublicCollection(template);

    // Générer l'URL publique
    final publicUrl = 'https://cards-control.app/template/${template.id}';

    // Mettre à jour le template privé avec l'URL publique
    await _userTemplatesRef.doc(template.id).update({
      'isPublic': true,
      'publicUrl': publicUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return publicUrl;
  }

  /// Synchronise vers la collection publique
  Future<void> _syncToPublicCollection(WriteTemplate template) async {
    final publicData = {
      'id': template.id,
      'userId': userId,
      'name': template.name,
      'type': template.type.name,
      'data': template.data,
      'createdAt': template.createdAt.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _publicTemplatesRef.doc(template.id).set(publicData, SetOptions(merge: true));
  }

  /// Retire un template du partage public
  Future<void> unpublishTemplate(String templateId) async {
    if (userId == null) throw Exception('User not authenticated');

    // Supprimer de la collection publique
    await _publicTemplatesRef.doc(templateId).delete();

    // Mettre à jour le template privé
    await _userTemplatesRef.doc(templateId).update({
      'isPublic': false,
      'publicUrl': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Récupère un template public par son ID
  Future<WriteTemplate?> getPublicTemplate(String templateId) async {
    try {
      final doc = await _publicTemplatesRef.doc(templateId).get();
      if (!doc.exists || doc.data() == null) return null;
      return _templateFromDoc(doc);
    } catch (e) {
      print('Failed to get public template: $e');
      return null;
    }
  }

  // ==================== Helpers ====================

  Map<String, dynamic> _templateToJson(WriteTemplate template) {
    return {
      'id': template.id,
      'name': template.name,
      'type': template.type.name,
      'data': template.data,
      'createdAt': template.createdAt.toIso8601String(),
      'updatedAt': template.updatedAt.toIso8601String(),
      'lastUsedAt': template.lastUsedAt?.toIso8601String(),
      'useCount': template.useCount,
      'isPublic': template.isPublic,
      'publicUrl': template.publicUrl,
    };
  }

  WriteTemplate _templateFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.parse(data['createdAt'] as String);
    } else {
      createdAt = DateTime.now();
    }

    DateTime updatedAt;
    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    } else if (data['updatedAt'] is String) {
      updatedAt = DateTime.parse(data['updatedAt'] as String);
    } else {
      updatedAt = createdAt;
    }

    DateTime? lastUsedAt;
    if (data['lastUsedAt'] is Timestamp) {
      lastUsedAt = (data['lastUsedAt'] as Timestamp).toDate();
    } else if (data['lastUsedAt'] is String) {
      lastUsedAt = DateTime.parse(data['lastUsedAt'] as String);
    }

    return WriteTemplate(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String,
      type: WriteDataType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => WriteDataType.text,
      ),
      data: Map<String, dynamic>.from(data['data'] as Map),
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastUsedAt: lastUsedAt,
      useCount: data['useCount'] as int? ?? 0,
      userId: data['userId'] as String?,
      isPublic: data['isPublic'] as bool? ?? false,
      publicUrl: data['publicUrl'] as String?,
    );
  }
}
