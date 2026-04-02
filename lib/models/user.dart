// Modèle représentant l'utilisateur connecté.
class User {
  User({
    required this.id,
    required this.username,
    this.role,
  });

  final int id;
  final String username;
  final String? role;

  // Getter pratique utilisé dans l'UI pour afficher les actions réservées à l'admin.
  bool get isAdmin => role == 'admin';

  // Convertit le JSON reçu de l'API en objet Dart typé.
  // C'est le principe classique des modèles fromJson.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String?,
    );
  }
}
