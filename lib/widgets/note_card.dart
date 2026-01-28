import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../screens/note_editor_screen.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final bool isListView;

  const NoteCard({super.key, required this.note, this.isListView = false});

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm').format(date);
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = Provider.of<NotesProvider>(context, listen: false);
      final success = await provider.deleteNote(note.id!);
      if (success) {
        Fluttertoast.showToast(
          msg: 'Note deleted',
          backgroundColor: Colors.green,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final updatedDate = note.updatedAtDate ?? note.createdAtDate;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(note: note),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.fav)
                    Icon(Icons.star, size: 16, color: Colors.amber[700]),
                  if (note.fav) const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: isListView ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      final provider = Provider.of<NotesProvider>(
                        context,
                        listen: false,
                      );
                      switch (value) {
                        case 'favorite':
                          await provider.toggleFavorite(note.id!, !note.fav);
                          Fluttertoast.showToast(
                            msg: note.fav
                                ? 'Removed from favorites'
                                : 'Added to favorites',
                          );
                          break;
                        case 'trash':
                          await provider.toggleTrash(note.id!, true);
                          Fluttertoast.showToast(msg: 'Moved to trash');
                          break;
                        case 'delete':
                          _showDeleteDialog(context);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'favorite',
                        child: Row(
                          children: [
                            Icon(
                              note.fav ? Icons.star : Icons.star_border,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              note.fav
                                  ? 'Remove from Favorites'
                                  : 'Add to Favorites',
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'trash',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Move to Trash'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_forever,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Permanently',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.body,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
                maxLines: isListView ? 2 : 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (note.category != null && note.category!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        note.category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                  Text(
                    _formatDate(updatedDate),
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
}
