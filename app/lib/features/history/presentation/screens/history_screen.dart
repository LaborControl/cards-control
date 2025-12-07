import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../nfc_reader/domain/entities/nfc_tag.dart';
import '../../../nfc_reader/presentation/providers/nfc_reader_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  NfcTagType? _filterType;
  bool _showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(tagHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.star : Icons.star_outline,
              color: _showFavoritesOnly ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() => _showFavoritesOnly = !_showFavoritesOnly);
            },
            tooltip: 'Favoris uniquement',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Exporter tout'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Effacer l\'historique',
                      style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: historyAsync.when(
        data: (tags) {
          // Filtrage
          var filteredTags = tags.where((tag) {
            // Filtre favoris
            if (_showFavoritesOnly && !tag.isFavorite) return false;

            // Filtre type
            if (_filterType != null && tag.type != _filterType) return false;

            // Filtre recherche
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              return tag.uid.toLowerCase().contains(query) ||
                  tag.type.displayName.toLowerCase().contains(query) ||
                  (tag.notes?.toLowerCase().contains(query) ?? false);
            }

            return true;
          }).toList();

          if (filteredTags.isEmpty) {
            return _buildEmptyState(theme, tags.isEmpty);
          }

          return Column(
            children: [
              // Filtres par type
              if (!_showFavoritesOnly && _searchQuery.isEmpty)
                _buildTypeFilters(theme, tags),

              // Liste
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTags.length,
                  itemBuilder: (context, index) {
                    final tag = filteredTags[index];
                    return _TagHistoryTile(
                      tag: tag,
                      onTap: () => context.push('/reader/details/${tag.id}'),
                      onFavorite: () => _toggleFavorite(tag.id),
                      onDelete: () => _deleteTag(tag.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEmpty ? Icons.history : Icons.search_off,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              isEmpty ? 'Aucun historique' : 'Aucun résultat',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isEmpty
                  ? 'Les tags que vous scannez apparaîtront ici'
                  : 'Essayez avec d\'autres critères',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (isEmpty) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/reader'),
                icon: const Icon(Icons.nfc),
                label: const Text('Scanner un tag'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilters(ThemeData theme, List<NfcTag> tags) {
    // Compte les types
    final typeCounts = <NfcTagType, int>{};
    for (final tag in tags) {
      typeCounts[tag.type] = (typeCounts[tag.type] ?? 0) + 1;
    }

    if (typeCounts.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('Tous'),
            selected: _filterType == null,
            onSelected: (selected) {
              setState(() => _filterType = null);
            },
          ),
          const SizedBox(width: 8),
          ...typeCounts.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('${entry.key.displayName} (${entry.value})'),
                selected: _filterType == entry.key,
                onSelected: (selected) {
                  setState(() => _filterType = selected ? entry.key : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  void _toggleFavorite(String id) {
    ref.read(tagHistoryUseCaseProvider).toggleFavorite(id);
    ref.invalidate(tagHistoryProvider);
  }

  void _deleteTag(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Supprimer ce tag de l\'historique ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tagHistoryUseCaseProvider).deleteTag(id);
      ref.invalidate(tagHistoryProvider);
    }
  }

  Future<void> _exportHistory() async {
    final historyAsync = ref.read(tagHistoryProvider);

    historyAsync.whenData((tags) async {
      if (tags.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun historique à exporter')),
          );
        }
        return;
      }

      // Créer le contenu JSON
      final exportData = tags.map((tag) => {
        'uid': tag.uid,
        'type': tag.type.displayName,
        'technology': tag.technology.displayName,
        'memorySize': tag.memorySize,
        'usedMemory': tag.usedMemory,
        'isWritable': tag.isWritable,
        'isLocked': tag.isLocked,
        'scannedAt': tag.scannedAt.toIso8601String(),
        'isFavorite': tag.isFavorite,
        'notes': tag.notes,
        'ndefRecords': tag.ndefRecords.map((record) => {
          'type': record.type.displayName,
          'payload': record.decodedPayload,
        }).toList(),
      }).toList();

      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'exportDate': DateTime.now().toIso8601String(),
        'totalTags': tags.length,
        'tags': exportData,
      });

      // Partager le fichier
      await Share.share(
        jsonString,
        subject: 'Historique Cards Control - ${DateTime.now().toString().split(' ')[0]}',
      );
    });
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'export':
        await _exportHistory();
        break;

      case 'clear':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Effacer l\'historique'),
            content: const Text(
              'Voulez-vous vraiment supprimer tout l\'historique ? '
              'Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Effacer'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await ref.read(tagHistoryUseCaseProvider).clearHistory();
          ref.invalidate(tagHistoryProvider);
        }
        break;
    }
  }
}

class _TagHistoryTile extends StatelessWidget {
  final NfcTag tag;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  const _TagHistoryTile({
    required this.tag,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(tag.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer'),
            content: const Text('Supprimer ce tag de l\'historique ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.nfc,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            tag.type.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tag.formattedUid,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatDate(tag.scannedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  tag.isFavorite ? Icons.star : Icons.star_outline,
                  color: tag.isFavorite ? Colors.amber : null,
                ),
                tooltip: tag.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                onPressed: onFavorite,
                visualDensity: VisualDensity.compact,
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
