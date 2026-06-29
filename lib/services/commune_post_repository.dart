import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/commune_post.dart';

class CurrentUserPostProfile {
  const CurrentUserPostProfile({
    required this.uid,
    required this.displayName,
    required this.comuna,
    required this.communeKey,
  });

  final String uid;
  final String displayName;
  final String comuna;
  final String communeKey;
}

class CommunePostRepository {
  CommunePostRepository(this._db);

  static const int maxTextLength = 220;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _postsRef(String communeKey) {
    return _db.collection('communePosts').doc(communeKey).collection('posts');
  }

  Stream<List<CommunePost>> watchPostsForCommune({
    required String communeKey,
    int limit = 100,
  }) {
    return _postsRef(communeKey)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(CommunePost.fromDoc).toList();
        });
  }

  Future<CurrentUserPostProfile> loadCurrentUserProfile(String uid) async {
    final publicProfileDoc = await _db
        .collection('publicProfiles')
        .doc(uid)
        .get();

    if (!publicProfileDoc.exists) {
      throw Exception('Primero completa tu perfil.');
    }

    final data = publicProfileDoc.data() ?? <String, dynamic>{};

    final displayName = _readString(data['displayName']);
    final comuna = _readString(data['comuna']);
    final communeKey = _readString(data['comunaKey']);

    if (displayName.isEmpty) {
      throw Exception('Primero guarda tu nombre de usuario.');
    }

    if (comuna.isEmpty || communeKey.isEmpty) {
      throw Exception('Primero guarda tu comuna en Mi perfil.');
    }

    return CurrentUserPostProfile(
      uid: uid,
      displayName: displayName,
      comuna: comuna,
      communeKey: communeKey,
    );
  }

  Future<void> createTodayPost({
    required String uid,
    required String text,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception('La publicación no puede estar vacía.');
    }

    if (cleanText.length > maxTextLength) {
      throw Exception(
        'La publicación no puede superar $maxTextLength caracteres.',
      );
    }

    final profile = await loadCurrentUserProfile(uid);
    final dayKey = _todayDayKey();
    final postId = '${uid}_$dayKey';
    final postRef = _postsRef(profile.communeKey).doc(postId);

    final wasCreated = await _db.runTransaction<bool>((transaction) async {
      final existingPost = await transaction.get(postRef);

      if (existingPost.exists) {
        return false;
      }

      transaction.set(postRef, {
        'uid': uid,
        'displayName': profile.displayName,
        'comuna': profile.comuna,
        'communeKey': profile.communeKey,
        'dayKey': dayKey,
        'text': cleanText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    });

    if (!wasCreated) {
      throw Exception('Ya publicaste hoy en ${profile.comuna}.');
    }
  }

  Future<bool> hasTodayPost(String uid) async {
    final profile = await loadCurrentUserProfile(uid);
    final dayKey = _todayDayKey();
    final postId = '${uid}_$dayKey';

    final postDoc = await _postsRef(profile.communeKey).doc(postId).get();

    return postDoc.exists;
  }

  Future<void> deletePost(CommunePost post) async {
    await _postsRef(post.communeKey).doc(post.id).delete();
  }

  String _todayDayKey() {
    final now = DateTime.now();

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$year$month$day';
  }

  String _readString(dynamic value) {
    if (value is String) {
      return value.trim();
    }

    return '';
  }
}
