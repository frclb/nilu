import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Görsellerin ağa bağımlı olmadığını doğrular.
///
/// Uygulamadaki 13 görselin tamamı Google'ın `lh3.googleusercontent.com/
/// aida-public/...` adreslerinden geliyordu. Bunlar tasarım aracının ürettiği
/// geçici bağlantılar: biri mağazaya çıkmadan HTTP 400 dönmeye başlamıştı
/// (kütüphanedeki öne çıkan makale), gerisi de aynı hostta bekliyordu.
///
/// Tasarım dosyalarından kopyalanan yeni bir ekranla bu adreslerin geri
/// gelmesi kolay; test onu derleme aşamasında yakalar.
void main() {
  /// Tasarım aracı çıktısı olan, kalıcılığı garanti edilmeyen adresler.
  const forbiddenHosts = ['lh3.googleusercontent.com', 'aida-public'];

  late List<File> dartFiles;

  setUpAll(() {
    dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  });

  test('hiçbir ekranda geçici mockup görsel adresi yok', () {
    final offenders = <String>[];

    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Belgelendirme satırları hariç: sorunu anlatan yorumlar kalmalı.
        if (line.trimLeft().startsWith('//')) continue;
        for (final host in forbiddenHosts) {
          if (line.contains(host)) {
            offenders.add('${file.path}:${i + 1}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Geçici mockup adresi geri gelmiş. Görseli ContentIllustration ile '
          'çizin ya da kalıcı bir adresi SafeNetworkImage üzerinden verin.\n'
          '${offenders.join('\n')}',
    );
  });

  test('çıplak Image.network kullanılmıyor', () {
    // Uzak görsel yalnızca SafeNetworkImage üzerinden gelmeli: orada hem
    // errorBuilder hem yükleme sırasında gösterilecek içerik var. Önceki
    // kodda dört çağrıda errorBuilder hiç yoktu, adres ölünce kullanıcı
    // gri bir boşluk görüyordu.
    // `SafeNetworkImage` sarmalayıcısının kendisi eşleşmesin: adı
    // `NetworkImage(` dizesini içeriyor.
    final bareNetworkImage = RegExp(
      r'(?<![A-Za-z])(Image\.network|NetworkImage)\(',
    );
    final offenders = <String>[];

    for (final file in dartFiles) {
      if (file.path.endsWith('content_illustration.dart')) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (bareNetworkImage.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Uzak görsel SafeNetworkImage üzerinden gösterilmeli.\n'
          '${offenders.join('\n')}',
    );
  });
}
