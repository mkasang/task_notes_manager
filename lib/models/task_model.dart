import 'package:get/get.dart';

/// Modèle représentant une tâche dans l'application
/// Une tâche appartient à un utilisateur et peut avoir des commentaires
class TaskModel {
  /// Constructeur pour créer une nouvelle tâche
  TaskModel({
    this.id,
    required this.userId, // ID de l'utilisateur propriétaire
    required this.title,
    required this.description,
    this.status = 'pending', // Par défaut, la tâche est en attente
    this.createdAt,
  });

  int? id;
  int userId; // Clé étrangère vers la table users
  String title; // Titre de la tâche
  String description; // Description détaillée
  String status; // 'pending' ou 'done'
  DateTime? createdAt; // Date de création

  /// Factory constructor depuis Map (depuis SQLite)
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      description: map['description'],
      status: map['status'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  /// Conversion en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'status': status,
      'created_at':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  /// Copie avec modifications
  TaskModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    String? status,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Vérifie si la tâche est terminée
  bool get isDone => status == 'done';

  /// Vérifie si la tâche est en attente
  bool get isPending => status == 'pending';

  /// Basculer le statut de la tâche
  void toggleStatus() {
    status = isDone ? 'pending' : 'done';
  }
}

/// Controller GetX pour gérer la liste des tâches
/// RxList est une liste observable - les changements sont automatiquement détectés
class TaskController extends GetxController {
  /// Liste observable de toutes les tâches
  final RxList<TaskModel> _tasks = <TaskModel>[].obs;

  /// Getter pour accéder à la liste des tâches
  List<TaskModel> get tasks => _tasks;

  /// Ajouter une nouvelle tâche
  void addTask(TaskModel task) {
    _tasks.add(task);
    update();
  }

  /// Supprimer une tâche par son ID
  void removeTask(int taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    update();
  }

  /// Mettre à jour une tâche existante
  void updateTask(TaskModel updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      update();
    }
  }

  /// Récupérer les tâches d'un utilisateur spécifique
  List<TaskModel> getTasksByUserId(int userId) {
    return _tasks.where((task) => task.userId == userId).toList();
  }

  /// Marquer une tâche comme terminée
  void markAsDone(int taskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = 'done';
    update();
  }

  /// Marquer une tâche comme en attente
  void markAsPending(int taskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = 'pending';
    update();
  }
}
