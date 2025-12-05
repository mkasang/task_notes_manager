import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_notes_manager/controllers/task_controller.dart';
import 'package:task_notes_manager/controllers/admin_controller.dart';
import 'package:task_notes_manager/controllers/auth_controller.dart';
import 'package:task_notes_manager/models/comment_model.dart';
import 'package:task_notes_manager/models/task_model.dart';
import 'package:task_notes_manager/utils/helpers.dart';

class TaskCommentsView extends StatefulWidget {
  const TaskCommentsView({super.key});

  @override
  State<TaskCommentsView> createState() => _TaskCommentsViewState();
}

class _TaskCommentsViewState extends State<TaskCommentsView>
    with SingleTickerProviderStateMixin {
  final TaskController _taskController = Get.find();
  final AdminController _adminController = Get.find();
  final AuthController _authController = Get.find();

  late TaskModel _task; // Tâche à afficher
  late TextEditingController
  _commentController; // Controller pour les commentaires
  late AnimationController
  _animationController; // Controller pour les animations
  late Animation<double> _fadeAnimation; // Animation de fondu
  late Animation<Offset> _slideAnimation; // Animation de glissement

  bool _isLoading = false; // État de chargement

  @override
  void initState() {
    super.initState();
    _task = Get.arguments as TaskModel; // Récupère la tâche passée en argument
    _commentController = TextEditingController();
    _setupAnimations();
    _loadComments();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _animationController.forward();
  }

  Future<void> _loadComments() async {
    await _adminController.loadCommentsForTask(_task.id!);
  }

  Future<void> _addComment() async {
    final message = _commentController.text.trim();

    if (message.isEmpty) {
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Le commentaire ne peut pas être vide',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _adminController.addCommentToTask(
      _task.id!,
      _authController.currentUser!.id!,
      message,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus(); // Cache le clavier
    }
  }

  Future<void> _updateTaskStatus(String status) async {
    final success = await _taskController.updateTaskStatus(_task.id!, status);

    if (success) {
      setState(() {
        _task = _task.copyWith(status: status);
      });

      Helpers.showSnackbar(
        title: 'Succès',
        message: 'Statut mis à jour',
        backgroundColor: Colors.green,
      );
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await Helpers.showConfirmDialog(
      title: 'Supprimer la tâche',
      message: 'Êtes-vous sûr de vouloir supprimer cette tâche?',
      confirmText: 'Supprimer',
    );

    if (confirm == true) {
      final success = await _taskController.deleteTask(_task.id!);
      if (success) {
        Get.back();
      }
    }
  }

  void _showCommentMenu(CommentModel comment, BuildContext context) {
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
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  _editComment(comment);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteComment(comment.id!);
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

  void _editComment(CommentModel comment) {
    final messageController = TextEditingController(text: comment.message);

    Get.defaultDialog(
      title: 'Modifier le commentaire',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
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
                    final updatedComment = comment.copyWith(
                      message: messageController.text,
                    );
                    await _adminController.updateComment(updatedComment);
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

  Future<void> _deleteComment(int commentId) async {
    final confirm = await Helpers.showConfirmDialog(
      title: 'Supprimer le commentaire',
      message: 'Êtes-vous sûr de vouloir supprimer ce commentaire?',
      confirmText: 'Supprimer',
    );

    if (confirm == true) {
      await _adminController.deleteComment(commentId);
    }
  }

  Widget _buildTaskHeader() {
    final user = _adminController.getUserById(_task.userId);

    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Helpers.getStatusColor(
                        _task.status,
                      ).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Helpers.getStatusIcon(_task.status),
                      color: Helpers.getStatusColor(_task.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _task.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.name ?? 'Utilisateur inconnu',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: _updateTaskStatus,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pending',
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.orange[400]),
                            const SizedBox(width: 8),
                            const Text('En attente'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'done',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[400]),
                            const SizedBox(width: 8),
                            const Text('Terminé'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Helpers.getStatusColor(
                          _task.status,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Helpers.getStatusColor(
                            _task.status,
                          ).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _task.status == 'pending'
                                ? 'En attente'
                                : 'Terminé',
                            style: TextStyle(
                              color: Helpers.getStatusColor(_task.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Helpers.getStatusColor(_task.status),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_task.description.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _task.description,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Helpers.formatDate(_task.createdAt!),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteTask,
                    tooltip: 'Supprimer la tâche',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Ajouter un commentaire...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _addComment(),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isLoading ? 48 : null,
              height: 48,
              child: _isLoading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : ElevatedButton(
                      onPressed: _addComment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send, size: 18),
                          SizedBox(width: 8),
                          Text('Envoyer'),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    final admin = _adminController.getUserById(comment.adminId);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.blue[400],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              admin?.name ?? 'Admin',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.more_vert,
                                size: 18,
                                color: Colors.grey[500],
                              ),
                              onPressed: () =>
                                  _showCommentMenu(comment, context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          comment.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      Helpers.formatDate(comment.createdAt!),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Commentaires'),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTaskHeader(),

                  const SizedBox(height: 32),

                  // Titre des commentaires
                  Row(
                    children: [
                      const Text(
                        'Commentaires',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Obx(() {
                        final commentCount = _adminController.comments.length;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            commentCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Liste des commentaires
                  Obx(() {
                    final comments = _adminController.comments;

                    if (comments.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 60,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun commentaire',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Soyez le premier à commenter',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        return _buildCommentItem(comments[index]);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),

          // Input pour ajouter un commentaire
          _buildCommentInput(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
