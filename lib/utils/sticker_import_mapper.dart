import '../data/album_catalog.dart';
import '../models/album_country.dart';
import '../models/card_status.dart';
import '../utils/card_display_utils.dart';
import 'sticker_list_import_parser.dart';

class StickerImportPreview {
  const StickerImportPreview({
    required this.rawResult,
    required this.statusesByCardId,
    required this.unknownItems,
    required this.missingCount,
    required this.obtainedCount,
    required this.duplicateCount,
  });

  final StickerImportResult rawResult;
  final Map<String, CardStatus> statusesByCardId;
  final List<String> unknownItems;
  final int missingCount;
  final int obtainedCount;
  final int duplicateCount;

  bool get hasAnyData => rawResult.hasAnyData;
}

StickerImportPreview buildStickerImportPreview(StickerImportResult result) {
  final cardByImportKey = <String, CardDefinition>{};

  for (final country in albumCountries) {
    for (final card in country.cards) {
      final code = card.countryCode.toUpperCase();
      final visibleNumber = displayCardNumber(card);
      cardByImportKey['$code-$visibleNumber'] = card;
    }
  }

  // Regla de importación:
  // todo lo que no aparece como faltante o repetida queda como obtenida.
  final statusesByCardId = <String, CardStatus>{
    for (final card in allCardDefinitions) card.id: CardStatus.obtained,
  };

  final unknownItems = <String>{};

  void applySection(Map<String, Set<String>> section, CardStatus status) {
    for (final entry in section.entries) {
      final code = entry.key.toUpperCase();

      for (final number in entry.value) {
        final key = '$code-$number';
        final card = cardByImportKey[key];

        if (card == null) {
          unknownItems.add(key);
          continue;
        }

        statusesByCardId[card.id] = status;
      }
    }
  }

  applySection(result.missing, CardStatus.missing);

  // Repetida tiene prioridad si una lámina viene contradicha.
  applySection(result.repeated, CardStatus.duplicate);

  final missingCount = _countStatus(statusesByCardId, CardStatus.missing);
  final obtainedCount = _countStatus(statusesByCardId, CardStatus.obtained);
  final duplicateCount = _countStatus(statusesByCardId, CardStatus.duplicate);

  final sortedUnknownItems = unknownItems.toList()..sort();

  return StickerImportPreview(
    rawResult: result,
    statusesByCardId: statusesByCardId,
    unknownItems: sortedUnknownItems,
    missingCount: missingCount,
    obtainedCount: obtainedCount,
    duplicateCount: duplicateCount,
  );
}

int _countStatus(
  Map<String, CardStatus> statusesByCardId,
  CardStatus targetStatus,
) {
  var count = 0;

  for (final card in allCardDefinitions) {
    if (statusesByCardId[card.id] == targetStatus) {
      count++;
    }
  }

  return count;
}
