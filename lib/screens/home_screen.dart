import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cards_screen.dart';
import 'matching_screen.dart';
import 'profile_screen.dart';

import 'confirmed_matches_screen.dart';
import 'received_likes_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                Text(
                  'Hola, $displayName',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Registra tus láminas, configura tu perfil y encuentra intercambios cercanos.',
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Perfil'),
                    subtitle: const Text(
                      'Configura nombre, comuna y forma de contacto privada.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.style),
                    title: const Text('Láminas'),
                    subtitle: const Text(
                      'Marca faltantes, obtenidas y repetidas.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CardsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text('Descubrir'),
                    subtitle: const Text(
                      'Encuentra usuarios compatibles y dales like o dislike.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MatchingScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.favorite_border),
                    title: const Text('Likes recibidos'),
                    subtitle: const Text(
                      'Personas que te dieron like. Responde para crear match.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReceivedLikesScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.handshake_outlined),
                    title: const Text('Mis matches'),
                    subtitle: const Text(
                      'Matches mutuos con descripción y contacto permitido.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ConfirmedMatchesScreen(),
                        ),
                      );
                    },
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
