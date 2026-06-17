class AlbumCountry {
  const AlbumCountry({
    required this.id,
    required this.name,
    required this.firstNumber,
    required this.cardCount,
  });

  final String id;
  final String name;
  final int firstNumber;
  final int cardCount;

  List<CardDefinition> get cards {
    return List.generate(cardCount, (index) {
      final number = firstNumber + index;

      return CardDefinition(
        id: '${id}_${number.toString().padLeft(3, '0')}',
        countryId: id,
        countryName: name,
        number: number,
      );
    });
  }
}

class CardDefinition {
  const CardDefinition({
    required this.id,
    required this.countryId,
    required this.countryName,
    required this.number,
  });

  final String id;
  final String countryId;
  final String countryName;
  final int number;
}
