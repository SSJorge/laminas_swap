import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/account_repository.dart';

class DeleteAccountButton extends StatelessWidget {
  const DeleteAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (_) => const _DeleteAccountDialog(),
        );
      },
      icon: const Icon(Icons.delete_forever),
      label: const Text('Eliminar cuenta'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();

  late final AccountRepository _accountRepository;

  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _accountRepository = AccountRepository(
      db: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (_isDeleting) {
      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await _accountRepository.deleteCurrentAccount(
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta eliminada correctamente.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _firebaseErrorToSpanish(e);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });
    }
  }

  String _firebaseErrorToSpanish(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'La contraseña no es correcta.';
      case 'requires-recent-login':
        return 'Por seguridad, vuelve a iniciar sesión e intenta nuevamente.';
      case 'network-request-failed':
        return 'Error de conexión. Intenta nuevamente.';
      default:
        return 'Error eliminando cuenta: ${e.message ?? e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar cuenta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Esta acción eliminará tu perfil, láminas, matches, acciones, '
              'contacto privado y cuenta de acceso. No se puede deshacer.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _deleteAccount(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isDeleting ? null : _deleteAccount,
          icon: const Icon(Icons.delete_forever),
          label: _isDeleting
              ? const Text('Eliminando...')
              : const Text('Eliminar definitivamente'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
        ),
      ],
    );
  }
}
