import 'album_country.dart';

class AlbumGroup {
  const AlbumGroup({
    required this.id,
    required this.name,
    required this.countries,
  });

  final String id;
  final String name;
  final List<AlbumCountry> countries;

  List<CardDefinition> get cards {
    return countries.expand((country) => country.cards).toList(growable: false);
  }
}
