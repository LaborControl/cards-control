import 'package:flutter/material.dart';

/// Extensions sur BuildContext pour faciliter l'accès aux ressources
extension ContextExtensions on BuildContext {
  /// Accès rapide au ThemeData
  ThemeData get theme => Theme.of(this);

  /// Accès rapide au ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Accès rapide au TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Accès rapide au MediaQueryData
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Largeur de l'écran
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Hauteur de l'écran
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Padding du système (notch, etc.)
  EdgeInsets get padding => MediaQuery.of(this).padding;

  /// Vérifie si le thème est en mode sombre
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Vérifie si c'est une tablette (largeur > 600)
  bool get isTablet => MediaQuery.of(this).size.shortestSide >= 600;

  /// Vérifie si c'est un téléphone
  bool get isPhone => MediaQuery.of(this).size.shortestSide < 600;

  /// Affiche un SnackBar
  void showSnackBar(String message, {Duration? duration, SnackBarAction? action}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
        action: action,
      ),
    );
  }

  /// Affiche un SnackBar d'erreur
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Affiche un SnackBar de succès
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Ferme le clavier
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  /// Affiche un dialog de confirmation
  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Affiche un dialog de chargement
  void showLoadingDialog({String? message}) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message ?? 'Chargement...'),
          ],
        ),
      ),
    );
  }
}
