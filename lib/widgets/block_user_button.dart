import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/block_repository.dart';

class BlockUserButton extends StatelessWidget {
  const BlockUserButton({
    super.key,
    required this.blockedUid,
    required this.blockedDisplayName,
    this.onBlocked,
  });

  final String blockedUid;
  final String blockedDisplayName;
  final Future<void> Function()? onBlocked;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (_) {
            return _BlockUserDialog(
              blockedUid: blockedUid,
              blockedDisplayName: blockedDisplayName,
              onBlocked: onBlocked,
            );
          },
        );
      },
      icon: const Icon(Icons.block),
      label: const Text('Bloquear'),
    );
  }
}

class _BlockUserDialog extends StatefulWidget {
  const _BlockUserDialog({
    required this.blockedUid,
    required this.blockedDisplayName,
    required this.onBlocked,
  });

  final String blockedUid;
  final String blockedDisplayName;
  final Future<void> Function()? onBlocked;

  @override
  State<_BlockUserDialog> createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends State<_BlockUserDialog> {
  late final BlockRepository _blockRepository;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _blockRepository = BlockRepository(FirebaseFirestore.instance);
  }

  Future<void> _blockUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _blockRepository.blockUser(
        blockerUid: user.uid,
        blockedUid: widget.blockedUid,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.blockedDisplayName} fue bloqueado.')),
      );

      await widget.onBlocked?.call();
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
      title: const Text('Bloquear usuario'),
      content: Text(
        '¿Quieres bloquear a ${widget.blockedDisplayName}? '
        'Ya no aparecerá en tus resultados, likes recibidos ni matches.',
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
          onPressed: _isSaving ? null : _blockUser,
          icon: const Icon(Icons.block),
          label: _isSaving
              ? const Text('Bloqueando...')
              : const Text('Bloquear'),
        ),
      ],
    );
  }
}
