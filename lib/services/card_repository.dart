import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/album_catalog.dart';
import '../models/album_country.dart';
import '../models/card_status.dart';

class CardRepository {
  CardRepository(this._db);

  final FirebaseFirestore _db;

  Stream<Map<String, CardStatus>> watchMyCardStatuses(String uid) {
    return _db.collection('users').doc(uid).collection('cards').snapshots().map(
      (snapshot) {
        final statuses = <String, CardStatus>{};

        for (final doc in snapshot.docs) {
          final data = doc.data();
          statuses[doc.id] = CardStatus.fromValue(data['status']);
        }

        return statuses;
      },
    );
  }

  Future<void> setCardStatus({
    required String uid,
    required CardDefinition card,
    required CardStatus status,
    required Map<String, CardStatus> currentStatuses,
  }) async {
    final updatedStatuses = Map<String, CardStatus>.from(currentStatuses);
    updatedStatuses[card.id] = status;

    final summary = _buildSummary(updatedStatuses);
    final now = FieldValue.serverTimestamp();

    final batch = _db.batch();

    final cardRef = _db
        .collection('users')
        .doc(uid)
        .collection('cards')
        .doc(card.id);

    batch.set(cardRef, {
      'cardId': card.id,
      'countryId': card.countryId,
      'number': card.number,
      'status': status.value,
      'updatedAt': now,
    }, SetOptions(merge: true));

    final userRef = _db.collection('users').doc(uid);

    batch.set(userRef, {
      'lastActiveAt': now,
      'stats': {
        'totalCards': allCardDefinitions.length,
        'missingCount': summary.missingIds.length,
        'obtainedCount': summary.obtainedCount,
        'duplicateCount': summary.duplicateIds.length,
      },
    }, SetOptions(merge: true));

    final publicProfileRef = _db.collection('publicProfiles').doc(uid);

    batch.set(publicProfileRef, {
      'missingIds': summary.missingIds,
      'duplicateIds': summary.duplicateIds,
      'lastActiveAt': now,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> shiftCountryStatuses({
    required String uid,
    required AlbumCountry country,
    required int direction,
    required Map<String, CardStatus> currentStatuses,
  }) async {
    final updatedStatuses = Map<String, CardStatus>.from(currentStatuses);
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();

    for (final card in country.cards) {
      final currentStatus = updatedStatuses[card.id] ?? CardStatus.missing;
      final nextStatus = direction > 0
          ? currentStatus.next
          : currentStatus.previous;

      updatedStatuses[card.id] = nextStatus;

      final cardRef = _db
          .collection('users')
          .doc(uid)
          .collection('cards')
          .doc(card.id);

      batch.set(cardRef, {
        'cardId': card.id,
        'countryId': card.countryId,
        'number': card.number,
        'status': nextStatus.value,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }

    final summary = _buildSummary(updatedStatuses);

    final userRef = _db.collection('users').doc(uid);

    batch.set(userRef, {
      'lastActiveAt': now,
      'stats': {
        'totalCards': allCardDefinitions.length,
        'missingCount': summary.missingIds.length,
        'obtainedCount': summary.obtainedCount,
        'duplicateCount': summary.duplicateIds.length,
      },
    }, SetOptions(merge: true));

    final publicProfileRef = _db.collection('publicProfiles').doc(uid);

    batch.set(publicProfileRef, {
      'missingIds': summary.missingIds,
      'duplicateIds': summary.duplicateIds,
      'lastActiveAt': now,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  _CardsSummary _buildSummary(Map<String, CardStatus> statuses) {
    final missingIds = <String>[];
    final duplicateIds = <String>[];
    var obtainedCount = 0;

    for (final card in allCardDefinitions) {
      final status = statuses[card.id] ?? CardStatus.missing;

      switch (status) {
        case CardStatus.missing:
          missingIds.add(card.id);
          break;
        case CardStatus.obtained:
          obtainedCount++;
          break;
        case CardStatus.duplicate:
          duplicateIds.add(card.id);
          break;
      }
    }

    return _CardsSummary(
      missingIds: missingIds,
      duplicateIds: duplicateIds,
      obtainedCount: obtainedCount,
    );
  }
}

class _CardsSummary {
  const _CardsSummary({
    required this.missingIds,
    required this.duplicateIds,
    required this.obtainedCount,
  });

  final List<String> missingIds;
  final List<String> duplicateIds;
  final int obtainedCount;
}
