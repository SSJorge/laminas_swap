enum CardStatus {
  missing(0),
  obtained(1),
  duplicate(2);

  const CardStatus(this.value);

  final int value;

  CardStatus get next {
    return CardStatus.values[(index + 1) % CardStatus.values.length];
  }

  CardStatus get previous {
    return CardStatus.values[(index - 1 + CardStatus.values.length) %
        CardStatus.values.length];
  }

  String get label {
    switch (this) {
      case CardStatus.missing:
        return 'Faltante';
      case CardStatus.obtained:
        return 'Obtenida';
      case CardStatus.duplicate:
        return 'Repetida';
    }
  }

  String get shortLabel {
    switch (this) {
      case CardStatus.missing:
        return 'F';
      case CardStatus.obtained:
        return 'O';
      case CardStatus.duplicate:
        return 'R';
    }
  }

  static CardStatus fromValue(dynamic value) {
    if (value is int && value >= 0 && value <= 2) {
      return CardStatus.values[value];
    }

    return CardStatus.missing;
  }
}
