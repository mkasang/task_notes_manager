import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_notes_manager/controllers/note_controller.dart';
import 'package:task_notes_manager/controllers/auth_controller.dart';
import 'package:task_notes_manager/models/note_model.dart';
import 'package:task_notes_manager/utils/helpers.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView>
    with SingleTickerProviderStateMixin {
  final NoteController _noteController = Get.find();
  final AuthController _authController = Get.find();

  late TextEditingController _searchController; // Controller pour la recherche
  late AnimationController
  _animationController; // Controller pour les animations
  late Animation<double> _scaleAnimation; // Animation de mise à l'échelle
  late Animation<Offset> _slideAnimation; // Animation de glissement

  String _searchQuery = ''; // Requête de recherche
  String _viewMode = 'grid'; // Mode d'affichage (grid/list)
  bool _isSelectionMode = false; // Mode de sélection multiple
  List<int> _selectedNotes = []; // Notes sélectionnées

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _setupAnimations();
    _loadNotes();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  Future<void> _loadNotes() async {
    await _noteController.loadUserNotes(_authController.currentUser!.id!);
  }

  List<NoteModel> _getFilteredNotes() {
    List<NoteModel> notes = _noteController.notes;

    if (_searchQuery.isEmpty) {
      return notes;
    }

    return notes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNotes.clear();
      }
    });
  }

  void _toggleNoteSelection(int noteId) {
    setState(() {
      if (_selectedNotes.contains(noteId)) {
        _selectedNotes.remove(noteId);
      } else {
        _selectedNotes.add(noteId);
      }

      if (_selectedNotes.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAllNotes() {
    setState(() {
      _selectedNotes = _getFilteredNotes().map((note) => note.id!).toList();
    });
  }

  void _deselectAllNotes() {
    setState(() {
      _selectedNotes.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedNotes() async {
    if (_selectedNotes.isEmpty) return;

    final confirm = await Helpers.showConfirmDialog(
      title: 'Supprimer les notes',
      message:
          'Êtes-vous sûr de vouloir supprimer ${_selectedNotes.length} note(s)?',
      confirmText: 'Supprimer',
    );

    if (confirm == true) {
      Helpers.showLoading('Suppression en cours...');

      bool allDeleted = true;
      for (final noteId in _selectedNotes) {
        final success = await _noteController.deleteNote(noteId);
        if (!success) {
          allDeleted = false;
        }
      }

      Helpers.hideLoading();

      if (allDeleted) {
        _deselectAllNotes();
        Helpers.showSnackbar(
          title: 'Succès',
          message: '${_selectedNotes.length} note(s) supprimée(s)',
          backgroundColor: Colors.green,
        );
      } else {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Certaines notes n\'ont pas pu être supprimées',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _addNewNote() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Nouvelle Note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return ScaleTransition(scale: _scaleAnimation, child: child);
                },
                child: Column(
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Titre',
                        prefixIcon: Icon(Icons.title, color: Colors.blue[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: contentController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: 'Contenu',
                        prefixIcon: Icon(
                          Icons.description,
                          color: Colors.blue[400],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                await _noteController.createNote(
                  titleController.text,
                  contentController.text,
                  _authController.currentUser!.id!,
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _viewNote(NoteModel note) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // En-tête avec le titre
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.note, color: Colors.blue[400], size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu de la note
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
              ),
            ),

            // Pied de page avec les actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Helpers.formatDate(note.createdAt!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue[400]),
                        onPressed: () {
                          Get.back();
                          _editNote(note);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[400]),
                        onPressed: () async {
                          Get.back();
                          final confirm = await Helpers.showConfirmDialog(
                            title: 'Supprimer la note',
                            message:
                                'Êtes-vous sûr de vouloir supprimer cette note?',
                            confirmText: 'Supprimer',
                          );

                          if (confirm == true) {
                            await _noteController.deleteNote(note.id!);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editNote(NoteModel note) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);

    Get.defaultDialog(
      title: 'Modifier la Note',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: contentController,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: 'Contenu',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    final updatedNote = note.copyWith(
                      title: titleController.text,
                      content: contentController.text,
                    );
                    await _noteController.updateNote(updatedNote);
                    Get.back();
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteGridItem(NoteModel note) {
    final isSelected = _selectedNotes.contains(note.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleNoteSelection(note.id!);
          } else {
            _viewNote(note);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
            _toggleNoteSelection(note.id!);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? const BorderSide(color: Colors.blue, width: 2)
                : BorderSide.none,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.note,
                            color: Colors.blue[400],
                            size: 24,
                          ),
                        ),
                        if (_isSelectionMode) ...[
                          const Spacer(),
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) =>
                                _toggleNoteSelection(note.id!),
                            activeColor: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Helpers.truncateText(note.title, maxLength: 20),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        Helpers.truncateText(note.content, maxLength: 80),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Helpers.formatDate(note.createdAt!),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              if (!_isSelectionMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'view') {
                        _viewNote(note);
                      } else if (value == 'edit') {
                        _editNote(note);
                      } else if (value == 'delete') {
                        _noteController.deleteNote(note.id!);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 18),
                            SizedBox(width: 8),
                            Text('Voir'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteListItem(NoteModel note) {
    final isSelected = _selectedNotes.contains(note.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? const BorderSide(color: Colors.blue, width: 2)
              : BorderSide.none,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.note, color: Colors.blue[400], size: 24),
          ),
          title: Text(
            note.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                Helpers.truncateText(note.content, maxLength: 60),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                Helpers.formatDate(note.createdAt!),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
          trailing: _isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleNoteSelection(note.id!),
                  activeColor: Colors.blue,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.visibility, color: Colors.blue[400]),
                      onPressed: () => _viewNote(note),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue[400]),
                      onPressed: () => _editNote(note),
                    ),
                  ],
                ),
          onTap: () {
            if (_isSelectionMode) {
              _toggleNoteSelection(note.id!);
            } else {
              _viewNote(note);
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              _toggleSelectionMode();
              _toggleNoteSelection(note.id!);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSelectionMode
              ? Text(
                  '${_selectedNotes.length} sélectionné(s)',
                  style: const TextStyle(fontSize: 16),
                )
              : const Text('Mes Notes'),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (!_isSelectionMode) ...[
            IconButton(
              icon: Icon(_viewMode == 'grid' ? Icons.list : Icons.grid_view),
              onPressed: _toggleViewMode,
              tooltip: _viewMode == 'grid' ? 'Vue liste' : 'Vue grille',
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: 'Mode sélection',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAllNotes,
              tooltip: 'Tout sélectionner',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelectedNotes,
              tooltip: 'Supprimer la sélection',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _deselectAllNotes,
              tooltip: 'Annuler la sélection',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: SlideTransition(
              position: _slideAnimation,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher une note...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),

          // Liste des notes
          Expanded(
            child: Obx(() {
              final filteredNotes = _getFilteredNotes();

              if (filteredNotes.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: _loadNotes,
                child: _viewMode == 'grid'
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.8,
                            ),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          return ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildNoteGridItem(filteredNotes[index]),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          return SlideTransition(
                            position: _slideAnimation,
                            child: _buildNoteListItem(filteredNotes[index]),
                          );
                        },
                      ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: !_isSelectionMode
          ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return ScaleTransition(
                  scale: _scaleAnimation,
                  child: FloatingActionButton(
                    onPressed: _addNewNote,
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    child: const Icon(Icons.note_add),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty ? 'Aucune note' : 'Aucun résultat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Commencez par créer votre première note'
                : 'Essayez avec d\'autres termes',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_searchQuery.isEmpty)
            ElevatedButton(
              onPressed: _addNewNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note_add),
                  SizedBox(width: 8),
                  Text('Ajouter une note'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
