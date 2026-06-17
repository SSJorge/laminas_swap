import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/album_catalog.dart';
import '../models/album_country.dart';
import '../models/card_status.dart';
import '../services/card_repository.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  late final CardRepository _cardRepository;

  @override
  void initState() {
    super.initState();
    _cardRepository = CardRepository(FirebaseFirestore.instance);
  }

  Future<void> _changeSingleCard({
    required BuildContext context,
    required String uid,
    required CardDefinitionViewModel card,
    required CardStatus newStatus,
    required Map<String, CardStatus> currentStatuses,
  }) async {
    try {
      await _cardRepository.setCardStatus(
        uid: uid,
        card: card.definition,
        status: newStatus,
        currentStatuses: currentStatuses,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error guardando lámina: $e')));
    }
  }

  Future<void> _shiftCountry({
    required BuildContext context,
    required String uid,
    required AlbumCountry country,
    required int direction,
    required Map<String, CardStatus> currentStatuses,
  }) async {
    try {
      await _cardRepository.shiftCountryStatuses(
        uid: uid,
        country: country,
        direction: direction,
        currentStatuses: currentStatuses,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error actualizando país: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay usuario autenticado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis láminas')),
      body: StreamBuilder<Map<String, CardStatus>>(
        stream: _cardRepository.watchMyCardStatuses(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final statuses = snapshot.data ?? {};

          final missingCount = _countByStatus(statuses, CardStatus.missing);
          final obtainedCount = _countByStatus(statuses, CardStatus.obtained);
          final duplicateCount = _countByStatus(statuses, CardStatus.duplicate);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _SummaryChip(label: 'Faltantes', value: missingCount),
                          _SummaryChip(
                            label: 'Obtenidas',
                            value: obtainedCount,
                          ),
                          _SummaryChip(
                            label: 'Repetidas',
                            value: duplicateCount,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final country in albumCountries)
                    _CountrySection(
                      uid: user.uid,
                      country: country,
                      statuses: statuses,
                      onCardTap: ({required card, required newStatus}) {
                        return _changeSingleCard(
                          context: context,
                          uid: user.uid,
                          card: card,
                          newStatus: newStatus,
                          currentStatuses: statuses,
                        );
                      },
                      onShiftCountry: (direction) {
                        return _shiftCountry(
                          context: context,
                          uid: user.uid,
                          country: country,
                          direction: direction,
                          currentStatuses: statuses,
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _countByStatus(
    Map<String, CardStatus> statuses,
    CardStatus targetStatus,
  ) {
    var count = 0;

    for (final card in allCardDefinitions) {
      final status = statuses[card.id] ?? CardStatus.missing;

      if (status == targetStatus) {
        count++;
      }
    }

    return count;
  }
}

class _CountrySection extends StatelessWidget {
  const _CountrySection({
    required this.uid,
    required this.country,
    required this.statuses,
    required this.onCardTap,
    required this.onShiftCountry,
  });

  final String uid;
  final AlbumCountry country;
  final Map<String, CardStatus> statuses;
  final Future<void> Function({
    required CardDefinitionViewModel card,
    required CardStatus newStatus,
  })
  onCardTap;
  final Future<void> Function(int direction) onShiftCountry;

  @override
  Widget build(BuildContext context) {
    final cards = country.cards
        .map(
          (definition) => CardDefinitionViewModel(
            definition: definition,
            status: statuses[definition.id] ?? CardStatus.missing,
          ),
        )
        .toList();

    final missing = cards
        .where((card) => card.status == CardStatus.missing)
        .length;
    final obtained = cards
        .where((card) => card.status == CardStatus.obtained)
        .length;
    final duplicate = cards
        .where((card) => card.status == CardStatus.duplicate)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(country.name),
        subtitle: Text(
          'Faltantes: $missing · Obtenidas: $obtained · Repetidas: $duplicate',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => onShiftCountry(1),
                  icon: const Icon(Icons.add),
                  label: const Text('+1 a todo el país'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => onShiftCountry(-1),
                  icon: const Icon(Icons.remove),
                  label: const Text('-1 a todo el país'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              final crossAxisCount = width >= 700
                  ? 8
                  : width >= 520
                  ? 6
                  : width >= 360
                  ? 4
                  : 3;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final card = cards[index];

                  return _CardTile(
                    card: card,
                    onTap: () {
                      return onCardTap(card: card, newStatus: card.status.next);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.onTap});

  final CardDefinitionViewModel card;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = switch (card.status) {
      CardStatus.missing => colorScheme.surface,
      CardStatus.obtained => colorScheme.primaryContainer,
      CardStatus.duplicate => colorScheme.secondaryContainer,
    };

    final borderColor = switch (card.status) {
      CardStatus.missing => colorScheme.outlineVariant,
      CardStatus.obtained => colorScheme.primary,
      CardStatus.duplicate => colorScheme.secondary,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                card.definition.number.toString(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                card.status.shortLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                card.status.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class CardDefinitionViewModel {
  const CardDefinitionViewModel({
    required this.definition,
    required this.status,
  });

  final dynamic definition;
  final CardStatus status;
}
