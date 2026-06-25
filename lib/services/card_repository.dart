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
    final currentStatus = currentStatuses[card.id] ?? CardStatus.missing;

    if (currentStatus == status) {
      return;
    }

    final updatedStatuses = Map<String, CardStatus>.from(currentStatuses);
    updatedStatuses[card.id] = status;

    final summary = _buildSummary(updatedStatuses);
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();

    _writeCardStatus(
      batch: batch,
      uid: uid,
      card: card,
      status: status,
      now: now,
    );

    _writeUserSummary(batch: batch, uid: uid, summary: summary, now: now);

    _writePublicProfileSummary(
      batch: batch,
      uid: uid,
      summary: summary,
      now: now,
    );

    await batch.commit();
  }

  Future<void> shiftCountryStatuses({
    required String uid,
    required AlbumCountry country,
    required int direction,
    required Map<String, CardStatus> currentStatuses,
  }) {
    return shiftCountriesStatuses(
      uid: uid,
      countries: [country],
      direction: direction,
      currentStatuses: currentStatuses,
    );
  }

  Future<void> shiftCountriesStatuses({
    required String uid,
    required List<AlbumCountry> countries,
    required int direction,
    required Map<String, CardStatus> currentStatuses,
  }) async {
    if (direction != 1 && direction != -1) {
      throw ArgumentError('direction debe ser 1 o -1.');
    }

    final cards = countries.expand((country) => country.cards).toList();

    if (cards.isEmpty) {
      return;
    }

    final updatedStatuses = Map<String, CardStatus>.from(currentStatuses);
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();

    for (final card in cards) {
      final currentStatus = updatedStatuses[card.id] ?? CardStatus.missing;
      final newStatus = direction == 1
          ? currentStatus.next
          : currentStatus.previous;

      updatedStatuses[card.id] = newStatus;

      _writeCardStatus(
        batch: batch,
        uid: uid,
        card: card,
        status: newStatus,
        now: now,
      );
    }

    final summary = _buildSummary(updatedStatuses);

    _writeUserSummary(batch: batch, uid: uid, summary: summary, now: now);

    _writePublicProfileSummary(
      batch: batch,
      uid: uid,
      summary: summary,
      now: now,
    );

    await batch.commit();
  }

  void _writeCardStatus({
    required WriteBatch batch,
    required String uid,
    required CardDefinition card,
    required CardStatus status,
    required FieldValue now,
  }) {
    final cardRef = _db
        .collection('users')
        .doc(uid)
        .collection('cards')
        .doc(card.id);

    if (status == CardStatus.missing) {
      batch.delete(cardRef);
      return;
    }

    batch.set(cardRef, {
      'cardId': card.id,
      'countryId': card.countryId,
      'number': card.number,
      'status': status.value,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  void _writeUserSummary({
    required WriteBatch batch,
    required String uid,
    required _CardsSummary summary,
    required FieldValue now,
  }) {
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
  }

  void _writePublicProfileSummary({
    required WriteBatch batch,
    required String uid,
    required _CardsSummary summary,
    required FieldValue now,
  }) {
    final publicProfileRef = _db.collection('publicProfiles').doc(uid);

    batch.set(publicProfileRef, {
      'missingIds': summary.missingIds,
      'duplicateIds': summary.duplicateIds,
      'lastActiveAt': now,
    }, SetOptions(merge: true));
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
