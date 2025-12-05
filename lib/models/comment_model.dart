import 'package:get/get.dart';

/// Modèle représentant un commentaire sur une tâche
/// Les commentaires sont écrits par l'admin sur les tâches des utilisateurs
class CommentModel {
  /// Constructeur pour créer un nouveau commentaire
  CommentModel({
    this.id,
    required this.taskId, // ID de la tâche commentée
    required this.adminId, // ID de l'admin qui a écrit le commentaire
    required this.message,
    this.createdAt,
  });

  int? id;
  int taskId; // Clé étrangère vers la table tasks
  int adminId; // Clé étrangère vers la table users (admin)
  String message; // Contenu du commentaire
  DateTime? createdAt;

  /// Factory constructor depuis Map
  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'],
      taskId: map['task_id'],
      adminId: map['admin_id'],
      message: map['message'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  /// Conversion en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'task_id': taskId,
      'admin_id': adminId,
      'message': message,
      'created_at':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  /// Copie avec modifications
  CommentModel copyWith({
    int? id,
    int? taskId,
    int? adminId,
    String? message,
    DateTime? createdAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      adminId: adminId ?? this.adminId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Controller GetX pour gérer les commentaires
class CommentController extends GetxController {
  /// Liste observable de tous les commentaires
  final RxList<CommentModel> _comments = <CommentModel>[].obs;

  /// Getter pour accéder à la liste des commentaires
  List<CommentModel> get comments => _comments;

  /// Ajouter un nouveau commentaire
  void addComment(CommentModel comment) {
    _comments.add(comment);
    update();
  }

  /// Supprimer un commentaire par son ID
  void removeComment(int commentId) {
    _comments.removeWhere((comment) => comment.id == commentId);
    update();
  }

  /// Récupérer les commentaires d'une tâche spécifique
  List<CommentModel> getCommentsByTaskId(int taskId) {
    return _comments.where((comment) => comment.taskId == taskId).toList();
  }

  /// Mettre à jour un commentaire existant
  void updateComment(CommentModel updatedComment) {
    final index = _comments.indexWhere((c) => c.id == updatedComment.id);
    if (index != -1) {
      _comments[index] = updatedComment;
      update();
    }
  }
}
