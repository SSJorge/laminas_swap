import '../data/album_catalog.dart';
import '../models/album_country.dart';
import '../models/card_status.dart';
import 'card_display_utils.dart';

String buildStickerExportList(Map<String, CardStatus> statuses) {
  final buffer = StringBuffer();

  buffer.writeln('TruequeGol - Lista');
  buffer.writeln();
  buffer.writeln('Me faltan');
  _writeStatusSection(buffer, statuses, CardStatus.missing);
  buffer.writeln();
  buffer.writeln('Tengo repetidas');
  _writeStatusSection(buffer, statuses, CardStatus.duplicate);

  return buffer.toString().trimRight();
}

void _writeStatusSection(
  StringBuffer buffer,
  Map<String, CardStatus> statuses,
  CardStatus targetStatus,
) {
  var wroteAnyLine = false;

  for (final country in albumCountries) {
    final numbers = <String>[];

    for (final card in country.cards) {
      final status = statuses[card.id] ?? CardStatus.missing;

      if (status == targetStatus) {
        numbers.add(displayCardNumber(card));
      }
    }

    if (numbers.isEmpty) {
      continue;
    }

    wroteAnyLine = true;
    buffer.writeln('${_countryExportLabel(country)}: ${numbers.join(', ')}');
  }

  if (!wroteAnyLine) {
    buffer.writeln('Sin datos');
  }
}

String _countryExportLabel(AlbumCountry country) {
  if (country.id == fwcCountry.id) {
    return 'FWC 🏆';
  }

  if (country.id == cocaColaCountry.id) {
    return 'CC';
  }

  final flag = country.flagEmoji.trim();
  if (flag.isEmpty) {
    return country.code;
  }

  return '${country.code} $flag';
}