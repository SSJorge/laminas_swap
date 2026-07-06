import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/card_status.dart';
import '../services/card_repository.dart';
import '../utils/sticker_list_exporter.dart';

class ShareProfileScreen extends StatelessWidget {
  const ShareProfileScreen({super.key});

  static const String productionBaseUrl = 'https://truequegol.cl';

  Future<void> _copyText({
    required BuildContext context,
    required String text,
    required String successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  }

  String _profileLink(String displayNameKey) {
    return '$productionBaseUrl/u/$displayNameKey';
  }

  String _fullShareMessage({
    required String profileLink,
    required String exportList,
  }) {
    return [
      'Estoy usando TruequeGol para intercambiar láminas.',
      '',
      'Revisa compatibilidad conmigo aquí:',
      profileLink,
      '',
      'Mi lista:',
      '',
      exportList,
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay usuario autenticado.')),
      );
    }
    if (user.isAnonymous) {
  final cardRepository = CardRepository(FirebaseFirestore.instance);

  return Scaffold(
    appBar: AppBar(title: const Text('Compartir lista')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: StreamBuilder<Map<String, CardStatus>>(
          stream: cardRepository.watchMyCardStatuses(user.uid),
          builder: (context, cardsSnapshot) {
            final statuses = cardsSnapshot.data ?? {};
            final exportList = buildStickerExportList(statuses);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Modo invitado',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Como invitado puedes copiar tu lista, pero no puedes compartir perfil, QR ni recibir matches.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            _copyText(
                              context: context,
                              text: exportList,
                              successMessage: 'Lista copiada.',
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copiar lista'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

    final cardRepository = CardRepository(FirebaseFirestore.instance);

    return Scaffold(
      appBar: AppBar(title: const Text('Compartir')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('publicProfiles')
                .doc(user.uid)
                .snapshots(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting &&
                  !profileSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final profileData = profileSnapshot.data?.data() ?? {};
              final displayName =
                  (profileData['displayName'] as String?)?.trim() ?? 'Usuario';
              final displayNameKey =
                  (profileData['displayNameKey'] as String?)?.trim() ?? '';

              if (displayNameKey.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Primero guarda tu perfil para generar tu enlace.',
                        ),
                      ),
                    ),
                  ],
                );
              }

              final profileLink = _profileLink(displayNameKey);

              return StreamBuilder<Map<String, CardStatus>>(
                stream: cardRepository.watchMyCardStatuses(user.uid),
                builder: (context, cardsSnapshot) {
                  final statuses = cardsSnapshot.data ?? {};
                  final exportList = buildStickerExportList(statuses);
                  final fullMessage = _fullShareMessage(
                    profileLink: profileLink,
                    exportList: exportList,
                  );

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                child: Text(
                                  displayName.isEmpty
                                      ? '?'
                                      : displayName[0].toUpperCase(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '@$displayNameKey',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Comparte tu perfil para que otra persona pueda encontrarte y hacer match contigo.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Tu enlace',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(profileLink),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _copyText(
                                    context: context,
                                    text: profileLink,
                                    successMessage: 'Enlace copiado.',
                                  );
                                },
                                icon: const Icon(Icons.link),
                                label: const Text('Copiar enlace'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              Text(
                                'QR de tu perfil',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                                ),
                                child: QrImageView(
                                  data: profileLink,
                                  version: QrVersions.auto,
                                  size: 220,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Quien escanee el QR llegará a tu perfil en TruequeGol.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Compartir lista',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Copia solo tu lista o un mensaje completo con enlace incluido.',
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () {
                                  _copyText(
                                    context: context,
                                    text: exportList,
                                    successMessage: 'Lista copiada.',
                                  );
                                },
                                icon: const Icon(Icons.copy),
                                label: const Text('Copiar lista'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _copyText(
                                    context: context,
                                    text: fullMessage,
                                    successMessage: 'Mensaje completo copiado.',
                                  );
                                },
                                icon: const Icon(Icons.ios_share),
                                label: const Text('Copiar mensaje completo'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}