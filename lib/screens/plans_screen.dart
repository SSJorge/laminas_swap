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
        monthlyLabel: 'mensual',
        icon: Icons.lock_open,
        highlight: false,
        features: [
          '3 likes diarios',
          '20 dislikes diarios',
          '3 búsquedas exactas diarias',
          '3 cambios de comuna diarios',
          '3 usuarios + 1 espacio de anuncio en Descubrir',
        ],
      ),
      _PlanInfo(
        name: 'Sin anuncios',
        price: '\$500',
        monthlyLabel: 'mensual',
        icon: Icons.block,
        highlight: false,
        discountLabel: '50% descuento',
        features: [
          'Sin espacios publicitarios',
          'Mejor experiencia visual',
          'Mantiene funciones base del plan gratis',
          'Ideal si solo quieres usar la app sin anuncios',
        ],
      ),
      _PlanInfo(
        name: 'Premium',
        price: '\$500',
        monthlyLabel: 'mensual',
        icon: Icons.workspace_premium,
        highlight: false,
        discountLabel: '50% descuento',
        features: [
          'Límites diarios aumentados',
          '15 likes diarios',
          '80 dislikes diarios',
          '15 búsquedas exactas',
          '10 cambios de comuna',
          'Funciones premium futuras, como búsqueda avanzada por lámina o tarjeta específica',
        ],
      ),
      _PlanInfo(
        name: 'Pack',
        price: '\$750',
        monthlyLabel: 'mensual',
        icon: Icons.local_fire_department,
        highlight: true,
        discountLabel: '50% descuento',
        features: [
          'Incluye Sin anuncios',
          'Incluye Premium',
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

                  if (isWide) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: plans.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.05,
                          ),
                      itemBuilder: (context, index) {
                        return _PlanCard(plan: plans[index]);
                      },
                    );
                  }

                  return Column(
                    children: [
                      for (final plan in plans) ...[
                        _PlanCard(plan: plan),
                        const SizedBox(height: 12),
                      ],
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.savings_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              'Planes mensuales',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Compara el plan gratis, quitar anuncios, premium y el pack completo.',
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
    required this.monthlyLabel,
    required this.icon,
    required this.highlight,
    required this.features,
    this.discountLabel,
  });

  final String name;
  final String price;
  final String monthlyLabel;
  final IconData icon;
  final bool highlight;
  final List<String> features;
  final String? discountLabel;
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
                if (plan.discountLabel != null) const _DiscountBadge(),
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
                    plan.monthlyLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
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
                          Expanded(child: Text(feature)),
                        ],
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

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '50% de descuento fundador',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.percent, color: Colors.white, size: 14),
            SizedBox(width: 2),
            Text(
              '50%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
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
                    'Versión beta',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Actualmente no está integrado el sistema de pagos. '
              'Aun así, si quieres suscribirte con anticipo, escríbeme a '
              'trueque.gol.contacto@gmail.com para obtener los datos de transferencia. Las primeras 100 suscripciones '
              'estarán con 50% de descuento. Todo plan pagado en junio '
              'estará disponible hasta el 31 de julio.',
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
      'Los planes, límites y funciones pueden ajustarse durante la beta. '
      'La app es independiente y no está afiliada, patrocinada ni respaldada '
      'por marcas, federaciones, editoriales o eventos deportivos oficiales.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
