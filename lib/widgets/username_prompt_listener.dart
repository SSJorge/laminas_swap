import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/profile_constants.dart';
import '../services/user_repository.dart';

class UsernamePromptListener extends StatefulWidget {
  const UsernamePromptListener({super.key, required this.child});

  final Widget child;

  @override
  State<UsernamePromptListener> createState() => _UsernamePromptListenerState();
}

class _UsernamePromptListenerState extends State<UsernamePromptListener> {
  bool _isDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return widget.child;
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final shouldShowPrompt =
            data != null &&
            data['hasChosenDisplayName'] != true &&
            data['usernamePromptDismissed'] != true;

        if (shouldShowPrompt && !_isDialogOpen) {
          _isDialogOpen = true;

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;

            await showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) {
                return const _UsernamePromptDialog();
              },
            );

            if (!mounted) return;

            _isDialogOpen = false;
          });
        }

        return widget.child;
      },
    );
  }
}

class _UsernamePromptDialog extends StatefulWidget {
  const _UsernamePromptDialog();

  @override
  State<_UsernamePromptDialog> createState() => _UsernamePromptDialogState();
}

class _UsernamePromptDialogState extends State<_UsernamePromptDialog> {
  final _controller = TextEditingController();

  late final UserRepository _userRepository;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _userRepository = UserRepository(FirebaseFirestore.instance);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _userRepository.setDisplayNameOnly(
        user: user,
        displayName: _controller.text,
      );

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _skipForNow() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _userRepository.dismissUsernamePrompt(uid: user.uid);

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
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
      title: const Text('Elige tu nombre de usuario'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu nombre de usuario es público, se muestra a otros usuarios y '
              'sirve como identificador cuando alguien te busca o hace match contigo. '
              'Debe ser único.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLength: displayNameMaxLength,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Nombre de usuario',
                helperText: 'Letras, números, punto o guion bajo.',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _saveUsername(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : _skipForNow,
          child: const Text('Omitir por ahora'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveUsername,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Aceptar'),
        ),
      ],
    );
  }
}
