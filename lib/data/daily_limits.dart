import '../models/user_entitlements.dart';

enum DailyLimitType { like, dislike, userSearch, communeChange }

class DailyLimitDefinition {
  const DailyLimitDefinition({
    required this.field,
    required this.freeBaseLimit,
    required this.rewardedAdExtraLimit,
    required this.premiumLimit,
    required this.label,
  });

  final String field;
  final int freeBaseLimit;
  final int rewardedAdExtraLimit;
  final int premiumLimit;
  final String label;

  int limitFor(UserEntitlements entitlements) {
    if (entitlements.premiumEnabled) {
      return premiumLimit;
    }

    if (entitlements.adsRemoved) {
      return freeBaseLimit + rewardedAdExtraLimit;
    }

    return freeBaseLimit;
  }

  int get freeLimitWithRewardedAds {
    return freeBaseLimit + rewardedAdExtraLimit;
  }
}

// Edita estos números cuando quieras cambiar los límites.
const Map<DailyLimitType, DailyLimitDefinition> dailyLimitDefinitions = {
  DailyLimitType.like: DailyLimitDefinition(
    field: 'likesUsed',
    freeBaseLimit: 20,
    rewardedAdExtraLimit: 10,
    premiumLimit: 40,
    label: 'Likes',
  ),
  DailyLimitType.dislike: DailyLimitDefinition(
    field: 'dislikesUsed',
    freeBaseLimit: 100,
    rewardedAdExtraLimit: 20,
    premiumLimit: 200,
    label: 'Dislikes',
  ),
  DailyLimitType.userSearch: DailyLimitDefinition(
    field: 'userSearchesUsed',
    freeBaseLimit: 50,
    rewardedAdExtraLimit: 3,
    premiumLimit: 100,
    label: 'Búsquedas exactas',
  ),
  DailyLimitType.communeChange: DailyLimitDefinition(
    field: 'communeChangesUsed',
    freeBaseLimit: 20,
    rewardedAdExtraLimit: 10,
    premiumLimit: 40,
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
