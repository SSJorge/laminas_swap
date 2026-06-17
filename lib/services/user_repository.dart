import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  UserRepository(this._db);

  final FirebaseFirestore _db;

  Future<void> initUserIfNeeded({
    required User user,
    String? displayName,
  }) async {
    final now = FieldValue.serverTimestamp();

    final cleanName = _resolveDisplayName(
      displayName: displayName,
      firebaseDisplayName: user.displayName,
      email: user.email,
    );

    final userRef = _db.collection('users').doc(user.uid);
    final publicProfileRef = _db.collection('publicProfiles').doc(user.uid);

    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        'displayName': cleanName,
        'email': user.email,
        'contactType': 'whatsapp',
        'contactValue': '',
        'contactVisible': true,
        'profileVisible': true,
        'createdAt': now,
        'lastActiveAt': now,
        'location': {'comuna': ''},
        'stats': {
          'unlockedToday': 0,
          'totalCards': 0,
          'missingCount': 0,
          'obtainedCount': 0,
          'duplicateCount': 0,
        },
      });
    } else {
      await userRef.update({'lastActiveAt': now});
    }

    final publicDoc = await publicProfileRef.get();

    if (!publicDoc.exists) {
      await publicProfileRef.set({
        'displayName': cleanName,
        'comuna': '',
        'missingIds': [],
        'duplicateIds': [],
        'lastActiveAt': now,
        'profileVisible': true,
      });
    } else {
      await publicProfileRef.set({
        'lastActiveAt': now,
        'duplicateCounts': FieldValue.delete(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> updateProfile({
    required User user,
    required String displayName,
    required String comuna,
    required String contactType,
    required String contactValue,
    required bool contactVisible,
    required bool profileVisible,
  }) async {
    final now = FieldValue.serverTimestamp();

    final cleanName = displayName.trim().isEmpty
        ? 'Usuario'
        : displayName.trim();

    final cleanComuna = comuna.trim();

    await user.updateDisplayName(cleanName);

    await _db.collection('users').doc(user.uid).set({
      'displayName': cleanName,
      'email': user.email,
      'contactType': contactType,
      'contactValue': contactValue.trim(),
      'contactVisible': contactVisible,
      'profileVisible': profileVisible,
      'location': {'comuna': cleanComuna},
      'lastActiveAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await _db.collection('publicProfiles').doc(user.uid).set({
      'displayName': cleanName,
      'comuna': cleanComuna,
      'lastActiveAt': now,
      'profileVisible': profileVisible,

      // Limpieza del modelo anterior.
      // Ya no guardamos cantidades de repetidas.
      'duplicateCounts': FieldValue.delete(),

      // Importante:
      // No tocar missingIds ni duplicateIds aquí.
      // Esos campos los actualiza CardRepository.
    }, SetOptions(merge: true));
  }

  String _resolveDisplayName({
    required String? displayName,
    required String? firebaseDisplayName,
    required String? email,
  }) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    if (firebaseDisplayName != null && firebaseDisplayName.trim().isNotEmpty) {
      return firebaseDisplayName.trim();
    }

    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Usuario';
  }
}
