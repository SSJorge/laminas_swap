class AlbumCountry {
  const AlbumCountry({
    required this.id,
    required this.name,
    required this.code,
    required this.flagEmoji,
    required this.groupName,
    required this.firstNumber,
    required this.cardCount,
  });

  final String id;
  final String name;
  final String code;
  final String flagEmoji;
  final String groupName;
  final int firstNumber;
  final int cardCount;

  List<CardDefinition> get cards {
    return List.generate(cardCount, (index) {
      final number = firstNumber + index;

      return CardDefinition(
        id: '${id}_${number.toString().padLeft(3, '0')}',
        countryId: id,
        countryName: name,
        countryCode: code,
        countryFlagEmoji: flagEmoji,
        groupName: groupName,
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
    required this.countryCode,
    required this.countryFlagEmoji,
    required this.groupName,
    required this.number,
  });

  final String id;
  final String countryId;
  final String countryName;
  final String countryCode;
  final String countryFlagEmoji;
  final String groupName;
  final int number;
}
