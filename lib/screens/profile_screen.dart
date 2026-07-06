import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/chile_locations.dart';
import '../data/profile_constants.dart';
import '../services/user_repository.dart';
import '../utils/display_name_utils.dart';
import '../data/daily_limits.dart';
import '../widgets/daily_limits_card.dart';
import '../widgets/delete_account_button.dart';
import '../widgets/feedback_footer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _phoneDigitsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _publicDescriptionController = TextEditingController();

  String _selectedRegionId = 'valparaiso';
  String _selectedComuna = 'Quilpué';
  String _contactType = contactTypeEmail;

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
    _phoneDigitsController.dispose();
    _descriptionController.dispose();
    _publicDescriptionController.dispose();
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
        _contactType = contactTypeEmail;
        _profileVisible = true;
        _descriptionController.text = '';
        _publicDescriptionController.text = '';
        return;
      }

      _displayNameController.text = data['displayName'] ?? '';
      _contactType = _safeContactType(data['contactType']);
      _profileVisible = data['profileVisible'] ?? true;
      final privateProfileDoc = await _db
          .collection('privateProfiles')
          .doc(user.uid)
          .get();

      final privateProfileData = privateProfileDoc.data() ?? {};

      _descriptionController.text =
          (privateProfileData['description'] as String?) ??
          (data['description'] as String?) ??
          '';

      final publicProfileDoc = await _db
          .collection('publicProfiles')
          .doc(user.uid)
          .get();

      final publicProfileData = publicProfileDoc.data() ?? {};

      _publicDescriptionController.text =
          (publicProfileData['publicDescription'] as String?) ?? '';

      final contactValue = data['contactValue'];

      if (_contactType == contactTypePhone && contactValue is String) {
        _phoneDigitsController.text = _extractPhoneDigits(contactValue);
      } else {
        _phoneDigitsController.clear();
      }

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
      final cleanName = validateDisplayName(_displayNameController.text);

      await _userRepository.updateProfile(
        user: user,
        displayName: cleanName,
        regionId: region.id,
        region: region.name,
        comuna: _selectedComuna,
        contactType: _contactType,
        contactValue: _contactType == contactTypePhone
            ? _phoneDigitsController.text
            : user.email ?? '',
        contactVisible: false,
        profileVisible: _profileVisible,
        description: _descriptionController.text,
        publicDescription: _publicDescriptionController.text,
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
          _isSaving = false;
        });
      }
    }
  }

  String _safeContactType(dynamic value) {
    if (value == contactTypeEmail || value == contactTypePhone) {
      return value;
    }

    return contactTypeEmail;
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

  String _extractPhoneDigits(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('569') && digits.length == 11) {
      return digits.substring(3);
    }

    if (digits.startsWith('9') && digits.length == 9) {
      return digits.substring(1);
    }

    if (digits.length <= chilePhoneLocalDigitsLength) {
      return digits;
    }

    return '';
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
                  maxLength: displayNameMaxLength,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
                  ],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    helperText: 'Debe ser único. Máximo 15 caracteres.',
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
                      value: contactTypeEmail,
                      child: Text('Correo electrónico'),
                    ),
                    DropdownMenuItem(
                      value: contactTypePhone,
                      child: Text('Número de teléfono'),
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
                if (_contactType == contactTypeEmail)
                  TextFormField(
                    initialValue: userEmail,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      helperText: 'Se usará el correo de tu cuenta.',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  TextField(
                    controller: _phoneDigitsController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                        chilePhoneLocalDigitsLength,
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Número',
                      prefixText: '$chilePhonePrefix ',
                      helperText: 'Escribe solo los 8 dígitos restantes.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _publicDescriptionController,
                  maxLength: profileDescriptionMaxLength,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción pública',
                    hintText: 'Ej: Vendo Messi',
                    helperText:
                        'Visible antes del match. \nNo escribas teléfono, WhatsApp, Instagram \nni dirección exacta.',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLength: profileDescriptionMaxLength,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción privada',
                    hintText: 'Ej: háblame a mi insta @mi_insta',
                    helperText: 'Solo visible después de un match mutuo.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const _ContactVisibilityNotice(),
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
                const SizedBox(height: 16),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_message!, textAlign: TextAlign.center),
                  ),
                //limites diarios
                const DailyLimitsCard(types: [DailyLimitType.communeChange]),
                const SizedBox(height: 12),

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
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                const DeleteAccountButton(),
                const SizedBox(height: 24),
                const FeedbackFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactVisibilityNotice extends StatelessWidget {
  const _ContactVisibilityNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.visibility_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tu contacto solo será visible para las personas con match a las que tú decidas mostrárselo.',
              ),
            ),
          ],
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
                'Tu contacto real se guarda privado. ',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
