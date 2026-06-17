import 'package:cloud_firestore/cloud_firestore.dart';

import 'card_status.dart';

class UserCard {
  const UserCard({
    required this.cardId,
    required this.countryId,
    required this.number,
    required this.status,
  });

  final String cardId;
  final String countryId;
  final int number;
  final CardStatus status;

  factory UserCard.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return UserCard(
      cardId: data['cardId'] ?? doc.id,
      countryId: data['countryId'] ?? '',
      number: data['number'] ?? 0,
      status: CardStatus.fromValue(data['status']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardId': cardId,
      'countryId': countryId,
      'number': number,
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
