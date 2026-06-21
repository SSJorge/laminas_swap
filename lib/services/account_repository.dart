import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountRepository {
  AccountRepository({required FirebaseFirestore db, required FirebaseAuth auth})
    : _db = db,
      _auth = auth;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<void> deleteCurrentAccount({required String password}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No hay usuario autenticado.');
    }

    final email = user.email;

    if (email == null || email.trim().isEmpty) {
      throw Exception('Tu cuenta no tiene email asociado.');
    }

    final cleanPassword = password.trim();

    if (cleanPassword.isEmpty) {
      throw Exception('Ingresa tu contraseña para confirmar.');
    }

    // Reautenticación antes de borrar datos.
    final credential = EmailAuthProvider.credential(
      email: email,
      password: cleanPassword,
    );

    await user.reauthenticateWithCredential(credential);

    final uid = user.uid;

    await _deleteUserFirestoreData(uid: uid);

    await user.delete();
  }

  Future<void> _deleteUserFirestoreData({required String uid}) async {
    final userRef = _db.collection('users').doc(uid);
    final userDoc = await userRef.get();
    final userData = userDoc.data();

    final displayNameKey = userData?['displayNameKey'];

    await _deleteCollection(userRef.collection('cards'));

    await _deleteCollection(userRef.collection('actions'));

    await _deleteCollection(userRef.collection('dailyUsage'));

    await _deleteCollection(userRef.collection('blockedUsers'));

    await _deleteCollection(
      _db.collection('contactShares').doc(uid).collection('allowedViewers'),
    );

    final batch = _db.batch();

    batch.delete(userRef);
    batch.delete(_db.collection('publicProfiles').doc(uid));
    batch.delete(_db.collection('privateProfiles').doc(uid));
    batch.delete(_db.collection('privateContacts').doc(uid));
    batch.delete(_db.collection('contactShares').doc(uid));
    batch.delete(_db.collection('userEntitlements').doc(uid));

    if (displayNameKey is String && displayNameKey.trim().isNotEmpty) {
      batch.delete(_db.collection('usernames').doc(displayNameKey));
    }

    await batch.commit();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection, {
    int batchSize = 100,
  }) async {
    while (true) {
      final snapshot = await collection.limit(batchSize).get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = _db.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (snapshot.docs.length < batchSize) {
        return;
      }
    }
  }
}
