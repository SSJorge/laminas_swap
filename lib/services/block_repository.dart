import 'package:cloud_firestore/cloud_firestore.dart';

class BlockRepository {
  BlockRepository(this._db);

  final FirebaseFirestore _db;

  Future<void> blockUser({
    required String blockerUid,
    required String blockedUid,
  }) async {
    if (blockerUid == blockedUid) {
      throw Exception('No puedes bloquearte a ti mismo.');
    }

    final now = FieldValue.serverTimestamp();

    final blockedUserRef = _db
        .collection('users')
        .doc(blockerUid)
        .collection('blockedUsers')
        .doc(blockedUid);

    final myContactShareRef = _db
        .collection('contactShares')
        .doc(blockerUid)
        .collection('allowedViewers')
        .doc(blockedUid);

    final theirContactShareRef = _db
        .collection('contactShares')
        .doc(blockedUid)
        .collection('allowedViewers')
        .doc(blockerUid);

    final batch = _db.batch();

    batch.set(blockedUserRef, {
      'blockedUid': blockedUid,
      'createdAt': now,
    }, SetOptions(merge: true));

    // Si yo le había mostrado mi contacto, se lo quito.
    batch.delete(myContactShareRef);

    // Opcional pero recomendable: si esa persona me había mostrado su contacto,
    // también dejo de verlo desde la app.
    batch.delete(theirContactShareRef);

    await batch.commit();
  }

  Future<void> unblockUser({
    required String blockerUid,
    required String blockedUid,
  }) async {
    final blockedUserRef = _db
        .collection('users')
        .doc(blockerUid)
        .collection('blockedUsers')
        .doc(blockedUid);

    await blockedUserRef.delete();
  }

  Future<Set<String>> getBlockedUserIds(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('blockedUsers')
        .get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  Future<bool> hasBlocked({
    required String blockerUid,
    required String blockedUid,
  }) async {
    final doc = await _db
        .collection('users')
        .doc(blockerUid)
        .collection('blockedUsers')
        .doc(blockedUid)
        .get();

    return doc.exists;
  }
}
