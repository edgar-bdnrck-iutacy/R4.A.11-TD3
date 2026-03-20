import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../states/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String username = '';
  String password = '';
  String? error;

  final _formKey = GlobalKey<FormState>();

  String? _validateRequired(String? value) {
    return value == null || value.isEmpty
        ? 'Ce champ est obligatoire.'
        : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = await context.read<AuthState>().login(username, password);

    if (user != null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/polls', (_) => false);
      }
    } else {
      setState(() {
        error = 'Une erreur est survenue.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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