import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/album_catalog.dart';
import '../models/match_candidate.dart';
import '../services/matching_repository.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  late final MatchingRepository _matchingRepository;
  late Future<List<MatchCandidate>> _matchesFuture;

  final _cardById = {for (final card in allCardDefinitions) card.id: card};

  @override
  void initState() {
    super.initState();
    _matchingRepository = MatchingRepository(FirebaseFirestore.instance);
    _matchesFuture = _loadMatches();
  }

  Future<List<MatchCandidate>> _loadMatches() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Future.error('No hay usuario autenticado.');
    }

    return _matchingRepository.findMatches(uid: user.uid);
  }

  Future<void> _refresh() async {
    setState(() {
      _matchesFuture = _loadMatches();
    });

    await _matchesFuture;
  }

  String _formatCardId(String cardId) {
    final card = _cardById[cardId];

    if (card == null) {
      return cardId;
    }

    return '${card.countryName} #${card.number}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matching')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: FutureBuilder<List<MatchCandidate>>(
            future: _matchesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _ScrollableMessage(
                  icon: Icons.info_outline,
                  title: 'No se pudo calcular matching',
                  message: snapshot.error.toString().replaceFirst(
                    'Exception: ',
                    '',
                  ),
                  onRefresh: _refresh,
                );
              }

              final matches = snapshot.data ?? <MatchCandidate>[];

              if (matches.isEmpty) {
                return _ScrollableMessage(
                  icon: Icons.people_outline,
                  title: 'Todavía no hay matches',
                  message:
                      'Necesitas otros usuarios visibles en tu misma comuna con faltantes o repetidas compatibles.',
                  onRefresh: _refresh,
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const _MatchingInfoCard(),
                    const SizedBox(height: 12),
                    for (final candidate in matches)
                      _MatchCandidateCard(
                        candidate: candidate,
                        formatCardId: _formatCardId,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MatchingInfoCard extends StatelessWidget {
  const _MatchingInfoCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Mostrando usuarios visibles de tu misma comuna. '
          'El contacto real todavía no se muestra; eso se desbloquea en el Día 6.',
        ),
      ),
    );
  }
}

class _MatchCandidateCard extends StatelessWidget {
  const _MatchCandidateCard({
    required this.candidate,
    required this.formatCardId,
  });

  final MatchCandidate candidate;
  final String Function(String cardId) formatCardId;

  @override
  Widget build(BuildContext context) {
    final matchType = candidate.hasTwoWayMatch
        ? 'Intercambio posible'
        : 'Coincidencia parcial';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(candidate.displayName.characters.first.toUpperCase()),
        ),
        title: Text(candidate.displayName),
        subtitle: Text(
          '${candidate.comuna.isEmpty ? 'Sin comuna' : candidate.comuna} · $matchType',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              candidate.totalMatchCount.toString(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text('matches'),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: _CountCard(
                  label: 'Tú puedes darle',
                  value: candidate.iCanGiveCount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CountCard(
                  label: 'Puede darte',
                  value: candidate.theyCanGiveCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CardIdSection(
            title: 'Láminas que tú puedes ofrecerle',
            emptyText: 'No tienes repetidas que le falten.',
            cardIds: candidate.iCanGiveIds,
            formatCardId: formatCardId,
          ),
          const SizedBox(height: 12),
          _CardIdSection(
            title: 'Láminas que esa persona puede ofrecerte',
            emptyText: 'Esa persona no tiene repetidas que te falten.',
            cardIds: candidate.theyCanGiveIds,
            formatCardId: formatCardId,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: null,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Desbloqueo de contacto: Día 6'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value.toString(), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _CardIdSection extends StatelessWidget {
  const _CardIdSection({
    required this.title,
    required this.emptyText,
    required this.cardIds,
    required this.formatCardId,
  });

  final String title;
  final String emptyText;
  final List<String> cardIds;
  final String Function(String cardId) formatCardId;

  @override
  Widget build(BuildContext context) {
    final sortedIds = [...cardIds];

    sortedIds.sort((a, b) => formatCardId(a).compareTo(formatCardId(b)));

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (sortedIds.isEmpty)
            Text(emptyText)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cardId in sortedIds)
                  Chip(label: Text(formatCardId(cardId))),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScrollableMessage extends StatelessWidget {
  const _ScrollableMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRefresh,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(icon, size: 56),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.tonalIcon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    );
  }
}
