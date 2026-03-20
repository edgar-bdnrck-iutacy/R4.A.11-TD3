import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/poll.dart';
import '../states/auth_state.dart';
import '../states/polls_state.dart';

class PollsPage extends StatefulWidget {
  const PollsPage({super.key});

  @override
  State<PollsPage> createState() => _PollsPageState();
}

class _PollsPageState extends State<PollsPage> {
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await context.read<PollsState>().fetchPolls();
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

  @override
  Widget build(BuildContext context) {
    final pollsState = context.watch<PollsState>();
    final authState = context.watch<AuthState>();
    final polls = pollsState.polls;
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('dd/MM/yyyy', 'fr');

    if (pollsState.isLoading && polls.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null && polls.isEmpty) {
      return Center(
        child: Text(
          error!,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    if (polls.isEmpty) {
      return const Center(
        child: Text('Aucun événement disponible.'),
      );
    }

    return Column(
      children: [
        if (authState.currentUser?.isAdmin == true)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/polls/create');
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer un événement'),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final result = await context.read<PollsState>().fetchPolls();
              if (!mounted) {
                return;
              }
              if (!result.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.failure!),
                  ),
                );
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: polls.length,
              itemBuilder: (context, index) {
                final Poll poll = polls[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(poll.title),
                    subtitle: Text(dateFormatter.format(poll.date)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/polls/detail',
                        arguments: poll,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}