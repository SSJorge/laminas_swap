import '../models/album_country.dart';
import '../models/album_group.dart';

class _CountryMeta {
  const _CountryMeta({
    required this.code,
    required this.flagEmoji,
    required this.name,
  });

  final String code;
  final String flagEmoji;
  final String name;
}

const fwcCountry = AlbumCountry(
  id: 'fwc',
  name: 'FWC',
  code: 'FWC',
  flagEmoji: '🏆',
  groupName: 'FWC',
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

const _countryMetas = [
  _CountryMeta(code: 'MEX', flagEmoji: '🇲🇽', name: 'México'),
  _CountryMeta(code: 'RSA', flagEmoji: '🇿🇦', name: 'Sudáfrica'),
  _CountryMeta(code: 'KOR', flagEmoji: '🇰🇷', name: 'República de Korea'),
  _CountryMeta(code: 'CZE', flagEmoji: '🇨🇿', name: 'Chequia'),
  _CountryMeta(code: 'CAN', flagEmoji: '🇨🇦', name: 'Canadá'),
  _CountryMeta(code: 'BIH', flagEmoji: '🇧🇦', name: 'Bosnia y Herzegovina'),
  _CountryMeta(code: 'QAT', flagEmoji: '🇶🇦', name: 'Catar'),
  _CountryMeta(code: 'SUI', flagEmoji: '🇨🇭', name: 'Suiza'),
  _CountryMeta(code: 'BRA', flagEmoji: '🇧🇷', name: 'Brazil'),
  _CountryMeta(code: 'MAR', flagEmoji: '🇲🇦', name: 'Marruecos'),
  _CountryMeta(code: 'HAI', flagEmoji: '🇭🇹', name: 'Haití'),
  _CountryMeta(code: 'SCO', flagEmoji: '🏴󠁧󠁢󠁳󠁣󠁴󠁿', name: 'Escocia'),
  _CountryMeta(code: 'USA', flagEmoji: '🇺🇸', name: 'EE.UU.'),
  _CountryMeta(code: 'PAR', flagEmoji: '🇵🇾', name: 'Paraguay'),
  _CountryMeta(code: 'AUS', flagEmoji: '🇦🇺', name: 'Australia'),
  _CountryMeta(code: 'TUR', flagEmoji: '🇹🇷', name: 'Turquía'),
  _CountryMeta(code: 'GER', flagEmoji: '🇩🇪', name: 'Alemania'),
  _CountryMeta(code: 'CUW', flagEmoji: '🇨🇼', name: 'Curazao'),
  _CountryMeta(code: 'CIV', flagEmoji: '🇨🇮', name: 'Costa de Marfil'),
  _CountryMeta(code: 'ECU', flagEmoji: '🇪🇨', name: 'Ecuador'),
  _CountryMeta(code: 'NED', flagEmoji: '🇳🇱', name: 'Países Bajos'),
  _CountryMeta(code: 'JPN', flagEmoji: '🇯🇵', name: 'Japón'),
  _CountryMeta(code: 'SWE', flagEmoji: '🇸🇪', name: 'Suecia'),
  _CountryMeta(code: 'TUN', flagEmoji: '🇹🇳', name: 'Túnez'),
  _CountryMeta(code: 'BEL', flagEmoji: '🇧🇪', name: 'Bélgica'),
  _CountryMeta(code: 'EGY', flagEmoji: '🇪🇬', name: 'Egipto'),
  _CountryMeta(code: 'IRN', flagEmoji: '🇮🇷', name: 'Irán'),
  _CountryMeta(code: 'NZL', flagEmoji: '🇳🇿', name: 'Nueva Zelanda'),
  _CountryMeta(code: 'ESP', flagEmoji: '🇪🇸', name: 'España'),
  _CountryMeta(code: 'CPV', flagEmoji: '🇨🇻', name: 'Cabo Verde'),
  _CountryMeta(code: 'KSA', flagEmoji: '🇸🇦', name: 'Arabia Saudita'),
  _CountryMeta(code: 'URU', flagEmoji: '🇺🇾', name: 'Uruguay'),
  _CountryMeta(code: 'FRA', flagEmoji: '🇫🇷', name: 'Francia'),
  _CountryMeta(code: 'SEN', flagEmoji: '🇸🇳', name: 'Senegal'),
  _CountryMeta(code: 'IRQ', flagEmoji: '🇮🇶', name: 'Irak'),
  _CountryMeta(code: 'NOR', flagEmoji: '🇳🇴', name: 'Noruega'),
  _CountryMeta(code: 'ARG', flagEmoji: '🇦🇷', name: 'Argentina'),
  _CountryMeta(code: 'ALG', flagEmoji: '🇩🇿', name: 'Algeria'),
  _CountryMeta(code: 'AUT', flagEmoji: '🇦🇹', name: 'Austria'),
  _CountryMeta(code: 'JOR', flagEmoji: '🇯🇴', name: 'Jordania'),
  _CountryMeta(code: 'POR', flagEmoji: '🇵🇹', name: 'Portugal'),
  _CountryMeta(code: 'COD', flagEmoji: '🇨🇩', name: 'RD del Congo'),
  _CountryMeta(code: 'UZB', flagEmoji: '🇺🇿', name: 'Uzbekistán'),
  _CountryMeta(code: 'COL', flagEmoji: '🇨🇴', name: 'Colombia'),
  _CountryMeta(code: 'ENG', flagEmoji: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', name: 'Inglaterra'),
  _CountryMeta(code: 'CRO', flagEmoji: '🇭🇷', name: 'Croacia'),
  _CountryMeta(code: 'GHA', flagEmoji: '🇬🇭', name: 'Ghana'),
  _CountryMeta(code: 'PAN', flagEmoji: '🇵🇦', name: 'Panamá'),
];

final albumGroups = List.generate(_groupLetters.length, (groupIndex) {
  final groupLetter = _groupLetters[groupIndex];
  final groupName = 'Grupo $groupLetter';
  final firstCountryNumber = groupIndex * 4 + 1;

  final countries = List.generate(4, (countryIndex) {
    final countryNumber = firstCountryNumber + countryIndex;
    final firstCardNumber = 20 + ((countryNumber - 1) * 20);
    final meta = _countryMetas[countryNumber - 1];

    return AlbumCountry(
      id: 'pais_${countryNumber.toString().padLeft(2, '0')}',
      name: meta.name,
      code: meta.code,
      flagEmoji: meta.flagEmoji,
      groupName: groupName,
      firstNumber: firstCardNumber,
      cardCount: 20,
    );
  });

  return AlbumGroup(
    id: 'grupo_${groupLetter.toLowerCase()}',
    name: groupName,
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
