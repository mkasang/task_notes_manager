import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_notes_manager/controllers/auth_controller.dart';
import 'package:task_notes_manager/controllers/task_controller.dart';
import 'package:task_notes_manager/controllers/note_controller.dart';
import 'package:task_notes_manager/models/note_model.dart';
import 'package:task_notes_manager/models/task_model.dart';
import 'package:task_notes_manager/routes/app_routes.dart';
import 'package:task_notes_manager/utils/helpers.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard>
    with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find();
  final TaskController _taskController = Get.find();
  final NoteController _noteController = Get.find();

  late TabController _tabController; // Controller pour les onglets
  int _selectedIndex = 0; // Index de l'onglet sélectionné
  late AnimationController
  _animationController; // Controller pour les animations
  late Animation<double> _scaleAnimation; // Animation de mise à l'échelle

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 onglets
    _setupAnimations(); // Initialise les animations
    _loadData(); // Charge les données
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(); // Démarre l'animation
  }

  Future<void> _loadData() async {
    // Charge les tâches et notes de l'utilisateur
    await _taskController.loadUserTasks(_authController.currentUser!.id!);
    await _noteController.loadUserNotes(_authController.currentUser!.id!);
  }

  void _refreshData() async {
    // Rafraîchit toutes les données
    await _loadData();
    Helpers.showSnackbar(
      title: 'Actualisé',
      message: 'Les données ont été rafraîchies',
      backgroundColor: Colors.green,
    );
  }

  void _logout() async {
    final confirm = await Helpers.showConfirmDialog(
      title: 'Déconnexion',
      message: 'Voulez-vous vraiment vous déconnecter?',
    );

    if (confirm == true) {
      _authController.logout();
    }
  }

  void _addTask() {
    Get.defaultDialog(title: 'Nouvelle Tâche', content: _buildTaskForm());
  }

  void _addNote() {
    Get.defaultDialog(title: 'Nouvelle Note', content: _buildNoteForm());
  }

  Widget _buildTaskForm() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    return SingleChildScrollView(
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
            controller: descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
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
                  if (titleController.text.isNotEmpty) {
                    await _taskController.createTask(
                      titleController.text,
                      descriptionController.text,
                      _authController.currentUser!.id!,
                    );
                    Get.back();
                  }
                },
                child: const Text('Créer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteForm() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    return SingleChildScrollView(
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
            maxLines: 5,
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
                child: const Text('Créer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Text(
                'Tableau de Bord',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.1),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.refresh, color: Colors.blue),
          onPressed: _refreshData,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: TextStyle(fontWeight: FontWeight.w500),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          tabs: const [
            Tab(text: 'Tâches', icon: Icon(Icons.task)),
            Tab(text: 'Notes', icon: Icon(Icons.note)),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedIndex == 0 ? _buildTasksTab() : _buildNotesTab(),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FloatingActionButton(
              onPressed: _selectedIndex == 0 ? _addTask : _addNote,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 5,
              child: Icon(
                _selectedIndex == 0 ? Icons.add_task : Icons.note_add,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTasksTab() {
    return Obx(() {
      final tasks = _taskController.tasks;

      if (tasks.isEmpty) {
        return _buildEmptyState(
          icon: Icons.task,
          title: 'Aucune tâche',
          message: 'Créez votre première tâche',
          action: _addTask,
          actionText: 'Ajouter une tâche',
        );
      }

      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Get.toNamed(AppRoutes.userTasks, arguments: task);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Helpers.getStatusColor(task.status),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                task.isDone
                                    ? Icons.check_circle
                                    : Icons.access_time,
                                color: Helpers.getStatusColor(task.status),
                              ),
                              onPressed: () =>
                                  _taskController.toggleTaskStatus(task.id!),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (task.description.isNotEmpty)
                          Text(
                            Helpers.truncateText(
                              task.description,
                              maxLength: 100,
                            ),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Helpers.formatDate(task.createdAt!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 18),
                                  onPressed: () => _editTask(task),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _taskController.deleteTask(task.id!),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildNotesTab() {
    return Obx(() {
      final notes = _noteController.notes;

      if (notes.isEmpty) {
        return _buildEmptyState(
          icon: Icons.note,
          title: 'Aucune note',
          message: 'Créez votre première note',
          action: _addNote,
          actionText: 'Ajouter une note',
        );
      }

      return RefreshIndicator(
        onRefresh: _loadData,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _viewNote(note),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.note, color: Colors.blue, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          Helpers.truncateText(note.title, maxLength: 20),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            Helpers.truncateText(note.content, maxLength: 80),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Helpers.formatDate(note.createdAt!),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required VoidCallback action,
    required String actionText,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: action,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(actionText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editTask(TaskModel task) {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);

    Get.defaultDialog(
      title: 'Modifier la tâche',
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
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: task.status,
              decoration: InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('En attente')),
                DropdownMenuItem(value: 'done', child: Text('Terminé')),
              ],
              onChanged: (value) {
                task.status = value!;
              },
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
                    final updatedTask = task.copyWith(
                      title: titleController.text,
                      description: descriptionController.text,
                    );
                    await _taskController.updateTask(updatedTask);
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

  void _viewNote(NoteModel note) {
    Get.defaultDialog(
      title: note.title,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.content,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Text(
              'Créée le: ${Helpers.formatDate(note.createdAt!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Fermer'),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editNote(note),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _noteController.deleteNote(note.id!),
                ),
              ],
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
      title: 'Modifier la note',
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
              maxLines: 5,
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
}
