import '../models/album_country.dart';

const albumCountries = <AlbumCountry>[
  AlbumCountry(id: 'pais_01', name: 'País 1', firstNumber: 1, cardCount: 20),
  AlbumCountry(id: 'pais_02', name: 'País 2', firstNumber: 21, cardCount: 20),
  AlbumCountry(id: 'pais_03', name: 'País 3', firstNumber: 41, cardCount: 20),
  AlbumCountry(id: 'pais_04', name: 'País 4', firstNumber: 61, cardCount: 20),
];

final allCardDefinitions = albumCountries
    .expand((country) => country.cards)
    .toList(growable: false);

final allCardIds = allCardDefinitions.map((card) => card.id).toList();
