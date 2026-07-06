import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/match_candidate.dart';
import '../services/matching_repository.dart';

class DirectMatchScreen extends StatefulWidget {
  const DirectMatchScreen({
    super.key,
    required this.displayNameKey,
  });

  final String displayNameKey;

  @override
  State<DirectMatchScreen> createState() => _DirectMatchScreenState();
}

class _DirectMatchScreenState extends State<DirectMatchScreen> {
  late final MatchingRepository _matchingRepository;
  late Future<MatchCandidate> _candidateFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _matchingRepository = MatchingRepository(FirebaseFirestore.instance);
    _candidateFuture = _loadCandidate();
  }

  Future<MatchCandidate> _loadCandidate() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Future.error('Inicia sesión para ver este perfil.');
    }

    return _matchingRepository.findCandidateByDisplayNameKey(
      uid: user.uid,
      displayNameKey: widget.displayNameKey,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _candidateFuture = _loadCandidate();
    });

    await _candidateFuture;
  }

  Future<void> _sendAction({
    required MatchCandidate candidate,
    required String action,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

if (user == null || _isSaving) {
  return;
}

if (user.isAnonymous) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Crea una cuenta para dar like y hacer match.'),
    ),
  );
  return;
}

    setState(() {
      _isSaving = true;
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
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
      appBar: AppBar(
        title: const Text('Perfil compartido'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: FutureBuilder<MatchCandidate>(
            future: _candidateFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      const Icon(Icons.info_outline, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        'No se pudo abrir el perfil',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error
                            .toString()
                            .replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: FilledButton.tonalIcon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final candidate = snapshot.data!;

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _DirectCandidateCard(
                      candidate: candidate,
                      initial: _initialFor(candidate.displayName),
                      isSaving: _isSaving,
                      onLike: () {
                        return _sendAction(
                          candidate: candidate,
                          action: 'like',
                        );
                      },
                      onDislike: () {
                        return _sendAction(
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

class _DirectCandidateCard extends StatelessWidget {
  const _DirectCandidateCard({
    required this.candidate,
    required this.initial,
    required this.isSaving,
    required this.onLike,
    required this.onDislike,
  });

  final MatchCandidate candidate;
  final String initial;
  final bool isSaving;
  final Future<void> Function() onLike;
  final Future<void> Function() onDislike;

  @override
  Widget build(BuildContext context) {
    final hasCompatibility = candidate.totalMatchCount > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              child: Text(initial),
            ),
            const SizedBox(height: 12),
            Text(
              candidate.displayName,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              candidate.comuna.isEmpty ? 'Sin comuna' : candidate.comuna,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _CountCard(
                    label: 'Tú puedes darle',
                    value: candidate.iCanGiveCount,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CountCard(
                    label: 'Puede darte',
                    value: candidate.theyCanGiveCount,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hasCompatibility
                  ? 'El detalle de láminas y contacto se muestra después del match mutuo.'
                  : 'Aún no hay compatibilidad detectada con tu álbum actual.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSaving ? null : onDislike,
                    icon: const Icon(Icons.close),
                    label: const Text('Dislike'),
                  ),
                ),
                const SizedBox(width: 10),
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
  const _CountCard({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}