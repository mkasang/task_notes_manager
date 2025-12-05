import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_notes_manager/controllers/task_controller.dart';
import 'package:task_notes_manager/controllers/auth_controller.dart';
import 'package:task_notes_manager/models/task_model.dart';
import 'package:task_notes_manager/utils/helpers.dart';

class TaskListView extends StatefulWidget {
  const TaskListView({super.key});

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView>
    with SingleTickerProviderStateMixin {
  final TaskController _taskController = Get.find();
  final AuthController _authController = Get.find();

  late TextEditingController _searchController; // Controller pour la recherche
  late AnimationController
  _animationController; // Controller pour les animations
  // Animation de fondu
  late Animation<Offset> _slideAnimation; // Animation de glissement
  late Animation<double> _scaleAnimation;

  String _searchQuery = ''; // Requête de recherche
  String _filterStatus = 'all'; // Filtre par statut
  bool _showCompleted = true; // Afficher les tâches terminées

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _setupAnimations();
    _loadTasks();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  Future<void> _loadTasks() async {
    await _taskController.loadUserTasks(_authController.currentUser!.id!);
  }

  List<TaskModel> _getFilteredTasks() {
    List<TaskModel> tasks = _taskController.tasks;

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      tasks = tasks.where((task) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filtre par statut
    if (_filterStatus != 'all') {
      tasks = tasks.where((task) => task.status == _filterStatus).toList();
    }

    // Filtre des tâches terminées
    if (!_showCompleted) {
      tasks = tasks.where((task) => task.status != 'done').toList();
    }

    return tasks;
  }

  void _addNewTask() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Nouvelle Tâche'),
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
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
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
              if (titleController.text.isNotEmpty) {
                await _taskController.createTask(
                  titleController.text,
                  descriptionController.text,
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

  void _showTaskDetails(TaskModel task) {
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
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Helpers.getStatusColor(task.status).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Helpers.getStatusIcon(task.status),
                    color: Helpers.getStatusColor(task.status),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              if (task.description.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _buildDetailItem(
                icon: Icons.access_time,
                label: 'Statut',
                value: task.status == 'pending' ? 'En attente' : 'Terminé',
                color: Helpers.getStatusColor(task.status),
              ),
              _buildDetailItem(
                icon: Icons.calendar_today,
                label: 'Créée le',
                value: Helpers.formatDate(task.createdAt!),
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _editTask(task);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        final confirm = await Helpers.showConfirmDialog(
                          title: 'Supprimer la tâche',
                          message:
                              'Êtes-vous sûr de vouloir supprimer cette tâche?',
                          confirmText: 'Supprimer',
                        );

                        if (confirm == true) {
                          await _taskController.deleteTask(task.id!);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, size: 18),
                          SizedBox(width: 8),
                          Text('Supprimer'),
                        ],
                      ),
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

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
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
      title: 'Modifier la Tâche',
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
              maxLines: 4,
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

  Widget _buildTaskItem(TaskModel task) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(task.id.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 30),
        ),
        confirmDismiss: (direction) async {
          return await Helpers.showConfirmDialog(
            title: 'Supprimer la tâche',
            message: 'Êtes-vous sûr de vouloir supprimer cette tâche?',
            confirmText: 'Supprimer',
          );
        },
        onDismissed: (direction) async {
          await _taskController.deleteTask(task.id!);
        },
        child: SlideTransition(
          position: _slideAnimation,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showTaskDetails(task),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Checkbox pour marquer comme terminé
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: task.status == 'done'
                            ? Colors.green
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: task.status == 'done'
                              ? Colors.green
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: task.status == 'done'
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),

                    const SizedBox(width: 16),

                    // Contenu de la tâche
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.grey[800],
                              decoration: task.status == 'done'
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),

                          const SizedBox(height: 8),

                          if (task.description.isNotEmpty)
                            Text(
                              Helpers.truncateText(
                                task.description,
                                maxLength: 80,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                decoration: task.status == 'done'
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Helpers.getStatusColor(
                                    task.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  task.status == 'pending'
                                      ? 'En attente'
                                      : 'Terminé',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Helpers.getStatusColor(task.status),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              const Spacer(),

                              Text(
                                Helpers.formatDateOnly(task.createdAt!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Bouton d'action rapide
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey[500]),
                      onPressed: () => _showTaskActions(task),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskActions(TaskModel task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  task.status == 'pending'
                      ? Icons.check_circle
                      : Icons.access_time,
                  color: task.status == 'pending'
                      ? Colors.green
                      : Colors.orange,
                ),
                title: Text(
                  task.status == 'pending'
                      ? 'Marquer comme terminé'
                      : 'Marquer comme en attente',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _taskController.toggleTaskStatus(task.id!);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  _editTask(task);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await Helpers.showConfirmDialog(
                    title: 'Supprimer la tâche',
                    message: 'Êtes-vous sûr de vouloir supprimer cette tâche?',
                    confirmText: 'Supprimer',
                  );

                  if (confirm == true) {
                    await _taskController.deleteTask(task.id!);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes Tâches'),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addNewTask),
        ],
      ),
      body: Column(
        children: [
          // Filtres et recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barre de recherche
                SlideTransition(
                  position: _slideAnimation,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher une tâche...',
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

                const SizedBox(height: 16),

                // Filtres
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus,
                        decoration: InputDecoration(
                          hintText: 'Filtrer par statut',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tous')),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('En attente'),
                          ),
                          DropdownMenuItem(
                            value: 'done',
                            child: Text('Terminé'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterStatus = value!;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Toggle pour afficher/masquer les terminées
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: _showCompleted ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showCompleted,
                            onChanged: (value) {
                              setState(() {
                                _showCompleted = value;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des tâches
          Expanded(
            child: Obx(() {
              final filteredTasks = _getFilteredTasks();

              if (filteredTasks.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: _loadTasks,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskItem(filteredTasks[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ScaleTransition(
            scale: _scaleAnimation,
            child: FloatingActionButton(
              onPressed: _addNewTask,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 5,
              child: const Icon(Icons.add_task),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty ? 'Aucune tâche' : 'Aucun résultat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Commencez par créer votre première tâche'
                : 'Essayez avec d\'autres termes',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_searchQuery.isEmpty)
            ElevatedButton(
              onPressed: _addNewTask,
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
                  Icon(Icons.add_task),
                  SizedBox(width: 8),
                  Text('Ajouter une tâche'),
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
