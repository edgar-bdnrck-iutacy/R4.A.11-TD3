import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/poll.dart';
import '../states/polls_state.dart';

// Page de formulaire utilisée à la fois pour créer et modifier un événement.
class PollEditPage extends StatefulWidget {
  const PollEditPage({super.key});

  @override
  State<PollEditPage> createState() => _PollEditPageState();
}

class _PollEditPageState extends State<PollEditPage> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String description = '';
  DateTime? eventDate;
  String? error;
  bool initialized = false;

  // Validation minimale des champs obligatoires du formulaire.
  String? _validateRequired(String? value) {
    return value == null || value.isEmpty ? 'Ce champ est obligatoire.' : null;
  }

  // Ouvre le sélecteur de date natif de Flutter.
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: eventDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('fr'),
    );

    if (pickedDate != null) {
      // setState est nécessaire pour réafficher la date choisie dans l'interface.
      setState(() {
        eventDate = pickedDate;
      });
    }
  }

  // Selon qu'un Poll est fourni ou non, on appelle createPoll() ou updatePoll().
  Future<void> _submit(Poll? poll) async {
    if (!_formKey.currentState!.validate() || eventDate == null) {
      setState(() {
        error = eventDate == null ? 'La date est obligatoire.' : null;
      });
      return;
    }

    final pollsState = context.read<PollsState>();

    final result = poll == null
        ? await pollsState.createPoll(
            name: name,
            description: description,
            eventDate: eventDate!,
          )
        : await pollsState.updatePoll(
            id: poll.id,
            name: name,
            description: description,
            eventDate: eventDate!,
          );

    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      Navigator.pushNamedAndRemoveUntil(context, '/polls', (_) => false);
    } else {
      setState(() {
        error = result.failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Les arguments de navigation contiennent l'événement à modifier.
    final poll = ModalRoute.of(context)?.settings.arguments as Poll?;
    final theme = Theme.of(context);

    // On initialise les champs une seule fois depuis les arguments.
    // Sinon, chaque rebuild écraserait la saisie en cours de l'utilisateur.
    if (!initialized) {
      name = poll?.name ?? '';
      description = poll?.description ?? '';
      eventDate = poll?.eventDate;
      initialized = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                  ),
                  onChanged: (value) => name = value,
                  validator: _validateRequired,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: 4,
                  onChanged: (value) => description = value,
                  validator: _validateRequired,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        eventDate == null
                            ? 'Aucune date sélectionnée'
                            : "Date : ${eventDate!.day.toString().padLeft(2, '0')}/${eventDate!.month.toString().padLeft(2, '0')}/${eventDate!.year}",
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text('Choisir une date'),
                    ),
                  ],
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
                  onPressed: () => _submit(poll),
                  child: Text(
                    poll == null ? 'Créer l’événement' : 'Enregistrer',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
