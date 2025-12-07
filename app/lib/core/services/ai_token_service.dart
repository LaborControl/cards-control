import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Types d'utilisation de l'IA
enum AIUsageType {
  businessCardOcr('business_card_ocr', 'Lecture carte de visite'),
  tagAnalysis('tag_analysis', 'Analyse de tag NFC'),
  templateGeneration('template_generation', 'Génération de description'),
  imageGeneration('image_generation', 'Génération d\'image'),
  other('other', 'Autre');

  final String value;
  final String displayName;

  const AIUsageType(this.value, this.displayName);

  static AIUsageType fromString(String value) {
    return AIUsageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AIUsageType.other,
    );
  }
}

/// Enregistrement d'une utilisation d'IA
class AIUsageRecord {
  final String id;
  final String userId;
  final AIUsageType type;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final DateTime timestamp;
  final String? model;
  final String? details;

  const AIUsageRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.timestamp,
    this.model,
    this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type.value,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'totalTokens': totalTokens,
      'timestamp': Timestamp.fromDate(timestamp),
      'model': model,
      'details': details,
    };
  }

  factory AIUsageRecord.fromJson(String id, Map<String, dynamic> json) {
    return AIUsageRecord(
      id: id,
      userId: json['userId'] as String,
      type: AIUsageType.fromString(json['type'] as String),
      inputTokens: json['inputTokens'] as int? ?? 0,
      outputTokens: json['outputTokens'] as int? ?? 0,
      totalTokens: json['totalTokens'] as int? ?? 0,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      model: json['model'] as String?,
      details: json['details'] as String?,
    );
  }
}

/// Statistiques d'utilisation de l'IA
class AIUsageStats {
  final int totalTokensUsed;
  final int tokenLimit;
  final int tokensRemaining;
  final Map<AIUsageType, int> usageByType;
  final DateTime? lastUsage;
  final DateTime periodStart;
  final DateTime periodEnd;
  final bool isPremium;
  final DateTime? subscriptionStartDate;

  const AIUsageStats({
    required this.totalTokensUsed,
    required this.tokenLimit,
    required this.tokensRemaining,
    required this.usageByType,
    this.lastUsage,
    required this.periodStart,
    required this.periodEnd,
    this.isPremium = false,
    this.subscriptionStartDate,
  });

  double get usagePercentage => tokenLimit > 0 ? (totalTokensUsed / tokenLimit) * 100 : 0;

  bool get hasReachedLimit => tokensRemaining <= 0;

  /// Pour les Pro : période annuelle à partir de la date d'abonnement
  bool get isAnnualBilling => isPremium;

  factory AIUsageStats.empty() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return AIUsageStats(
      totalTokensUsed: 0,
      tokenLimit: 100000, // 100k tokens par défaut
      tokensRemaining: 100000,
      usageByType: {},
      periodStart: startOfMonth,
      periodEnd: endOfMonth,
      isPremium: false,
    );
  }
}

/// Service de gestion des tokens IA
class AITokenService {
  static const int defaultMonthlyLimit = 100000; // 100k tokens/mois
  static const int premiumMonthlyLimit = 500000; // 500k tokens/mois pour premium

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Cache local pour réduire les lectures Firestore
  AIUsageStats? _cachedStats;
  DateTime? _lastStatsFetch;
  static const Duration _cacheValidity = Duration(minutes: 5);

  AITokenService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Enregistre une utilisation d'IA
  Future<bool> recordUsage({
    required AIUsageType type,
    required int inputTokens,
    required int outputTokens,
    String? model,
    String? details,
  }) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      final totalTokens = inputTokens + outputTokens;

      // Créer l'enregistrement
      await _firestore.collection('ai_usage').add({
        'userId': userId,
        'type': type.value,
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        'totalTokens': totalTokens,
        'timestamp': FieldValue.serverTimestamp(),
        'model': model,
        'details': details,
      });

      // Mettre à jour le compteur mensuel
      await _updateMonthlyCounter(userId, totalTokens, type);

      // Invalider le cache
      _cachedStats = null;

      debugPrint('AI usage recorded: $type - $totalTokens tokens');
      return true;
    } catch (e) {
      debugPrint('Error recording AI usage: $e');
      return false;
    }
  }

  /// Met à jour le compteur mensuel
  Future<void> _updateMonthlyCounter(
    String userId,
    int tokens,
    AIUsageType type,
  ) async {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final docRef = _firestore.collection('ai_usage_monthly').doc('$userId-$monthKey');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (snapshot.exists) {
        final data = snapshot.data()!;
        final currentTotal = data['totalTokens'] as int? ?? 0;
        final typeKey = 'usage_${type.value}';
        final currentTypeUsage = data[typeKey] as int? ?? 0;

        transaction.update(docRef, {
          'totalTokens': currentTotal + tokens,
          typeKey: currentTypeUsage + tokens,
          'lastUsage': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(docRef, {
          'userId': userId,
          'month': monthKey,
          'totalTokens': tokens,
          'usage_${type.value}': tokens,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUsage': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Récupère les statistiques d'utilisation du mois courant
  Future<AIUsageStats> getMonthlyStats({bool forceRefresh = false}) async {
    final userId = _userId;
    if (userId == null) return AIUsageStats.empty();

    // Vérifier le cache
    if (!forceRefresh &&
        _cachedStats != null &&
        _lastStatsFetch != null &&
        DateTime.now().difference(_lastStatsFetch!) < _cacheValidity) {
      return _cachedStats!;
    }

    try {
      final now = DateTime.now();

      // Récupérer les infos d'abonnement de l'utilisateur
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final isPremium = userData?['isPremium'] as bool? ?? false;

      DateTime? subscriptionStartDate;
      if (userData?['subscriptionStartDate'] != null) {
        subscriptionStartDate = (userData!['subscriptionStartDate'] as Timestamp).toDate();
      }

      // Calculer la période selon le type d'abonnement
      DateTime periodStart;
      DateTime periodEnd;
      int tokenLimit;

      if (isPremium && subscriptionStartDate != null) {
        // Pour les Pro : période annuelle basée sur la date d'abonnement
        tokenLimit = premiumMonthlyLimit;

        // Calculer l'anniversaire annuel de l'abonnement
        int yearsElapsed = now.year - subscriptionStartDate.year;
        DateTime currentPeriodStart = DateTime(
          subscriptionStartDate.year + yearsElapsed,
          subscriptionStartDate.month,
          subscriptionStartDate.day,
        );

        // Si on n'est pas encore arrivé à l'anniversaire cette année, on est dans la période précédente
        if (currentPeriodStart.isAfter(now)) {
          yearsElapsed--;
          currentPeriodStart = DateTime(
            subscriptionStartDate.year + yearsElapsed,
            subscriptionStartDate.month,
            subscriptionStartDate.day,
          );
        }

        periodStart = currentPeriodStart;
        periodEnd = DateTime(
          currentPeriodStart.year + 1,
          currentPeriodStart.month,
          currentPeriodStart.day,
        ).subtract(const Duration(seconds: 1));
      } else {
        // Pour les gratuits : période mensuelle
        tokenLimit = defaultMonthlyLimit;
        periodStart = DateTime(now.year, now.month, 1);
        periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }

      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Récupérer le compteur mensuel
      final doc = await _firestore
          .collection('ai_usage_monthly')
          .doc('$userId-$monthKey')
          .get();

      int totalTokens = 0;
      DateTime? lastUsage;
      final usageByType = <AIUsageType, int>{};

      if (doc.exists) {
        final data = doc.data()!;
        totalTokens = data['totalTokens'] as int? ?? 0;

        if (data['lastUsage'] != null) {
          lastUsage = (data['lastUsage'] as Timestamp).toDate();
        }

        // Extraire l'usage par type
        for (final type in AIUsageType.values) {
          final typeKey = 'usage_${type.value}';
          if (data.containsKey(typeKey)) {
            usageByType[type] = data[typeKey] as int;
          }
        }
      }

      _cachedStats = AIUsageStats(
        totalTokensUsed: totalTokens,
        tokenLimit: tokenLimit,
        tokensRemaining: (tokenLimit - totalTokens).clamp(0, tokenLimit),
        usageByType: usageByType,
        lastUsage: lastUsage,
        periodStart: periodStart,
        periodEnd: periodEnd,
        isPremium: isPremium,
        subscriptionStartDate: subscriptionStartDate,
      );
      _lastStatsFetch = DateTime.now();

      return _cachedStats!;
    } catch (e) {
      debugPrint('Error fetching AI usage stats: $e');
      return AIUsageStats.empty();
    }
  }

  /// Vérifie si l'utilisateur peut utiliser l'IA (a assez de tokens)
  Future<bool> canUseAI({int estimatedTokens = 1000}) async {
    final stats = await getMonthlyStats();
    return stats.tokensRemaining >= estimatedTokens;
  }

  /// Récupère l'historique d'utilisation
  Future<List<AIUsageRecord>> getUsageHistory({
    int limit = 50,
    AIUsageType? filterType,
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    try {
      Query query = _firestore
          .collection('ai_usage')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (filterType != null) {
        query = query.where('type', isEqualTo: filterType.value);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return AIUsageRecord.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching AI usage history: $e');
      return [];
    }
  }

  /// Estime le nombre de tokens pour un texte (approximation)
  static int estimateTokens(String text) {
    // Approximation: ~4 caractères = 1 token pour le français
    return (text.length / 4).ceil();
  }

  /// Parse la réponse API Claude pour extraire l'usage de tokens
  static Map<String, int> parseClaudeUsage(Map<String, dynamic> responseBody) {
    final usage = responseBody['usage'] as Map<String, dynamic>?;
    if (usage == null) {
      return {'input': 0, 'output': 0};
    }

    return {
      'input': usage['input_tokens'] as int? ?? 0,
      'output': usage['output_tokens'] as int? ?? 0,
    };
  }
}
