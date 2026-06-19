import '../data/profile_constants.dart';

String cleanDisplayName(String value) {
  return value.trim();
}

String displayNameKeyFrom(String value) {
  return cleanDisplayName(value).toLowerCase();
}

String validateDisplayName(String value) {
  final cleanName = cleanDisplayName(value);

  if (cleanName.isEmpty) {
    throw Exception('El nombre visible es obligatorio.');
  }

  if (cleanName.length > displayNameMaxLength) {
    throw Exception(
      'El nombre visible no puede superar $displayNameMaxLength caracteres.',
    );
  }

  final validPattern = RegExp(r'^[a-zA-Z0-9._]+$');

  if (!validPattern.hasMatch(cleanName)) {
    throw Exception(
      'Usa solo letras, números, punto o guion bajo. No uses espacios.',
    );
  }

  if (cleanName.startsWith('.') ||
      cleanName.endsWith('.') ||
      cleanName.contains('..')) {
    throw Exception('El punto no puede ir al inicio, al final ni repetido.');
  }

  return cleanName;
}
