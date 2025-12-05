import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_notes_manager/models/user_model.dart';
import 'package:task_notes_manager/services/auth_service.dart';
import 'package:task_notes_manager/utils/helpers.dart';
import 'package:task_notes_manager/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService(); // Service d'authentification
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(
    null,
  ); // Utilisateur courant observable

  UserModel? get currentUser => _currentUser.value; // Getter pour l'utilisateur
  bool get isLoggedIn => _currentUser.value != null; // Vérifie si connecté
  bool get isAdmin => _currentUser.value?.role == 'admin'; // Vérifie si admin
  bool get isUser =>
      _currentUser.value?.role == 'user'; // Vérifie si user standard

  // Méthode de connexion
  Future<bool> login(String email, String password) async {
    try {
      Helpers.showLoading('Connexion en cours...'); // Affiche un loader

      final user = await _authService.login(
        email,
        password,
      ); // Appelle le service

      if (user != null) {
        _currentUser.value = user; // Stocke l'utilisateur connecté
        Helpers.hideLoading(); // Cache le loader

        // Redirection selon le rôle
        if (user.role == 'admin') {
          Get.offAllNamed(
            AppRoutes.adminDashboard,
          ); // Redirige vers dashboard admin
        } else {
          Get.offAllNamed(
            AppRoutes.userDashboard,
          ); // Redirige vers dashboard user
        }

        Helpers.showSnackbar(
          // Message de succès
          title: 'Succès',
          message: 'Connexion réussie!',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        Helpers.hideLoading();
        Helpers.showSnackbar(
          // Message d'erreur
          title: 'Erreur',
          message: 'Email ou mot de passe incorrect',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Une erreur est survenue: $e',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  // Méthode de déconnexion
  void logout() {
    _authService.logout(); // Appelle le service de déconnexion
    _currentUser.value = null; // Réinitialise l'utilisateur
    Get.offAllNamed(AppRoutes.login); // Redirige vers la page de connexion

    Helpers.showSnackbar(
      title: 'Déconnexion',
      message: 'Vous avez été déconnecté',
      backgroundColor: Colors.blue,
    );
  }

  // Création d'un nouvel utilisateur (admin seulement)
  Future<bool> createUser(String name, String email, String password) async {
    try {
      // Validation des données
      if (Helpers.isNullOrEmpty(name) ||
          Helpers.isNullOrEmpty(email) ||
          Helpers.isNullOrEmpty(password)) {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Tous les champs sont obligatoires',
          backgroundColor: Colors.red,
        );
        return false;
      }

      if (!Helpers.isValidEmail(email)) {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Format d\'email invalide',
          backgroundColor: Colors.red,
        );
        return false;
      }

      if (password.length < 3) {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Le mot de passe doit contenir au moins 3 caractères',
          backgroundColor: Colors.red,
        );
        return false;
      }

      Helpers.showLoading('Création de l\'utilisateur...');

      // Vérifie si l'email existe déjà
      final emailExists = await _authService.emailExists(email);
      if (emailExists) {
        Helpers.hideLoading();
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Cet email est déjà utilisé',
          backgroundColor: Colors.red,
        );
        return false;
      }

      // Crée le nouvel utilisateur
      final newUser = UserModel(
        name: name,
        email: email,
        password: password,
        role: 'user', // Toujours user pour les nouvelles créations
      );

      final userId = await _authService.register(newUser);

      Helpers.hideLoading();

      if (userId != null) {
        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Utilisateur créé avec succès',
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

  // Récupère tous les utilisateurs (admin seulement)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final users = await _authService.getAllUsers();
      return users
          .where((user) => user.id != currentUser?.id)
          .toList(); // Exclut l'admin connecté
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  // Supprime un utilisateur (admin seulement)
  Future<bool> deleteUser(int userId) async {
    try {
      final success = await _authService.deleteUser(userId);
      if (success) {
        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Utilisateur supprimé',
          backgroundColor: Colors.green,
        );
      } else {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Impossible de supprimer le dernier admin',
          backgroundColor: Colors.red,
        );
      }
      return success;
    } catch (e) {
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur lors de la suppression: $e',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  // Met à jour un utilisateur
  Future<bool> updateUser(UserModel user) async {
    try {
      Helpers.showLoading('Mise à jour en cours...');

      final success = await _authService.updateUser(user);

      Helpers.hideLoading();

      if (success) {
        // Si c'est l'utilisateur courant, on met à jour l'état
        if (user.id == currentUser?.id) {
          _currentUser.value = user;
        }

        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Utilisateur mis à jour',
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
}
