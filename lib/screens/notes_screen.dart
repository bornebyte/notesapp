import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notes_provider.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import 'note_editor_screen.dart';
import 'trash_screen.dart';
import 'favorites_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: const Text('My Notes'),
              floating: true,
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.star_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  },
                  tooltip: 'Favorites',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TrashScreen(),
                      ),
                    );
                  },
                  tooltip: 'Trash',
                ),
                Consumer<NotesProvider>(
                  builder: (context, provider, _) {
                    return PopupMenuButton<SortOrder>(
                      icon: const Icon(Icons.sort),
                      onSelected: (order) => provider.setSortOrder(order),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: SortOrder.updatedDesc,
                          child: Text('Recently Updated'),
                        ),
                        const PopupMenuItem(
                          value: SortOrder.createdDesc,
                          child: Text('Recently Created'),
                        ),
                        const PopupMenuItem(
                          value: SortOrder.titleAsc,
                          child: Text('Title (A-Z)'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchBarDelegate(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                Provider.of<NotesProvider>(
                                  context,
                                  listen: false,
                                ).setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      Provider.of<NotesProvider>(
                        context,
                        listen: false,
                      ).setSearchQuery(value);
                    },
                  ),
                ),
              ),
            ),
          ];
        },
        body: _buildNotesList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  Widget _buildNotesList() {
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchNotes(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_add_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No notes yet',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to create your first note',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchNotes(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.notes.length,
            itemBuilder: (context, index) {
              return _buildNoteCard(provider.notes[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    final createdDate = note.createdAtDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showNoteDrawer(note);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            height: 1.3,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildNoteMenu(note),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                note.body,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (note.fav)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Favorite',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (note.shareid != null && note.shareid!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.share, size: 12, color: Colors.green[800]),
                          const SizedBox(width: 4),
                          Text(
                            'Shared',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    createdDate != null ? _formatDate(createdDate) : 'No date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteMenu(Note note) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        final provider = Provider.of<NotesProvider>(context, listen: false);
        switch (value) {
          case 'edit':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditorScreen(note: note),
              ),
            );
            break;
          case 'share':
            await _handleShare(note);
            break;
          case 'copy_share':
            if (note.shareid != null && note.shareid!.isNotEmpty) {
              await _copyShareLink(note.shareid!);
            }
            break;
          case 'favorite':
            await provider.toggleFavorite(note.id!, !note.fav);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    note.fav ? 'Removed from favorites' : 'Added to favorites',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            break;
          case 'trash':
            await provider.toggleTrash(note.id!, true);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Moved to trash'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 12),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              const Icon(Icons.share, size: 20),
              const SizedBox(width: 12),
              Text(
                note.shareid != null && note.shareid!.isNotEmpty
                    ? 'Create New Share Link'
                    : 'Share',
              ),
            ],
          ),
        ),
        if (note.shareid != null && note.shareid!.isNotEmpty)
          const PopupMenuItem(
            value: 'copy_share',
            child: Row(
              children: [
                Icon(Icons.content_copy, size: 20, color: Colors.blue),
                SizedBox(width: 12),
                Text('Copy Share Link'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'favorite',
          child: Row(
            children: [
              Icon(note.fav ? Icons.star : Icons.star_border, size: 20),
              const SizedBox(width: 12),
              Text(note.fav ? 'Remove from Favorites' : 'Add to Favorites'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'trash',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Move to Trash', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copyShareLink(String shareId) async {
    try {
      final apiService = ApiService();
      final domain = await apiService.baseUrl;
      final shareUrl = '$domain/shared/$shareId';

      await Clipboard.setData(ClipboardData(text: shareUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share link copied: $shareUrl'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleShare(Note note) async {
    try {
      final apiService = ApiService();
      final shareId = await apiService.createNoteShareId(note.id!);
      final domain = await apiService.baseUrl;
      final shareUrl = '$domain/shared/$shareId';

      // Refresh notes to update share ID
      if (mounted) {
        final provider = Provider.of<NotesProvider>(context, listen: false);
        await provider.fetchNotes();
      }

      if (mounted) {
        await Clipboard.setData(ClipboardData(text: shareUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share link copied: $shareUrl'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create share link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNoteDrawer(Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  note.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    note.body,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'unknown';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SearchBarDelegate({required this.child});

  @override
  double get minExtent => 80;

  @override
  double get maxExtent => 80;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
