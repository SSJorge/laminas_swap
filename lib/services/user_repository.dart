import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/profile_constants.dart';
import '../utils/display_name_utils.dart';
import '../data/daily_limits.dart';
import '../models/user_entitlements.dart';

class UserRepository {
  UserRepository(this._db);

  final FirebaseFirestore _db;
  Future<void> ensureDisplayNameAvailable({
    required String displayName,
    String? currentUid,
  }) async {
    final cleanName = validateDisplayName(displayName);
    final cleanNameKey = displayNameKeyFrom(cleanName);

    final usernameDoc = await _db
        .collection('usernames')
        .doc(cleanNameKey)
        .get();

    if (!usernameDoc.exists) {
      return;
    }

    final ownerUid = usernameDoc.data()?['uid'];

    if (currentUid != null && ownerUid == currentUid) {
      return;
    }

    throw Exception('Ese nombre de usuario ya está ocupado.');
  }

  Future<void> initUserIfNeeded({
    required User user,
    String? displayName,
  }) async {
    final userRef = _db.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (userDoc.exists) {
      await userRef.set({
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    final cleanName = validateDisplayName(
      displayName ?? user.displayName ?? '',
    );
    final cleanNameKey = displayNameKeyFrom(cleanName);
    final now = FieldValue.serverTimestamp();

    final usernameRef = _db.collection('usernames').doc(cleanNameKey);
    final publicProfileRef = _db.collection('publicProfiles').doc(user.uid);
    final privateProfileRef = _db.collection('privateProfiles').doc(user.uid);
    final privateContactRef = _db.collection('privateContacts').doc(user.uid);

    var usernameAlreadyTaken = false;

    await _db.runTransaction((transaction) async {
      final usernameDoc = await transaction.get(usernameRef);

      if (usernameDoc.exists) {
        usernameAlreadyTaken = true;
        return;
      }

      transaction.set(usernameRef, {
        'uid': user.uid,
        'displayName': cleanName,
        'displayNameKey': cleanNameKey,
        'createdAt': now,
        'updatedAt': now,
      });

      transaction.set(userRef, {
        'displayName': cleanName,
        'displayNameKey': cleanNameKey,
        'email': user.email,
        'contactType': contactTypeEmail,
        'contactValue': user.email ?? '',
        'contactVisible': false,
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

      transaction.set(publicProfileRef, {
        'displayName': cleanName,
        'displayNameKey': cleanNameKey,
        'regionId': 'valparaiso',
        'region': 'Valparaíso',
        'regionKey': 'valparaiso',
        'comuna': 'Quilpué',
        'comunaKey': 'quilpue',
        'countryCode': 'CL',
        'locationPrecision': 'comuna',
        'missingIds': [],
        'duplicateIds': [],
        'lastActiveAt': now,
        'profileVisible': true,
      });

      transaction.set(privateProfileRef, {'description': '', 'updatedAt': now});

      transaction.set(privateContactRef, {
        'contactType': contactTypeEmail,
        'contactValue': user.email ?? '',
        'updatedAt': now,
      });
      if (usernameAlreadyTaken) {
        throw Exception('Ese nombre de usuario ya está ocupado.');
      }
    });

    await user.updateDisplayName(cleanName);
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
    final cleanName = validateDisplayName(displayName);
    final cleanNameKey = displayNameKeyFrom(cleanName);

    await ensureDisplayNameAvailable(
      displayName: cleanName,
      currentUid: user.uid,
    );

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

    if (cleanRegionId.isEmpty || cleanRegion.isEmpty) {
      throw Exception('La región es obligatoria.');
    }

    if (cleanComuna.isEmpty) {
      throw Exception('La comuna es obligatoria.');
    }

    final effectiveContactValue = _resolveContactValue(
      user: user,
      contactType: cleanContactType,
      contactValue: contactValue,
    );

    final now = FieldValue.serverTimestamp();

    final userRef = _db.collection('users').doc(user.uid);
    final publicProfileRef = _db.collection('publicProfiles').doc(user.uid);
    final privateProfileRef = _db.collection('privateProfiles').doc(user.uid);
    final newUsernameRef = _db.collection('usernames').doc(cleanNameKey);
    final privateContactRef = _db.collection('privateContacts').doc(user.uid);

    DocumentReference<Map<String, dynamic>>? dailyUsageRef;
    Map<String, dynamic>? dailyUsageUpdate;

    final currentUserDoc = await userRef.get();
    final currentUserData = currentUserDoc.data() ?? <String, dynamic>{};

    final location = currentUserData['location'];

    String oldComunaKey = '';

    if (location is Map) {
      final rawOldComunaKey = location['comunaKey'];

      if (rawOldComunaKey is String) {
        oldComunaKey = rawOldComunaKey;
      }
    }

    final shouldConsumeCommuneChange =
        oldComunaKey.isNotEmpty && oldComunaKey != cleanComunaKey;

    if (shouldConsumeCommuneChange) {
      final quotaDefinition = dailyLimitDefinitionFor(
        DailyLimitType.communeChange,
      );
      final entitlementsDoc = await _db
          .collection('userEntitlements')
          .doc(user.uid)
          .get();

      final entitlements = UserEntitlements.fromMap(entitlementsDoc.data());
      final quotaLimit = quotaDefinition.limitFor(entitlements);

      final dayKey = todayUsageDocId();

      dailyUsageRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('dailyUsage')
          .doc(dayKey);

      final dailyUsageDoc = await dailyUsageRef.get();
      final dailyUsageData = dailyUsageDoc.data();

      final used = _readInt(dailyUsageData?[quotaDefinition.field]);

      if (used >= quotaLimit) {
        throw Exception(
          'Ya usaste tus ${quotaDefinition.label.toLowerCase()} de hoy.',
        );
      }

      dailyUsageUpdate = {
        'dayKey': dayKey,
        quotaDefinition.field: used + 1,
        'updatedAt': now,
      };
    }

    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final newUsernameDoc = await transaction.get(newUsernameRef);

      final userData = userDoc.data() ?? <String, dynamic>{};
      final oldNameKey = userData['displayNameKey'] as String?;

      if (newUsernameDoc.exists) {
        final ownerUid = newUsernameDoc.data()?['uid'];

        if (ownerUid != user.uid) {
          throw Exception('Ese nombre de usuario ya está ocupado.');
        }
      }

      if (oldNameKey != null &&
          oldNameKey.isNotEmpty &&
          oldNameKey != cleanNameKey) {
        final oldUsernameRef = _db.collection('usernames').doc(oldNameKey);
        transaction.delete(oldUsernameRef);
      }

      transaction.set(newUsernameRef, {
        'uid': user.uid,
        'displayName': cleanName,
        'displayNameKey': cleanNameKey,
        'updatedAt': now,
      }, SetOptions(merge: true));

      transaction.set(userRef, {
        'displayName': cleanName,
        'displayNameKey': cleanNameKey,
        'email': user.email,
        'contactType': cleanContactType,
        'contactValue': effectiveContactValue,
        'contactVisible': contactVisible,
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

      transaction.set(publicProfileRef, {
        'displayName': cleanName,
        'displayNameKey': cleanNameKey,
        'regionId': cleanRegionId,
        'region': cleanRegion,
        'regionKey': cleanRegionKey,
        'comuna': cleanComuna,
        'comunaKey': cleanComunaKey,
        'countryCode': 'CL',
        'locationPrecision': 'comuna',
        'lastActiveAt': now,
        'profileVisible': profileVisible,

        // Limpieza: nada privado ni descripción en publicProfiles.
        'description': FieldValue.delete(),
        'contactVisible': FieldValue.delete(),
        'publicContactType': FieldValue.delete(),
        'publicContactValue': FieldValue.delete(),
        'contactType': FieldValue.delete(),
        'contactValue': FieldValue.delete(),
        'email': FieldValue.delete(),
        'phone': FieldValue.delete(),
        'telefono': FieldValue.delete(),
        'whatsapp': FieldValue.delete(),
        'instagram': FieldValue.delete(),
      }, SetOptions(merge: true));

      transaction.set(privateProfileRef, {
        'description': cleanDescription,
        'updatedAt': now,

        // Limpieza de campos antiguos.
        'contactType': FieldValue.delete(),
        'contactValue': FieldValue.delete(),
        'contactVisible': FieldValue.delete(),
      }, SetOptions(merge: true));

      transaction.set(privateContactRef, {
        'contactType': cleanContactType,
        'contactValue': effectiveContactValue,
        'updatedAt': now,
      }, SetOptions(merge: true));
      if (dailyUsageRef != null && dailyUsageUpdate != null) {
        transaction.set(
          dailyUsageRef,
          dailyUsageUpdate,
          SetOptions(merge: true),
        );
      }
    });

    await user.updateDisplayName(cleanName);
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
