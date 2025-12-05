import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:task_notes_manager/models/user_model.dart';
import 'package:task_notes_manager/utils/helpers.dart';

/// Service de base de données - Responsable unique de la gestion de SQLite
/// Ce service suit le pattern Singleton pour avoir une seule instance
class DatabaseService {
  static DatabaseService? _instance; // Instance unique du service
  static Database? _database; // Connexion à la base de données

  /// Constructeur privé pour empêcher l'instanciation directe
  DatabaseService._privateConstructor();

  /// Getter pour obtenir l'instance unique (Singleton pattern)
  static DatabaseService get instance {
    _instance ??= DatabaseService._privateConstructor();
    return _instance!;
  }

  /// Getter pour obtenir la connexion à la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialise la base de données
  /// Crée les tables si elles n'existent pas et crée l'admin par défaut
  Future<Database> _initDatabase() async {
    try {
      // Chemin de la base de données sur le téléphone
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'task_notes_manager.db');

      // Ouverture de la base de données
      return await openDatabase(
        path,
        version: 1, // Version du schéma de la base
        onCreate: _createDatabase, // Crée les tables si première fois
        onUpgrade: _upgradeDatabase, // Pour les futures mises à jour
      );
    } catch (e) {
      print('Erreur lors de l\'initialisation de la base: $e');
      rethrow; // Relance l'erreur pour la gérer ailleurs
    }
  }

  /// Crée toutes les tables lors de la première installation
  Future<void> _createDatabase(Database db, int version) async {
    // Transactions garantissent que toutes les opérations réussissent ou échouent ensemble
    await db.transaction((txn) async {
      // Table des utilisateurs
      await txn.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          role TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      // Table des tâches
      await txn.execute('''
        CREATE TABLE tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // Table des commentaires
      await txn.execute('''
        CREATE TABLE comments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER NOT NULL,
          admin_id INTEGER NOT NULL,
          message TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
          FOREIGN KEY (admin_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // Table des notes
      await txn.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // Création de l'admin par défaut
      await _createDefaultAdmin(db);
    });

    print('Base de données créée avec succès!');
  }

  /// Crée l'utilisateur admin par défaut
  Future<void> _createDefaultAdmin(Database db) async {
    final admin = UserModel(
      name: 'Administrateur',
      email: 'admin@app.com',
      password: Helpers.hashPassword('admin'), // Mot de passe hashé
      role: 'admin',
      createdAt: DateTime.now(),
    );

    await db.insert(
      'users',
      admin.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.ignore, // Ignore si admin existe déjà
    );

    print('Admin par défaut créé: admin@app.com / admin');
  }

  /// Méthode pour les mises à jour futures du schéma
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Ici on peut ajouter des ALTER TABLE pour les futures versions
    if (oldVersion < 2) {
      // Exemple: ajouter une colonne à une table existante
      // await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
    }
  }

  /// Ferme la connexion à la base de données
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _instance = null;
  }

  /// Supprime toute la base de données (pour les tests)
  Future<void> deleteAppDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'task_notes_manager.db');
    await deleteDatabase(path);
  }
}
