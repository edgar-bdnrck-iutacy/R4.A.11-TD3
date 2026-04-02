import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/poll.dart';
import '../states/auth_state.dart';
import '../states/polls_state.dart';

// Page de détail d'un événement.
// Elle affiche aussi l'état du vote et les actions possibles.
class PollPage extends StatefulWidget {
  const PollPage({super.key});

  @override
  State<PollPage> createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  String? error;
  bool _hasLoaded = false;
  bool _isSubmittingVote = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // didChangeDependencies est un bon endroit pour lire ModalRoute.of(context),
    // car les dépendances liées au BuildContext sont disponibles.
    if (_hasLoaded) {
      return;
    }
    _hasLoaded = true;

    final poll = ModalRoute.of(context)?.settings.arguments as Poll?;
    if (poll != null) {
      // On recharge le détail depuis l'API pour récupérer les votes à jour.
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

  // Envoie le vote à l'API tout en évitant les doubles clics.
  Future<void> _vote(bool status) async {
    if (_isSubmittingVote) {
      return;
    }

    final currentPoll = context.read<PollsState>().currentPoll;
    if (currentPoll == null) {
      return;
    }

    setState(() {
      _isSubmittingVote = true;
    });

    // Le Future est attendu avant de réactiver les boutons.
    final result =
        await context.read<PollsState>().votePoll(currentPoll.id, status);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmittingVote = false;
    });

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
            poll.name,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Date : ${dateFormatter.format(poll.eventDate)}',
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
          Text('Je participe : ${poll.yesCount}'),
          Text('Je ne participe pas : ${poll.noCount}'),
          const SizedBox(height: 8),
          if (authState.currentUser != null)
            Builder(
              builder: (context) {
                // Recherche le vote déjà enregistré pour l'utilisateur connecté.
                final currentUserVote = poll.votes
                    .where((v) => v.user.id == authState.currentUser!.id)
                    .cast<PollVote?>()
                    .firstWhere(
                      (v) => v != null,
                      orElse: () => null,
                    );

                if (currentUserVote == null) {
                  return const SizedBox.shrink();
                }

                return Text(
                  'Votre vote : ${currentUserVote.status ? 'Je participe' : 'Je ne participe pas'}',
                );
              },
            ),
          const SizedBox(height: 24),
          if (authState.isLoggedIn) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: _isSubmittingVote ? null : () => _vote(true),
                  child: const Text('Je participe'),
                ),
                ElevatedButton(
                  onPressed: _isSubmittingVote ? null : () => _vote(false),
                  child: const Text('Je ne participe pas'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (authState.currentUser?.isAdmin == true)
            ElevatedButton.icon(
              onPressed: () {
                // Navigation vers la page d'édition avec l'événement courant.
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
