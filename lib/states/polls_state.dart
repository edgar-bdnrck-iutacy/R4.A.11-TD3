import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../configs.dart';
import '../models/poll.dart';
import '../result.dart';

// Etat global lié aux événements.
// Cette classe centralise les appels HTTP et les données partagées
// entre la liste, le détail, la création, la modification et le vote.
class PollsState extends ChangeNotifier {
  String? _token;
  List<Poll> _polls = [];
  Poll? _currentPoll;
  bool _isLoading = false;

  List<Poll> get polls => _polls;
  Poll? get currentPoll => _currentPoll;
  bool get isLoading => _isLoading;

  // Le token est injecté par main.dart via ChangeNotifierProxyProvider.
  // PollsState n'a donc pas à connaître directement AuthState.
  void setAuthToken(String? token) {
    _token = token;
  }

  // Récupère la liste des événements depuis l'API.
  // Le booléen _isLoading permet aux pages d'afficher un loader,
  // puis notifyListeners() déclenche la mise à jour de l'interface.
  Future<Result<List<Poll>, String>> fetchPolls() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${Configs.baseUrl}/polls'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          if (_token != null) HttpHeaders.authorizationHeader: 'Bearer $_token',
        },
      );

      debugPrint('GET /polls -> ${response.statusCode}');
      debugPrint('GET /polls body -> ${response.body}');

      if (response.statusCode == HttpStatus.ok) {
        final decoded = json.decode(response.body);

        List<dynamic>? rawList;

        // Le code accepte plusieurs formats de réponse possibles de l'API.
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['items'] is List) {
            rawList = decoded['items'] as List<dynamic>;
          } else if (decoded['polls'] is List) {
            rawList = decoded['polls'] as List<dynamic>;
          } else if (decoded['data'] is List) {
            rawList = decoded['data'] as List<dynamic>;
          }
        }

        if (rawList == null) {
          _isLoading = false;
          notifyListeners();
          return Result.failure(
            'Format de réponse inattendu pour la liste des événements.',
          );
        }

        // Chaque élément JSON est converti en objet Poll grâce à fromJson.
        _polls = rawList
            .map((item) => Poll.fromJson(item as Map<String, dynamic>))
            .toList();

        _isLoading = false;
        notifyListeners();
        return Result.success(_polls);
      }

      _isLoading = false;
      notifyListeners();
      return Result.failure(
        'Impossible de charger les événements (HTTP ${response.statusCode}).',
      );
    } catch (e) {
      debugPrint('fetchPolls exception -> $e');
      _isLoading = false;
      notifyListeners();
      return Result.failure(
        'Une erreur est survenue lors du chargement : $e',
      );
    }
  }

  // Charge le détail complet d'un événement puis le stocke dans currentPoll.
  Future<Result<Poll, String>> fetchPollById(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${Configs.baseUrl}/polls/$id'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          if (_token != null) HttpHeaders.authorizationHeader: 'Bearer $_token',
        },
      );

      debugPrint('GET /polls/$id -> ${response.statusCode}');
      debugPrint('GET /polls/$id body -> ${response.body}');

      if (response.statusCode == HttpStatus.ok) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _currentPoll = Poll.fromJson(data);
        _isLoading = false;
        notifyListeners();
        return Result.success(_currentPoll!);
      }

      _isLoading = false;
      notifyListeners();
      return Result.failure('Impossible de charger cet événement.');
    } catch (e) {
      debugPrint('fetchPollById exception -> $e');
      _isLoading = false;
      notifyListeners();
      return Result.failure('Une erreur est survenue lors du chargement.');
    }
  }

  // Envoie un POST pour créer un événement, puis recharge la liste.
  Future<Result<Unit, String>> createPoll({
    required String name,
    required String description,
    required DateTime eventDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Configs.baseUrl}/polls'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          if (_token != null) HttpHeaders.authorizationHeader: 'Bearer $_token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'eventDate': eventDate.toIso8601String(),
        }),
      );

      debugPrint('POST /polls -> ${response.statusCode}');
      debugPrint('POST /polls body -> ${response.body}');

      if (response.statusCode == HttpStatus.created) {
        await fetchPolls();
        return Result.success(unit);
      }

      if (response.statusCode == HttpStatus.forbidden ||
          response.statusCode == HttpStatus.unauthorized) {
        return Result.failure('Vous n’êtes pas autorisé à créer un événement.');
      }

      return Result.failure('Impossible de créer l’événement.');
    } catch (e) {
      debugPrint('createPoll exception -> $e');
      return Result.failure('Une erreur est survenue lors de la création.');
    }
  }

  // Envoie un PUT pour modifier un événement, puis resynchronise la liste et le détail.
  Future<Result<Unit, String>> updatePoll({
    required int id,
    required String name,
    required String description,
    required DateTime eventDate,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${Configs.baseUrl}/polls/$id'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          if (_token != null) HttpHeaders.authorizationHeader: 'Bearer $_token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'eventDate': eventDate.toIso8601String(),
        }),
      );

      debugPrint('PUT /polls/$id -> ${response.statusCode}');
      debugPrint('PUT /polls/$id body -> ${response.body}');

      if (response.statusCode == HttpStatus.ok) {
        await fetchPolls();
        await fetchPollById(id);
        return Result.success(unit);
      }

      if (response.statusCode == HttpStatus.forbidden ||
          response.statusCode == HttpStatus.unauthorized) {
        return Result.failure('Vous n’êtes pas autorisé à modifier cet événement.');
      }

      return Result.failure('Impossible de modifier l’événement.');
    } catch (e) {
      debugPrint('updatePoll exception -> $e');
      return Result.failure('Une erreur est survenue lors de la modification.');
    }
  }

  // Enregistre le vote de l'utilisateur, puis recharge les données côté serveur
  // pour garder les compteurs et la liste cohérents.
  Future<Result<Unit, String>> votePoll(int pollId, bool status) async {
    try {
      final response = await http.post(
        Uri.parse('${Configs.baseUrl}/polls/$pollId/votes'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          if (_token != null) HttpHeaders.authorizationHeader: 'Bearer $_token',
        },
        body: json.encode({
          'status': status,
        }),
      );

      debugPrint('POST /polls/$pollId/votes -> ${response.statusCode}');
      debugPrint('POST /polls/$pollId/votes body -> ${response.body}');

      if (response.statusCode == HttpStatus.created) {
        final refreshedPollResult = await fetchPollById(pollId);
        await fetchPolls();

        if (!refreshedPollResult.isSuccess) {
          return Result.failure(refreshedPollResult.failure!);
        }

        notifyListeners();
        return Result.success(unit);
      }

      if (response.statusCode == HttpStatus.unauthorized) {
        return Result.failure('Vous devez être connecté pour voter.');
      }

      return Result.failure('Impossible d’enregistrer votre vote.');
    } catch (e) {
      debugPrint('votePoll exception -> $e');
      return Result.failure('Une erreur est survenue lors du vote.');
    }
  }
}
