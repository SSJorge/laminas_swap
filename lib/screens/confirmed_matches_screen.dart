import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/album_catalog.dart';
import '../models/confirmed_match.dart';
import '../services/matching_repository.dart';
import '../widgets/report_user_button.dart';

class ConfirmedMatchesScreen extends StatefulWidget {
  const ConfirmedMatchesScreen({super.key});

  @override
  State<ConfirmedMatchesScreen> createState() => _ConfirmedMatchesScreenState();
}

class _ConfirmedMatchesScreenState extends State<ConfirmedMatchesScreen> {
  late final MatchingRepository _matchingRepository;
  late Future<List<ConfirmedMatch>> _matchesFuture;

  final _cardById = {for (final card in allCardDefinitions) card.id: card};

  @override
  void initState() {
    super.initState();
    _matchingRepository = MatchingRepository(FirebaseFirestore.instance);
    _matchesFuture = _loadConfirmedMatches();
  }

  Future<List<ConfirmedMatch>> _loadConfirmedMatches() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Future.error('No hay usuario autenticado.');
    }

    return _matchingRepository.findConfirmedMatches(uid: user.uid);
  }

  Future<void> _refresh() async {
    setState(() {
      _matchesFuture = _loadConfirmedMatches();
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

  String _initialFor(String value) {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty) {
      return '?';
    }

    return cleanValue[0].toUpperCase();
  }

  Future<void> _copyText(
    BuildContext context,
    String text,
    String successMessage,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis matches')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: FutureBuilder<List<ConfirmedMatch>>(
            future: _matchesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _ScrollableMessage(
                  icon: Icons.info_outline,
                  title: 'No se pudieron cargar tus matches',
                  message: snapshot.error.toString().replaceFirst(
                    'Exception: ',
                    '',
                  ),
                  onRefresh: _refresh,
                );
              }

              final matches = snapshot.data ?? <ConfirmedMatch>[];

              if (matches.isEmpty) {
                return _ScrollableMessage(
                  icon: Icons.handshake_outlined,
                  title: 'Todavía no tienes matches',
                  message:
                      'Cuando tú y otra persona se den like mutuamente, aparecerá aquí la descripción y el contacto permitido.',
                  onRefresh: _refresh,
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const _ConfirmedMatchesInfoCard(),
                    const SizedBox(height: 12),
                    for (final confirmedMatch in matches)
                      _ConfirmedMatchCard(
                        confirmedMatch: confirmedMatch,
                        formatCardId: _formatCardId,
                        initial: _initialFor(
                          confirmedMatch.candidate.displayName,
                        ),
                        onShareMyContact: () {
                          return _shareMyContact(confirmedMatch.candidate.uid);
                        },
                        onHideMyContact: () {
                          return _hideMyContact(confirmedMatch.candidate.uid);
                        },
                        onCopyDescription: confirmedMatch.hasDescription
                            ? () {
                                return _copyText(
                                  context,
                                  confirmedMatch.description,
                                  'Descripción copiada.',
                                );
                              }
                            : null,
                        onCopyContact: confirmedMatch.hasVisibleContact
                            ? () {
                                return _copyText(
                                  context,
                                  confirmedMatch.theirContactValue,
                                  'Contacto copiado.',
                                );
                              }
                            : null,
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

  Future<void> _shareMyContact(String targetUid) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _matchingRepository.shareMyContactWith(
        ownerUid: user.uid,
        viewerUid: targetUid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu contacto ahora está visible para esta persona.'),
        ),
      );

      await _refresh();
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _hideMyContact(String targetUid) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _matchingRepository.hideMyContactFrom(
        ownerUid: user.uid,
        viewerUid: targetUid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu contacto dejó de estar visible para esta persona.'),
        ),
      );

      await _refresh();
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ConfirmedMatchesInfoCard extends StatelessWidget {
  const _ConfirmedMatchesInfoCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Aquí solo aparecen matches mutuos. Recién en esta pantalla se muestra '
          'la descripción y el contacto, si la otra persona permitió mostrarlo.',
        ),
      ),
    );
  }
}

class _ConfirmedMatchCard extends StatelessWidget {
  const _ConfirmedMatchCard({
    required this.confirmedMatch,
    required this.formatCardId,
    required this.initial,
    required this.onShareMyContact,
    required this.onHideMyContact,
    required this.onCopyDescription,
    required this.onCopyContact,
  });

  final ConfirmedMatch confirmedMatch;
  final String Function(String cardId) formatCardId;
  final String initial;
  final Future<void> Function()? onCopyDescription;
  final Future<void> Function()? onCopyContact;
  final Future<void> Function() onShareMyContact;
  final Future<void> Function() onHideMyContact;

  @override
  Widget build(BuildContext context) {
    final candidate = confirmedMatch.candidate;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(child: Text(initial)),
        title: Text(candidate.displayName),
        subtitle: Text(
          candidate.comuna.isEmpty ? 'Sin comuna' : candidate.comuna,
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
          _CopyableInfoBlock(
            title: 'Descripción',
            value: confirmedMatch.hasDescription
                ? confirmedMatch.description
                : 'Sin descripción.',
            copyLabel: 'Copiar descripción',
            onCopy: onCopyDescription,
          ),
          const SizedBox(height: 12),
          if (confirmedMatch.hasVisibleContact)
            _CopyableInfoBlock(
              title: confirmedMatch.contactLabel,
              value: confirmedMatch.theirContactValue,
              copyLabel: 'Copiar contacto',
              onCopy: onCopyContact,
            )
          else
            const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Contacto no compartido'),
              subtitle: Text(
                'Esta persona todavía no te ha mostrado su contacto.',
              ),
            ),
          const SizedBox(height: 12),
          if (confirmedMatch.myContactSharedWithThem)
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Tu contacto está visible para esta persona'),
              subtitle: const Text(
                'Puedes ocultarlo si ya no quieres que lo vea desde la app.',
              ),
              trailing: OutlinedButton.icon(
                onPressed: onHideMyContact,
                icon: const Icon(Icons.visibility_off),
                label: const Text('Ocultar'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onShareMyContact,
                icon: const Icon(Icons.visibility),
                label: const Text('Mostrar mi contacto a esta persona'),
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ReportUserButton(
              reportedUid: candidate.uid,
              reportedDisplayName: candidate.displayName,
              source: 'confirmed_matches',
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyableInfoBlock extends StatelessWidget {
  const _CopyableInfoBlock({
    required this.title,
    required this.value,
    required this.copyLabel,
    required this.onCopy,
  });

  final String title;
  final String value;
  final String copyLabel;
  final Future<void> Function()? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          SelectableText(value),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy),
              label: Text(copyLabel),
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
