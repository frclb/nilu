// Lokalizasyon bütünlük denetimi. CI'da ve elle çalıştırılabilir:
//   dart run tool/check_localization.dart
//
// Denetler:
//   1. Her dil dosyası geçerli JSON mu?
//   2. Kodda `context.tr('...')` ile çağrılan her anahtar tanımlı mı?
//   3. Diller referans dille (tr) aynı anahtar setine sahip mi?
//
// Not: `de/es/fr/pt` henüz tamamlanmadıysa eksikler UYARI olarak raporlanır,
// hata sayılmaz — çalışma zamanında İngilizceye düşülür. Kodda çağrılıp
// hiçbir yerde tanımlı olmayan anahtar ise HATA'dır.

import 'dart:convert';
import 'dart:io';

const referenceLanguage = 'tr';
const fallbackLanguage = 'en';
const localizationDir = 'lib/localization';

void main() {
  var hasError = false;

  // ── 1. Dil dosyalarını yükle ──
  final files =
      Directory(localizationDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final languages = <String, Set<String>>{};

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final code = name.replaceAll('.json', '');
    final raw = file.readAsStringSync().trim();

    if (raw.isEmpty) {
      languages[code] = <String>{};
      stdout.writeln('WARN  $name is empty (falls back to $fallbackLanguage)');
      continue;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        stderr.writeln('ERROR $name is not a JSON object');
        hasError = true;
        continue;
      }
      languages[code] = decoded.keys.toSet();
    } on FormatException catch (e) {
      stderr.writeln('ERROR $name is not valid JSON — $e');
      hasError = true;
    }
  }

  final reference = languages[referenceLanguage];
  final fallback = languages[fallbackLanguage];

  if (reference == null || fallback == null) {
    stderr.writeln(
      'ERROR $referenceLanguage.json and $fallbackLanguage.json are required',
    );
    exit(1);
  }

  // ── 2. Kodda kullanılan anahtarlar ──
  final usagePattern = RegExp(r"""\.tr\(\s*'([a-zA-Z0-9_]+)'""");
  final usedKeys = <String>{};

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    for (final match in usagePattern.allMatches(entity.readAsStringSync())) {
      usedKeys.add(match.group(1)!);
    }
  }

  // Bir anahtar en azından referans veya fallback dilde tanımlı olmalı.
  final defined = {...reference, ...fallback};
  final undefined = usedKeys.difference(defined).toList()..sort();

  if (undefined.isNotEmpty) {
    hasError = true;
    stderr.writeln(
      'ERROR ${undefined.length} key(s) used in code but never defined:',
    );
    for (final key in undefined) {
      stderr.writeln('        $key');
    }
  }

  // ── 3. Diller arası eşitlik ──
  final missingInFallback = reference.difference(fallback).toList()..sort();
  if (missingInFallback.isNotEmpty) {
    hasError = true;
    stderr.writeln(
      'ERROR $fallbackLanguage.json is the fallback and must be complete; '
      '${missingInFallback.length} key(s) missing:',
    );
    for (final key in missingInFallback) {
      stderr.writeln('        $key');
    }
  }

  for (final entry in languages.entries) {
    final code = entry.key;
    if (code == referenceLanguage || code == fallbackLanguage) continue;

    final missing = reference.difference(entry.value).length;
    final extra = entry.value.difference(reference).toList()..sort();

    if (missing > 0) {
      stdout.writeln(
        'WARN  $code.json is missing $missing of '
        '${reference.length} keys (falls back to $fallbackLanguage)',
      );
    }
    if (extra.isNotEmpty) {
      hasError = true;
      stderr.writeln(
        'ERROR $code.json defines ${extra.length} key(s) that do '
        'not exist in $referenceLanguage.json:',
      );
      for (final key in extra) {
        stderr.writeln('        $key');
      }
    }
  }

  if (hasError) {
    stderr.writeln('\nLocalization check failed.');
    exit(1);
  }

  stdout.writeln(
    '\nLocalization check passed '
    '(${reference.length} keys, ${usedKeys.length} used in code).',
  );
}
