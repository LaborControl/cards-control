import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/animations/nfc_scan_animation.dart';

class FormatTagScreen extends ConsumerStatefulWidget {
  const FormatTagScreen({super.key});

  @override
  ConsumerState<FormatTagScreen> createState() => _FormatTagScreenState();
}

class _FormatTagScreenState extends ConsumerState<FormatTagScreen> {
  static const _nfcChannel = MethodChannel('com.cardscontrol.app/nfc');

  bool _isFormatting = false;
  bool _formatSuccess = false;
  String? _errorMessage;
  Completer<Map<String, dynamic>>? _formatCompleter;

  @override
  void initState() {
    super.initState();
    _nfcChannel.setMethodCallHandler(_handleNfcCallback);
  }

  @override
  void dispose() {
    _cancelFormatting();
    super.dispose();
  }

  Future<dynamic> _handleNfcCallback(MethodCall call) async {
    if (call.method == 'onTagFormatted') {
      final data = Map<String, dynamic>.from(call.arguments as Map);
      debugPrint('NFC Format callback received: $data');
      if (_formatCompleter != null && !_formatCompleter!.isCompleted) {
        _formatCompleter!.complete(data);
      }
    }
    return null;
  }

  Future<void> _startFormatting() async {
    setState(() {
      _isFormatting = true;
      _formatSuccess = false;
      _errorMessage = null;
    });

    try {
      _formatCompleter = Completer<Map<String, dynamic>>();

      await _nfcChannel.invokeMethod('startFormatting');

      final result = await _formatCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => {'success': false, 'error': 'Timeout - aucun tag détecté'},
      );

      await _nfcChannel.invokeMethod('stopFormatting');

      setState(() {
        _isFormatting = false;
        _formatSuccess = result['success'] == true;
        _errorMessage = result['error'] as String?;
      });

      if (_formatSuccess && mounted) {
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      try {
        await _nfcChannel.invokeMethod('stopFormatting');
      } catch (_) {}

      setState(() {
        _isFormatting = false;
        _formatSuccess = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _cancelFormatting() async {
    if (_isFormatting) {
      try {
        await _nfcChannel.invokeMethod('stopFormatting');
      } catch (_) {}

      if (_formatCompleter != null && !_formatCompleter!.isCompleted) {
        _formatCompleter!.complete({'success': false, 'error': 'Cancelled'});
      }

      setState(() {
        _isFormatting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.formatTag),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Warning card
            Card(
              color: AppColors.error.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.error, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.formatWarningTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.formatWarningMessage,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // NFC Animation or result
            if (_isFormatting) ...[
              const NfcScanAnimation(),
              const SizedBox(height: 24),
              Text(
                l10n.approachNfcTag,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.formattingInProgress,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (_formatSuccess) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.formatSuccess,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tagErased,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 80,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.formatFailed,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cleaning_services,
                  size: 64,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.formatTagInstruction,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.formatTagDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const Spacer(),

            // Action buttons
            if (_isFormatting)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancelFormatting,
                  icon: const Icon(Icons.close),
                  label: Text(l10n.cancel),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              )
            else if (_formatSuccess || _errorMessage != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _formatSuccess = false;
                      _errorMessage = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.formatAnother),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startFormatting,
                  icon: const Icon(Icons.cleaning_services),
                  label: Text(l10n.startFormat),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
