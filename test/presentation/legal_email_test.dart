import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/core/app_info.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/legal/privacy_policy_screen.dart';
import 'package:period_tracker/presentation/legal/terms_of_service_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Destek adresi politikada ve Şartlar'da tek kaynaktan.
///
/// Altı dilde on iki ayrı köşeli parantezli yer tutucu vardı; adres gelince
/// biri unutulursa kullanıcı haklarını kullanacağı adresi göremezdi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  for (final locale in AppLocalizations.supportedLanguageCodes) {
    for (final (ad, ekran) in [
      ('politika', const PrivacyPolicyScreen()),
      ('şartlar', const TermsOfServiceScreen()),
    ]) {
      testWidgets('$locale $ad: adres görünüyor, ham parametre yok', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          ekran,
          size: const Size(390, 844),
          locale: Locale(locale),
        );
        final ctx = tester.element(find.byWidget(ekran));
        final adres = AppInfo.supportEmail ?? ctx.tr('legal_email_placeholder');
        final metinler = tester
            .widgetList<Text>(find.byType(Text, skipOffstage: false))
            .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
            .toList();
        expect(metinler.where((m) => m.contains(adres)), isNotEmpty);
        expect(metinler.where((m) => m.contains('{email}')), isEmpty);
      });
    }
  }
}
