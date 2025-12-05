import 'package:sqflite/sqflite.dart';
import 'package:task_notes_manager/models/user_model.dart';
import 'package:task_notes_manager/services/db_service.dart';
import 'package:task_notes_manager/utils/helpers.dart';

class AuthService {
  final DatabaseService _dbService = DatabaseService(); // Pas de .instance

  Future<UserModel?> login(String email, String password) async {
    try {
      final db = await _dbService.database;

      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (result.isEmpty) {
        print('Utilisateur non trouvé: $email');
        return null;
      }

      final user = UserModel.fromMap(result.first);
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

  Future<int?> register(UserModel user) async {
    try {
      final db = await _dbService.database;

      final hashedUser = user.copyWith(
        password: Helpers.hashPassword(user.password),
      );

      final id = await db.insert(
        'users',
        hashedUser.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      print('Utilisateur créé avec ID: $id');
      return id;
    } catch (e) {
      print('Erreur lors de l\'inscription: $e');
      return null;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final db = await _dbService.database;
      final result = await db.query('users');
      return result.map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      final db = await _dbService.database;

      // Compte combien d'utilisateurs admin il reste
      final admins = await db.query(
        'users',
        where: 'role = ?',
        whereArgs: ['admin'],
      );

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

  Future<bool> updateUser(UserModel user) async {
    try {
      final db = await _dbService.database;

      final Map<String, dynamic> userMap;
      if (user.password.length < 60) {
        userMap = user
            .copyWith(password: Helpers.hashPassword(user.password))
            .toMap();
      } else {
        userMap = user.toMap();
      }

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

  void logout() {
    print('Utilisateur déconnecté');
  }
}
