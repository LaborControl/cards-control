import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../constants/app_constants.dart';
import '../../di/injection_container.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';

class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  FlutterSecureStorage get _storage => _ref.read(secureStorageProvider);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    // Get access token
    final accessToken = await _storage.read(key: AppConstants.keyAccessToken);

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - Try to refresh token
    if (err.response?.statusCode == 401) {
      final refreshed = await _refreshToken();

      if (refreshed) {
        // Retry the original request
        try {
          final accessToken = await _storage.read(
            key: AppConstants.keyAccessToken,
          );

          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $accessToken';

          final response = await Dio().fetch(opts);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      } else {
        // Refresh failed - logout user
        await _logout();
      }
    }

    return handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(
        key: AppConstants.keyRefreshToken,
      );

      if (refreshToken == null) return false;

      final dio = Dio();
      final response = await dio.post(
        '${_ref.read(dioProvider).options.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await _storage.write(
          key: AppConstants.keyAccessToken,
          value: data['accessToken'],
        );
        await _storage.write(
          key: AppConstants.keyRefreshToken,
          value: data['refreshToken'],
        );
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
    await _storage.delete(key: AppConstants.keyUserId);

    // Déconnecter l'utilisateur via le provider d'authentification
    // Le GoRouter redirigera automatiquement vers la page de login
    await _ref.read(authProvider.notifier).signOut();
  }

  bool _isPublicEndpoint(String path) {
    const publicEndpoints = [
      '/auth/register',
      '/auth/login',
      '/auth/forgot-password',
      '/auth/verify-email',
      '/cards/public/',
    ];

    return publicEndpoints.any((endpoint) => path.contains(endpoint));
  }
}
