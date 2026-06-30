import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login_screen.dart';
import '../widgets/feedback_footer.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  Future<void> _openLegalPage(String path) async {
    final uri = Uri.base.resolve(path);

    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  void _openAuth(BuildContext context, {required bool registerMode}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(initialRegisterMode: registerMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const fieldGreen = Color(0xFF0B7A3B);
    const darkGreen = Color(0xFF052E1A);
    // const grassGreen = Color(0xFF13A85B);
    const nearBlack = Color(0xFF07130D);

    return Scaffold(
      backgroundColor: nearBlack,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [nearBlack, darkGreen, fieldGreen],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 16),
                  const _LandingHeader(),
                  const SizedBox(height: 28),
                  _HeroCard(
                    onCreateAccount: () {
                      _openAuth(context, registerMode: true);
                    },
                    onLogin: () {
                      _openAuth(context, registerMode: false);
                    },
                  ),
                  const SizedBox(height: 20),
                  const _HowItWorksSection(),
                  const SizedBox(height: 20),
                  const _PrivacySection(),
                  const SizedBox(height: 20),
                  _LegalFooter(
                    onInstall: () => _openLegalPage('/install.html'),
                    onPrivacy: () => _openLegalPage('/privacy.html'),
                    onTerms: () => _openLegalPage('/terms.html'),
                    onAccountDeletion: () =>
                        _openLegalPage('/account-deletion.html'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Text(
                      'Aplicación independiente para intercambiar láminas coleccionables. '
                      'No estamos afiliados, patrocinados ni respaldados por marcas, '
                      'editoriales, federaciones o eventos deportivos oficiales.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Versión PWA en validación inicial',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FeedbackFooter(dark: true),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Versión PWA en validación inicial',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LandingHeader extends StatelessWidget {
  const _LandingHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.style, color: Color(0xFF0B7A3B)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'TruequeGol: Intercambio de Láminas',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onCreateAccount, required this.onLogin});

  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    const grassGreen = Color(0xFF13A85B);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;

            final textColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: grassGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Encuentra intercambios cerca de ti',
                    style: TextStyle(
                      color: Color(0xFF0B7A3B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Completa tu colección conectando con personas compatibles',
                  style: TextStyle(
                    color: Color(0xFF07130D),
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                    height: 1.05,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Pega tu lista de faltantes y repetidas, haz MATCH con amigos o gente de tu zona y descubre posibles intercambios',
                  style: TextStyle(
                    color: Color(0xFF405247),
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: onCreateAccount,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Crear cuenta'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0B7A3B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onLogin,
                      icon: const Icon(Icons.login),
                      label: const Text('Iniciar sesión'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B7A3B),
                        side: const BorderSide(color: Color(0xFF0B7A3B)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );

            final visual = const _PitchPreview();

            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 6, child: textColumn),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: visual),
                ],
              );
            }

            return Column(
              children: [textColumn, const SizedBox(height: 24), visual],
            );
          },
        ),
      ),
    );
  }
}

class _PitchPreview extends StatelessWidget {
  const _PitchPreview();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.05,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B7A3B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 3,
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 3,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            Positioned(
              left: 18,
              top: 42,
              bottom: 42,
              child: Container(
                width: 42,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 42,
              bottom: 42,
              child: Container(
                width: 42,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const Positioned(
              left: 24,
              top: 24,
              child: _MiniCard(label: 'Matches', value: '12'),
            ),
            const Positioned(
              right: 24,
              bottom: 24,
              child: _MiniCard(label: 'Faltantes', value: '320'),
            ),
            const Positioned(
              left: 24,
              bottom: 24,
              child: _MiniCard(label: 'Repetidas', value: '60'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0B7A3B),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF07130D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Cómo funciona',
      children: [
        _FeatureItem(
          icon: Icons.checklist,
          title: 'Marca tu colección',
          text:
              'Registra faltantes, obtenidas y repetidas pegando tu lista o con toques rápidos.',
        ),
        _FeatureItem(
          icon: Icons.groups_2_outlined,
          title: 'Encuentra personas compatibles',
          text:
              'La app calcula cuántas láminas puedes dar y cuántas puedes recibir.',
        ),
        _FeatureItem(
          icon: Icons.favorite_border,
          title: 'Haz match antes de contactar',
          text:
              'Primero ambos dan like. Después se desbloquea el detalle del intercambio.',
        ),
      ],
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Privacidad primero',
      children: [
        _FeatureItem(
          icon: Icons.location_on_outlined,
          title: 'Sin ubicación exacta',
          text:
              'Solo se usa comuna o ubicación aproximada seleccionada manualmente.',
        ),
        _FeatureItem(
          icon: Icons.lock_outline,
          title: 'Contacto bajo tu control',
          text:
              'Tu contacto solo será visible para los matches a quienes tú decidas mostrárselo.',
        ),
        _FeatureItem(
          icon: Icons.block,
          title: 'Reportes y bloqueos',
          text: 'Puedes reportar o bloquear usuarios si algo no corresponde.',
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF07130D),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF13A85B).withValues(alpha: 0.14),
            foregroundColor: const Color(0xFF0B7A3B),
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF07130D),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF405247),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({
    required this.onInstall,
    required this.onPrivacy,
    required this.onTerms,
    required this.onAccountDeletion,
  });

  final VoidCallback onInstall;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;
  final VoidCallback onAccountDeletion;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        TextButton.icon(
          onPressed: onInstall,
          icon: const Icon(Icons.install_mobile, color: Colors.white, size: 18),
          label: const Text(
            'Instalar como app',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: onPrivacy,
          child: const Text(
            'Política de privacidad',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: onTerms,
          child: const Text(
            'Términos y condiciones',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: onAccountDeletion,
          child: const Text(
            'Eliminar cuenta y datos',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
