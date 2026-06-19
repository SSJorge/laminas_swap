import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/daily_limits.dart';

class DailyUsage {
  const DailyUsage({required this.dayKey, required this.usedByField});

  final String dayKey;
  final Map<String, int> usedByField;

  int used(DailyLimitType type) {
    final definition = dailyLimitDefinitionFor(type);
    return usedByField[definition.field] ?? 0;
  }

  int limit(DailyLimitType type) {
    return dailyLimitDefinitionFor(type).limit;
  }

  int remaining(DailyLimitType type) {
    final remainingCount = limit(type) - used(type);
    return remainingCount < 0 ? 0 : remainingCount;
  }

  factory DailyUsage.empty(String dayKey) {
    return DailyUsage(dayKey: dayKey, usedByField: const {});
  }

  factory DailyUsage.fromMap({
    required String dayKey,
    required Map<String, dynamic>? data,
  }) {
    final usedByField = <String, int>{};

    if (data != null) {
      for (final definition in dailyLimitDefinitions.values) {
        usedByField[definition.field] = _readInt(data[definition.field]);
      }
    }

    return DailyUsage(dayKey: dayKey, usedByField: usedByField);
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }
}

class DailyQuotaRepository {
  DailyQuotaRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _todayRef(String uid) {
    final dayKey = todayUsageDocId();

    return _db
        .collection('users')
        .doc(uid)
        .collection('dailyUsage')
        .doc(dayKey);
  }

  Stream<DailyUsage> watchToday(String uid) {
    final dayKey = todayUsageDocId();

    return _todayRef(uid).snapshots().map((snapshot) {
      return DailyUsage.fromMap(dayKey: dayKey, data: snapshot.data());
    });
  }

  Future<void> consume({
    required String uid,
    required DailyLimitType type,
  }) async {
    final definition = dailyLimitDefinitionFor(type);
    final dayKey = todayUsageDocId();
    final usageRef = _todayRef(uid);
    final now = FieldValue.serverTimestamp();

    await _db.runTransaction((transaction) async {
      final usageDoc = await transaction.get(usageRef);
      final data = usageDoc.data();

      final used = DailyUsage.fromMap(dayKey: dayKey, data: data).used(type);

      if (used >= definition.limit) {
        throw Exception(
          'Ya usaste tus ${definition.label.toLowerCase()} de hoy.',
        );
      }

      transaction.set(usageRef, {
        'dayKey': dayKey,
        definition.field: used + 1,
        'updatedAt': now,
      }, SetOptions(merge: true));
    });
  }
}
