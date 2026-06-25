import '../data/album_catalog.dart';
import '../models/album_country.dart';

AlbumCountry? _countryFor(CardDefinition definition) {
  for (final country in albumCountries) {
    if (country.id == definition.countryId) {
      return country;
    }
  }

  return null;
}

String displayCardNumber(CardDefinition definition) {
  final country = _countryFor(definition);

  if (country == null) {
    return definition.number.toString();
  }

  final localNumber = definition.number - country.firstNumber + 1;

  if (definition.countryId == fwcCountry.id) {
    final fwcNumber = localNumber - 1;

    if (fwcNumber == 0) {
      return '00';
    }

    return fwcNumber.toString();
  }

  return localNumber.toString();
}

String displayCardLabel(CardDefinition definition) {
  if (definition.countryId == fwcCountry.id) {
    return 'FWC #${displayCardNumber(definition)}';
  }

  return '${definition.groupName} ${definition.countryCode} '
      '${definition.countryFlagEmoji} #${displayCardNumber(definition)}';
}

int compareCardDefinitions(CardDefinition a, CardDefinition b) {
  final countryA = _countryFor(a);
  final countryB = _countryFor(b);

  final countryOrderA = countryA?.firstNumber ?? a.number;
  final countryOrderB = countryB?.firstNumber ?? b.number;

  if (countryOrderA != countryOrderB) {
    return countryOrderA.compareTo(countryOrderB);
  }

  final localA = countryA == null ? a.number : a.number - countryA.firstNumber;
  final localB = countryB == null ? b.number : b.number - countryB.firstNumber;

  return localA.compareTo(localB);
}
