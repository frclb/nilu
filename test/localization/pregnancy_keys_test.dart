import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/log_vocabulary.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/presentation/pregnancy/care_grouping.dart';

/// Gebelik ve lohusalık ekranlarının anahtarları altı dilde tanımlı mı?
///
/// Denetçi (`tool/check_localization.dart`) yalnızca düz `tr('...')`
/// çağrılarını görüyor. Bu ekranların bir kısmı anahtarı değişkenle
/// kuruyor — `care_group_${grup.name}`, `preg_outcome_${sonuc.name}` — ve
/// modele yeni bir değer eklendiğinde karşılığı yazılmazsa ekranda
/// anahtarın kendisi görünür. Sonlandırma ekranında bu, kaybını anlatacak
/// seçeneği "preg_outcome_…" olarak gören bir kullanıcı demek.
void main() {
  const diller = ['tr', 'en', 'de', 'fr', 'es', 'pt'];
  final sozluk = {
    for (final d in diller)
      d:
          (jsonDecode(File('lib/localization/$d.json').readAsStringSync())
                  as Map<String, dynamic>)
              .keys
              .toSet(),
  };

  final dinamik = {
    for (final g in CareGroup.values) 'care_group_${g.name}',
    for (final o in PregnancyOutcome.values) 'preg_outcome_${o.name}',
    for (final f in LogVocabulary.flowIntensities) LogVocabulary.flowKey(f),
  };

  /// Gebelik klasöründe düz yazılmış anahtarlar. Widget anahtarları
  /// (`Key('...')`) çeviri değil, hariç.
  Set<String> duz() {
    final desen = RegExp(
      r"(?<!Key\()'((?:preg|pp|care|calendar|profile|notif|nav)_[a-z0-9_]+)'",
    );
    return {
      for (final f in Directory('lib/presentation/pregnancy').listSync())
        if (f is File && f.path.endsWith('.dart'))
          ...desen.allMatches(f.readAsStringSync()).map((m) => m.group(1)!),
    };
  }

  test('tarama anahtar buluyor', () {
    // Boş tarama aşağıdaki testleri boşa geçirirdi.
    expect(
      duz(),
      containsAll(['preg_setup_title', 'pp_concern_body', 'care_empty']),
    );
    expect(duz(), isNot(contains('care_add_save')), reason: 'widget anahtarı');
  });

  for (final dil in diller) {
    test('$dil: gebelik ve lohusalık anahtarları tanımlı', () {
      final eksik = {...dinamik, ...duz()}.difference(sozluk[dil]!);
      expect(
        eksik,
        isEmpty,
        reason:
            '$dil sözlüğünde yok; ekranda anahtarın kendisi ya da '
            'İngilizcesi görünür:\n${eksik.join('\n')}',
      );
    });
  }
}
