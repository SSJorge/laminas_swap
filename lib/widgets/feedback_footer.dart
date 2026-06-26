import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackFooter extends StatelessWidget {
  const FeedbackFooter({super.key, this.dark = false});

  final bool dark;

  static const feedbackEmail = 'trueque.gol.contacto@gmail.com';

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      queryParameters: const {
        'subject': 'Comentario TruequeGol',
        'body': 'Hola, tengo el siguiente comentario:\n\n',
      },
    );

    final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copia el correo: $feedbackEmail')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = dark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    final mutedColor = baseColor.withValues(alpha: 0.70);
    final linkColor = dark
        ? Colors.white
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¿Tienes comentarios, ideas o encontraste un problema?',
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedColor, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Cualquier comentario sirve: ',
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedColor, fontSize: 12, height: 1.35),
              ),
              InkWell(
                onTap: () => _openEmail(context),
                child: Text(
                  feedbackEmail,
                  style: TextStyle(
                    color: linkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: linkColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Para comentarios generales, preferiblemente escribe desde un correo diferente al que usas para registrarte.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedColor, fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }
}
