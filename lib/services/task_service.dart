import 'package:task_notes_manager/models/task_model.dart';
import 'package:task_notes_manager/services/db_service.dart';

/// Service des tâches - Gère le CRUD des tâches
class TaskService {
  final DatabaseService _dbService = DatabaseService.instance;

  /// Crée une nouvelle tâche
  Future<int?> createTask(TaskModel task) async {
    try {
      final db = await _dbService.database;

      final id = await db.insert('tasks', task.toMap());

      print('Tâche créée avec ID: $id');
      return id;
    } catch (e) {
      print('Erreur lors de la création de la tâche: $e');
      return null;
    }
  }

  /// Récupère toutes les tâches (pour l'admin)
  Future<List<TaskModel>> getAllTasks() async {
    try {
      final db = await _dbService.database;

      final result = await db.query('tasks', orderBy: 'created_at DESC');

      return result.map((map) => TaskModel.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des tâches: $e');
      return [];
    }
  }

  /// Récupère les tâches d'un utilisateur spécifique
  Future<List<TaskModel>> getTasksByUserId(int userId) async {
    try {
      final db = await _dbService.database;

      final result = await db.query(
        'tasks',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      return result.map((map) => TaskModel.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des tâches utilisateur: $e');
      return [];
    }
  }

  /// Récupère une tâche par son ID
  Future<TaskModel?> getTaskById(int taskId) async {
    try {
      final db = await _dbService.database;

      final result = await db.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return TaskModel.fromMap(result.first);
    } catch (e) {
      print('Erreur lors de la récupération de la tâche: $e');
      return null;
    }
  }

  /// Met à jour une tâche existante
  Future<bool> updateTask(TaskModel task) async {
    try {
      final db = await _dbService.database;

      final updated = await db.update(
        'tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );

      print('Tâche mise à jour: ${task.id} ($updated ligne affectée)');
      return updated > 0;
    } catch (e) {
      print('Erreur lors de la mise à jour de la tâche: $e');
      return false;
    }
  }

  /// Supprime une tâche par son ID
  Future<bool> deleteTask(int taskId) async {
    try {
      final db = await _dbService.database;

      final deleted = await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );

      print('Tâche supprimée: $taskId ($deleted ligne affectée)');
      return deleted > 0;
    } catch (e) {
      print('Erreur lors de la suppression de la tâche: $e');
      return false;
    }
  }

  /// Change le statut d'une tâche
  Future<bool> updateTaskStatus(int taskId, String status) async {
    try {
      final db = await _dbService.database;

      final updated = await db.update(
        'tasks',
        {'status': status},
        where: 'id = ?',
        whereArgs: [taskId],
      );

      print('Statut de tâche mis à jour: $taskId -> $status');
      return updated > 0;
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }

  /// Recherche des tâches par mot-clé
  Future<List<TaskModel>> searchTasks(String keyword, {int? userId}) async {
    try {
      final db = await _dbService.database;

      String whereClause = '(title LIKE ? OR description LIKE ?)';
      List<dynamic> whereArgs = ['%$keyword%', '%$keyword%'];

      if (userId != null) {
        whereClause += ' AND user_id = ?';
        whereArgs.add(userId);
      }

      final result = await db.query(
        'tasks',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );

      return result.map((map) => TaskModel.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la recherche de tâches: $e');
      return [];
    }
  }
}
