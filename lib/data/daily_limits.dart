enum DailyLimitType { like, dislike, userSearch, communeChange }

class DailyLimitDefinition {
  const DailyLimitDefinition({
    required this.field,
    required this.limit,
    required this.label,
  });

  final String field;
  final int limit;
  final String label;
}

// Edita estos números cuando quieras cambiar los límites.
const int dailyLikeLimit = 3;
const int dailyDislikeLimit = 3;
const int dailyUserSearchLimit = 3;
const int dailyCommuneChangeLimit = 3;

const Map<DailyLimitType, DailyLimitDefinition> dailyLimitDefinitions = {
  DailyLimitType.like: DailyLimitDefinition(
    field: 'likesUsed',
    limit: dailyLikeLimit,
    label: 'Likes',
  ),
  DailyLimitType.dislike: DailyLimitDefinition(
    field: 'dislikesUsed',
    limit: dailyDislikeLimit,
    label: 'Dislikes',
  ),
  DailyLimitType.userSearch: DailyLimitDefinition(
    field: 'userSearchesUsed',
    limit: dailyUserSearchLimit,
    label: 'Búsquedas exactas',
  ),
  DailyLimitType.communeChange: DailyLimitDefinition(
    field: 'communeChangesUsed',
    limit: dailyCommuneChangeLimit,
    label: 'Cambios de comuna',
  ),
};

DailyLimitDefinition dailyLimitDefinitionFor(DailyLimitType type) {
  return dailyLimitDefinitions[type]!;
}

String todayUsageDocId([DateTime? date]) {
  final now = date ?? DateTime.now();

  final year = now.year.toString().padLeft(4, '0');
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}
