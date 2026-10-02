import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/calendar/widgets/calendar_grid.dart';

/// Ardışık iki regl gününün birleştiği yerdeki dikiş.
///
/// Bant her hücrede ayrı bir kap olarak çiziliyor ve komşu hücreyle aynı
/// noktada bitiyordu. İki kenar da ayrı ayrı kenar yumuşatmadan geçtiği için
/// sınır pikselini ikisi birden yarım kaplıyor, arada zemin kalıyordu:
/// bandın `(178, 74, 102)` rengi dikişte `(197, 118, 139)`'a açılan, tek
/// piksel genişliğinde **keskin bir çizgi** bırakıyordu.
///
/// Bu dosya ekranı gerçekten çizip pikselleri okuyor. Widget ağacına bakan
/// bir test bunu göremezdi: kusur ağaçta değil, rasterleştirmede.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Ay içinde, aynı satırda kalan ardışık iki gün seçer.
  ///
  /// Pazar satırı bitirdiği için oradan başlanamaz; testin hangi ayda
  /// koştuğuna bağlı kalmaması gerekiyor.
  (DateTime, DateTime) adjacentPair() {
    final now = DateTime.now();
    for (var day = 3; day <= 25; day++) {
      final date = DateTime(now.year, now.month, day);
      if (date.weekday != DateTime.sunday) {
        return (date, date.add(const Duration(days: 1)));
      }
    }
    throw StateError('uygun gün bulunamadı');
  }

  Future<List<double>> bandProfile(WidgetTester tester) async {
    final key = GlobalKey();
    final (first, second) = adjacentPair();

    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late List<double> profile;
    await tester.runAsync(() async {
      await PeriodRepository().savePeriodLogs([
        PeriodLog(id: 'p', startDate: first, endDate: second),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppFlavor.plum),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr')],
          locale: const Locale('tr'),
          home: Scaffold(
            body: MultiProvider(
              // Uygulamadaki gibi: ızgara gebelik izini de okuyor.
              providers: [
                ChangeNotifierProvider(create: (_) => PregnancyViewModel()),
                ChangeNotifierProvider(create: (_) => CalendarViewModel()),
              ],
              child: Center(
                child: RepaintBoundary(
                  key: key,
                  child: const SizedBox(width: 340, child: CalendarGrid()),
                ),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    // Kare tamamlanmadan `RepaintBoundary`'nin bağlamı yok; çizim bitsin.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List();

      double lum(int x, int y) {
        final i = (y * image.width + x) * 4;
        return 0.2126 * bytes[i] +
            0.7152 * bytes[i + 1] +
            0.0722 * bytes[i + 2];
      }

      /// Kayıtlı regl bandının pikseli mi?
      ///
      /// Parlaklığa bakılamıyor: kırpılmış alanın saydam pikselleri de koyu
      /// görünüyor ve en "koyu" satır olarak boş bir satır seçiliyordu.
      /// Bant erik: kırmızı kanalı yeşilden belirgin yüksek. Eşik tahmin
      /// bandını dışarıda bırakacak kadar yüksek — o tül katman zemine
      /// karışıyor ve farkı ~30'a düşüyor.
      bool isBand(int x, int y) {
        final i = (y * image.width + x) * 4;
        if (bytes[i + 3] < 200) return false;
        return bytes[i] - bytes[i + 1] > 60 && bytes[i] > 140;
      }

      var bandY = 0;
      var best = 0;
      for (var y = 0; y < image.height; y++) {
        var n = 0;
        for (var x = 0; x < image.width; x++) {
          if (isBand(x, y)) n++;
        }
        if (n > best) {
          best = n;
          bandY = y;
        }
      }

      // O satırdaki en uzun kesintisiz bant koşusu.
      var start = -1, end = -1, runStart = -1;
      for (var x = 0; x <= image.width; x++) {
        final on = x < image.width && isBand(x, bandY);
        if (on && runStart < 0) runStart = x;
        if (!on && runStart >= 0) {
          if (x - runStart > end - start) {
            start = runStart;
            end = x;
          }
          runStart = -1;
        }
      }
      // Uçlardaki birkaç piksel atlanıyor: yuvarlak kapağın zeminle
      // sınırı zaten keskin, ölçülmek istenen içerideki dikiş.
      const trim = 5;
      profile = [for (var x = start + trim; x < end - trim; x++) lum(x, bandY)];
    });
    return profile;
  }

  testWidgets('bandın içinde keskin bir çizgi yok', (tester) async {
    final profile = await bandProfile(tester);
    expect(profile.length, greaterThan(40), reason: 'bant bulunamadı');

    var worst = 0.0;
    var worstAt = 0;
    for (var i = 1; i < profile.length; i++) {
      final jump = (profile[i] - profile[i - 1]).abs();
      if (jump > worst) {
        worst = jump;
        worstAt = i;
      }
    }

    // Eskiden dikiş tek pikselde 38 birim sıçrıyordu. Yumuşak geçişte en
    // sert değişim bunun çok altında kalmalı.
    expect(
      worst,
      lessThan(20),
      reason:
          'Bant içinde $worstAt. pikselde ${worst.toStringAsFixed(0)} '
          'birimlik sıçrama var: iki hücrenin kabı arasından zemin sızıyor.',
    );
  });

  testWidgets('geçiş görünür biçimde yumuşuyor', (tester) async {
    final profile = await bandProfile(tester);

    final body = profile[profile.length ~/ 8];
    final middle = profile.sublist(
      profile.length * 2 ~/ 5,
      profile.length * 3 ~/ 5,
    );

    // Ayırt edici olan tepe değil, **ara ton sayısı**. Eski keskin dikiş de
    // "ortası daha açık" koşulunu sağlıyordu: iki ton arasında tek piksellik
    // bir sıçrama. Yumuşak geçişte arada onlarca ara ton oluyor.
    final shades = middle.map((v) => v.round()).toSet().length;
    expect(
      shades,
      greaterThan(5),
      reason:
          'Geçişte yalnızca $shades ton var: soluklaşma değil, '
          'keskin bir çizgi.',
    );

    // Ama "hafif" kalmalı; bant ikiye bölünmüş gibi görünmemeli.
    final peak = middle.reduce((a, b) => a > b ? a : b);
    expect(
      peak - body,
      lessThan(40),
      reason: 'Geçiş fazla açık: bant tek parça okunmuyor.',
    );
  });
}
