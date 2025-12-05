import 'package:sqflite/sqflite.dart';
import 'package:task_notes_manager/models/comment_model.dart';
import 'package:task_notes_manager/services/db_service.dart';

class CommentService {
  final DatabaseService _dbService = DatabaseService(); // Pas de .instance

  Future<int?> addComment(CommentModel comment) async {
    try {
      final db = await _dbService.database;
      final id = await db.insert('comments', comment.toMap());
      print('Commentaire ajouté avec ID: $id');
      return id;
    } catch (e) {
      print('Erreur lors de l\'ajout du commentaire: $e');
      return null;
    }
  }

  Future<List<CommentModel>> getCommentsByTaskId(int taskId) async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        'comments',
        where: 'task_id = ?',
        whereArgs: [taskId],
        orderBy: 'created_at ASC',
      );
      return result.map((map) => CommentModel.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des commentaires: $e');
      return [];
    }
  }

  Future<bool> updateComment(CommentModel comment) async {
    try {
      final db = await _dbService.database;
      final updated = await db.update(
        'comments',
        comment.toMap(),
        where: 'id = ?',
        whereArgs: [comment.id],
      );
      print('Commentaire mis à jour: ${comment.id}');
      return updated > 0;
    } catch (e) {
      print('Erreur lors de la mise à jour du commentaire: $e');
      return false;
    }
  }

  Future<bool> deleteComment(int commentId) async {
    try {
      final db = await _dbService.database;
      final deleted = await db.delete(
        'comments',
        where: 'id = ?',
        whereArgs: [commentId],
      );
      print('Commentaire supprimé: $commentId');
      return deleted > 0;
    } catch (e) {
      print('Erreur lors de la suppression du commentaire: $e');
      return false;
    }
  }

  Future<CommentModel?> getCommentById(int commentId) async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        'comments',
        where: 'id = ?',
        whereArgs: [commentId],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return CommentModel.fromMap(result.first);
    } catch (e) {
      print('Erreur lors de la récupération du commentaire: $e');
      return null;
    }
  }

  Future<bool> deleteCommentsByTaskId(int taskId) async {
    try {
      final db = await _dbService.database;
      final deleted = await db.delete(
        'comments',
        where: 'task_id = ?',
        whereArgs: [taskId],
      );
      print(
        'Commentaires supprimés pour la tâche: $taskId ($deleted supprimés)',
      );
      return deleted > 0;
    } catch (e) {
      print('Erreur lors de la suppression des commentaires: $e');
      return false;
    }
  }
}
