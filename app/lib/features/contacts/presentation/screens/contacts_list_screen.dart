import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/contact.dart';
import '../providers/contacts_provider.dart';
import 'contact_edit_screen.dart';

class ContactsListScreen extends ConsumerWidget {
  const ContactsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contactsState = ref.watch(contactsProvider);
    final filteredContacts = ref.watch(filteredContactsProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final categoryCounts = ref.watch(contactsCountByCategoryProvider);
    final syncStatus = ref.watch(contactsSyncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myContacts),
        actions: [
          _SyncIndicator(
            syncStatus: syncStatus,
            onTap: () {
              ref.read(contactsProvider.notifier).forceSyncAllContacts();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _ContactSearchDelegate(contactsState.contacts, l10n),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(contactsProvider.notifier).forceSyncAllContacts();
        },
        child: contactsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : contactsState.contacts.isEmpty
                ? _EmptyState(l10n: l10n)
                : Column(
                    children: [
                      // Sélecteur de catégories
                      _CategoryFilterBar(
                        selectedCategory: selectedCategory,
                        categoryCounts: categoryCounts,
                        onCategorySelected: (category) {
                          ref.read(selectedCategoryFilterProvider.notifier).state = category;
                        },
                      ),
                      // Liste des contacts filtrés
                      Expanded(
                        child: filteredContacts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.filter_list_off,
                                      size: 64,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucun contact dans cette catégorie',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredContacts.length,
                                itemBuilder: (context, index) {
                                  final contact = filteredContacts[index];
                                  return _ContactCard(
                                    contact: contact,
                                    onTap: () => _showContactDetails(context, ref, contact, l10n),
                                    onDelete: () => _deleteContact(context, ref, contact, l10n),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: _ExpandableFab(
        onAddManual: () => _showAddContactDialog(context, ref, l10n),
        onScanCard: () => context.push('/contacts/scan-card'),
        onReadNfc: () => context.push('/nfc/read'),
      ),
    );
  }

  void _showContactDetails(BuildContext context, WidgetRef ref, Contact contact, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ContactDetailsSheet(
        contact: contact,
        onEdit: () {
          Navigator.pop(context);
          _showEditContactDialog(context, ref, contact, l10n);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteContact(context, ref, contact, l10n);
        },
      ),
    );
  }

  void _deleteContact(BuildContext context, WidgetRef ref, Contact contact, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text('${l10n.deleteConfirmation} ${contact.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(contactsProvider.notifier).deleteContact(contact.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.contactDeleted)),
              );
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContactEditScreen(),
      ),
    );
  }

  void _showEditContactDialog(BuildContext context, WidgetRef ref, Contact contact, AppLocalizations l10n) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactEditScreen(contact: contact),
      ),
    );
  }
}

class _CategoryFilterBar extends ConsumerWidget {
  final ContactCategory? selectedCategory;
  final Map<ContactCategory, int> categoryCounts;
  final ValueChanged<ContactCategory?> onCategorySelected;

  const _CategoryFilterBar({
    required this.selectedCategory,
    required this.categoryCounts,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(contactCategoriesProvider);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Bouton "Tous"
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selectedCategory == null,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tous'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: selectedCategory == null
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${categoryCounts[ContactCategory.none] ?? 0}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: selectedCategory == null
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              onSelected: (_) => onCategorySelected(null),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: selectedCategory == null
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              checkmarkColor: theme.colorScheme.onPrimary,
              showCheckmark: false,
            ),
          ),
          // Catégories dynamiques
          ...categories.map((category) {
            final count = categoryCounts[category] ?? 0;
            final isSelected = selectedCategory?.id == category.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                avatar: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.label),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                              : theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                onSelected: (_) => onCategorySelected(isSelected ? null : category),
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                checkmarkColor: theme.colorScheme.onPrimary,
                showCheckmark: false,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SyncIndicator extends StatelessWidget {
  final ContactsSyncStatus syncStatus;
  final VoidCallback onTap;

  const _SyncIndicator({
    required this.syncStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget icon;
    Color color;

    if (syncStatus.isSyncing) {
      icon = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
      color = AppColors.primary;
    } else if (syncStatus.error != null) {
      icon = const Icon(Icons.cloud_off, size: 20);
      color = Colors.red;
    } else if (syncStatus.hasPendingSync) {
      icon = Badge(
        label: Text('${syncStatus.pendingCount}'),
        child: const Icon(Icons.cloud_upload, size: 20),
      );
      color = Colors.orange;
    } else {
      icon = const Icon(Icons.cloud_done, size: 20);
      color = Colors.green;
    }

    return IconButton(
      onPressed: onTap,
      icon: icon,
      color: color,
      tooltip: syncStatus.error ?? (syncStatus.isSyncing ? 'Synchronisation...' : 'Synchronisé'),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noContacts,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noContactsDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends ConsumerWidget {
  final Contact contact;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ContactCard({
    required this.contact,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(contactCategoriesProvider);
    final category = contact.getCategory(categories);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: contact.photoUrl != null ? NetworkImage(contact.photoUrl!) : null,
                child: contact.photoUrl == null
                    ? Text(
                        contact.initials,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (contact.company != null || contact.jobTitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [contact.jobTitle, contact.company].whereType<String>().join(' - '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (contact.email != null || contact.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (contact.email != null) ...[
                            Icon(Icons.email_outlined, size: 14, color: theme.colorScheme.outline),
                            const SizedBox(width: 4),
                          ],
                          if (contact.phone != null) ...[
                            Icon(Icons.phone_outlined, size: 14, color: theme.colorScheme.outline),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  _SourceBadge(source: contact.source),
                  if (contact.category.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _CategoryBadge(category: category),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final ContactCategory category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (source) {
      case 'nfc':
        icon = Icons.nfc;
        color = AppColors.primary;
        break;
      case 'scan':
        icon = Icons.camera_alt;
        color = AppColors.secondary;
        break;
      default:
        icon = Icons.edit;
        color = AppColors.tertiary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _ContactDetailsSheet extends ConsumerWidget {
  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactDetailsSheet({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(contactCategoriesProvider);
    final category = contact.getCategory(categories);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: contact.photoUrl != null ? NetworkImage(contact.photoUrl!) : null,
              child: contact.photoUrl == null
                  ? Text(
                      contact.initials,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              contact.fullName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (contact.jobTitle != null || contact.company != null) ...[
              const SizedBox(height: 4),
              Text(
                [contact.jobTitle, contact.company].whereType<String>().join(' - '),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (contact.category.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: category.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (contact.email != null)
              _DetailRow(icon: Icons.email_outlined, label: l10n.email, value: contact.email!),
            if (contact.phone != null)
              _DetailRow(icon: Icons.phone_outlined, label: l10n.phone, value: contact.phone!),
            if (contact.mobile != null)
              _DetailRow(icon: Icons.smartphone, label: l10n.mobile, value: contact.mobile!),
            if (contact.website != null)
              _DetailRow(icon: Icons.language, label: l10n.website, value: contact.website!),
            if (contact.address != null)
              _DetailRow(icon: Icons.location_on_outlined, label: l10n.address, value: contact.address!),
            if (contact.notes != null)
              _DetailRow(icon: Icons.notes, label: l10n.notes, value: contact.notes!),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.edit),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableFab extends StatefulWidget {
  final VoidCallback onAddManual;
  final VoidCallback onScanCard;
  final VoidCallback onReadNfc;

  const _ExpandableFab({
    required this.onAddManual,
    required this.onScanCard,
    required this.onReadNfc,
  });

  @override
  State<_ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<_ExpandableFab> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 280,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Overlay pour fermer le menu
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggle,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
          // Bouton Scanner NFC
          _buildExpandingActionButton(
            index: 2,
            icon: Icons.nfc,
            label: 'Scanner NFC',
            color: AppColors.primary,
            onPressed: () {
              _toggle();
              widget.onReadNfc();
            },
          ),
          // Bouton Lire carte de visite
          _buildExpandingActionButton(
            index: 1,
            icon: Icons.camera_alt,
            label: 'Lire carte de visite',
            color: AppColors.secondary,
            onPressed: () {
              _toggle();
              widget.onScanCard();
            },
          ),
          // Bouton Ajout manuel
          _buildExpandingActionButton(
            index: 0,
            icon: Icons.edit,
            label: 'Saisie manuelle',
            color: AppColors.tertiary,
            onPressed: () {
              _toggle();
              widget.onAddManual();
            },
          ),
          // Bouton principal
          FloatingActionButton(
            heroTag: 'main_fab',
            onPressed: _toggle,
            child: AnimatedRotation(
              turns: _isOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandingActionButton({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final offset = 70.0 * (index + 1);
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: _expandAnimation.value * offset,
          right: 0,
          child: Opacity(
            opacity: _expandAnimation.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label
                if (_expandAnimation.value > 0.5)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                // Mini FAB
                FloatingActionButton.small(
                  heroTag: 'fab_$index',
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  onPressed: onPressed,
                  child: Icon(icon),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContactSearchDelegate extends SearchDelegate<Contact?> {
  final List<Contact> contacts;
  final AppLocalizations l10n;

  _ContactSearchDelegate(this.contacts, this.l10n);

  @override
  String get searchFieldLabel => l10n.searchContacts;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final results = contacts.where((contact) {
      final searchLower = query.toLowerCase();
      return contact.fullName.toLowerCase().contains(searchLower) ||
          (contact.email?.toLowerCase().contains(searchLower) ?? false) ||
          (contact.company?.toLowerCase().contains(searchLower) ?? false) ||
          (contact.phone?.contains(query) ?? false);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final contact = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              contact.initials,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          title: Text(contact.fullName),
          subtitle: Text(
            [contact.jobTitle, contact.company].whereType<String>().join(' - '),
          ),
          onTap: () => close(context, contact),
        );
      },
    );
  }
}
