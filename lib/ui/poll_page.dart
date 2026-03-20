import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/poll.dart';
import '../states/auth_state.dart';
import '../states/polls_state.dart';

class PollPage extends StatefulWidget {
  const PollPage({super.key});

  @override
  State<PollPage> createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  String? error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final poll = ModalRoute.of(context)?.settings.arguments as Poll?;
    if (poll != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final result = await context.read<PollsState>().fetchPollById(poll.id);
        if (!mounted) {
          return;
        }
        if (!result.isSuccess) {
          setState(() {
            error = result.failure;
          });
        }
      });
    }
  }

  Future<void> _vote(String vote) async {
    final currentPoll = context.read<PollsState>().currentPoll;
    if (currentPoll == null) {
      return;
    }

    final result = await context.read<PollsState>().votePoll(currentPoll.id, vote);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? 'Votre vote a bien été enregistré.'
              : result.failure!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pollsState = context.watch<PollsState>();
    final authState = context.watch<AuthState>();
    final poll = pollsState.currentPoll;
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('dd/MM/yyyy', 'fr');

    if (pollsState.isLoading && poll == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null && poll == null) {
      return Center(
        child: Text(
          error!,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    if (poll == null) {
      return const Center(
        child: Text('Événement introuvable.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll.title,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Date : ${dateFormatter.format(poll.date)}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            poll.description,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text(
            'Votes',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('Oui : ${poll.nbYes ?? 0}'),
          Text('Non : ${poll.nbNo ?? 0}'),
          Text('Peut-être : ${poll.nbMaybe ?? 0}'),
          const SizedBox(height: 8),
          if (poll.userVote != null)
            Text('Votre vote : ${poll.userVote!}'),
          const SizedBox(height: 24),
          if (authState.isLoggedIn) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => _vote('yes'),
                  child: const Text('Je participe'),
                ),
                ElevatedButton(
                  onPressed: () => _vote('maybe'),
                  child: const Text('Peut-être'),
                ),
                ElevatedButton(
                  onPressed: () => _vote('no'),
                  child: const Text('Je ne participe pas'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (authState.currentUser?.isAdmin == true)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/polls/edit',
                  arguments: poll,
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Modifier l’événement'),
            ),
        ],
      ),
    );
  }
}