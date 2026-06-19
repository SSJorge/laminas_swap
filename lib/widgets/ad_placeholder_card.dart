import 'package:flutter/material.dart';

class AdPlaceholderCard extends StatelessWidget {
  const AdPlaceholderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.campaign_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Espacio publicitario. Quita anuncios con el plan sin anuncios.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
