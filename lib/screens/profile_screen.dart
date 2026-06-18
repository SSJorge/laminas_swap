import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/chile_locations.dart';
import '../services/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _contactValueController = TextEditingController();

  String _selectedRegionId = 'valparaiso';
  String _selectedComuna = 'Quilpué';
  String _contactType = 'email';

  bool _contactVisible = true;
  bool _profileVisible = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _message;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  late final UserRepository _userRepository;

  ChileRegion get _selectedRegion => findRegionById(_selectedRegionId);

  @override
  void initState() {
    super.initState();
    _userRepository = UserRepository(_db);
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
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
        _selectedRegionId = 'valparaiso';
        _selectedComuna = 'Quilpué';
        _contactType = 'email';
        return;
      }

      _displayNameController.text = data['displayName'] ?? '';
      _contactType = _safeContactType(data['contactType']);
      _contactValueController.text = data['contactValue'] ?? '';
      _contactVisible = data['contactVisible'] ?? true;
      _profileVisible = data['profileVisible'] ?? true;

      final location = data['location'];

      if (location is Map) {
        final loadedRegionId = location['regionId'];

        _selectedRegionId = _safeRegionId(loadedRegionId);
        _selectedComuna = _safeComuna(
          regionId: _selectedRegionId,
          comuna: location['comuna'],
        );
      } else {
        _selectedRegionId = 'valparaiso';
        _selectedComuna = 'Quilpué';
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
      final region = _selectedRegion;

      await _userRepository.updateProfile(
        user: user,
        displayName: _displayNameController.text,
        regionId: region.id,
        region: region.name,
        comuna: _selectedComuna,
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

  String _safeContactType(dynamic value) {
    if (value == 'email' || value == 'whatsapp' || value == 'instagram') {
      return value;
    }

    return 'email';
  }

  String _safeRegionId(dynamic value) {
    if (value is String && chileRegions.any((region) => region.id == value)) {
      return value;
    }

    return 'valparaiso';
  }

  String _safeComuna({required String regionId, required dynamic comuna}) {
    final region = findRegionById(regionId);

    if (comuna is String && region.comunas.contains(comuna)) {
      return comuna;
    }

    if (region.id == 'valparaiso' && region.comunas.contains('Quilpué')) {
      return 'Quilpué';
    }

    return region.comunas.first;
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _auth.currentUser?.email ?? '';

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
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRegionId,
                  decoration: const InputDecoration(
                    labelText: 'Región',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final region in chileRegions)
                      DropdownMenuItem(
                        value: region.id,
                        child: Text(region.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    final newRegion = findRegionById(value);

                    setState(() {
                      _selectedRegionId = newRegion.id;

                      if (newRegion.id == 'valparaiso' &&
                          newRegion.comunas.contains('Quilpué')) {
                        _selectedComuna = 'Quilpué';
                      } else {
                        _selectedComuna = newRegion.comunas.first;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedRegionId),
                  initialValue: _selectedComuna,
                  decoration: const InputDecoration(
                    labelText: 'Comuna',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final comuna in _selectedRegion.comunas)
                      DropdownMenuItem(value: comuna, child: Text(comuna)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedComuna = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _contactType,
                  decoration: const InputDecoration(
                    labelText: 'Modo de contacto',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'email',
                      child: Text('Correo electrónico'),
                    ),
                    DropdownMenuItem(
                      value: 'whatsapp',
                      child: Text('WhatsApp'),
                    ),
                    DropdownMenuItem(
                      value: 'instagram',
                      child: Text('Instagram'),
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
                if (_contactType == 'email')
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: userEmail),
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      helperText:
                          'Se usará el email de tu cuenta. No queda público hasta desbloqueo.',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  TextField(
                    controller: _contactValueController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: _contactType == 'whatsapp'
                          ? 'WhatsApp'
                          : 'Instagram',
                      hintText: _contactType == 'whatsapp'
                          ? 'Ej: +56912345678'
                          : 'Ej: @usuario',
                      helperText:
                          'Solo se mostrará cuando otro usuario desbloquee tu perfil.',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _profileVisible,
                  title: const Text('Perfil visible'),
                  subtitle: const Text(
                    'Si lo apagas, no aparecerás en resultados de matching.',
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
                    'Tu contacto nunca queda público directamente.',
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
                'Usaremos solo región y comuna aproximada. '
                'No guardes dirección exacta. Tu contacto real se guarda privado '
                'y no aparece en tu perfil público.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
