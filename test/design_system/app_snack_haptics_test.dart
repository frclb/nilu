import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/core/platform/app_platform.dart';
import 'package:period_tracker/core/platform/apple_health_icon.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_snack.dart';
import 'package:period_tracker/design_system/app_theme.dart';

/// Sonuç bildirimleri titreşimle de geliyor (Apple'ın geri bildirim
/// yönergeleri): başarı ve hata ayrı titreşiyor, nötr bildirim titreşmiyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('nilu/haptics');
  final calls = <Object?>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'notify') calls.add(call.arguments);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<BuildContext> pump(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppFlavor.plum),
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return context;
  }

  testWidgets('başarı ve hata kendi titreşimini çalıyor', (tester) async {
    final context = await pump(tester);

    AppSnack.success(context, 'Kaydedildi');
    await tester.pump();
    expect(find.text('Kaydedildi'), findsOneWidget);

    AppSnack.error(context, 'Olmadı');
    await tester.pump();
    expect(find.text('Olmadı'), findsOneWidget);

    AppSnack.of(context).warning('Eksik kaldı');
    await tester.pump();

    expect(calls, ['success', 'error', 'warning']);
  });

  testWidgets('nötr bildirim titreşmiyor', (tester) async {
    final context = await pump(tester);

    AppSnack.show(context, 'Kopyalandı');
    await tester.pump();

    expect(find.text('Kopyalandı'), findsOneWidget);
    expect(calls, isEmpty);
  });

  test('Apple Sağlık simgesi Android paketinde yok', () async {
    // Lisans simgeyi yalnızca iOS'ta kullanmaya izin veriyor: Flutter
    // varlıklarında değil, iOS'un Assets.xcassets'inde duruyor.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('apple_health')));
    expect(
      File(
        'ios/Runner/Assets.xcassets/AppleHealthIcon.imageset/apple_health@3x.png',
      ).existsSync(),
      isTrue,
    );

    AppPlatform.debugAndroid = true;
    addTearDown(() => AppPlatform.debugAndroid = null);
    expect(await AppleHealthIcon.load(), isNull);
  });
}
