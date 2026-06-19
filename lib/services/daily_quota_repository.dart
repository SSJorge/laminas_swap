import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/daily_limits.dart';
import '../models/user_entitlements.dart';

class DailyUsage {
  const DailyUsage({
    required this.dayKey,
    required this.usedByField,
    required this.entitlements,
  });

  final String dayKey;
  final Map<String, int> usedByField;
  final UserEntitlements entitlements;

  int used(DailyLimitType type) {
    final definition = dailyLimitDefinitionFor(type);
    return usedByField[definition.field] ?? 0;
  }

  int limit(DailyLimitType type) {
    return dailyLimitDefinitionFor(type).limitFor(entitlements);
  }

  int remaining(DailyLimitType type) {
    final remainingCount = limit(type) - used(type);
    return remainingCount < 0 ? 0 : remainingCount;
  }

  factory DailyUsage.empty(String dayKey) {
    return DailyUsage(
      dayKey: dayKey,
      usedByField: const {},
      entitlements: UserEntitlements.free(),
    );
  }

  factory DailyUsage.fromMap({
    required String dayKey,
    required Map<String, dynamic>? data,
    required UserEntitlements entitlements,
  }) {
    final usedByField = <String, int>{};

    if (data != null) {
      for (final definition in dailyLimitDefinitions.values) {
        usedByField[definition.field] = _readInt(data[definition.field]);
      }
    }

    return DailyUsage(
      dayKey: dayKey,
      usedByField: usedByField,
      entitlements: entitlements,
    );
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

  DocumentReference<Map<String, dynamic>> _entitlementsRef(String uid) {
    return _db.collection('userEntitlements').doc(uid);
  }

  Stream<UserEntitlements> watchEntitlements(String uid) {
    return _entitlementsRef(uid).snapshots().map((snapshot) {
      return UserEntitlements.fromMap(snapshot.data());
    });
  }

  Future<UserEntitlements> readEntitlements(String uid) async {
    final snapshot = await _entitlementsRef(uid).get();

    return UserEntitlements.fromMap(snapshot.data());
  }

  Stream<DailyUsage> watchToday(String uid) {
    final dayKey = todayUsageDocId();

    return _todayRef(uid).snapshots().asyncMap((snapshot) async {
      final entitlements = await readEntitlements(uid);

      return DailyUsage.fromMap(
        dayKey: dayKey,
        data: snapshot.data(),
        entitlements: entitlements,
      );
    });
  }

  Future<void> consume({
    required String uid,
    required DailyLimitType type,
  }) async {
    final definition = dailyLimitDefinitionFor(type);
    final entitlements = await readEntitlements(uid);
    final limit = definition.limitFor(entitlements);

    final dayKey = todayUsageDocId();
    final usageRef = _todayRef(uid);
    final now = FieldValue.serverTimestamp();

    final usageDoc = await usageRef.get();
    final used = DailyUsage.fromMap(
      dayKey: dayKey,
      data: usageDoc.data(),
      entitlements: entitlements,
    ).used(type);

    if (used >= limit) {
      throw Exception(
        'Ya usaste tus ${definition.label.toLowerCase()} de hoy.',
      );
    }

    var consumed = false;

    await _db.runTransaction((transaction) async {
      final freshUsageDoc = await transaction.get(usageRef);

      final freshUsed = DailyUsage.fromMap(
        dayKey: dayKey,
        data: freshUsageDoc.data(),
        entitlements: entitlements,
      ).used(type);

      if (freshUsed >= limit) {
        return;
      }

      transaction.set(usageRef, {
        'dayKey': dayKey,
        definition.field: freshUsed + 1,
        'updatedAt': now,
      }, SetOptions(merge: true));

      consumed = true;
    });

    if (!consumed) {
      throw Exception(
        'Ya usaste tus ${definition.label.toLowerCase()} de hoy.',
      );
    }
  }
}
