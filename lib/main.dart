import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'states/auth_state.dart';
import 'states/polls_state.dart';
import 'ui/app_scaffold.dart';
import 'ui/login_page.dart';
import 'ui/signup_page.dart';
import 'ui/poll_edit_page.dart';
import 'ui/poll_page.dart';
import 'ui/polls_page.dart';

// Point d'entrée de l'application.
// On déclare ici les Provider globaux afin que les pages puissent accéder
// à l'état partagé (authentification, liste des événements, etc.).
void main() {
  runApp(
    // MultiProvider permet d'exposer plusieurs objets d'état à tout l'arbre.
    MultiProvider(
      providers: [
        // AuthState contient l'utilisateur connecté et le token.
        ChangeNotifierProvider(
          create: (_) => AuthState(),
        ),
        // PollsState dépend du token d'authentification.
        // ChangeNotifierProxyProvider sert à lui injecter la valeur d'AuthState
        // dès qu'elle change, sans dupliquer la logique dans les pages.
        ChangeNotifierProxyProvider<AuthState, PollsState>(
          create: (_) => PollsState(),
          update: (_, authState, pollsState) =>
              pollsState!..setAuthToken(authState.token),
        ),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // App est un StatelessWidget : il ne stocke pas d'état local,
    // il décrit simplement la structure générale de l'application.
    return MaterialApp(
      title: 'Event Poll',
      debugShowCheckedModeBanner: false,
      // Ces delegates activent la localisation française pour les widgets Material.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
      ],
      // La navigation est centralisée ici avec des routes nommées.
      // Les pages naviguent ensuite via Navigator.pushNamed(...).
      initialRoute: '/polls',
      routes: {
        '/polls': (_) => const AppScaffold(
              title: 'Événements',
              body: PollsPage(),
            ),
        '/polls/detail': (_) => const AppScaffold(
              title: 'Détail de l’événement',
              body: PollPage(),
            ),
        '/polls/create': (_) => const AppScaffold(
              title: 'Créer un événement',
              body: PollEditPage(),
            ),
        '/polls/edit': (_) => const AppScaffold(
              title: 'Modifier un événement',
              body: PollEditPage(),
            ),
        '/login': (_) => const AppScaffold(
              title: 'Connexion',
              body: LoginPage(),
            ),
        '/signup': (_) => const AppScaffold(
              title: 'Inscription',
              body: SignupPage(),
            ),
      },
    );
  }
}
