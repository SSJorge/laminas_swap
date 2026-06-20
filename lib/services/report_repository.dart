import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/report_reasons.dart';

class ReportRepository {
  ReportRepository(this._db);

  final FirebaseFirestore _db;

  Future<void> reportUser({
    required String reporterUid,
    required String reportedUid,
    required String reason,
    required String details,
    required String source,
  }) async {
    if (reporterUid == reportedUid) {
      throw Exception('No puedes reportarte a ti mismo.');
    }

    if (!isValidReportReason(reason)) {
      throw Exception('Selecciona un motivo válido.');
    }

    final cleanDetails = details.trim();

    if (cleanDetails.length > 500) {
      throw Exception('El detalle no puede superar 500 caracteres.');
    }

    final now = FieldValue.serverTimestamp();

    await _db.collection('reports').add({
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reason': reason,
      'details': cleanDetails,
      'source': source,
      'status': 'open',
      'createdAt': now,
      'updatedAt': now,
    });
  }
}
