class MatchCandidate {
  const MatchCandidate({
    required this.uid,
    required this.displayName,
    required this.comuna,
    required this.description,
    required this.contactVisible,
    required this.publicContactType,
    required this.publicContactValue,
    required this.iCanGiveIds,
    required this.theyCanGiveIds,
    required this.lastActiveAt,
  });

  final String uid;
  final String displayName;
  final String comuna;
  final String description;
  final bool contactVisible;
  final String publicContactType;
  final String publicContactValue;
  final List<String> iCanGiveIds;
  final List<String> theyCanGiveIds;
  final DateTime? lastActiveAt;

  int get iCanGiveCount => iCanGiveIds.length;

  int get theyCanGiveCount => theyCanGiveIds.length;

  int get totalMatchCount => iCanGiveCount + theyCanGiveCount;

  bool get hasTwoWayMatch => iCanGiveCount > 0 && theyCanGiveCount > 0;

  bool get hasPublicContact =>
      contactVisible && publicContactValue.trim().isNotEmpty;

  String get contactLabel {
    if (publicContactType == 'phone') {
      return 'Número';
    }

    return 'Correo';
  }

  int get twoWayScore {
    if (!hasTwoWayMatch) {
      return 0;
    }

    return iCanGiveCount < theyCanGiveCount
        ? iCanGiveCount
        : theyCanGiveCount;
  }
}
