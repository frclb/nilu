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
  //
  // Anahtarların hepsi kodda düz yazmıyor. Bir kısmı çalışma anında
  // kuruluyor:
  //
  //     context.tr('terms_section${i}_title')
  //     context.tr('log_mood_$code')
  //
  // Bunları saymayan bir denetim "866 anahtarın 483'ü kullanılıyor" diyordu
  // ve 383 anahtar ölü sanılıyordu. Gerçek sayı 47'ydi. Yanlış yöne bakan
  // bir rapor, rapor olmamasından kötü.
  final usagePattern = RegExp(r"""\.tr\(\s*'([a-zA-Z0-9_]+)'""");

  // İçinde değişken geçen anahtar dizeleri: 'log_mood_$code' gibi.
  final dynamicPattern = RegExp(r"""'([a-z][a-zA-Z0-9_]*\$[^']*)'""");

  // Anahtarın `.tr(...)` içinde geçmesi şart değil: veri modelleri anahtarı
  // alan olarak taşıyor (`titleKey: 'article_hormones_title'`) ve çeviri
  // başka yerde yapılıyor. Bunları saymayan denetim 252 anahtarı ölü
  // sanıyordu.
  final literalPattern = RegExp(r"""'([a-z][a-zA-Z0-9_]{3,})'""");

  // İki ayrı küme, çünkü iki ayrı soru soruluyor:
  //   calledKeys  -> `.tr(...)` ile çağrıldı, tanımlı OLMAK ZORUNDA
  //   mentionedKeys -> kodda bir yerde anıldı, yani ölü DEĞİL
  //
  // İkisini birleştirmek denetimi bozuyor: veri modellerindeki her kısa
  // dize ("acne", "calm") çağrılmış anahtar sanılıp "tanımsız" diye
  // raporlanıyordu.
  final calledKeys = <String>{};
  final mentionedKeys = <String>{};
  final dynamicKeyPatterns = <RegExp>[];

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = entity.readAsStringSync();

    for (final match in usagePattern.allMatches(source)) {
      calledKeys.add(match.group(1)!);
      mentionedKeys.add(match.group(1)!);
    }

    for (final match in literalPattern.allMatches(source)) {
      mentionedKeys.add(match.group(1)!);
    }

    for (final match in dynamicPattern.allMatches(source)) {
      final literal = match.group(1)!;
      final prefix = literal.split(r'$').first;

      // 'p$offset' ya da 'kart$i' anahtar değil. Anahtar ad uzayları uzun
      // ve alt çizgili olur; bu ayrım olmadan '^p.+$' her şeyi yutuyordu.
      if (prefix.length < 6 || !prefix.contains('_')) continue;

      final escaped = RegExp.escape(literal)
          .replaceAll(RegExp(r'\\\$\\\{[^}]*\\\}'), '[A-Za-z0-9_]+')
          .replaceAll(RegExp(r'\\\$[a-zA-Z_][a-zA-Z0-9_]*'), '[A-Za-z0-9_]+');
      dynamicKeyPatterns.add(RegExp('^$escaped\$'));
    }
  }

  bool isUsed(String key) =>
      mentionedKeys.contains(key) ||
      dynamicKeyPatterns.any((p) => p.hasMatch(key));

  // Bir anahtar en azından referans veya fallback dilde tanımlı olmalı.
  final defined = {...reference, ...fallback};
  final undefined = calledKeys.difference(defined).toList()..sort();

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

  // ── 4. Hiçbir yerde kullanılmayan anahtarlar ──
  //
  // Hata değil uyarı: ölü anahtar uygulamayı bozmuyor, yalnızca altı dilde
  // bakım yükü bırakıyor.
  // Bilerek duran, kullanılmayan anahtarlar.
  //
  // Sürekli tekrarlayan bir uyarı öğrenilip görmezden geliniyor; gerekçesi
  // yazılı bir istisna daha iyi.
  const intentionallyUnused = {
    // Partner bildirim ayarları ekranı kaldırıldı: yerele yazıyordu,
    // hiçbir yere yüklenmiyordu ve gönderen bir taraf yoktu. Anahtar,
    // satırın geri gelmediğini sınayan testin çıpası olarak duruyor
    // (test/presentation/device_sizes_test.dart).
    'profile_notification_settings',
  };

  final unused = reference
      .where((key) => !isUsed(key) && !intentionallyUnused.contains(key))
      .toList()..sort();
  if (unused.isNotEmpty) {
    stdout.writeln('WARN  ${unused.length} key(s) defined but never used:');
    for (final key in unused.take(20)) {
      stdout.writeln('        $key');
    }
    if (unused.length > 20) {
      stdout.writeln('        … ve ${unused.length - 20} tane daha');
    }
  }

  if (hasError) {
    stderr.writeln('\nLocalization check failed.');
    exit(1);
  }

  stdout.writeln(
    '\nLocalization check passed '
    '(${reference.length} keys, ${unused.length} unused).',
  );
}
