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
