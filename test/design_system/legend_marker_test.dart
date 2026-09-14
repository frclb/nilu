import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Takvim açıklamasındaki noktalar **işaret**; zemin tülü olamazlar.
///
/// Bir göç sırasında doğurganlık noktası `flowTint`e bağlanmıştı. O ton
/// hücrenin altına serilen bir zemin ve koyu temada zeminle 1.25:1 kalıyor —
/// nokta kayboluyor, üstelik açıklama ile takvimin boyadığı renk de
/// ayrışıyordu.
///
/// Tüllerin zemine yakınlığı sayıyla `theme_contrast_test.dart` içinde
/// ölçülüyor; buradaki kural ise **nerede kullanılamayacakları**. İkisi ayrı
/// sorular: biri tonun ne olduğunu, diğeri hangi rolde durduğunu koruyor.
void main() {
  test('takvim açıklaması işaret için tül kullanmıyor', () {
    final source = File(
      'lib/presentation/calendar/widgets/calendar_grid.dart',
    ).readAsStringSync();

    final calls = RegExp(
      r'_buildLegendItem\(([^;]*?)\),\s*\n',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!).toList();

    expect(calls, isNotEmpty, reason: 'açıklama çağrıları bulunamadı');
    for (final call in calls) {
      expect(
        call.contains('Tint'),
        isFalse,
        reason: 'açıklama noktası zemin tülü kullanıyor: ${call.trim()}',
      );
    }
  });
}
