import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/album_catalog.dart';
import '../models/album_country.dart';
import '../models/album_group.dart';
import '../models/card_status.dart';
import '../services/card_repository.dart';
import '../utils/card_display_utils.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  late final CardRepository _cardRepository;

  final Set<String> _savingCountryIds = <String>{};
  final Set<String> _savingGroupIds = <String>{};
  final Set<String> _savingCardIds = <String>{};

  SharedPreferences? _prefs;
  bool _isLoadingExpansionState = true;

  @override
  void initState() {
    super.initState();
    _cardRepository = CardRepository(FirebaseFirestore.instance);
    _loadExpansionState();
  }

  Future<void> _loadExpansionState() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _prefs = prefs;
      _isLoadingExpansionState = false;
    });
  }

  String _expansionKey({required String uid, required String tileId}) {
    return 'cards_screen_expanded_${uid}_$tileId';
  }

  bool _isExpanded({
    required String uid,
    required String tileId,
    required bool defaultValue,
  }) {
    return _prefs?.getBool(_expansionKey(uid: uid, tileId: tileId)) ??
        defaultValue;
  }

  Future<void> _setExpanded({
    required String uid,
    required String tileId,
    required bool expanded,
  }) async {
    await _prefs?.setBool(_expansionKey(uid: uid, tileId: tileId), expanded);
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

  Future<void> _shiftGroup({
    required BuildContext context,
    required String uid,
    required AlbumGroup group,
    required int direction,
    required Map<String, CardStatus> currentStatuses,
  }) async {
    if (_savingGroupIds.contains(group.id)) {
      return;
    }

    setState(() {
      _savingGroupIds.add(group.id);
    });

    try {
      await _cardRepository.shiftCountriesStatuses(
        uid: uid,
        countries: group.countries,
        direction: direction,
        currentStatuses: currentStatuses,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error actualizando grupo: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _savingGroupIds.remove(group.id);
        });
      }
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

    if (_isLoadingExpansionState) {
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
        body: const Center(child: CircularProgressIndicator()),
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
                  _CountrySection(
                    country: fwcCountry,
                    statuses: statuses,
                    isSavingCountry: _savingCountryIds.contains(fwcCountry.id),
                    savingCardIds: _savingCardIds,
                    initiallyExpanded: _isExpanded(
                      uid: user.uid,
                      tileId: 'country_${fwcCountry.id}',
                      defaultValue: true,
                    ),
                    onExpansionChanged: (expanded) {
                      _setExpanded(
                        uid: user.uid,
                        tileId: 'country_${fwcCountry.id}',
                        expanded: expanded,
                      );
                    },
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
                        country: fwcCountry,
                        direction: direction,
                        currentStatuses: statuses,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _CountrySection(
                    country: cocaColaCountry,
                    statuses: statuses,
                    isSavingCountry: _savingCountryIds.contains(
                      cocaColaCountry.id,
                    ),
                    savingCardIds: _savingCardIds,
                    initiallyExpanded: _isExpanded(
                      uid: user.uid,
                      tileId: 'country_${cocaColaCountry.id}',
                      defaultValue: false,
                    ),
                    onExpansionChanged: (expanded) {
                      _setExpanded(
                        uid: user.uid,
                        tileId: 'country_${cocaColaCountry.id}',
                        expanded: expanded,
                      );
                    },
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
                        country: cocaColaCountry,
                        direction: direction,
                        currentStatuses: statuses,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  for (final group in albumGroups)
                    _GroupSection(
                      group: group,
                      statuses: statuses,
                      isSavingGroup: _savingGroupIds.contains(group.id),
                      savingCountryIds: _savingCountryIds,
                      savingCardIds: _savingCardIds,
                      initiallyExpanded: _isExpanded(
                        uid: user.uid,
                        tileId: 'group_${group.id}',
                        defaultValue: false,
                      ),
                      isCountryExpanded: (country) {
                        return _isExpanded(
                          uid: user.uid,
                          tileId: 'country_${country.id}',
                          defaultValue: false,
                        );
                      },
                      onGroupExpansionChanged: (expanded) {
                        _setExpanded(
                          uid: user.uid,
                          tileId: 'group_${group.id}',
                          expanded: expanded,
                        );
                      },
                      onCountryExpansionChanged: (country, expanded) {
                        _setExpanded(
                          uid: user.uid,
                          tileId: 'country_${country.id}',
                          expanded: expanded,
                        );
                      },
                      onShiftGroup: (direction) {
                        return _shiftGroup(
                          context: context,
                          uid: user.uid,
                          group: group,
                          direction: direction,
                          currentStatuses: statuses,
                        );
                      },
                      onShiftCountry: (country, direction) {
                        return _shiftCountry(
                          context: context,
                          uid: user.uid,
                          country: country,
                          direction: direction,
                          currentStatuses: statuses,
                        );
                      },
                      onCardTap: ({required card, required newStatus}) {
                        return _changeSingleCard(
                          context: context,
                          uid: user.uid,
                          card: card,
                          newStatus: newStatus,
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

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.group,
    required this.statuses,
    required this.isSavingGroup,
    required this.savingCountryIds,
    required this.savingCardIds,
    required this.initiallyExpanded,
    required this.isCountryExpanded,
    required this.onGroupExpansionChanged,
    required this.onCountryExpansionChanged,
    required this.onShiftGroup,
    required this.onShiftCountry,
    required this.onCardTap,
  });

  final AlbumGroup group;
  final Map<String, CardStatus> statuses;
  final bool isSavingGroup;
  final Set<String> savingCountryIds;
  final Set<String> savingCardIds;
  final bool initiallyExpanded;
  final bool Function(AlbumCountry country) isCountryExpanded;
  final ValueChanged<bool> onGroupExpansionChanged;
  final void Function(AlbumCountry country, bool expanded)
  onCountryExpansionChanged;
  final Future<void> Function(int direction) onShiftGroup;
  final Future<void> Function(AlbumCountry country, int direction)
  onShiftCountry;
  final Future<void> Function({
    required CardDefinitionViewModel card,
    required CardStatus newStatus,
  })
  onCardTap;

  @override
  Widget build(BuildContext context) {
    final counts = _StatusCounts.fromDefinitions(group.cards, statuses);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        key: PageStorageKey('group_${group.id}'),
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onGroupExpansionChanged,
        title: Text(group.name),
        subtitle: Text(counts.label),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: isSavingGroup
                      ? null
                      : () {
                          onShiftGroup(1);
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('+1 a todo el grupo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: isSavingGroup
                      ? null
                      : () {
                          onShiftGroup(-1);
                        },
                  icon: const Icon(Icons.remove),
                  label: const Text('-1 a todo el grupo'),
                ),
              ),
            ],
          ),
          if (isSavingGroup) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 12),
          for (final country in group.countries)
            _CountrySection(
              country: country,
              statuses: statuses,
              isNested: true,
              isSavingCountry:
                  isSavingGroup || savingCountryIds.contains(country.id),
              savingCardIds: savingCardIds,
              initiallyExpanded: isCountryExpanded(country),
              onExpansionChanged: (expanded) {
                onCountryExpansionChanged(country, expanded);
              },
              onCardTap: onCardTap,
              onShiftCountry: (direction) {
                return onShiftCountry(country, direction);
              },
            ),
        ],
      ),
    );
  }
}

class _CountrySection extends StatelessWidget {
  const _CountrySection({
    required this.country,
    required this.statuses,
    required this.isSavingCountry,
    required this.savingCardIds,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.onCardTap,
    required this.onShiftCountry,
    this.isNested = false,
  });

  final AlbumCountry country;
  final Map<String, CardStatus> statuses;
  final bool isSavingCountry;
  final Set<String> savingCardIds;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final Future<void> Function({
    required CardDefinitionViewModel card,
    required CardStatus newStatus,
  })
  onCardTap;
  final Future<void> Function(int direction) onShiftCountry;
  final bool isNested;

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

    final counts = _StatusCounts.fromViewModels(cards);

    return Card(
      margin: EdgeInsets.only(
        bottom: isNested ? 8 : 12,
        left: isNested ? 4 : 0,
        right: isNested ? 4 : 0,
      ),
      child: ExpansionTile(
        key: PageStorageKey('country_${country.id}'),
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        title: _CountryTitle(country: country),
        subtitle: Text(counts.label),
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
                  label: Text(
                    country.id == fwcCountry.id
                        ? '+1 a FWC'
                        : '+1 a todo el país',
                  ),
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
                  label: Text(
                    country.id == fwcCountry.id
                        ? '-1 a FWC'
                        : '-1 a todo el país',
                  ),
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

              const spacing = 8.0;
              final totalSpacing = spacing * (crossAxisCount - 1);
              final tileSize = (width - totalSpacing) / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final card in cards)
                    SizedBox(
                      width: tileSize,
                      height: tileSize,
                      child: _CardTile(
                        card: card,
                        isSaving:
                            isSavingCountry ||
                            savingCardIds.contains(card.definition.id),
                        onTap: () {
                          return onCardTap(
                            card: card,
                            newStatus: card.status.next,
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CountryTitle extends StatelessWidget {
  const _CountryTitle({required this.country});

  final AlbumCountry country;

  @override
  Widget build(BuildContext context) {
    if (country.id == fwcCountry.id) {
      return const Text('FWC');
    }

    return Row(
      children: [
        Text(country.code, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        Text(country.flagEmoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Text('- ${country.name}', overflow: TextOverflow.ellipsis),
        ),
      ],
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
      CardStatus.missing => const Color(0xFFE3F2FD),
      CardStatus.obtained => const Color(0xFFC8E6C9),
      CardStatus.duplicate => const Color(0xFFFFCDD2),
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
                      displayCardNumber(card.definition),
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

class _StatusCounts {
  const _StatusCounts({
    required this.missing,
    required this.obtained,
    required this.duplicate,
  });

  final int missing;
  final int obtained;
  final int duplicate;

  String get label {
    return 'Faltantes: $missing · Obtenidas: $obtained · Repetidas: $duplicate';
  }

  factory _StatusCounts.fromDefinitions(
    Iterable<CardDefinition> definitions,
    Map<String, CardStatus> statuses,
  ) {
    var missing = 0;
    var obtained = 0;
    var duplicate = 0;

    for (final definition in definitions) {
      final status = statuses[definition.id] ?? CardStatus.missing;

      switch (status) {
        case CardStatus.missing:
          missing++;
          break;
        case CardStatus.obtained:
          obtained++;
          break;
        case CardStatus.duplicate:
          duplicate++;
          break;
      }
    }

    return _StatusCounts(
      missing: missing,
      obtained: obtained,
      duplicate: duplicate,
    );
  }

  factory _StatusCounts.fromViewModels(
    Iterable<CardDefinitionViewModel> cards,
  ) {
    var missing = 0;
    var obtained = 0;
    var duplicate = 0;

    for (final card in cards) {
      switch (card.status) {
        case CardStatus.missing:
          missing++;
          break;
        case CardStatus.obtained:
          obtained++;
          break;
        case CardStatus.duplicate:
          duplicate++;
          break;
      }
    }

    return _StatusCounts(
      missing: missing,
      obtained: obtained,
      duplicate: duplicate,
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
