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

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthState(),
        ),
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
    return MaterialApp(
      title: 'Event Poll',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
      ],
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