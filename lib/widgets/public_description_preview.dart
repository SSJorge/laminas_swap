import 'package:flutter/material.dart';

class PublicDescriptionPreview extends StatelessWidget {
  const PublicDescriptionPreview({super.key, required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final cleanDescription = description.trim();

    if (cleanDescription.isEmpty) {
      return Text(
        'Sin descripción pública. El contacto sigue oculto hasta que haya match.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descripción pública',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(cleanDescription, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
