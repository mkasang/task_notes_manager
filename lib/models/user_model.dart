import 'package:get/get.dart';

/// Modèle représentant un utilisateur dans l'application
/// Cette classe définit la structure des données d'un utilisateur
class UserModel {
  /// Constructeur pour créer un nouvel utilisateur
  UserModel({
    this.id, // Identifiant unique (null si nouvel utilisateur)
    required this.name,
    required this.email,
    required this.password, // Stocké hashé dans la base de données
    required this.role, // 'admin' ou 'user'
    this.createdAt,
  });

  int? id; // Clé primaire auto-incrémentée
  String name; // Nom complet de l'utilisateur
  String email; // Email unique pour la connexion
  String password; // Mot de passe hashé
  String role; // Rôle : 'admin' ou 'user'
  DateTime? createdAt; // Date de création du compte

  /// Factory constructor pour créer un UserModel à partir d'une Map
  /// Utile quand on récupère les données de la base SQLite
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      role: map['role'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  /// Convertit le UserModel en Map pour l'insérer dans SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id, // On inclut l'id seulement s'il existe
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'created_at':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  /// Copie l'utilisateur avec des valeurs modifiées
  /// Utile pour les mises à jour partielles
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Controller GetX pour gérer l'état de l'utilisateur courant
/// Rx signifie "Reactive" - les changements sont observables
class UserController extends GetxController {
  /// Utilisateur courant, null si personne n'est connecté
  /// Rx<UserModel?> signifie que c'est une valeur observable qui peut être null
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);

  /// Getter pour accéder à l'utilisateur courant
  UserModel? get currentUser => _currentUser.value;

  /// Getter pour vérifier si un utilisateur est connecté
  bool get isLoggedIn => _currentUser.value != null;

  /// Getter pour vérifier si l'utilisateur connecté est admin
  bool get isAdmin => _currentUser.value?.role == 'admin';

  /// Getter pour vérifier si l'utilisateur connecté est un user standard
  bool get isUser => _currentUser.value?.role == 'user';

  /// Méthode pour connecter un utilisateur
  void login(UserModel user) {
    _currentUser.value = user;
    update(); // Notifie tous les widgets qui observent ce controller
  }

  /// Méthode pour déconnecter l'utilisateur
  void logout() {
    _currentUser.value = null;
    update();
  }

  /// Méthode pour mettre à jour les informations de l'utilisateur
  void updateUser(UserModel user) {
    _currentUser.value = user;
    update();
  }
}
