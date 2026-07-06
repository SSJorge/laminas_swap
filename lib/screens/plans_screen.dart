import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  static const String contactEmail = 'trueque.gol.contacto@gmail.com';

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: contactEmail));

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Correo copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    const plans = [
      _PlanInfo(
        name: 'Gratis',
        price: '\$0',
        priceLabel: 'permanente',
        icon: Icons.lock_open,
        highlight: false,
        features: [
          '20 likes diarios',
          '100 dislikes diarios',
          '50 búsquedas exactas diarias',
          '20 cambios de comuna diarios',
          'Con espacios publicitarios',
          'Publicaciones disponibles durante la beta',
        ],
      ),
      _PlanInfo(
        name: 'Sin anuncios',
        price: '\$750',
        priceLabel: 'pago único',
        icon: Icons.block,
        highlight: false,
        badgeLabel: 'fundador',
        features: [
          'Sin espacios publicitarios',
          '30 likes diarios',
          '120 dislikes diarios',
          '53 búsquedas exactas diarias',
          '30 cambios de comuna diarios',
          'No es una suscripción mensual',
        ],
      ),
      _PlanInfo(
        name: 'Premium',
        price: '\$750',
        priceLabel: 'pago único',
        icon: Icons.workspace_premium,
        highlight: false,
        badgeLabel: 'fundador',
        features: [
          '40 likes diarios',
          '200 dislikes diarios',
          '100 búsquedas exactas diarias',
          '40 cambios de comuna diarios',
          'Publicar podrá pasar a ser función Premium cuando la app se masifique',
          'Funciones premium futuras, como búsqueda avanzada por lámina',
          'No quita anuncios por sí solo',
        ],
      ),
      _PlanInfo(
        name: 'Pack permanente',
        price: '\$1000',
        priceLabel: 'pago único',
        icon: Icons.local_fire_department,
        highlight: true,
        badgeLabel: 'mejor opción',
        features: [
          'Incluye Sin anuncios',
          'Incluye Premium',
          '40 likes diarios',
          '200 dislikes diarios',
          '100 búsquedas exactas diarias',
          '40 cambios de comuna diarios',
          'Mejor relación precio/beneficio',
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Planes')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _HeaderCard(),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  final cardWidth = isWide
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final plan in plans)
                        SizedBox(
                          width: cardWidth,
                          child: _PlanCard(plan: plan),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _BetaNoticeCard(onCopyEmail: () => _copyEmail(context)),
              const SizedBox(height: 16),
              const _LegalSmallNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0B7A3B),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              Icons.savings_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              'Planes permanentes',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paga una vez y mantén los beneficios mientras TruequeGol esté operativo. No son suscripciones mensuales.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanInfo {
  const _PlanInfo({
    required this.name,
    required this.price,
    required this.priceLabel,
    required this.icon,
    required this.highlight,
    required this.features,
    this.badgeLabel,
  });

  final String name;
  final String price;
  final String priceLabel;
  final IconData icon;
  final bool highlight;
  final List<String> features;
  final String? badgeLabel;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final _PlanInfo plan;

  @override
  Widget build(BuildContext context) {
    final borderColor = plan.highlight
        ? const Color(0xFF0B7A3B)
        : Theme.of(context).colorScheme.outlineVariant;

    return Card(
      elevation: plan.highlight ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor, width: plan.highlight ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(
                    0xFF0B7A3B,
                  ).withValues(alpha: 0.12),
                  foregroundColor: const Color(0xFF0B7A3B),
                  child: Icon(plan.icon),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                if (plan.badgeLabel != null) _PlanBadge(label: plan.badgeLabel!),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.price,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    plan.priceLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final feature in plan.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Color(0xFF0B7A3B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0B7A3B),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _BetaNoticeCard extends StatelessWidget {
  const _BetaNoticeCard({required this.onCopyEmail});

  final VoidCallback onCopyEmail;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Planes fundadores',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Los primeros 100 planes tendrán 50\% de descuento.\n'
              'Actualmente no está integrado el sistema de pagos. '
              'Si quieres activar un plan permanente fundador, escríbeme a '
              'trueque.gol.contacto@gmail.com para obtener los datos de transferencia.\n\n'
              'Los planes pagados son de pago único: no son mensuales ni se renuevan automáticamente. '
              'El acceso se mantiene mientras TruequeGol esté operativo.\n\n'
              'Durante la beta, publicar está disponible para todos. '
              'Cuando la app se masifique, publicar podrá pasar a ser una función Premium.\n\n'
              'Mantenimiento correctivo garantizado hasta el 31 de diciembre de 2026. '
              'Después de esa fecha, la app podrá seguir disponible, pero no se garantiza soporte, nuevas funciones ni corrección de fallas.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCopyEmail,
                icon: const Icon(Icons.copy),
                label: const Text('Copiar correo de contacto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSmallNote extends StatelessWidget {
  const _LegalSmallNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      '“Permanente” significa pago único con beneficios activos mientras TruequeGol siga operativo. '
      'No significa acceso de por vida. '
      'Los planes, límites y funciones pueden ajustarse durante la beta. '
      'La app es independiente y no está afiliada, patrocinada ni respaldada '
      'por marcas, federaciones, editoriales o eventos deportivos oficiales.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}