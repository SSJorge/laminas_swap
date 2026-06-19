import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/match_candidate.dart';
import '../services/matching_repository.dart';
import '../data/daily_limits.dart';
import '../widgets/daily_limits_card.dart';

class ReceivedLikesScreen extends StatefulWidget {
  const ReceivedLikesScreen({super.key});

  @override
  State<ReceivedLikesScreen> createState() => _ReceivedLikesScreenState();
}

class _ReceivedLikesScreenState extends State<ReceivedLikesScreen> {
  late final MatchingRepository _matchingRepository;
  late Future<List<MatchCandidate>> _receivedLikesFuture;

  final Set<String> _savingCandidateIds = <String>{};

  @override
  void initState() {
    super.initState();
    _matchingRepository = MatchingRepository(FirebaseFirestore.instance);
    _receivedLikesFuture = _loadReceivedLikes();
  }

  Future<List<MatchCandidate>> _loadReceivedLikes() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Future.error('No hay usuario autenticado.');
    }

    return _matchingRepository.findReceivedLikes(uid: user.uid);
  }

  Future<void> _refresh() async {
    setState(() {
      _receivedLikesFuture = _loadReceivedLikes();
    });

    await _receivedLikesFuture;
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
            action == 'like'
                ? 'Match creado. Ahora puedes verlo en Mis matches.'
                : 'Like rechazado.',
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
      appBar: AppBar(title: const Text('Likes recibidos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: FutureBuilder<List<MatchCandidate>>(
            future: _receivedLikesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _ScrollableMessage(
                  icon: Icons.info_outline,
                  title: 'No se pudieron cargar tus likes',
                  message: snapshot.error.toString().replaceFirst(
                    'Exception: ',
                    '',
                  ),
                  onRefresh: _refresh,
                );
              }

              final candidates = snapshot.data ?? <MatchCandidate>[];

              if (candidates.isEmpty) {
                return _ScrollableMessage(
                  icon: Icons.favorite_border,
                  title: 'Todavía no tienes likes pendientes',
                  message:
                      'Cuando alguien te dé like, aparecerá aquí. Si tú también le das like, se crea un match.',
                  onRefresh: _refresh,
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const _ReceivedLikesInfoCard(),
                    const SizedBox(height: 12),
                    const DailyLimitsCard(
                      types: [DailyLimitType.like, DailyLimitType.dislike],
                    ),
                    const SizedBox(height: 12),
                    for (final candidate in candidates)
                      _ReceivedLikeCard(
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

class _ReceivedLikesInfoCard extends StatelessWidget {
  const _ReceivedLikesInfoCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Estas personas ya te dieron like. Antes de responder solo ves la cantidad de láminas compatibles. '
          'Si tú también les das like, se crea un match y se desbloquea el detalle.',
        ),
      ),
    );
  }
}

class _ReceivedLikeCard extends StatelessWidget {
  const _ReceivedLikeCard({
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
              'El detalle exacto de las láminas se desbloquea solo si devuelves el like.',
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
                    label: const Text('Like de vuelta'),
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
