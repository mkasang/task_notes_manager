import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_notes_manager/models/task_model.dart';
import 'package:task_notes_manager/services/task_service.dart';
import 'package:task_notes_manager/utils/helpers.dart';

class TaskController extends GetxController {
  final TaskService _taskService = TaskService();
  final RxList<TaskModel> _tasks = <TaskModel>[].obs;

  List<TaskModel> get tasks => _tasks;

  static TaskController get to => Get.find<TaskController>();

  @override
  void onInit() {
    super.onInit();
    print('✅ TaskController initialisé');
  }

  // Charge toutes les tâches (pour admin)
  Future<void> loadAllTasks() async {
    try {
      Helpers.showLoading('Chargement des tâches...');
      final allTasks = await _taskService.getAllTasks();
      _tasks.assignAll(allTasks);
      Helpers.hideLoading();
    } catch (e) {
      Helpers.hideLoading();
      print('Erreur lors du chargement des tâches: $e');
    }
  }

  // Charge les tâches d'un utilisateur
  Future<void> loadUserTasks(int userId) async {
    try {
      Helpers.showLoading('Chargement de vos tâches...');
      final userTasks = await _taskService.getTasksByUserId(userId);
      _tasks.assignAll(userTasks);
      Helpers.hideLoading();
    } catch (e) {
      Helpers.hideLoading();
      print('Erreur lors du chargement des tâches utilisateur: $e');
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
        _tasks.insert(0, newTask);

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

  // Met à jour une tâche existante
  Future<bool> updateTask(TaskModel task) async {
    try {
      Helpers.showLoading('Mise à jour en cours...');

      final success = await _taskService.updateTask(task);
      Helpers.hideLoading();

      if (success) {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task;
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
        _tasks.removeWhere((task) => task.id == taskId);

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
  Future<bool> updateTaskStatus(int taskId, String status) async {
    try {
      final success = await _taskService.updateTaskStatus(taskId, status);

      if (success) {
        final task = _tasks.firstWhere((t) => t.id == taskId);
        task.status = status;
        update(); // Notifie les observateurs
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }

  // Toggle le statut d'une tâche
  Future<void> toggleTaskStatus(int taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final newStatus = task.status == 'pending' ? 'done' : 'pending';

      final success = await updateTaskStatus(taskId, newStatus);

      if (success) {
        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Statut mis à jour',
          backgroundColor: Colors.green,
        );
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
  Future<List<TaskModel>> searchTasks(String keyword, {int? userId}) async {
    try {
      return await _taskService.searchTasks(keyword, userId: userId);
    } catch (e) {
      print('Erreur lors de la recherche de tâches: $e');
      return [];
    }
  }

  // Récupère les tâches d'un utilisateur spécifique
  List<TaskModel> getTasksByUserId(int userId) {
    return _tasks.where((task) => task.userId == userId).toList();
  }

  // Récupère une tâche par son ID
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

  // Vide la liste des tâches
  void clearTasks() {
    _tasks.clear();
  }
}
