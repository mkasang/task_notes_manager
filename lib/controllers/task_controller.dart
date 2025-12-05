import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_notes_manager/models/task_model.dart';
import 'package:task_notes_manager/services/task_service.dart';
import 'package:task_notes_manager/utils/helpers.dart';

class TaskController extends GetxController {
  final TaskService _taskService = TaskService(); // Service des tâches
  final RxList<TaskModel> _tasks =
      <TaskModel>[].obs; // Liste observable des tâches

  List<TaskModel> get tasks => _tasks; // Getter pour toutes les tâches

  // Charge toutes les tâches (admin seulement)
  Future<void> loadAllTasks() async {
    try {
      Helpers.showLoading('Chargement des tâches...');

      final allTasks = await _taskService.getAllTasks();
      _tasks.assignAll(allTasks); // Remplace toutes les tâches

      Helpers.hideLoading();
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur lors du chargement: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  // Charge les tâches d'un utilisateur spécifique
  Future<void> loadUserTasks(int userId) async {
    try {
      Helpers.showLoading('Chargement de vos tâches...');

      final userTasks = await _taskService.getTasksByUserId(userId);
      _tasks.assignAll(userTasks);

      Helpers.hideLoading();
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur lors du chargement: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  // Crée une nouvelle tâche
  Future<bool> createTask(String title, String description, int userId) async {
    try {
      if (Helpers.isNullOrEmpty(title)) {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Le titre est requis',
          backgroundColor: Colors.red,
        );
        return false;
      }

      Helpers.showLoading('Création de la tâche...');

      final newTask = TaskModel(
        userId: userId,
        title: title,
        description: description,
        status: 'pending',
      );

      final taskId = await _taskService.createTask(newTask);

      Helpers.hideLoading();

      if (taskId != null) {
        newTask.id = taskId;
        _tasks.insert(0, newTask); // Ajoute au début de la liste

        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Tâche créée avec succès',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Erreur lors de la création',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur: $e',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  // Met à jour une tâche
  Future<bool> updateTask(TaskModel task) async {
    try {
      Helpers.showLoading('Mise à jour en cours...');

      final success = await _taskService.updateTask(task);

      Helpers.hideLoading();

      if (success) {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task; // Met à jour dans la liste
        }

        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Tâche mise à jour',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Erreur lors de la mise à jour',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur: $e',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  Future<bool> updateTaskStatus(int taskId, String status) async {
    try {
      Helpers.showLoading('Mise à jour du statut...');

      final success = await _taskService.updateTaskStatus(taskId, status);

      Helpers.hideLoading();

      if (success) {
        final task = _tasks.firstWhere((t) => t.id == taskId);
        task.status = status;
        update(); // Notifie les observateurs

        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Statut mis à jour',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Erreur lors de la mise à jour',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur: $e',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  // Supprime une tâche
  Future<bool> deleteTask(int taskId) async {
    try {
      final confirm = await Helpers.showConfirmDialog(
        title: 'Confirmer la suppression',
        message: 'Voulez-vous vraiment supprimer cette tâche?',
      );

      if (confirm != true) return false;

      Helpers.showLoading('Suppression en cours...');

      final success = await _taskService.deleteTask(taskId);

      Helpers.hideLoading();

      if (success) {
        _tasks.removeWhere((task) => task.id == taskId); // Supprime de la liste

        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Tâche supprimée',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Erreur lors de la suppression',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur: $e',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  // Change le statut d'une tâche
  Future<void> toggleTaskStatus(int taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final newStatus = task.status == 'pending' ? 'done' : 'pending';

      final success = await _taskService.updateTaskStatus(taskId, newStatus);

      if (success) {
        task.status = newStatus; // Met à jour localement
        update(); // Notifie les observateurs
      }
    } catch (e) {
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  // Recherche des tâches
  Future<void> searchTasks(String keyword, {int? userId}) async {
    try {
      Helpers.showLoading('Recherche en cours...');

      final results = await _taskService.searchTasks(keyword, userId: userId);
      _tasks.assignAll(results);

      Helpers.hideLoading();
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur lors de la recherche: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  // Récupère les tâches d'un utilisateur
  List<TaskModel> getTasksByUserId(int userId) {
    return _tasks.where((task) => task.userId == userId).toList();
  }

  // Récupère une tâche par ID
  TaskModel? getTaskById(int taskId) {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  // Filtre les tâches par statut
  List<TaskModel> getTasksByStatus(String status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  // Compte les tâches par statut
  int countTasksByStatus(String status) {
    return _tasks.where((task) => task.status == status).length;
  }
}
