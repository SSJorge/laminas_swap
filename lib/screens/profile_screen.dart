import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _comunaController = TextEditingController();
  final _contactValueController = TextEditingController();

  String _contactType = 'whatsapp';
  bool _contactVisible = true;
  bool _profileVisible = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _message;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  late final UserRepository _userRepository;

  @override
  void initState() {
    super.initState();
    _userRepository = UserRepository(_db);
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _comunaController.dispose();
    _contactValueController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('No hay usuario autenticado.');
      }

      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data == null) {
        _displayNameController.text = user.displayName ?? '';
        return;
      }

      _displayNameController.text = data['displayName'] ?? '';
      _contactType = data['contactType'] ?? 'whatsapp';
      _contactValueController.text = data['contactValue'] ?? '';
      _contactVisible = data['contactVisible'] ?? true;
      _profileVisible = data['profileVisible'] ?? false;

      final location = data['location'];

      if (location is Map) {
        _comunaController.text = location['comuna'] ?? '';
      }
    } catch (e) {
      debugPrint('ERROR cargando perfil: $e');

      if (!mounted) return;

      setState(() {
        _message = 'Error cargando perfil: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      await _userRepository.updateProfile(
        user: user,
        displayName: _displayNameController.text,
        comuna: _comunaController.text,
        contactType: _contactType,
        contactValue: _contactValueController.text,
        contactVisible: _contactVisible,
        profileVisible: _profileVisible,
      );

      if (!mounted) return;

      setState(() {
        _message = 'Perfil guardado correctamente.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const _PrivacyNotice(),
                const SizedBox(height: 16),
                TextField(
                  controller: _displayNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre visible',
                    helperText:
                        'Este nombre sí aparecerá en tu perfil público.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _comunaController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Comuna',
                    hintText: 'Ej: Santiago, Maipú, Providencia',
                    helperText: 'No escribas dirección exacta.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _contactType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de contacto privado',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'whatsapp',
                      child: Text('WhatsApp'),
                    ),
                    DropdownMenuItem(
                      value: 'instagram',
                      child: Text('Instagram'),
                    ),
                    DropdownMenuItem(
                      value: 'telefono',
                      child: Text('Teléfono'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _contactType = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contactValueController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Contacto privado',
                    hintText: 'Ej: +56912345678 o @usuario',
                    helperText:
                        'Solo se mostrará cuando otro usuario desbloquee tu perfil.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _profileVisible,
                  title: const Text('Perfil visible'),
                  subtitle: const Text(
                    'Si está apagado, no deberías aparecer en el matching.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _profileVisible = value;
                    });
                  },
                ),
                SwitchListTile(
                  value: _contactVisible,
                  title: const Text('Permitir mostrar contacto al desbloquear'),
                  subtitle: const Text(
                    'Tu contacto no queda público directamente.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _contactVisible = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_message!, textAlign: TextAlign.center),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar perfil'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Para el MVP solo usaremos comuna aproximada. '
                'No guardes dirección exacta. Tu contacto real se guarda privado '
                'y no aparece en el perfil público.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
