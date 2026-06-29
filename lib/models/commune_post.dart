import 'package:cloud_firestore/cloud_firestore.dart';

class CommunePost {
  const CommunePost({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.comuna,
    required this.communeKey,
    required this.dayKey,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String uid;
  final String displayName;
  final String comuna;
  final String communeKey;
  final String dayKey;
  final String text;
  final DateTime? createdAt;

  factory CommunePost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return CommunePost(
      id: doc.id,
      uid: _readString(data['uid']),
      displayName: _readString(data['displayName']).isEmpty
          ? 'Usuario'
          : _readString(data['displayName']),
      comuna: _readString(data['comuna']),
      communeKey: _readString(data['communeKey']),
      dayKey: _readString(data['dayKey']),
      text: _readString(data['text']),
      createdAt: _readDateTime(data['createdAt']),
    );
  }

  bool matchesSearch(String rawQuery) {
    final query = normalizeForSearch(rawQuery);

    if (query.isEmpty) {
      return true;
    }

    return normalizeForSearch(text).contains(query) ||
        normalizeForSearch(displayName).contains(query);
  }

  static String normalizeForSearch(String value) {
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

  static String _readString(dynamic value) {
    if (value is String) {
      return value.trim();
    }

    return '';
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}
