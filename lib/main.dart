import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'states/auth_state.dart';
import 'ui/app_scaffold.dart';
import 'ui/login_page.dart';
import 'ui/signup_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthState(),
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
              body: Center(child: Text('Liste des événements à venir')),
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