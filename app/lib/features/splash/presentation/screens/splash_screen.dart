import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _elasticScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const _biometricEnabledKey = 'biometric_enabled';

  // Pour l'effet machine à écrire
  String _displayedText = '';
  String _fullText = '';
  Timer? _typewriterTimer;
  bool _showTypewriter = false;

  @override
  void initState() {
    super.initState();

    // Controller principal pour l'entrée élastique (1.5s)
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controller pour le pulse continu
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controller pour l'effet shimmer
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade in rapide
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Scale élastique (dépasse 1.0 puis revient)
    _elasticScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
    ]).animate(_mainController);

    // Animation pulse subtile (scale 1.0 -> 1.05 -> 1.0)
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Animation shimmer (position de -1 à 2 pour traverser tout le logo)
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOut,
      ),
    );

    // Démarrer la séquence d'animations
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Phase 1: Entrée élastique (1.5s)
    _mainController.forward();

    await Future.delayed(const Duration(milliseconds: 1500));

    // Phase 2: Shimmer (1.5s)
    if (mounted) {
      _shimmerController.forward();
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    // Phase 3: Pulse continu + texte machine à écrire
    if (mounted) {
      _pulseController.repeat(reverse: true);
      _startTypewriterEffect();
    }

    // Attendre que le texte soit terminé (environ 3s pour le texte long)
    await Future.delayed(const Duration(milliseconds: 3500));

    // Phase 4: Pause de 3 secondes avec spinner visible
    // (le spinner est déjà affiché, on attend juste)
    await Future.delayed(const Duration(seconds: 3));

    // Navigation
    if (mounted) {
      _checkAuthAndNavigate();
    }
  }

  void _startTypewriterEffect() {
    final authState = ref.read(authProvider);

    // Déterminer le texte à afficher
    if (authState.isAuthenticated && authState.user != null) {
      // displayName a toujours une valeur grâce au fallback dans auth_provider
      // (email.split('@').first ou 'Utilisateur')
      final displayName = authState.user!.displayName ?? 'Utilisateur';
      _fullText = 'Bonjour $displayName';
    } else {
      _fullText = 'Bienvenue dans la nouvelle ère du Networking';
    }

    setState(() {
      _showTypewriter = true;
      _displayedText = '';
    });

    int charIndex = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (charIndex < _fullText.length) {
        setState(() {
          _displayedText = _fullText.substring(0, charIndex + 1);
        });
        charIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState.status == AuthStatus.initial) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _checkAuthAndNavigate();
      return;
    }

    if (authState.isAuthenticated) {
      final biometricEnabled = await _secureStorage.read(key: _biometricEnabledKey);
      final isBiometricEnabled = biometricEnabled == 'true';

      if (isBiometricEnabled) {
        final authenticated = await _authenticateWithBiometrics();
        if (!mounted) return;

        if (authenticated) {
          context.go('/');
        } else {
          await ref.read(authProvider.notifier).signOut();
          if (!mounted) return;
          context.go('/login');
        }
      } else {
        context.go('/');
      }
    } else {
      context.go('/login');
    }
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheck || !isDeviceSupported) {
        return true;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour accéder à Cards Control',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      return true;
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _mainController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo avec animations combinées
              AnimatedBuilder(
                animation: Listenable.merge([
                  _mainController,
                  _pulseController,
                  _shimmerController,
                ]),
                builder: (context, child) {
                  // Combine elastic scale avec pulse
                  double scale = _elasticScaleAnimation.value;
                  if (_mainController.isCompleted) {
                    scale = _pulseAnimation.value;
                  }

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.scale(
                      scale: scale,
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.5),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: [
                              (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                              _shimmerAnimation.value.clamp(0.0, 1.0),
                              (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                            ],
                          ).createShader(bounds);
                        },
                        blendMode: _shimmerController.isAnimating
                            ? BlendMode.srcATop
                            : BlendMode.dst,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 250,
                          height: 250,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              // Texte machine à écrire
              AnimatedOpacity(
                opacity: _showTypewriter ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _displayedText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E3A8A),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // Loading indicator
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                        strokeWidth: 3,
                      ),
                    ),
                  );
                },
              ),
              const Spacer(flex: 1),
              // Author
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'by Jean Claude PASTOR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                        letterSpacing: 1,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
