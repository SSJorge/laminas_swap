import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/profile_constants.dart';

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
        'contactType': contactTypeEmail,
        'contactValue': user.email ?? '',
        'contactVisible': false,
        'description': '',
        'profileVisible': true,
        'createdAt': now,
        'lastActiveAt': now,
        'updatedAt': now,
        'location': {
          'regionId': 'valparaiso',
          'region': 'Valparaíso',
          'regionKey': 'valparaiso',
          'comuna': 'Quilpué',
          'comunaKey': 'quilpue',
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
      'regionId': 'valparaiso',
      'region': 'Valparaíso',
      'regionKey': 'valparaiso',
      'comuna': 'Quilpué',
      'comunaKey': 'quilpue',
      'countryCode': 'CL',
      'locationPrecision': 'comuna',
      'description': '',
      'contactVisible': false,
      'missingIds': [],
      'duplicateIds': [],
      'lastActiveAt': now,
      'profileVisible': true,

      'publicContactType': FieldValue.delete(),
      'publicContactValue': FieldValue.delete(),

      // Limpieza de campos antiguos o privados.
      'contactType': FieldValue.delete(),
      'contactValue': FieldValue.delete(),
      'email': FieldValue.delete(),
      'phone': FieldValue.delete(),
      'telefono': FieldValue.delete(),
      'whatsapp': FieldValue.delete(),
      'instagram': FieldValue.delete(),
      'duplicateCounts': FieldValue.delete(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> updateProfile({
    required User user,
    required String displayName,
    required String regionId,
    required String region,
    required String comuna,
    required String contactType,
    required String contactValue,
    required bool contactVisible,
    required bool profileVisible,
    required String description,
  }) async {
    final cleanName = displayName.trim().isEmpty
        ? 'Usuario'
        : displayName.trim();

    final cleanRegionId = regionId.trim();
    final cleanRegion = region.trim();
    final cleanRegionKey = _normalizeLocation(region);
    final cleanComuna = comuna.trim();
    final cleanComunaKey = _normalizeLocation(cleanComuna);
    final cleanContactType = _normalizeContactType(contactType);
    final cleanDescription = description.trim();

    if (cleanDescription.length > profileDescriptionMaxLength) {
      throw Exception(
        'La descripción no puede superar $profileDescriptionMaxLength caracteres.',
      );
    }

    final effectiveContactValue = _resolveContactValue(
      user: user,
      contactType: cleanContactType,
      contactValue: contactValue,
    );

    if (cleanRegionId.isEmpty || cleanRegion.isEmpty) {
      throw Exception('La región es obligatoria.');
    }

    if (cleanComuna.isEmpty) {
      throw Exception('La comuna es obligatoria.');
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
      'contactValue': effectiveContactValue,
      'contactVisible': contactVisible,
      'description': cleanDescription,
      'profileVisible': profileVisible,
      'location': {
        'regionId': cleanRegionId,
        'region': cleanRegion,
        'regionKey': cleanRegionKey,
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
      'regionId': cleanRegionId,
      'region': cleanRegion,
      'regionKey': cleanRegionKey,
      'comuna': cleanComuna,
      'comunaKey': cleanComunaKey,
      'countryCode': 'CL',
      'locationPrecision': 'comuna',
      'description': cleanDescription,
      'contactVisible': contactVisible,
      'lastActiveAt': now,
      'profileVisible': profileVisible,

      if (contactVisible) ...{
        'publicContactType': cleanContactType,
        'publicContactValue': effectiveContactValue,
      } else ...{
        'publicContactType': FieldValue.delete(),
        'publicContactValue': FieldValue.delete(),
      },

      // Nunca exponer estos nombres privados/antiguos en publicProfiles.
      'contactType': FieldValue.delete(),
      'contactValue': FieldValue.delete(),
      'email': FieldValue.delete(),
      'phone': FieldValue.delete(),
      'telefono': FieldValue.delete(),
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
      case contactTypeEmail:
      case contactTypePhone:
        return cleanValue;
      default:
        return contactTypeEmail;
    }
  }

  String _resolveContactValue({
    required User user,
    required String contactType,
    required String contactValue,
  }) {
    if (contactType == contactTypeEmail) {
      final email = user.email?.trim() ?? '';

      if (email.isEmpty) {
        throw Exception('Tu cuenta no tiene email asociado.');
      }

      return email;
    }

    final digits = contactValue.replaceAll(RegExp(r'\D'), '');

    var localDigits = digits;

    if (digits.startsWith('569') && digits.length == 11) {
      localDigits = digits.substring(3);
    }

    if (digits.startsWith('9') && digits.length == 9) {
      localDigits = digits.substring(1);
    }

    if (localDigits.length != chilePhoneLocalDigitsLength) {
      throw Exception(
        'Escribe los 8 dígitos de tu número después de $chilePhonePrefix.',
      );
    }

    return '$chilePhonePrefix$localDigits';
  }

  String _normalizeLocation(String value) {
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
