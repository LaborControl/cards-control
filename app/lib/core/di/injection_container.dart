import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/logging_interceptor.dart';
import '../constants/api_constants.dart';

// Secure Storage Provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

// Dio Provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors
  dio.interceptors.addAll([
    AuthInterceptor(ref),
    LoggingInterceptor(),
  ]);

  return dio;
});

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

// Initialize dependencies
Future<void> initializeDependencies() async {
  // Open Hive boxes
  await Hive.openBox('settings');
  await Hive.openBox('tags_history');
  await Hive.openBox('write_templates');
  await Hive.openBox('business_cards');
  await Hive.openBox('business_cards_cache');
  await Hive.openBox('contacts');
}

// Settings Box Provider
final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box('settings');
});

// Tags History Box Provider
final tagsHistoryBoxProvider = Provider<Box>((ref) {
  return Hive.box('tags_history');
});

// Write Templates Box Provider
final writeTemplatesBoxProvider = Provider<Box>((ref) {
  return Hive.box('write_templates');
});

// Business Cards Cache Box Provider
final businessCardsCacheBoxProvider = Provider<Box>((ref) {
  return Hive.box('business_cards_cache');
});
