import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_candidate.dart';
import '../models/confirmed_match.dart';
import '../data/daily_limits.dart';
import '../models/user_entitlements.dart';

class MatchingRepository {
  MatchingRepository(this._db);

  final FirebaseFirestore _db;

  Future<List<MatchCandidate>> findReceivedLikes({
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

    final publicProfilesSnapshot = await _db
        .collection('publicProfiles')
        .where('profileVisible', isEqualTo: true)
        .limit(limit)
        .get();

    final receivedLikes = <MatchCandidate>[];

    for (final doc in publicProfilesSnapshot.docs) {
      if (doc.id == uid) {
        continue;
      }

      final myActionDoc = await _db
          .collection('users')
          .doc(uid)
          .collection('actions')
          .doc(doc.id)
          .get();

      if (myActionDoc.exists) {
        continue;
      }

      final theirActionDoc = await _db
          .collection('users')
          .doc(doc.id)
          .collection('actions')
          .doc(uid)
          .get();

      final theirAction = theirActionDoc.data()?['action'];

      if (theirAction != 'like') {
        continue;
      }

      final data = doc.data();
      final otherComunaKey = _effectiveComunaKey(data);

      if (otherComunaKey.isEmpty || otherComunaKey != myComunaKey) {
        continue;
      }

      final candidate = _buildCandidateFromPublicProfile(
        uid: doc.id,
        data: data,
        myMissingIds: myMissingIds,
        myDuplicateIds: myDuplicateIds,
      );

      if (candidate != null) {
        receivedLikes.add(candidate);
      }
    }

    receivedLikes.sort(_compareMatches);

    return receivedLikes;
  }

  Future<List<ConfirmedMatch>> findConfirmedMatches({
    required String uid,
    int limit = 100,
  }) async {
    final myProfileDoc = await _db.collection('publicProfiles').doc(uid).get();

    if (!myProfileDoc.exists) {
      throw Exception('Primero completa tu perfil público.');
    }

    final myData = myProfileDoc.data() ?? <String, dynamic>{};
    final myMissingIds = _readStringSet(myData['missingIds']);
    final myDuplicateIds = _readStringSet(myData['duplicateIds']);

    final myLikesSnapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('actions')
        .where('action', isEqualTo: 'like')
        .limit(limit)
        .get();

    final confirmedMatches = <ConfirmedMatch>[];

    for (final myLikeDoc in myLikesSnapshot.docs) {
      final targetUid = myLikeDoc.id;

      if (targetUid == uid) {
        continue;
      }

      final theirActionDoc = await _db
          .collection('users')
          .doc(targetUid)
          .collection('actions')
          .doc(uid)
          .get();

      final theirAction = theirActionDoc.data()?['action'];

      if (theirAction != 'like') {
        continue;
      }

      final publicProfileDoc = await _db
          .collection('publicProfiles')
          .doc(targetUid)
          .get();

      if (!publicProfileDoc.exists) {
        continue;
      }

      final publicData = publicProfileDoc.data() ?? <String, dynamic>{};

      final candidate = _buildCandidateFromPublicProfile(
        uid: targetUid,
        data: publicData,
        myMissingIds: myMissingIds,
        myDuplicateIds: myDuplicateIds,
      );

      if (candidate == null) {
        continue;
      }

      final privateProfileDoc = await _db
          .collection('privateProfiles')
          .doc(targetUid)
          .get();

      final privateData = privateProfileDoc.data() ?? <String, dynamic>{};

      confirmedMatches.add(
        ConfirmedMatch(
          candidate: candidate,
          description: _readString(privateData['description']),
          contactType: _readString(privateData['contactType']),
          contactValue: _readString(privateData['contactValue']),
          contactVisible: privateData['contactVisible'] == true,
        ),
      );
    }

    confirmedMatches.sort((a, b) => _compareMatches(a.candidate, b.candidate));

    return confirmedMatches;
  }

  MatchCandidate? _buildCandidateFromPublicProfile({
    required String uid,
    required Map<String, dynamic> data,
    required Set<String> myMissingIds,
    required Set<String> myDuplicateIds,
  }) {
    final otherMissingIds = _readStringSet(data['missingIds']);
    final otherDuplicateIds = _readStringSet(data['duplicateIds']);

    final iCanGiveIds = myDuplicateIds.intersection(otherMissingIds).toList();
    final theyCanGiveIds = otherDuplicateIds
        .intersection(myMissingIds)
        .toList();

    iCanGiveIds.sort();
    theyCanGiveIds.sort();

    if (iCanGiveIds.isEmpty && theyCanGiveIds.isEmpty) {
      return null;
    }

    final displayName = _readString(data['displayName']);

    return MatchCandidate(
      uid: uid,
      displayName: displayName.isEmpty ? 'Usuario' : displayName,
      comuna: _readString(data['comuna']),
      iCanGiveIds: iCanGiveIds,
      theyCanGiveIds: theyCanGiveIds,
      lastActiveAt: _readDateTime(data['lastActiveAt']),
    );
  }

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
    final myActionsSnapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('actions')
        .get();

    final actedTargetIds = myActionsSnapshot.docs.map((doc) => doc.id).toSet();

    for (final doc in snapshot.docs) {
      if (doc.id == uid || actedTargetIds.contains(doc.id)) {
        continue;
      }
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

  Future<void> setAction({
    required String fromUid,
    required String targetUid,
    required String action,
  }) async {
    if (fromUid == targetUid) {
      throw Exception('No puedes reaccionar a tu propio perfil.');
    }

    if (action != 'like' && action != 'dislike') {
      throw ArgumentError('La acción debe ser like o dislike.');
    }

    final quotaType = action == 'like'
        ? DailyLimitType.like
        : DailyLimitType.dislike;

    final quotaDefinition = dailyLimitDefinitionFor(quotaType);

    final entitlementsDoc = await _db
        .collection('userEntitlements')
        .doc(fromUid)
        .get();

    final entitlements = UserEntitlements.fromMap(entitlementsDoc.data());
    final quotaLimit = quotaDefinition.limitFor(entitlements);

    final dayKey = todayUsageDocId();
    final now = FieldValue.serverTimestamp();

    final actionRef = _db
        .collection('users')
        .doc(fromUid)
        .collection('actions')
        .doc(targetUid);

    final usageRef = _db
        .collection('users')
        .doc(fromUid)
        .collection('dailyUsage')
        .doc(dayKey);

    final existingActionDoc = await actionRef.get();

    if (existingActionDoc.exists) {
      throw Exception('Ya respondiste a este perfil.');
    }

    final usageDoc = await usageRef.get();
    final used = _readInt(usageDoc.data()?[quotaDefinition.field]);

    if (used >= quotaLimit) {
      throw Exception(
        'Ya usaste tus ${quotaDefinition.label.toLowerCase()} de hoy.',
      );
    }

    await _db.runTransaction((transaction) async {
      final freshActionDoc = await transaction.get(actionRef);
      final freshUsageDoc = await transaction.get(usageRef);

      if (freshActionDoc.exists) {
        return;
      }

      final freshUsed = _readInt(freshUsageDoc.data()?[quotaDefinition.field]);

      if (freshUsed >= quotaLimit) {
        return;
      }
      //duda

      transaction.set(usageRef, {
        'dayKey': dayKey,
        quotaDefinition.field: freshUsed + 1,
        'updatedAt': now,
      }, SetOptions(merge: true));

      transaction.set(actionRef, {
        'fromUid': fromUid,
        'targetUid': targetUid,
        'action': action,
        'createdAt': now,
        'updatedAt': now,
      });
    });
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

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }
}
