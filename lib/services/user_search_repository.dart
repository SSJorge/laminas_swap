import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_candidate.dart';
import '../utils/display_name_utils.dart';
import 'block_repository.dart';

class UserSearchRepository {
  UserSearchRepository(this._db);

  final FirebaseFirestore _db;

  Future<MatchCandidate> findCandidateByDisplayName({
    required String myUid,
    required String displayName,
  }) async {
    final cleanName = validateDisplayName(displayName);
    final key = displayNameKeyFrom(cleanName);

    final usernameDoc = await _db.collection('usernames').doc(key).get();

    if (!usernameDoc.exists) {
      throw Exception('No se encontró un usuario visible con ese nombre.');
    }

    final targetUid = usernameDoc.data()?['uid'] as String?;

    if (targetUid == null || targetUid.isEmpty) {
      throw Exception('El usuario encontrado no es válido.');
    }

    if (targetUid == myUid) {
      throw Exception('No puedes buscarte a ti mismo.');
    }
    final blockRepository = BlockRepository(_db);

    final iBlockedThem = await blockRepository.hasBlocked(
      blockerUid: myUid,
      blockedUid: targetUid,
    );

    if (iBlockedThem) {
      throw Exception('No se encontró un usuario visible con ese nombre.');
    }

    final theyBlockedMe = await blockRepository.hasBlocked(
      blockerUid: targetUid,
      blockedUid: myUid,
    );

    if (theyBlockedMe) {
      throw Exception('No se encontró un usuario visible con ese nombre.');
    }

    final myProfileDoc = await _db
        .collection('publicProfiles')
        .doc(myUid)
        .get();

    final targetProfileDoc = await _db
        .collection('publicProfiles')
        .doc(targetUid)
        .get();

    if (!myProfileDoc.exists || !targetProfileDoc.exists) {
      throw Exception(
        'Falta información pública para calcular compatibilidad.',
      );
    }

    final myData = myProfileDoc.data() ?? <String, dynamic>{};
    final targetData = targetProfileDoc.data() ?? <String, dynamic>{};

    if (targetData['profileVisible'] != true) {
      throw Exception('No se encontró un usuario visible con ese nombre.');
    }

    final myMissingIds = _readStringSet(myData['missingIds']);
    final myDuplicateIds = _readStringSet(myData['duplicateIds']);

    final targetMissingIds = _readStringSet(targetData['missingIds']);
    final targetDuplicateIds = _readStringSet(targetData['duplicateIds']);

    final iCanGiveIds = myDuplicateIds.intersection(targetMissingIds).toList();
    final theyCanGiveIds = targetDuplicateIds
        .intersection(myMissingIds)
        .toList();

    iCanGiveIds.sort();
    theyCanGiveIds.sort();

    final targetDisplayName = _readString(targetData['displayName']);

    return MatchCandidate(
      uid: targetUid,
      displayName: targetDisplayName.isEmpty ? cleanName : targetDisplayName,
      comuna: _readString(targetData['comuna']),
      //cambio mio
      publicDescription: _readString(targetData['publicDescription']),
      iCanGiveIds: iCanGiveIds,
      theyCanGiveIds: theyCanGiveIds,
      lastActiveAt: _readDateTime(targetData['lastActiveAt']),
    );
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
}
