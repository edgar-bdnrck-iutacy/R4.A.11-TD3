import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/poll.dart';
import '../states/polls_state.dart';

class PollEditPage extends StatefulWidget {
  const PollEditPage({super.key});

  @override
  State<PollEditPage> createState() => _PollEditPageState();
}

class _PollEditPageState extends State<PollEditPage> {
  final _formKey = GlobalKey<FormState>();

  String title = '';
  String description = '';
  DateTime? date;
  String? error;
  bool initialized = false;

  String? _validateRequired(String? value) {
    return value == null || value.isEmpty ? 'Ce champ est obligatoire.' : null;
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('fr'),
    );

    if (pickedDate != null) {
      setState(() {
        date = pickedDate;
      });
    }
  }

  Future<void> _submit(Poll? poll) async {
    if (!_formKey.currentState!.validate() || date == null) {
      setState(() {
        error = date == null ? 'La date est obligatoire.' : null;
      });
      return;
    }

    final pollsState = context.read<PollsState>();

    final result = poll == null
        ? await pollsState.createPoll(
            title: title,
            description: description,
            date: date!,
          )
        : await pollsState.updatePoll(
            id: poll.id,
            title: title,
            description: description,
            date: date!,
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
    final poll = ModalRoute.of(context)?.settings.arguments as Poll?;
    final theme = Theme.of(context);

    if (!initialized) {
      title = poll?.title ?? '';
      description = poll?.description ?? '';
      date = poll?.date;
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
                  initialValue: title,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                  ),
                  onChanged: (value) => title = value,
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
                        date == null
                            ? 'Aucune date sélectionnée'
                            : 'Date : ${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}',
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