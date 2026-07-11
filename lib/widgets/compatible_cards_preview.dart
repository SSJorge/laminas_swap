import 'package:flutter/material.dart';

import '../data/album_catalog.dart';
import '../models/match_candidate.dart';
import '../utils/card_display_utils.dart';
import '../models/album_country.dart';

class CompatibleCardsPreview extends StatelessWidget {
  const CompatibleCardsPreview({
    super.key,
    required this.candidate,
  });

  final MatchCandidate candidate;

  @override
  Widget build(BuildContext context) {
    if (candidate.totalMatchCount == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Aún no hay láminas compatibles con tu álbum actual.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Láminas compatibles',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Puedes ver el detalle antes del match. El contacto se desbloquea con match mutuo.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          _CompatibleCardsSection(
            title: 'Puede darte',
            emptyText: 'No tiene repetidas que te falten.',
            cardIds: candidate.theyCanGiveIds,
          ),
          const SizedBox(height: 6),
          _CompatibleCardsSection(
            title: 'Tú puedes darle',
            emptyText: 'No tienes repetidas que le falten.',
            cardIds: candidate.iCanGiveIds,
          ),
        ],
      ),
    );
  }
}

class _CompatibleCardsSection extends StatelessWidget {
  const _CompatibleCardsSection({
    required this.title,
    required this.emptyText,
    required this.cardIds,
  });

  final String title;
  final String emptyText;
  final List<String> cardIds;

  static final Map<String, CardDefinition> _cardById = {
    for (final card in allCardDefinitions) card.id: card,
  };

  @override
  Widget build(BuildContext context) {
    final sortedIds = [...cardIds];

    sortedIds.sort((a, b) {
      final cardA = _cardById[a];
      final cardB = _cardById[b];

      if (cardA == null || cardB == null) {
        return a.compareTo(b);
      }

      return compareCardDefinitions(cardA, cardB);
    });

    if (sortedIds.isEmpty) {
      return Text(
        '$title: $emptyText',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: sortedIds.length <= 6,
      title: Text(
        '$title (${sortedIds.length})',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
      subtitle: sortedIds.length > 6
          ? const Text('Toca para ver el detalle exacto')
          : null,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cardId in sortedIds)
                Chip(
                  label: Text(_formatCardId(cardId)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCardId(String cardId) {
    final card = _cardById[cardId];

    if (card == null) {
      return cardId;
    }

    return displayCardLabel(card);
  }
}