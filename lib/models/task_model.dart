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
