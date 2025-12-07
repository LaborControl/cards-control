import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/native_nfc_service.dart';
import '../../../../core/services/qr_code_service.dart';
import '../../../business_cards/presentation/providers/business_cards_provider.dart';
import 'emulation_screen.dart';

/// Écran d'émulation rapide avec compte à rebours
/// Lancé depuis un raccourci ou deep link
class QuickEmulationScreen extends ConsumerStatefulWidget {
  final String cardId;
  final bool autoStart;
  final bool closeOnFinish;

  const QuickEmulationScreen({
    super.key,
    required this.cardId,
    this.autoStart = true,
    this.closeOnFinish = true,
  });

  @override
  ConsumerState<QuickEmulationScreen> createState() => _QuickEmulationScreenState();
}

class _QuickEmulationScreenState extends ConsumerState<QuickEmulationScreen>
    with TickerProviderStateMixin {
  static const int _emulationDuration = 10; // secondes

  int _remainingSeconds = _emulationDuration;
  Timer? _countdownTimer;
  bool _isEmulating = false;
  bool _isInitializing = true;
  String? _error;

  late AnimationController _phoneController;
  late AnimationController _waveController;
  late Animation<double> _phoneAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeEmulation();
  }

  void _setupAnimations() {
    // Animation du téléphone qui s'approche
    _phoneController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _phoneAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _phoneController, curve: Curves.easeInOut),
    );

    // Animation des ondes NFC
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  Future<void> _initializeEmulation() async {
    try {
      // Vérifier si on est sur Android
      if (!Platform.isAndroid) {
        setState(() {
          _error = 'L\'émulation HCE n\'est disponible que sur Android';
          _isInitializing = false;
        });
        return;
      }

      final nfcService = NativeNfcService.instance;
      await nfcService.initialize();

      // Vérifier HCE
      final hceInfo = await nfcService.getHceInfo();
      if (!hceInfo.isSupported) {
        setState(() {
          _error = 'Votre appareil ne supporte pas l\'émulation HCE';
          _isInitializing = false;
        });
        return;
      }

      if (!hceInfo.nfcEnabled) {
        setState(() {
          _error = 'Veuillez activer le NFC dans les paramètres';
          _isInitializing = false;
        });
        return;
      }

      // Charger la carte - d'abord essayer localement, sinon depuis Firestore
      var card = ref.read(cardByIdProvider(widget.cardId));

      // Si la carte n'est pas encore chargée localement, attendre le chargement ou charger depuis Firestore
      if (card == null) {
        // Attendre que les cartes locales soient chargées
        final cardsState = ref.read(businessCardsProvider);
        if (cardsState.isLoading) {
          // Attendre jusqu'à 3 secondes que les cartes se chargent
          for (int i = 0; i < 30; i++) {
            await Future.delayed(const Duration(milliseconds: 100));
            card = ref.read(cardByIdProvider(widget.cardId));
            if (card != null) break;
            final state = ref.read(businessCardsProvider);
            if (!state.isLoading) break;
          }
        }

        // Si toujours pas trouvée, charger depuis Firestore (public_cards)
        if (card == null) {
          final publicCard = await ref.read(publicCardProvider(widget.cardId).future);
          card = publicCard;
        }

        if (card == null) {
          throw Exception('Carte non trouvée');
        }
      }

      // Configurer HCE
      final cardUrl = QrCodeService.instance.generateBusinessCardUrl(widget.cardId);
      await nfcService.setBusinessCardForEmulation(
        cardId: widget.cardId,
        cardUrl: cardUrl,
        vCardData: card.toVCard(),
      );

      setState(() {
        _isInitializing = false;
      });

      // Démarrer automatiquement si demandé
      if (widget.autoStart) {
        _startEmulation();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isInitializing = false;
      });
    }
  }

  void _startEmulation() async {
    if (_isEmulating) return;

    try {
      final nfcService = NativeNfcService.instance;
      // Utiliser la nouvelle méthode qui désactive le foreground dispatch et active le service préféré
      await nfcService.startEmulation();
      await nfcService.setEmulationEnabled(true);
      ref.read(emulationStateProvider.notifier).state = true;

      setState(() {
        _isEmulating = true;
        _remainingSeconds = _emulationDuration;
      });

      // Démarrer les animations
      _phoneController.repeat(reverse: true);
      _waveController.repeat();

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _stopEmulation(fromCountdown: true);
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du démarrage: $e';
      });
    }
  }

  void _stopEmulation({bool fromCountdown = false}) async {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    try {
      final nfcService = NativeNfcService.instance;
      // Utiliser la nouvelle méthode qui désactive le service préféré et réactive le foreground dispatch
      await nfcService.stopEmulation();
      await nfcService.setEmulationEnabled(false);
      ref.read(emulationStateProvider.notifier).state = false;
    } catch (_) {}

    // Arrêter les animations
    _phoneController.stop();
    _phoneController.reset();
    _waveController.stop();
    _waveController.reset();

    setState(() {
      _isEmulating = false;
      _remainingSeconds = _emulationDuration;
    });

    // Si lancé depuis un raccourci et que le countdown est terminé, fermer l'app
    if (fromCountdown && widget.closeOnFinish && mounted) {
      // Petit délai pour montrer que l'émulation est terminée
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        // Fermer l'activité (retour à l'écran d'accueil Android)
        SystemNavigator.pop();
      }
    }
  }

  void _restartEmulation() {
    _stopEmulation();
    Future.delayed(const Duration(milliseconds: 300), () {
      _startEmulation();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _waveController.dispose();
    // Arrêter l'émulation quand on quitte
    final nfcService = NativeNfcService.instance;
    nfcService.stopEmulation();
    nfcService.setEmulationEnabled(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = ref.watch(cardByIdProvider(widget.cardId));

    return Scaffold(
      backgroundColor: _isEmulating
          ? AppColors.success.withOpacity(0.05)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(card?.fullName ?? 'Émulation rapide'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isEmulating)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopEmulation,
              tooltip: 'Arrêter',
            ),
        ],
      ),
      body: _buildBody(theme, card),
    );
  }

  Widget _buildBody(ThemeData theme, card) {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initialisation...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Erreur',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    if (card == null) {
      return const Center(child: Text('Carte non trouvée'));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            // Animation des deux téléphones avec ondes NFC
            _buildEmulationAnimation(theme),

            const SizedBox(height: 32),

            // Titre et sous-titre
            Text(
              _isEmulating ? 'Émulation en cours' : 'Prêt à émuler',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isEmulating ? AppColors.success : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isEmulating
                  ? 'Approchez un autre appareil NFC'
                  : 'Appuyez sur Démarrer pour émuler votre carte',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            // Info carte
            Card(
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(int.parse(card.primaryColor.replaceFirst('#', '0xFF')))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Color(int.parse(card.primaryColor.replaceFirst('#', '0xFF'))),
                  ),
                ),
                title: Text(card.fullName),
                subtitle: Text(card.company ?? card.email ?? ''),
              ),
            ),

            const Spacer(),

            // Boutons d'action
            if (_isEmulating) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _stopEmulation,
                      icon: const Icon(Icons.stop),
                      label: const Text('Arrêter'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _restartEmulation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Relancer'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startEmulation,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Démarrer l\'émulation'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Bouton fermer
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit l'animation d'émulation avec les deux téléphones
  Widget _buildEmulationAnimation(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isEmulating
            ? AppColors.success.withOpacity(0.1)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: _isEmulating ? Border.all(color: AppColors.success) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animation des deux téléphones
          SizedBox(
            height: 120,
            child: _isEmulating
                ? _buildAnimatedPhones(theme)
                : _buildStaticIcon(theme),
          ),
          const SizedBox(height: 16),
          // Compte à rebours
          if (_isEmulating) ...[
            Text(
              '$_remainingSeconds',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            Text(
              'secondes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStaticIcon(ThemeData theme) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.nfc,
          size: 40,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildAnimatedPhones(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_phoneAnimation, _waveController]),
      builder: (context, child) {
        // Animation : le téléphone émetteur glisse de droite à gauche
        final slideOffset = _phoneAnimation.value * 15;

        return SizedBox(
          width: double.infinity,
          height: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Téléphone récepteur (à gauche, incliné de 20° vers la droite)
              Transform.rotate(
                angle: 0.35, // ~20 degrés vers la droite
                child: _buildReceiverPhone(theme),
              ),

              const SizedBox(width: 8),

              // Téléphone émetteur avec ondes NFC attachées en haut (glisse vers la gauche)
              Transform.translate(
                offset: Offset(-slideOffset, 0),
                child: Transform.rotate(
                  angle: -1.047, // ~-60 degrés (vers la gauche)
                  child: _buildEmitterWithWaves(theme),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Téléphone émetteur avec ondes NFC attachées en haut
  Widget _buildEmitterWithWaves(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ondes NFC collées au téléphone (sortent vers l'extérieur)
        SizedBox(
          width: 40,
          height: 25,
          child: CustomPaint(
            painter: _SonarWavePainter(
              progress: _waveController.value,
              color: AppColors.success,
            ),
          ),
        ),
        // Téléphone vu de profil (tranche verticale fine)
        Container(
          width: 10,
          height: 55,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: AppColors.success,
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Label
        Text(
          'Vous',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  /// Téléphone récepteur vu de profil
  Widget _buildReceiverPhone(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Téléphone vu de profil (tranche verticale fine)
        Container(
          width: 10,
          height: 55,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Bosse caméra en haut (sur le dos)
              Positioned(
                top: 3,
                left: -4,
                child: Container(
                  width: 6,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Label
        Text(
          'Récepteur',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

/// Painter pour dessiner des ondes sonar (arcs de cercle qui s'éloignent)
class _SonarWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _SonarWavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height; // Point d'origine en bas (haut du téléphone)

    // Dessiner 3 arcs qui s'éloignent progressivement
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i * 0.33) % 1.0;

      // L'arc commence petit et grandit en s'éloignant
      final radius = 5 + (waveProgress * 20); // De 5 à 25 pixels

      // Opacité décroissante à mesure que l'arc s'éloigne
      final opacity = (1.0 - waveProgress) * 0.9;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      // Dessiner un arc de cercle (demi-cercle orienté vers le haut)
      final rect = Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius,
      );

      // Arc de 180° orienté vers le haut (de -π à 0)
      canvas.drawArc(
        rect,
        -math.pi, // Angle de départ (gauche)
        math.pi,  // Angle balayé (180°)
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SonarWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
