import 'package:intl/intl.dart';

/// Extensions sur DateTime pour le formatage
extension DateTimeExtensions on DateTime {
  /// Formate la date en format court (ex: 15 nov.)
  String toShortDate() {
    return DateFormat('d MMM', 'fr_FR').format(this);
  }

  /// Formate la date en format long (ex: 15 novembre 2024)
  String toLongDate() {
    return DateFormat('d MMMM yyyy', 'fr_FR').format(this);
  }

  /// Formate l'heure (ex: 14:30)
  String toTime() {
    return DateFormat('HH:mm', 'fr_FR').format(this);
  }

  /// Formate la date et l'heure (ex: 15 nov. à 14:30)
  String toDateTime() {
    return '${toShortDate()} à ${toTime()}';
  }

  /// Retourne une description relative (ex: Il y a 5 min)
  String toRelative() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Il y a $minutes min';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Il y a $hours h';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'Il y a $days j';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks sem.';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }

  /// Vérifie si c'est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Vérifie si c'est hier
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Vérifie si c'est cette semaine
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Retourne le début de la journée
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Retourne la fin de la journée
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }
}

/// Extensions sur Duration
extension DurationExtensions on Duration {
  /// Formate la durée en texte lisible
  String toReadable() {
    if (inSeconds < 60) {
      return '$inSeconds sec';
    } else if (inMinutes < 60) {
      return '$inMinutes min';
    } else if (inHours < 24) {
      final hours = inHours;
      final minutes = inMinutes.remainder(60);
      return minutes > 0 ? '$hours h $minutes min' : '$hours h';
    } else {
      final days = inDays;
      final hours = inHours.remainder(24);
      return hours > 0 ? '$days j $hours h' : '$days j';
    }
  }
}
