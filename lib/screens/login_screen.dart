import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_repository.dart';
import 'package:flutter/services.dart';

import '../data/profile_constants.dart';
import '../utils/display_name_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialRegisterMode = true});

  final bool initialRegisterMode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late bool _isRegisterMode;
  bool _isLoading = false;
  String? _errorMessage;

  final _auth = FirebaseAuth.instance;
  final _userRepository = UserRepository(FirebaseFirestore.instance);

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.initialRegisterMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _closeAuthScreenAfterSuccess() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final displayName = _isRegisterMode
          ? validateDisplayName(_nameController.text)
          : _nameController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Ingresa email y contraseña.');
      }

      UserCredential credential;

      if (_isRegisterMode) {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        try {
          await _userRepository.initUserIfNeeded(
            user: credential.user!,
            displayName: displayName,
          );
        } catch (e) {
          await credential.user?.delete();
          await _auth.signOut();
          rethrow;
        }

        _closeAuthScreenAfterSuccess();
        return;
      } else {
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final user = credential.user;

      if (user == null) {
        throw Exception('No se pudo obtener el usuario.');
      }

      await _userRepository.initUserIfNeeded(
        user: user,
        displayName: displayName,
      );
      _closeAuthScreenAfterSuccess();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _firebaseErrorToSpanish(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _firebaseErrorToSpanish(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ese email ya está registrado.';
      case 'invalid-email':
        return 'El email no es válido.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'user-not-found':
        return 'No existe una cuenta con ese email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o contraseña incorrectos.';
      default:
        return 'Error de autenticación: ${e.message ?? e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isRegisterMode ? 'Crear cuenta' : 'Iniciar sesión';

    return Scaffold(
      appBar: AppBar(title: const Text('Intercambio de Láminas')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),

                    if (_isRegisterMode)
                      if (_isRegisterMode)
                        TextField(
                          controller: _nameController,
                          maxLength: displayNameMaxLength,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9._]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Nombre de usuario',
                            helperText:
                                'Único. Usa letras, números, punto o guion bajo.',
                            border: OutlineInputBorder(),
                          ),
                        ),

                    if (_isRegisterMode) const SizedBox(height: 12),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(title),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isRegisterMode = !_isRegisterMode;
                                _errorMessage = null;
                              });
                            },
                      child: Text(
                        _isRegisterMode
                            ? 'Ya tengo cuenta'
                            : 'Quiero crear una cuenta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
