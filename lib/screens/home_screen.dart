import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../providers/theme_provider.dart';
import 'note_editor_screen.dart';
import '../widgets/note_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          Consumer<NotesProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.viewMode == 'grid'
                      ? Icons.view_list
                      : Icons.grid_view,
                ),
                onPressed: () {
                  provider.setViewMode(
                    provider.viewMode == 'grid' ? 'list' : 'grid',
                  );
                },
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () => provider.toggleTheme(),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              final provider = Provider.of<NotesProvider>(
                context,
                listen: false,
              );
              switch (value) {
                case 'refresh':
                  provider.fetchNotes();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
      body: Consumer<NotesProvider>(
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
            child: provider.viewMode == 'grid'
                ? GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: provider.notes.length,
                    itemBuilder: (context, index) {
                      return NoteCard(note: provider.notes[index]);
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: provider.notes.length,
                    itemBuilder: (context, index) {
                      return NoteCard(
                        note: provider.notes[index],
                        isListView: true,
                      );
                    },
                  ),
          );
        },
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
}
