import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_notes_manager/controllers/auth_controller.dart';
import 'package:task_notes_manager/models/comment_model.dart';
import 'package:task_notes_manager/models/user_model.dart';
import 'package:task_notes_manager/services/comment_service.dart';
import 'package:task_notes_manager/utils/helpers.dart';

class AdminController extends GetxController {
  final CommentService _commentService =
      CommentService(); // Service des commentaires
  final RxList<UserModel> _users =
      <UserModel>[].obs; // Liste observable des utilisateurs
  final RxList<CommentModel> _comments =
      <CommentModel>[].obs; // Liste observable des commentaires

  List<UserModel> get users => _users; // Getter pour tous les utilisateurs
  List<CommentModel> get comments =>
      _comments; // Getter pour tous les commentaires

  // Charge tous les utilisateurs
  Future<void> loadAllUsers(AuthController authController) async {
    try {
      Helpers.showLoading('Chargement des utilisateurs...');

      final allUsers = await authController.getAllUsers();
      _users.assignAll(allUsers);

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

  // Ajoute un commentaire à une tâche
  Future<bool> addCommentToTask(int taskId, int adminId, String message) async {
    try {
      if (Helpers.isNullOrEmpty(message)) {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Le message est requis',
          backgroundColor: Colors.red,
        );
        return false;
      }

      Helpers.showLoading('Ajout du commentaire...');

      final newComment = CommentModel(
        taskId: taskId,
        adminId: adminId,
        message: message,
      );

      final commentId = await _commentService.addComment(newComment);

      Helpers.hideLoading();

      if (commentId != null) {
        newComment.id = commentId;
        _comments.add(newComment); // Ajoute à la liste

        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Commentaire ajouté',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Erreur lors de l\'ajout',
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

  // Charge les commentaires d'une tâche
  Future<void> loadCommentsForTask(int taskId) async {
    try {
      final taskComments = await _commentService.getCommentsByTaskId(taskId);
      _comments.assignAll(taskComments);
    } catch (e) {
      print('Erreur lors du chargement des commentaires: $e');
    }
  }

  // Supprime un commentaire
  Future<bool> deleteComment(int commentId) async {
    try {
      final confirm = await Helpers.showConfirmDialog(
        title: 'Confirmer la suppression',
        message: 'Voulez-vous vraiment supprimer ce commentaire?',
      );

      if (confirm != true) return false;

      Helpers.showLoading('Suppression en cours...');

      final success = await _commentService.deleteComment(commentId);

      Helpers.hideLoading();

      if (success) {
        _comments.removeWhere((comment) => comment.id == commentId);

        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Commentaire supprimé',
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

  // Met à jour un commentaire
  Future<bool> updateComment(CommentModel comment) async {
    try {
      if (Helpers.isNullOrEmpty(comment.message)) {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Le message est requis',
          backgroundColor: Colors.red,
        );
        return false;
      }

      Helpers.showLoading('Mise à jour en cours...');

      final success = await _commentService.updateComment(comment);

      Helpers.hideLoading();

      if (success) {
        final index = _comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          _comments[index] = comment;
        }

        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Commentaire mis à jour',
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

  // Récupère un utilisateur par ID
  UserModel? getUserById(int userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Compte le nombre d'utilisateurs
  int get usersCount => _users.length;

  // Compte le nombre de commentaires pour une tâche
  int getCommentsCountForTask(int taskId) {
    return _comments.where((comment) => comment.taskId == taskId).length;
  }

  // Vide la liste des utilisateurs
  void clearUsers() {
    _users.clear();
  }

  // Vide la liste des commentaires
  void clearComments() {
    _comments.clear();
  }
}
