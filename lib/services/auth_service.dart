import 'package:sqflite/sqflite.dart';
import 'package:task_notes_manager/models/user_model.dart';
import 'package:task_notes_manager/services/db_service.dart';
import 'package:task_notes_manager/utils/helpers.dart';

/// Service d'authentification - Gère la connexion, inscription et gestion des utilisateurs
class AuthService {
  final DatabaseService _dbService = DatabaseService.instance;

  /// Authentifie un utilisateur avec email et mot de passe
  /// Retourne l'utilisateur si les identifiants sont corrects, sinon null
  Future<UserModel?> login(String email, String password) async {
    try {
      final db = await _dbService.database;

      // Récupère l'utilisateur par email
      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      // Vérifie si l'utilisateur existe
      if (result.isEmpty) {
        print('Utilisateur non trouvé: $email');
        return null;
      }

      // Crée l'objet UserModel à partir du résultat
      final user = UserModel.fromMap(result.first);

      // Vérifie le mot de passe (comparaison des hash)
      final hashedPassword = Helpers.hashPassword(password);
      if (user.password != hashedPassword) {
        print('Mot de passe incorrect pour: $email');
        return null;
      }

      print('Connexion réussie pour: ${user.email} (${user.role})');
      return user;
    } catch (e) {
      print('Erreur lors de la connexion: $e');
      return null;
    }
  }

  /// Crée un nouvel utilisateur
  /// Retourne l'ID de l'utilisateur créé
  Future<int?> register(UserModel user) async {
    try {
      final db = await _dbService.database;

      // Hash le mot de passe avant stockage
      final hashedUser = user.copyWith(
        password: Helpers.hashPassword(user.password),
      );

      // Insère l'utilisateur dans la base
      final id = await db.insert(
        'users',
        hashedUser.toMap(),
        conflictAlgorithm:
            ConflictAlgorithm.fail, // Échoue si email existe déjà
      );

      print('Utilisateur créé avec ID: $id');
      return id;
    } catch (e) {
      print('Erreur lors de l\'inscription: $e');
      return null;
    }
  }

  /// Récupère tous les utilisateurs (pour l'admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final db = await _dbService.database;

      // Récupère tous les utilisateurs sauf l'admin connecté
      final result = await db.query('users');

      // Convertit chaque Map en UserModel
      return result.map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  /// Supprime un utilisateur par son ID
  Future<bool> deleteUser(int userId) async {
    try {
      final db = await _dbService.database;

      // Compte combien d'utilisateurs admin il reste
      final admins = await db.query(
        'users',
        where: 'role = ?',
        whereArgs: ['admin'],
      );

      // Empêche la suppression du dernier admin
      final userToDelete = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (userToDelete.isNotEmpty) {
        final user = UserModel.fromMap(userToDelete.first);
        if (user.role == 'admin' && admins.length <= 1) {
          print('Impossible de supprimer le dernier admin');
          return false;
        }
      }

      // Supprime l'utilisateur (CASCADE supprime aussi ses tâches et notes)
      final deleted = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      print('Utilisateur supprimé: $userId ($deleted ligne affectée)');
      return deleted > 0;
    } catch (e) {
      print('Erreur lors de la suppression de l\'utilisateur: $e');
      return false;
    }
  }

  /// Met à jour les informations d'un utilisateur
  Future<bool> updateUser(UserModel user) async {
    try {
      final db = await _dbService.database;

      // Si le mot de passe est modifié, on le hash
      final Map<String, dynamic> userMap;
      if (user.password.length < 60) {
        // Un hash SHA-256 fait 64 caractères
        userMap = user
            .copyWith(password: Helpers.hashPassword(user.password))
            .toMap();
      } else {
        userMap = user.toMap();
      }

      // Met à jour l'utilisateur
      final updated = await db.update(
        'users',
        userMap,
        where: 'id = ?',
        whereArgs: [user.id],
      );

      print('Utilisateur mis à jour: ${user.id} ($updated ligne affectée)');
      return updated > 0;
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'utilisateur: $e');
      return false;
    }
  }

  /// Vérifie si un email existe déjà
  Future<bool> emailExists(String email) async {
    try {
      final db = await _dbService.database;

      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification de l\'email: $e');
      return false;
    }
  }

  /// Récupère un utilisateur par son ID
  Future<UserModel?> getUserById(int userId) async {
    try {
      final db = await _dbService.database;

      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return UserModel.fromMap(result.first);
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  /// Déconnecte l'utilisateur (vide la session)
  void logout() {
    print('Utilisateur déconnecté');
  }
}
