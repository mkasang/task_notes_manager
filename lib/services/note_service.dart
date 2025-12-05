import 'package:sqflite/sqflite.dart';
import 'package:task_notes_manager/models/note_model.dart';
import 'package:task_notes_manager/services/db_service.dart';

class NoteService {
  final DatabaseService _dbService = DatabaseService(); // Pas de .instance

  Future<int?> createNote(NoteModel note) async {
    try {
      final db = await _dbService.database;
      final id = await db.insert('notes', note.toMap());
      print('Note créée avec ID: $id');
      return id;
    } catch (e) {
      print('Erreur lors de la création de la note: $e');
      return null;
    }
  }

  Future<List<NoteModel>> getNotesByUserId(int userId) async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        'notes',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      return result.map((map) => NoteModel.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des notes: $e');
      return [];
    }
  }

  Future<NoteModel?> getNoteById(int noteId) async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        'notes',
        where: 'id = ?',
        whereArgs: [noteId],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return NoteModel.fromMap(result.first);
    } catch (e) {
      print('Erreur lors de la récupération de la note: $e');
      return null;
    }
  }

  Future<bool> updateNote(NoteModel note) async {
    try {
      final db = await _dbService.database;
      final updated = await db.update(
        'notes',
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
      print('Note mise à jour: ${note.id}');
      return updated > 0;
    } catch (e) {
      print('Erreur lors de la mise à jour de la note: $e');
      return false;
    }
  }

  Future<bool> deleteNote(int noteId) async {
    try {
      final db = await _dbService.database;
      final deleted = await db.delete(
        'notes',
        where: 'id = ?',
        whereArgs: [noteId],
      );
      print('Note supprimée: $noteId');
      return deleted > 0;
    } catch (e) {
      print('Erreur lors de la suppression de la note: $e');
      return false;
    }
  }

  Future<List<NoteModel>> searchNotes(String keyword, int userId) async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        'notes',
        where: 'user_id = ? AND (title LIKE ? OR content LIKE ?)',
        whereArgs: [userId, '%$keyword%', '%$keyword%'],
        orderBy: 'created_at DESC',
      );
      return result.map((map) => NoteModel.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la recherche de notes: $e');
      return [];
    }
  }
}
