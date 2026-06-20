import 'match_candidate.dart';

class ConfirmedMatch {
  const ConfirmedMatch({
    required this.candidate,
    required this.description,
    required this.myContactSharedWithThem,
    required this.theirContactSharedWithMe,
    required this.theirContactType,
    required this.theirContactValue,
  });

  final MatchCandidate candidate;
  final String description;

  /// True si YO ya le mostré mi contacto a esta persona.
  final bool myContactSharedWithThem;

  /// True si ESTA PERSONA ya me mostró su contacto a mí.
  final bool theirContactSharedWithMe;

  final String theirContactType;
  final String theirContactValue;

  bool get hasDescription => description.trim().isNotEmpty;

  bool get hasVisibleContact {
    return theirContactSharedWithMe && theirContactValue.trim().isNotEmpty;
  }

  String get contactLabel {
    if (theirContactType == 'phone') {
      return 'Número';
    }

    return 'Correo';
  }
}
