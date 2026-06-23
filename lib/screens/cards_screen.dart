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

  final Set<String> _savingCountryIds = <String>{};
  final Set<String> _savingCardIds = <String>{};

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
    final cardId = card.definition.id;

    if (_savingCardIds.contains(cardId)) {
      return;
    }

    setState(() {
      _savingCardIds.add(cardId);
    });

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
    } finally {
      if (mounted) {
        setState(() {
          _savingCardIds.remove(cardId);
        });
      }
    }
  }

  Future<void> _shiftCountry({
    required BuildContext context,
    required String uid,
    required AlbumCountry country,
    required int direction,
    required Map<String, CardStatus> currentStatuses,
  }) async {
    if (_savingCountryIds.contains(country.id)) {
      return;
    }

    setState(() {
      _savingCountryIds.add(country.id);
    });

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
    } finally {
      if (mounted) {
        setState(() {
          _savingCountryIds.remove(country.id);
        });
      }
    }
  }

  void _showCardsHelp() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Estados de las láminas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Las láminas solo tienen 3 estados:\n\n'
                  '0: Faltante\n'
                  '1: Obtenida\n'
                  '2: Repetida\n\n'
                  'No se guarda la cantidad de repetidas para facilitar el llenado. '
                  'De esta manera, puedes usar el botón +1 o -1 en todo un país '
                  'si ya lo completaste y luego corregir manualmente solo las excepciones.',
                  style: TextStyle(height: 1.35),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/info_laminas.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
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
      appBar: AppBar(
        title: const Text('Mis láminas'),
        actions: [
          IconButton(
            tooltip: 'Ayuda',
            onPressed: _showCardsHelp,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, CardStatus>>(
        stream: _cardRepository.watchMyCardStatuses(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final statuses = snapshot.data ?? <String, CardStatus>{};

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
                      country: country,
                      statuses: statuses,
                      isSavingCountry: _savingCountryIds.contains(country.id),
                      savingCardIds: _savingCardIds,
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
    required this.country,
    required this.statuses,
    required this.isSavingCountry,
    required this.savingCardIds,
    required this.onCardTap,
    required this.onShiftCountry,
  });

  final AlbumCountry country;
  final Map<String, CardStatus> statuses;
  final bool isSavingCountry;
  final Set<String> savingCardIds;

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
                  onPressed: isSavingCountry
                      ? null
                      : () {
                          onShiftCountry(1);
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('+1 a todo el país'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: isSavingCountry
                      ? null
                      : () {
                          onShiftCountry(-1);
                        },
                  icon: const Icon(Icons.remove),
                  label: const Text('-1 a todo el país'),
                ),
              ),
            ],
          ),
          if (isSavingCountry) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
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
                  final isSavingCard =
                      isSavingCountry ||
                      savingCardIds.contains(card.definition.id);

                  return _CardTile(
                    card: card,
                    isSaving: isSavingCard,
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
  const _CardTile({
    required this.card,
    required this.isSaving,
    required this.onTap,
  });

  final CardDefinitionViewModel card;
  final bool isSaving;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (card.status) {
      CardStatus.missing => const Color(0xFFE3F2FD), // celeste/gris
      CardStatus.obtained => const Color(0xFFC8E6C9), // verde
      CardStatus.duplicate => const Color(0xFFFFCDD2), // rojo
    };

    final borderColor = switch (card.status) {
      CardStatus.missing => const Color(0xFF90CAF9),
      CardStatus.obtained => const Color(0xFF43A047),
      CardStatus.duplicate => const Color(0xFFE53935),
    };

    final textColor = switch (card.status) {
      CardStatus.missing => const Color(0xFF0D47A1),
      CardStatus.obtained => const Color(0xFF1B5E20),
      CardStatus.duplicate => const Color(0xFFB71C1C),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: isSaving
          ? null
          : () {
              onTap();
            },
      child: Ink(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      card.definition.number.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.status.shortLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.status.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: textColor),
                    ),
                  ],
                ),
              ),
              if (isSaving)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
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

  final CardDefinition definition;
  final CardStatus status;
}
