class MatchCandidate {
  const MatchCandidate({
    required this.uid,
    required this.displayName,
    required this.comuna,
    required this.publicDescription,
    required this.iCanGiveIds,
    required this.theyCanGiveIds,
    required this.lastActiveAt,
  });

  final String uid;
  final String displayName;
  final String comuna;
  final String publicDescription;
  final List<String> iCanGiveIds;
  final List<String> theyCanGiveIds;
  final DateTime? lastActiveAt;

  int get iCanGiveCount => iCanGiveIds.length;
  int get theyCanGiveCount => theyCanGiveIds.length;
  int get totalMatchCount => iCanGiveCount + theyCanGiveCount;
  bool get hasTwoWayMatch => iCanGiveCount > 0 && theyCanGiveCount > 0;
  bool get hasPublicDescription => publicDescription.trim().isNotEmpty;

  int get twoWayScore {
    if (!hasTwoWayMatch) {
      return 0;
    }
    return iCanGiveCount < theyCanGiveCount ? iCanGiveCount : theyCanGiveCount;
  }
}
