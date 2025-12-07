import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/routes.dart';
import '../../../l10n/app_localizations.dart';

/// Provider pour l'index de navigation actuel
final currentNavIndexProvider = StateProvider<int>((ref) => 0);

/// Shell principal avec barre de navigation
class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const List<String> _navPaths = [
    Routes.home,
    Routes.cards,
    Routes.templates,
    Routes.tags,
    Routes.settings,
  ];

  List<_NavItem> _buildNavItems(AppLocalizations l10n) {
    return [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: l10n.home,
      ),
      _NavItem(
        icon: Icons.contact_page_outlined,
        activeIcon: Icons.contact_page,
        label: l10n.cards,
      ),
      _NavItem(
        icon: Icons.bookmarks_outlined,
        activeIcon: Icons.bookmarks,
        label: l10n.templates,
      ),
      _NavItem(
        icon: Icons.nfc_outlined,
        activeIcon: Icons.nfc,
        label: l10n.tags,
      ),
      _NavItem(
        icon: Icons.more_horiz,
        activeIcon: Icons.more_horiz,
        label: l10n.more,
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentNavIndexProvider);
    final l10n = AppLocalizations.of(context)!;
    final navItems = _buildNavItems(l10n);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(currentNavIndexProvider.notifier).state = index;
          context.go(_navPaths[index]);
        },
        destinations: navItems.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
