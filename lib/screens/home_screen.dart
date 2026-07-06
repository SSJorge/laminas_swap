import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/matching_repository.dart';
import '../widgets/plan_status_card.dart';
// import '../widgets/username_prompt_listener.dart';
import 'cards_screen.dart';
import 'confirmed_matches_screen.dart';
import 'matching_screen.dart';
import 'profile_screen.dart';
import 'received_likes_screen.dart';
import 'user_search_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/feedback_footer.dart';
import 'commune_posts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MatchingRepository _matchingRepository;

  Future<int>? _receivedLikesCountFuture;
  Future<int>? _confirmedMatchesCountFuture;

  @override
  void initState() {
    super.initState();
    _matchingRepository = MatchingRepository(FirebaseFirestore.instance);
    _refreshCounters();
  }

  void _refreshCounters() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _receivedLikesCountFuture = Future.value(0);
      _confirmedMatchesCountFuture = Future.value(0);
      return;
    }

    _receivedLikesCountFuture = _loadReceivedLikesCount(user.uid);
    _confirmedMatchesCountFuture = _loadConfirmedMatchesCount(user.uid);
  }

  Future<void> _openStaticPage(String path) async {
    final uri = Uri.base.resolve(path);

    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Future<int> _loadReceivedLikesCount(String uid) async {
    try {
      final likes = await _matchingRepository.findReceivedLikes(uid: uid);
      return likes.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _loadConfirmedMatchesCount(String uid) async {
    try {
      final matches = await _matchingRepository.findConfirmedMatches(uid: uid);
      return matches.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _openScreen(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    if (!mounted) return;

    setState(() {
      _refreshCounters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                if (user != null)
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data();
                      final displayName =
                          data?['displayName'] ?? user.displayName ?? 'Usuario';

                      return Text(
                        'Hola, $displayName',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  )
                else
                  Text(
                    'Hola',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                const SizedBox(height: 16),
                const PlanStatusCard(),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.install_mobile),
                    title: const Text('Instalar como app'),
                    subtitle: const Text(
                      'Agrega TruequeGol a la pantalla de inicio de tu celular.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _openStaticPage('/install.html');
                    },
                  ),
                ),
                const SizedBox(height: 12),

                const SizedBox(height: 12),
                const Text(
                  'Registra tus láminas, configura tu perfil y encuentra intercambios cercanos.',
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Perfil'),
                    subtitle: const Text(
                      'Configura nombre, comuna, descripciones y forma de contacto privada.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _openScreen(const ProfileScreen());
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
                      _openScreen(const CardsScreen());
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
                      _openScreen(const MatchingScreen());
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.forum_outlined),
                    title: const Text('Publicaciones'),
                    subtitle: const Text(
                      'Publica y busca avisos de usuarios de tu comuna.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _openScreen(const CommunePostsScreen());
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
                    trailing: _CounterBadgeTrailing(
                      future: _receivedLikesCountFuture,
                    ),
                    onTap: () {
                      _openScreen(const ReceivedLikesScreen());
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
                    trailing: _CounterBadgeTrailing(
                      future: _confirmedMatchesCountFuture,
                    ),
                    onTap: () {
                      _openScreen(const ConfirmedMatchesScreen());
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_search),
                    title: const Text('Buscar usuario'),
                    subtitle: const Text(
                      'Busca a alguien por su nombre de usuario exacto.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _openScreen(const UserSearchScreen());
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Eliminar cuenta y datos'),
                    subtitle: const Text(
                      'Consulta cómo eliminar tu cuenta y los datos asociados.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _openStaticPage('/account-deletion.html');
                    },
                  ),
                ),
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

class _CounterBadgeTrailing extends StatelessWidget {
  const _CounterBadgeTrailing({required this.future});

  final Future<int>? future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return _BadgeChevron(count: count);
      },
    );
  }
}

class _BadgeChevron extends StatelessWidget {
  const _BadgeChevron({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const Icon(Icons.chevron_right);
    }

    final text = count > 99 ? '99+' : count.toString();

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(Icons.chevron_right),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
