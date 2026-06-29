import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/commune_post.dart';
import '../services/commune_post_repository.dart';
import '../services/matching_repository.dart';

class CommunePostsScreen extends StatefulWidget {
  const CommunePostsScreen({super.key});

  @override
  State<CommunePostsScreen> createState() => _CommunePostsScreenState();
}

class _CommunePostsScreenState extends State<CommunePostsScreen> {
  final _searchController = TextEditingController();

  late final CommunePostRepository _postRepository;
  late final MatchingRepository _matchingRepository;
  late Future<CurrentUserPostProfile> _profileFuture;

  bool _isCreating = false;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();

    final db = FirebaseFirestore.instance;

    _postRepository = CommunePostRepository(db);
    _matchingRepository = MatchingRepository(db);
    _profileFuture = _loadProfile();

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<CurrentUserPostProfile> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No hay usuario autenticado.');
    }

    return _postRepository.loadCurrentUserProfile(user.uid);
  }

  Future<void> _reloadProfile() async {
    setState(() {
      _profileFuture = _loadProfile();
    });

    await _profileFuture;
  }

  Future<void> _openCreatePostSheet() async {
    if (_isCreating) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final alreadyPosted = await _postRepository.hasTodayPost(user.uid);

      if (!mounted) {
        return;
      }

      if (alreadyPosted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya publicaste hoy en tu comuna.')),
        );
        return;
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }

    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final controller = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            final cleanText = controller.text.trim();
            final canPublish =
                cleanText.isNotEmpty &&
                cleanText.length <= CommunePostRepository.maxTextLength;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nueva publicación',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Puedes publicar una vez al día en tu comuna actual.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: CommunePostRepository.maxTextLength,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ej: vendo Messi a 8k',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: canPublish
                              ? () {
                                  Navigator.of(sheetContext).pop(cleanText);
                                }
                              : null,
                          icon: const Icon(Icons.send),
                          label: const Text('Publicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (text == null || text.trim().isEmpty) {
      return;
    }

    await _createPost(text);
  }

  Future<void> _createPost(String text) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await _postRepository.createTodayPost(uid: user.uid, text: text);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Publicación creada.')));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _handlePostTap(CommunePost post) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    if (post.uid == user.uid) {
      await _showDeletePostDialog(post);
      return;
    }

    await _showAuthorDialog(post);
  }

  Future<void> _showDeletePostDialog(CommunePost post) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar publicación'),
          content: Text(
            '¿Quieres eliminar esta publicación?\n\n"${post.text}"',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _postRepository.deletePost(post);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Publicación eliminada.')));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _showAuthorDialog(CommunePost post) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(child: Text(_initialFor(post.displayName))),
              const SizedBox(width: 12),
              Expanded(
                child: Text(post.displayName, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.comuna.isEmpty ? 'Sin comuna' : post.comuna),
              const SizedBox(height: 12),
              Text(post.text, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              const Text(
                'Si le das like y esa persona también te da like, aparecerá en tus matches.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              onPressed: _isLiking
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _likeAuthor(post);
                    },
              icon: const Icon(Icons.favorite),
              label: const Text('Dar like'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _likeAuthor(CommunePost post) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _isLiking) {
      return;
    }

    setState(() {
      _isLiking = true;
    });

    try {
      await _matchingRepository.setAction(
        fromUid: user.uid,
        targetUid: post.uid,
        action: 'like',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Like enviado a ${post.displayName}.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  String _initialFor(String value) {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty) {
      return '?';
    }

    return cleanValue[0].toUpperCase();
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'recién';
    }

    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Publicaciones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : _openCreatePostSheet,
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: FutureBuilder<CurrentUserPostProfile>(
            future: _profileFuture,
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (profileSnapshot.hasError) {
                return RefreshIndicator(
                  onRefresh: _reloadProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      const Icon(Icons.info_outline, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        'No se pudieron cargar publicaciones',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profileSnapshot.error.toString().replaceFirst(
                          'Exception: ',
                          '',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: FilledButton.tonalIcon(
                          onPressed: _reloadProfile,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final profile = profileSnapshot.data!;

              return StreamBuilder<List<CommunePost>>(
                stream: _postRepository.watchPostsForCommune(
                  communeKey: profile.communeKey,
                ),
                builder: (context, postsSnapshot) {
                  final posts = postsSnapshot.data ?? [];
                  final query = _searchController.text;
                  final filteredPosts = posts.where((post) {
                    return post.matchesSearch(query);
                  }).toList();

                  return RefreshIndicator(
                    onRefresh: _reloadProfile,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Publicaciones de ${profile.comuna}. '
                              'Puedes publicar una vez al día en tu comuna actual.',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Buscar publicación',
                            hintText: 'Ej: mess, Messi, vendo',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (postsSnapshot.connectionState ==
                            ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator())
                        else if (postsSnapshot.hasError)
                          Text(
                            postsSnapshot.error.toString().replaceFirst(
                              'Exception: ',
                              '',
                            ),
                            textAlign: TextAlign.center,
                          )
                        else if (posts.isEmpty)
                          const _EmptyPostsMessage(
                            title: 'No hay publicaciones todavía',
                            message: 'Sé el primero en publicar en tu comuna.',
                          )
                        else if (filteredPosts.isEmpty)
                          const _EmptyPostsMessage(
                            title: 'Sin resultados',
                            message:
                                'No hay publicaciones que coincidan con tu búsqueda.',
                          )
                        else
                          for (final post in filteredPosts) ...[
                            _CommunePostCard(
                              post: post,
                              isMine: post.uid == user?.uid,
                              initial: _initialFor(post.displayName),
                              dateText: _formatDate(post.createdAt),
                              onTap: () => _handlePostTap(post),
                            ),
                            const SizedBox(height: 12),
                          ],
                        const SizedBox(height: 88),
                      ],
                    ),
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

class _CommunePostCard extends StatelessWidget {
  const _CommunePostCard({
    required this.post,
    required this.isMine,
    required this.initial,
    required this.dateText,
    required this.onTap,
  });

  final CommunePost post;
  final bool isMine;
  final String initial;
  final String dateText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Text(initial)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          post.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (isMine)
                          Chip(
                            label: const Text('Tuya'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.text,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(isMine ? Icons.more_vert : Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPostsMessage extends StatelessWidget {
  const _EmptyPostsMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          const Icon(Icons.forum_outlined, size: 56),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
