import 'package:get/get.dart';

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

/// Controller GetX pour gérer les notes
class NoteController extends GetxController {
  /// Liste observable de toutes les notes
  final RxList<NoteModel> _notes = <NoteModel>[].obs;

  /// Getter pour accéder à la liste des notes
  List<NoteModel> get notes => _notes;

  /// Ajouter une nouvelle note
  void addNote(NoteModel note) {
    _notes.add(note);
    update();
  }

  /// Supprimer une note par son ID
  void removeNote(int noteId) {
    _notes.removeWhere((note) => note.id == noteId);
    update();
  }

  /// Mettre à jour une note existante
  void updateNote(NoteModel updatedNote) {
    final index = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      update();
    }
  }

  /// Récupérer les notes d'un utilisateur spécifique
  List<NoteModel> getNotesByUserId(int userId) {
    return _notes.where((note) => note.userId == userId).toList();
  }
}
