class StickerImportResult {
  final Map<String, Set<String>> missing;
  final Map<String, Set<String>> repeated;
  final List<String> ignoredLines;
  final List<String> warnings;

  const StickerImportResult({
    required this.missing,
    required this.repeated,
    required this.ignoredLines,
    required this.warnings,
  });

  int get missingCount =>
      missing.values.fold<int>(0, (sum, items) => sum + items.length);

  int get repeatedCount =>
      repeated.values.fold<int>(0, (sum, items) => sum + items.length);

  bool get hasAnyData => missingCount > 0 || repeatedCount > 0;
}

enum _ImportSection { none, missing, repeated }

StickerImportResult parseStickerImportList(String rawText) {
  final missing = <String, Set<String>>{};
  final repeated = <String, Set<String>>{};
  final ignoredLines = <String>[];
  final warnings = <String>[];

  var currentSection = _ImportSection.none;

  final lines = rawText
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  for (final line in lines) {
    final normalizedLine = _normalizeSectionText(line);

    if (normalizedLine == 'me faltan' ||
        normalizedLine == 'faltantes' ||
        normalizedLine == 'faltan') {
      currentSection = _ImportSection.missing;
      continue;
    }

    if (normalizedLine == 'repetidas' ||
    normalizedLine == 'repetidos' ||
    normalizedLine == 'tengo repetidas' ||
    normalizedLine == 'mis repetidas') {
  currentSection = _ImportSection.repeated;

  continue;
}

    if (_shouldIgnoreLine(line)) {
      ignoredLines.add(line);
      continue;
    }

    final parsedLine = _parseStickerLine(line);

    if (parsedLine == null) {
      ignoredLines.add(line);
      continue;
    }

    if (currentSection == _ImportSection.none) {
      ignoredLines.add(line);
      warnings.add(
        'Se ignoró una línea porque aparece antes de una sección: $line',
      );
      continue;
    }

    final targetMap = currentSection == _ImportSection.missing
        ? missing
        : repeated;

    targetMap.putIfAbsent(parsedLine.code, () => <String>{});
    targetMap[parsedLine.code]!.addAll(parsedLine.numbers);
  }

  final repeatedOverMissing = <String>[];

  for (final entry in repeated.entries) {
    final code = entry.key;
    final repeatedNumbers = entry.value;
    final missingNumbers = missing[code];

    if (missingNumbers == null) continue;

    final intersection = missingNumbers.intersection(repeatedNumbers);

    if (intersection.isNotEmpty) {
      repeatedOverMissing.add(
        '$code: ${intersection.toList()..sort((a, b) => _compareStickerNumbers(a, b))}',
      );
    }
  }

  if (repeatedOverMissing.isNotEmpty) {
    warnings.add(
      'Hay láminas marcadas como faltantes y repetidas a la vez. Al importar estados, conviene que "repetida" tenga prioridad.',
    );
  }

  return StickerImportResult(
    missing: missing,
    repeated: repeated,
    ignoredLines: ignoredLines,
    warnings: warnings,
  );
}

class _ParsedStickerLine {
  final String code;
  final Set<String> numbers;

  const _ParsedStickerLine({required this.code, required this.numbers});
}

_ParsedStickerLine? _parseStickerLine(String line) {
  // Formato esperado:
  // MEX 🇲🇽: 5 (×4), 15 (×2)
  // FWC 🏆: 00, 4
  // CC 🥤: 1, 2, 3
  final match = RegExp(r'^\s*([A-Z0-9]{2,5})\b.*?:\s*(.+)$').firstMatch(line);

  if (match == null) return null;

  final code = match.group(1)?.trim().toUpperCase();
  var numbersPart = match.group(2)?.trim();

  if (code == null ||
      code.isEmpty ||
      numbersPart == null ||
      numbersPart.isEmpty) {
    return null;
  }

  // Ignora cantidades de repetidas:
  // 5 (×4), 15 (x2), 2 ( X 3 )
  numbersPart = numbersPart.replaceAll(
    RegExp(r'\(\s*[x×]\s*\d+\s*\)', caseSensitive: false),
    '',
  );

  final numbers = RegExp(r'\b\d{1,2}\b')
      .allMatches(numbersPart)
      .map((m) => _normalizeStickerNumber(m.group(0)!))
      .toSet();

  if (numbers.isEmpty) return null;

  return _ParsedStickerLine(code: code, numbers: numbers);
}

String _normalizeStickerNumber(String value) {
  final trimmed = value.trim();

  // Mantiene "00" tal cual, porque FWC usa 00.
  if (trimmed == '00') return '00';

  // Normaliza "01" a "1", por si alguna lista viene con cero inicial.
  final parsed = int.tryParse(trimmed);
  if (parsed == null) return trimmed;

  return parsed.toString();
}

String _normalizeSectionText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(':', '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

bool _shouldIgnoreLine(String line) {
  final normalized = line.trim().toLowerCase();

  if (normalized.startsWith('figuritas app')) return true;
  if (normalized.contains('usa méx can')) return true;
  if (normalized.contains('usa mex can')) return true;
  if (normalized.startsWith('descarga la app')) return true;
  if (normalized.startsWith('http://')) return true;
  if (normalized.startsWith('https://')) return true;
  if (normalized.startsWith('www.')) return true;

  return false;
}

int _compareStickerNumbers(String a, String b) {
  if (a == '00' && b != '00') return -1;
  if (a != '00' && b == '00') return 1;

  final intA = int.tryParse(a);
  final intB = int.tryParse(b);

  if (intA != null && intB != null) return intA.compareTo(intB);

  return a.compareTo(b);
}

Map<String, int> buildStickerStatesFromImport({
  required StickerImportResult importResult,
  required Map<String, List<String>> albumStructure,
}) {
  final states = <String, int>{};

  // Primero todo como obtenido.
  for (final entry in albumStructure.entries) {
    final code = entry.key.toUpperCase();

    for (final number in entry.value) {
      final normalizedNumber = _normalizeStickerNumber(number);
      final cardId = '$code-$normalizedNumber';
      states[cardId] = 1;
    }
  }

  // Luego faltantes.
  for (final entry in importResult.missing.entries) {
    final code = entry.key.toUpperCase();

    for (final number in entry.value) {
      final cardId = '$code-$number';

      if (states.containsKey(cardId)) {
        states[cardId] = 0;
      }
    }
  }

  // Finalmente repetidas.
  // Tiene prioridad sobre faltante si hay contradicción.
  for (final entry in importResult.repeated.entries) {
    final code = entry.key.toUpperCase();

    for (final number in entry.value) {
      final cardId = '$code-$number';

      if (states.containsKey(cardId)) {
        states[cardId] = 2;
      }
    }
  }

  return states;
}
