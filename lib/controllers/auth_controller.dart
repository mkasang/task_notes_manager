import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_notes_manager/models/user_model.dart';
import 'package:task_notes_manager/services/auth_service.dart';
import 'package:task_notes_manager/utils/helpers.dart';
import 'package:task_notes_manager/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);

  UserModel? get currentUser => _currentUser.value;
  bool get isLoggedIn => _currentUser.value != null;
  bool get isAdmin => _currentUser.value?.role == 'admin';
  bool get isUser => _currentUser.value?.role == 'user';

  // Méthode statique pour obtenir le controller
  static AuthController get to => Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    print('✅ AuthController initialisé');
  }

  Future<bool> login(String email, String password) async {
    try {
      Helpers.showLoading('Connexion en cours...');

      final user = await _authService.login(email, password);
      Helpers.hideLoading();

      if (user != null) {
        _currentUser.value = user;

        // Utiliser un délai pour éviter les conflits de navigation
        await Future.delayed(const Duration(milliseconds: 100));

        // Redirection selon le rôle
        if (user.role == 'admin') {
          Get.offAllNamed(AppRoutes.adminDashboard);
        } else {
          Get.offAllNamed(AppRoutes.userDashboard);
        }

        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Connexion réussie!',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        Helpers.showSnackbar(
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

  void logout() {
    _authService.logout();
    _currentUser.value = null;

    // Utiliser un délai pour éviter les conflits
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.offAllNamed(AppRoutes.login);
    });

    Helpers.showSnackbar(
      title: 'Déconnexion',
      message: 'Vous avez été déconnecté',
      backgroundColor: Colors.blue,
    );
  }

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
        role: 'user',
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

  Future<List<UserModel>> getAllUsers() async {
    try {
      final users = await _authService.getAllUsers();
      // Exclure l'utilisateur courant de la liste
      final currentUserId = currentUser?.id;
      if (currentUserId != null) {
        return users.where((user) => user.id != currentUserId).toList();
      }
      return users;
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      final confirm = await Helpers.showConfirmDialog(
        title: 'Supprimer l\'utilisateur',
        message: 'Êtes-vous sûr de vouloir supprimer cet utilisateur?',
        confirmText: 'Supprimer',
      );

      if (confirm != true) return false;

      Helpers.showLoading('Suppression en cours...');

      final success = await _authService.deleteUser(userId);
      Helpers.hideLoading();

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
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur lors de la suppression: $e',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

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

  Future<UserModel?> getUserById(int userId) async {
    try {
      return await _authService.getUserById(userId);
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }
}
