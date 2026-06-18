import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_candidate.dart';

class MatchingRepository {
  MatchingRepository(this._db);

  final FirebaseFirestore _db;

  Future<List<MatchCandidate>> findMatches({
    required String uid,
    int limit = 100,
  }) async {
    final myProfileDoc = await _db.collection('publicProfiles').doc(uid).get();

    if (!myProfileDoc.exists) {
      throw Exception('Primero completa tu perfil público.');
    }

    final myData = myProfileDoc.data() ?? <String, dynamic>{};

    final myComunaKey = _effectiveComunaKey(myData);
    final myMissingIds = _readStringSet(myData['missingIds']);
    final myDuplicateIds = _readStringSet(myData['duplicateIds']);

    if (myComunaKey.isEmpty) {
      throw Exception('Primero guarda tu comuna en Mi perfil.');
    }

    if (myMissingIds.isEmpty && myDuplicateIds.isEmpty) {
      throw Exception(
        'Primero marca algunas láminas para generar tus faltantes y repetidas.',
      );
    }

    final snapshot = await _db
        .collection('publicProfiles')
        .where('profileVisible', isEqualTo: true)
        .limit(limit)
        .get();

    final matches = <MatchCandidate>[];

    for (final doc in snapshot.docs) {
      if (doc.id == uid) {
        continue;
      }

      final data = doc.data();

      final otherComunaKey = _effectiveComunaKey(data);

      if (otherComunaKey.isEmpty || otherComunaKey != myComunaKey) {
        continue;
      }

      final otherMissingIds = _readStringSet(data['missingIds']);
      final otherDuplicateIds = _readStringSet(data['duplicateIds']);

      final iCanGiveIds = myDuplicateIds.intersection(otherMissingIds).toList();

      final theyCanGiveIds = otherDuplicateIds
          .intersection(myMissingIds)
          .toList();

      if (iCanGiveIds.isEmpty && theyCanGiveIds.isEmpty) {
        continue;
      }

      matches.add(
        MatchCandidate(
          uid: doc.id,
          displayName: _readString(data['displayName']).isEmpty
              ? 'Usuario'
              : _readString(data['displayName']),
          comuna: _readString(data['comuna']),
          iCanGiveIds: iCanGiveIds,
          theyCanGiveIds: theyCanGiveIds,
          lastActiveAt: _readDateTime(data['lastActiveAt']),
        ),
      );
    }

    matches.sort(_compareMatches);

    return matches;
  }

  int _compareMatches(MatchCandidate a, MatchCandidate b) {
    final byTwoWay = _boolAsInt(
      b.hasTwoWayMatch,
    ).compareTo(_boolAsInt(a.hasTwoWayMatch));

    if (byTwoWay != 0) {
      return byTwoWay;
    }

    final byTwoWayScore = b.twoWayScore.compareTo(a.twoWayScore);

    if (byTwoWayScore != 0) {
      return byTwoWayScore;
    }

    final byTotal = b.totalMatchCount.compareTo(a.totalMatchCount);

    if (byTotal != 0) {
      return byTotal;
    }

    final byTheyCanGive = b.theyCanGiveCount.compareTo(a.theyCanGiveCount);

    if (byTheyCanGive != 0) {
      return byTheyCanGive;
    }

    final aTime = a.lastActiveAt?.millisecondsSinceEpoch ?? 0;
    final bTime = b.lastActiveAt?.millisecondsSinceEpoch ?? 0;

    return bTime.compareTo(aTime);
  }

  int _boolAsInt(bool value) {
    return value ? 1 : 0;
  }

  Set<String> _readStringSet(dynamic value) {
    if (value is Iterable) {
      return value.whereType<String>().toSet();
    }

    return <String>{};
  }

  String _readString(dynamic value) {
    if (value is String) {
      return value.trim();
    }

    return '';
  }

  DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }

  String _effectiveComunaKey(Map<String, dynamic> data) {
    final comunaKey = _readString(data['comunaKey']);

    if (comunaKey.isNotEmpty) {
      return comunaKey;
    }

    return _normalizeComuna(_readString(data['comuna']));
  }

  String _normalizeComuna(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
