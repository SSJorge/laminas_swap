import 'package:cloud_firestore/cloud_firestore.dart';

class CommunePostComment {
  const CommunePostComment({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String uid;
  final String displayName;
  final String text;
  final DateTime? createdAt;

  factory CommunePostComment.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return CommunePostComment(
      id: doc.id,
      uid: _readString(data['uid']),
      displayName: _readString(data['displayName']).isEmpty
          ? 'Usuario'
          : _readString(data['displayName']),
      text: _readString(data['text']),
      createdAt: _readDateTime(data['createdAt']),
    );
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