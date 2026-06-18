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

    final batch = _db.batch();

    if (!userDoc.exists) {
      batch.set(userRef, {
        'displayName': cleanName,
        'email': user.email,
        'contactType': 'whatsapp',
        'contactValue': '',
        'contactVisible': true,
        'profileVisible': false,
        'createdAt': now,
        'lastActiveAt': now,
        'updatedAt': now,
        'location': {
          'comuna': '',
          'comunaKey': '',
          'countryCode': 'CL',
          'precision': 'comuna',
        },
        'stats': {
          'unlockedToday': 0,
          'totalCards': 0,
          'missingCount': 0,
          'obtainedCount': 0,
          'duplicateCount': 0,
        },
      });
    } else {
      batch.set(userRef, {'lastActiveAt': now}, SetOptions(merge: true));
    }

    batch.set(publicProfileRef, {
      'displayName': cleanName,
      'comuna': '',
      'comunaKey': '',
      'countryCode': 'CL',
      'locationPrecision': 'comuna',
      'missingIds': [],
      'duplicateIds': [],
      'lastActiveAt': now,
      'profileVisible': false,

      // Limpieza preventiva por si alguna versión vieja escribió campos indebidos.
      'contactType': FieldValue.delete(),
      'contactValue': FieldValue.delete(),
      'contactVisible': FieldValue.delete(),
      'email': FieldValue.delete(),
      'phone': FieldValue.delete(),
      'whatsapp': FieldValue.delete(),
      'instagram': FieldValue.delete(),
      'duplicateCounts': FieldValue.delete(),
    }, SetOptions(merge: true));

    await batch.commit();
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
    final cleanName = displayName.trim().isEmpty
        ? 'Usuario'
        : displayName.trim();

    final cleanComuna = comuna.trim();
    final cleanComunaKey = _normalizeComuna(cleanComuna);
    final cleanContactType = _normalizeContactType(contactType);
    final cleanContactValue = contactValue.trim();

    if (cleanName.isEmpty) {
      throw Exception('El nombre visible es obligatorio.');
    }

    if (cleanComuna.isEmpty) {
      throw Exception('La comuna es obligatoria.');
    }

    if (profileVisible && cleanContactValue.isEmpty) {
      throw Exception(
        'Si tu perfil está visible, agrega una forma de contacto.',
      );
    }

    final now = FieldValue.serverTimestamp();

    await user.updateDisplayName(cleanName);

    final userRef = _db.collection('users').doc(user.uid);
    final publicProfileRef = _db.collection('publicProfiles').doc(user.uid);

    final batch = _db.batch();

    batch.set(userRef, {
      'displayName': cleanName,
      'email': user.email,
      'contactType': cleanContactType,
      'contactValue': cleanContactValue,
      'contactVisible': contactVisible,
      'profileVisible': profileVisible,
      'location': {
        'comuna': cleanComuna,
        'comunaKey': cleanComunaKey,
        'countryCode': 'CL',
        'precision': 'comuna',
      },
      'lastActiveAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    batch.set(publicProfileRef, {
      'displayName': cleanName,
      'comuna': cleanComuna,
      'comunaKey': cleanComunaKey,
      'countryCode': 'CL',
      'locationPrecision': 'comuna',
      'lastActiveAt': now,
      'profileVisible': profileVisible,

      // Seguridad por diseño:
      // publicProfiles nunca debe contener contacto real.
      'contactType': FieldValue.delete(),
      'contactValue': FieldValue.delete(),
      'contactVisible': FieldValue.delete(),
      'email': FieldValue.delete(),
      'phone': FieldValue.delete(),
      'whatsapp': FieldValue.delete(),
      'instagram': FieldValue.delete(),
    }, SetOptions(merge: true));

    await batch.commit();
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

  String _normalizeContactType(String value) {
    final cleanValue = value.trim().toLowerCase();

    switch (cleanValue) {
      case 'whatsapp':
      case 'instagram':
      case 'telefono':
        return cleanValue;
      default:
        return 'whatsapp';
    }
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
