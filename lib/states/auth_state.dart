import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../configs.dart';
import '../models/user.dart';
import '../result.dart';

// Etat global d'authentification.
// ChangeNotifier permet de prévenir l'interface quand l'utilisateur connecté
// ou le token changent.
class AuthState extends ChangeNotifier {
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _currentUser != null && _token != null;

  // Tente une connexion en deux étapes :
  // 1) POST /auth/login pour obtenir un token
  // 2) GET /users/me pour récupérer les informations du compte connecté.
  // async/await rend cette logique asynchrone plus lisible.
  Future<Result<User, String>> login(String username, String password) async {
    String error;

    final loginResponse = await http.post(
      Uri.parse('${Configs.baseUrl}/auth/login'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (loginResponse.statusCode == HttpStatus.ok) {
      _token = json.decode(loginResponse.body)['token'] as String?;

      final userResponse = await http.get(
        Uri.parse('${Configs.baseUrl}/users/me'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $_token',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      );

      if (userResponse.statusCode == HttpStatus.ok) {
        // fromJson transforme la Map JSON renvoyée par l'API
        // en objet User exploitable dans le code Dart.
        _currentUser =
            User.fromJson(json.decode(userResponse.body) as Map<String, dynamic>);
        // notifyListeners() force les widgets qui utilisent context.watch<AuthState>()
        // à se reconstruire avec le nouvel état.
        notifyListeners();
        return Result.success(_currentUser!);
      }

      error = 'Une erreur est survenue.';
    } else {
      error = loginResponse.statusCode == HttpStatus.badRequest ||
              loginResponse.statusCode == HttpStatus.unauthorized
          ? 'Identifiant ou mot de passe incorrect.'
          : 'Une erreur est survenue.';
    }

    logout();
    return Result.failure(error);
  }

  // Inscription via l'API. Ici on ne connecte pas automatiquement l'utilisateur :
  // la page d'inscription redirige ensuite vers la page de connexion.
  Future<Result<Unit, String>> signup(String username, String password) async {
    final response = await http.post(
      Uri.parse('${Configs.baseUrl}/auth/signup'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.created) {
      return Result.success(unit);
    }

    if (response.statusCode == HttpStatus.badRequest) {
      return Result.failure('Impossible de créer le compte.');
    }

    return Result.failure('Une erreur est survenue lors de l’inscription.');
  }

  // Déconnexion locale : on vide le token et l'utilisateur, puis on notifie l'UI.
  void logout() {
    _token = null;
    _currentUser = null;
    notifyListeners();
  }
}
