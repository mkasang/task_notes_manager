/// Modèle représentant une note personnelle
/// Les notes sont privées et appartiennent à un utilisateur
class NoteModel {
  /// Constructeur pour créer une nouvelle note
  NoteModel({
    this.id,
    required this.userId, // ID du propriétaire de la note
    required this.title,
    required this.content,
    this.createdAt,
  });

  int? id;
  int userId; // Clé étrangère vers la table users
  String title; // Titre de la note
  String content; // Contenu détaillé de la note
  DateTime? createdAt; // Date de création

  /// Factory constructor depuis Map
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      content: map['content'],
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
      'content': content,
      'created_at':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  /// Copie avec modifications
  NoteModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? content,
    DateTime? createdAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
