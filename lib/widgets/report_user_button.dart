import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/report_reasons.dart';
import '../services/report_repository.dart';

class ReportUserButton extends StatelessWidget {
  const ReportUserButton({
    super.key,
    required this.reportedUid,
    required this.reportedDisplayName,
    required this.source,
  });

  final String reportedUid;
  final String reportedDisplayName;
  final String source;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (_) {
            return _ReportUserDialog(
              reportedUid: reportedUid,
              reportedDisplayName: reportedDisplayName,
              source: source,
            );
          },
        );
      },
      icon: const Icon(Icons.flag_outlined),
      label: const Text('Reportar'),
    );
  }
}

class _ReportUserDialog extends StatefulWidget {
  const _ReportUserDialog({
    required this.reportedUid,
    required this.reportedDisplayName,
    required this.source,
  });

  final String reportedUid;
  final String reportedDisplayName;
  final String source;

  @override
  State<_ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<_ReportUserDialog> {
  final _detailsController = TextEditingController();

  late final ReportRepository _reportRepository;

  String _selectedReason = reportReasons.first.value;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _reportRepository = ReportRepository(FirebaseFirestore.instance);
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _reportRepository.reportUser(
        reporterUid: user.uid,
        reportedUid: widget.reportedUid,
        reason: _selectedReason,
        details: _detailsController.text,
        source: widget.source,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte enviado. Lo revisaremos pronto.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reportar usuario'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Usuario: ${widget.reportedDisplayName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final reason in reportReasons)
                  DropdownMenuItem(
                    value: reason.value,
                    child: Text(reason.label),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedReason = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              maxLength: 500,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Detalle opcional',
                hintText: 'Describe brevemente qué ocurrió.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _submitReport,
          icon: const Icon(Icons.flag_outlined),
          label: _isSaving
              ? const Text('Enviando...')
              : const Text('Enviar reporte'),
        ),
      ],
    );
  }
}
