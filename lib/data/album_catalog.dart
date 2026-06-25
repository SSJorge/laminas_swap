import '../models/album_country.dart';
import '../models/album_group.dart';

const fwcCountry = AlbumCountry(
  id: 'fwc',
  name: 'FWC',
  firstNumber: 1,
  cardCount: 20,
);

const _groupLetters = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
];

final albumGroups = List.generate(_groupLetters.length, (groupIndex) {
  final groupLetter = _groupLetters[groupIndex];
  final firstCountryNumber = groupIndex * 4 + 1;

  final countries = List.generate(4, (countryIndex) {
    final countryNumber = firstCountryNumber + countryIndex;
    final firstCardNumber = 20 + ((countryNumber - 1) * 20);

    return AlbumCountry(
      id: 'pais_${countryNumber.toString().padLeft(2, '0')}',
      name: 'País $countryNumber',
      firstNumber: firstCardNumber,
      cardCount: 20,
    );
  });

  return AlbumGroup(
    id: 'grupo_${groupLetter.toLowerCase()}',
    name: 'Grupo $groupLetter',
    countries: countries,
  );
});

final albumCountries = [
  fwcCountry,
  ...albumGroups.expand((group) => group.countries),
];

final allCardDefinitions = [
  ...fwcCountry.cards,
  ...albumGroups.expand((group) => group.cards),
];

final allCardIds = allCardDefinitions.map((card) => card.id).toList();
