import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../states/auth_state.dart';

// Page de connexion.
// StatefulWidget est utile ici car le formulaire et le message d'erreur
// évoluent au cours de la vie de la page.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String username = '';
  String password = '';
  String? error;

  // Cette clé permet de piloter la validation du formulaire depuis le code.
  final _formKey = GlobalKey<FormState>();

  // Validation simple des champs obligatoires.
  String? _validateRequired(String? value) {
    return value == null || value.isEmpty
        ? 'Ce champ est obligatoire.'
        : null;
  }

  // Appelée quand l'utilisateur envoie le formulaire.
  // La méthode est asynchrone car elle attend la réponse HTTP de login().
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // read permet d'appeler une méthode du Provider sans reconstruire la page
    // quand AuthState change.
    final result = await context.read<AuthState>().login(username, password);

    // Après un await, le widget peut avoir été retiré de l'arbre.
    // mounted évite de faire setState() ou Navigator sur un widget détruit.
    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      // Après connexion, on remplace l'historique pour revenir à l'écran principal.
      Navigator.pushNamedAndRemoveUntil(context, '/polls', (_) => false);
    } else {
      // setState redessine ce widget pour afficher l'erreur locale.
      setState(() {
        error = result.failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // build() peut être rappelé souvent : il doit seulement décrire l'UI
    // à partir de l'état courant, sans lancer de logique métier lourde.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Connexion',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Identifiant',
                  ),
                  onChanged: (value) => username = value,
                  validator: _validateRequired,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                  ),
                  obscureText: true,
                  onChanged: (value) => password = value,
                  validator: _validateRequired,
                ),
                const SizedBox(height: 16),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      error!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Connexion'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
