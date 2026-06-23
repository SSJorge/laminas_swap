import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialRegisterMode = true});

  final bool initialRegisterMode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _closeAuthScreenAfterSuccess() {
    if (!mounted) return;
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
      final confirmPassword = _confirmPasswordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Ingresa email y contraseña.');
      }

      if (_isRegisterMode) {
        if (confirmPassword.isEmpty) {
          throw Exception('Confirma tu contraseña.');
        }

        if (password != confirmPassword) {
          throw Exception('Las contraseñas no coinciden.');
        }
      }

      UserCredential credential;

      if (_isRegisterMode) {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        try {
          await _userRepository.initUserIfNeeded(user: credential.user!);
        } catch (e) {
          await credential.user?.delete();
          await _auth.signOut();
          rethrow;
        }

        _closeAuthScreenAfterSuccess();
        return;
      }

      credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('No se pudo obtener el usuario.');
      }

      await _userRepository.initUserIfNeeded(user: user);

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
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
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
                      onSubmitted: _isRegisterMode ? null : (_) => _submit(),
                    ),
                    if (_isRegisterMode) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contraseña',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (_errorMessage != null) const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
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
                                _confirmPasswordController.clear();
                              });
                            },
                      child: Text(
                        _isRegisterMode
                            ? 'Ya tengo cuenta'
                            : 'Crear cuenta nueva',
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
