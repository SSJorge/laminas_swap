import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/profile_constants.dart';
import '../models/match_candidate.dart';
import '../services/matching_repository.dart';
import '../services/user_search_repository.dart';
import '../data/daily_limits.dart';
import '../services/daily_quota_repository.dart';
import '../widgets/daily_limits_card.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _searchController = TextEditingController();

  late final UserSearchRepository _userSearchRepository;
  late final MatchingRepository _matchingRepository;
  late final DailyQuotaRepository _dailyQuotaRepository;

  MatchCandidate? _candidate;
  bool _isSearching = false;
  bool _isSavingAction = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final db = FirebaseFirestore.instance;
    _userSearchRepository = UserSearchRepository(db);
    _matchingRepository = MatchingRepository(db);
    _dailyQuotaRepository = DailyQuotaRepository(db);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isSearching = true;
      _message = null;
      _candidate = null;
    });

    try {
      await _dailyQuotaRepository.consume(
        uid: user.uid,
        type: DailyLimitType.userSearch,
      );
      final candidate = await _userSearchRepository.findCandidateByDisplayName(
        myUid: user.uid,
        displayName: _searchController.text,
      );

      if (!mounted) return;

      setState(() {
        _candidate = candidate;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _saveAction(String action) async {
    final user = FirebaseAuth.instance.currentUser;
    final candidate = _candidate;

    if (user == null || candidate == null || _isSavingAction) {
      return;
    }

    setState(() {
      _isSavingAction = true;
      _message = null;
    });

    try {
      await _matchingRepository.setAction(
        fromUid: user.uid,
        targetUid: candidate.uid,
        action: action,
      );

      if (!mounted) return;

      setState(() {
        _candidate = null;
        _message = action == 'like' ? 'Like enviado.' : 'Perfil descartado.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) {
        setState(() {
          _isSavingAction = false;
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
    final candidate = _candidate;

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar usuario')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Busca a alguien por su nombre de usuario exacto. '
                    'Solo verás cantidades de compatibilidad hasta que exista match mutuo.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const DailyLimitsCard(types: [DailyLimitType.userSearch]),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                maxLength: displayNameMaxLength,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  hintText: 'Ej: username123',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isSearching ? null : _search,
                icon: const Icon(Icons.search),
                label: _isSearching
                    ? const Text('Buscando...')
                    : const Text('Buscar'),
              ),
              const SizedBox(height: 16),
              if (_message != null)
                Text(_message!, textAlign: TextAlign.center),
              if (candidate != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              child: Text(_initialFor(candidate.displayName)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    candidate.displayName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    candidate.comuna.isEmpty
                                        ? 'Sin comuna'
                                        : candidate.comuna,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  candidate.totalMatchCount.toString(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
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
                          'El detalle exacto se muestra solo después del match mutuo.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isSavingAction
                                    ? null
                                    : () => _saveAction('dislike'),
                                icon: const Icon(Icons.close),
                                label: const Text('Dislike'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isSavingAction
                                    ? null
                                    : () => _saveAction('like'),
                                icon: const Icon(Icons.favorite),
                                label: const Text('Like'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
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
