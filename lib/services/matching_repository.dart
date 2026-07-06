import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_candidate.dart';
import '../models/confirmed_match.dart';
import '../data/daily_limits.dart';
import '../models/user_entitlements.dart';
import 'block_repository.dart';

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
    final blockRepository = BlockRepository(_db);
    final myBlockedIds = await blockRepository.getBlockedUserIds(uid);

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
      final shouldSkipBecauseOfBlock = await _shouldSkipBecauseOfBlock(
        myUid: uid,
        otherUid: doc.id,
        myBlockedIds: myBlockedIds,
      );

      if (shouldSkipBecauseOfBlock) {
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
    final blockRepository = BlockRepository(_db);
    final myBlockedIds = await blockRepository.getBlockedUserIds(uid);

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
      final shouldSkipBecauseOfBlock = await _shouldSkipBecauseOfBlock(
        myUid: uid,
        otherUid: targetUid,
        myBlockedIds: myBlockedIds,
      );

      if (shouldSkipBecauseOfBlock) {
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

      final myShareDoc = await _db
          .collection('contactShares')
          .doc(uid)
          .collection('allowedViewers')
          .doc(targetUid)
          .get();

      final theirShareDoc = await _db
          .collection('contactShares')
          .doc(targetUid)
          .collection('allowedViewers')
          .doc(uid)
          .get();

      var theirContactType = '';
      var theirContactValue = '';

      if (theirShareDoc.exists) {
        final theirContactDoc = await _db
            .collection('privateContacts')
            .doc(targetUid)
            .get();

        final theirContactData = theirContactDoc.data() ?? <String, dynamic>{};

        theirContactType = _readString(theirContactData['contactType']);
        theirContactValue = _readString(theirContactData['contactValue']);
      }

      confirmedMatches.add(
        ConfirmedMatch(
          candidate: candidate,
          description: _readString(privateData['description']),
          myContactSharedWithThem: myShareDoc.exists,
          theirContactSharedWithMe: theirShareDoc.exists,
          theirContactType: theirContactType,
          theirContactValue: theirContactValue,
        ),
      );
    }

    confirmedMatches.sort((a, b) => _compareMatches(a.candidate, b.candidate));

    return confirmedMatches;
  }
  Future<MatchCandidate> findCandidateByDisplayNameKey({
  required String uid,
  required String displayNameKey,
}) async {
  final cleanKey = displayNameKey.trim().toLowerCase();

  if (cleanKey.isEmpty) {
    throw Exception('El enlace no tiene un nombre de usuario válido.');
  }

  final myProfileDoc = await _db.collection('publicProfiles').doc(uid).get();

  if (!myProfileDoc.exists) {
    throw Exception('Primero completa tu perfil.');
  }

  final myData = myProfileDoc.data() ?? {};
  final myMissingIds = _readStringSet(myData['missingIds']);
  final myDuplicateIds = _readStringSet(myData['duplicateIds']);

  if (myMissingIds.isEmpty && myDuplicateIds.isEmpty) {
    throw Exception(
      'Primero marca algunas láminas para calcular compatibilidad.',
    );
  }

  final targetSnapshot = await _db
      .collection('publicProfiles')
      .where('displayNameKey', isEqualTo: cleanKey)
      .limit(1)
      .get();

  if (targetSnapshot.docs.isEmpty) {
    throw Exception('No encontré ese usuario. Puede que haya cambiado su nombre.');
  }

  final targetDoc = targetSnapshot.docs.first;

  if (targetDoc.id == uid) {
    throw Exception('Este enlace apunta a tu propio perfil.');
  }

  final targetData = targetDoc.data();

  if (targetData['profileVisible'] != true) {
    throw Exception('Este perfil no está visible actualmente.');
  }

  final blockRepository = BlockRepository(_db);
  final myBlockedIds = await blockRepository.getBlockedUserIds(uid);

  final shouldSkipBecauseOfBlock = await _shouldSkipBecauseOfBlock(
    myUid: uid,
    otherUid: targetDoc.id,
    myBlockedIds: myBlockedIds,
  );

  if (shouldSkipBecauseOfBlock) {
    throw Exception('No puedes ver este perfil.');
  }

  final candidate = _buildCandidateFromPublicProfile(
    uid: targetDoc.id,
    data: targetData,
    myMissingIds: myMissingIds,
    myDuplicateIds: myDuplicateIds,
    allowEmpty: true,
  );

  if (candidate == null) {
    throw Exception('No se pudo cargar este perfil.');
  }

  return candidate;
}

  MatchCandidate? _buildCandidateFromPublicProfile({
  required String uid,
  required Map<String, dynamic> data,
  required Set<String> myMissingIds,
  required Set<String> myDuplicateIds,
  bool allowEmpty = false,
}) {
    final otherMissingIds = _readStringSet(data['missingIds']);
    final otherDuplicateIds = _readStringSet(data['duplicateIds']);

    final iCanGiveIds = myDuplicateIds.intersection(otherMissingIds).toList();
    final theyCanGiveIds = otherDuplicateIds
        .intersection(myMissingIds)
        .toList();

    iCanGiveIds.sort();
    theyCanGiveIds.sort();

    if (!allowEmpty && iCanGiveIds.isEmpty && theyCanGiveIds.isEmpty) {
  return null;
}

    final displayName = _readString(data['displayName']);

    return MatchCandidate(
      uid: uid,
      displayName: displayName.isEmpty ? 'Usuario' : displayName,
      comuna: _readString(data['comuna']),
      publicDescription: _readString(data['publicDescription']),
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

    // final myComunaKey = _effectiveComunaKey(myData);
    final myRegionKey = _effectiveRegionKey(myData);
    final myMissingIds = _readStringSet(myData['missingIds']);
    final myDuplicateIds = _readStringSet(myData['duplicateIds']);
    final blockRepository = BlockRepository(_db);
    final myBlockedIds = await blockRepository.getBlockedUserIds(uid);

    if (myRegionKey.isEmpty) {
      throw Exception('Primero guarda tu región en Mi perfil.');
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
      final shouldSkipBecauseOfBlock = await _shouldSkipBecauseOfBlock(
        myUid: uid,
        otherUid: doc.id,
        myBlockedIds: myBlockedIds,
      );

      if (shouldSkipBecauseOfBlock) {
        continue;
      }

      final data = doc.data();
      // final otherComunaKey = _effectiveComunaKey(data);

      // if (otherComunaKey.isEmpty || otherComunaKey != myComunaKey) {
      //   continue;
      // }
      final otherRegionKey = _effectiveRegionKey(data);

      if (otherRegionKey.isEmpty || otherRegionKey != myRegionKey) {
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
          publicDescription: _readString(data['publicDescription']),
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

  Future<void> shareMyContactWith({
    required String ownerUid,
    required String viewerUid,
  }) async {
    if (ownerUid == viewerUid) {
      throw Exception('No puedes compartir contacto contigo mismo.');
    }

    final now = FieldValue.serverTimestamp();

    final shareRef = _db
        .collection('contactShares')
        .doc(ownerUid)
        .collection('allowedViewers')
        .doc(viewerUid);

    await shareRef.set({
      'ownerUid': ownerUid,
      'viewerUid': viewerUid,
      'createdAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> hideMyContactFrom({
    required String ownerUid,
    required String viewerUid,
  }) async {
    if (ownerUid == viewerUid) {
      throw Exception('No puedes ocultarte contacto a ti mismo.');
    }

    final shareRef = _db
        .collection('contactShares')
        .doc(ownerUid)
        .collection('allowedViewers')
        .doc(viewerUid);

    await shareRef.delete();
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

  String _effectiveRegionKey(Map<String, dynamic> data) {
    final regionKey = _readString(data['regionKey']);

    if (regionKey.isNotEmpty) {
      return regionKey;
    }

    return _normalizeComuna(_readString(data['region']));
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

  Future<bool> _shouldSkipBecauseOfBlock({
    required String myUid,
    required String otherUid,
    required Set<String> myBlockedIds,
  }) async {
    if (myBlockedIds.contains(otherUid)) {
      return true;
    }

    final blockRepository = BlockRepository(_db);

    final theyBlockedMe = await blockRepository.hasBlocked(
      blockerUid: otherUid,
      blockedUid: myUid,
    );

    return theyBlockedMe;
  }
}
