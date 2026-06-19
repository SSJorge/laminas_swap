import 'match_candidate.dart';

class ConfirmedMatch {
  const ConfirmedMatch({
    required this.candidate,
    required this.description,
    required this.contactType,
    required this.contactValue,
    required this.contactVisible,
  });

  final MatchCandidate candidate;
  final String description;
  final String contactType;
  final String contactValue;
  final bool contactVisible;

  bool get hasDescription => description.trim().isNotEmpty;

  bool get hasVisibleContact =>
      contactVisible && contactValue.trim().isNotEmpty;

  String get contactLabel {
    if (contactType == 'phone') {
      return 'Número';
    }

    return 'Correo';
  }
}
