import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/match_candidate.dart';
import '../services/matching_repository.dart';
import '../data/daily_limits.dart';
import '../widgets/daily_limits_card.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  late final MatchingRepository _matchingRepository;
  late Future<List<MatchCandidate>> _matchesFuture;

  final Set<String> _savingCandidateIds = <String>{};

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

  Future<void> _saveAction({
    required MatchCandidate candidate,
    required String action,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _savingCandidateIds.contains(candidate.uid)) {
      return;
    }

    setState(() {
      _savingCandidateIds.add(candidate.uid);
    });

    try {
      await _matchingRepository.setAction(
        fromUid: user.uid,
        targetUid: candidate.uid,
        action: action,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'like' ? 'Like enviado.' : 'Perfil descartado.',
          ),
        ),
      );

      await _refresh();
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (!mounted) return;

      setState(() {
        _savingCandidateIds.remove(candidate.uid);
      });
    }
  }

  String _initialFor(String value) {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty) {
      return '?';
    }

    return cleanValue[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Descubrir')),
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
                  title: 'Todavía no hay candidatos',
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
                    const DailyLimitsCard(
                      types: [DailyLimitType.like, DailyLimitType.dislike],
                    ),
                    const SizedBox(height: 12),
                    for (final candidate in matches)
                      _MatchCandidateCard(
                        candidate: candidate,
                        isSaving: _savingCandidateIds.contains(candidate.uid),
                        initial: _initialFor(candidate.displayName),
                        onLike: () {
                          return _saveAction(
                            candidate: candidate,
                            action: 'like',
                          );
                        },
                        onDislike: () {
                          return _saveAction(
                            candidate: candidate,
                            action: 'dislike',
                          );
                        },
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
          'Aquí solo ves cantidades de compatibilidad. '
          'Las láminas específicas, descripción y contacto se muestran recién después de un match mutuo.',
        ),
      ),
    );
  }
}

class _MatchCandidateCard extends StatelessWidget {
  const _MatchCandidateCard({
    required this.candidate,
    required this.isSaving,
    required this.initial,
    required this.onLike,
    required this.onDislike,
  });

  final MatchCandidate candidate;
  final bool isSaving;
  final String initial;
  final Future<void> Function() onLike;
  final Future<void> Function() onDislike;

  @override
  Widget build(BuildContext context) {
    final matchType = candidate.hasTwoWayMatch
        ? 'Intercambio posible'
        : 'Coincidencia parcial';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(initial)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${candidate.comuna.isEmpty ? 'Sin comuna' : candidate.comuna} · $matchType',
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      candidate.totalMatchCount.toString(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text('total'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            const Text(
              'El detalle exacto de las láminas se desbloquea solo si ambos se dan like.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSaving ? null : onDislike,
                    icon: const Icon(Icons.close),
                    label: const Text('Dislike'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isSaving ? null : onLike,
                    icon: const Icon(Icons.favorite),
                    label: const Text('Like'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
