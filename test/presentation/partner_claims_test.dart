import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Partner tarafının **iddia etmediği** şeyler.
///
/// Partner modunun yarısı hiç inşa edilmemişti ama arayüz inşa edilmiş gibi
/// konuşuyordu. Dört ayrı yerde, olmayan bir şey olmuş gibi anlatılıyordu:
///
///   * Önemli Günler ekranı sabit tarihler gösteriyordu ("14 Eyl", "Tahmini
///     2 gün sonra") — partnerin vücudu hakkında uydurma veri.
///   * Ana ekrandaki kart, partner hiç bağlı değilken bile "Bilgilendirildi
///     — hassas dönemde olduğunuzu biliyor" diyordu.
///   * Paylaşım ekranı "GÖRÜNÜR VERİLER" başlığı altında faz, semptom, ruh
///     hali ve tahminleri sayıyordu; hiçbiri gönderilmiyordu.
///   * Aynı ekran verinin "uçtan uca şifrelendiğini" söylüyordu.
///
/// Bu dosya kaynağı ve sözlüğü okuyor: iddialar geri sızarsa yakalansın.
void main() {
  const languages = ['tr', 'en', 'de', 'es', 'fr', 'pt'];

  Map<String, dynamic> dictionary(String lang) =>
      jsonDecode(File('lib/localization/$lang.json').readAsStringSync())
          as Map<String, dynamic>;

  group('kaldırılan yüzeyler geri gelmedi', () {
    test('uydurma Önemli Günler ekranı yok', () {
      expect(
        File(
          'lib/presentation/partner_match/partner_important_days_screen.dart',
        ).existsSync(),
        isFalse,
      );
    });

    test('gönderen tarafı olmayan partner bildirim ekranı yok', () {
      expect(
        File(
          'lib/presentation/partner_match/'
          'partner_notification_settings_screen.dart',
        ).existsSync(),
        isFalse,
      );
    });

    test('ölü anahtarlar sözlükten düştü', () {
      // Metin dosyada durursa ekranın da geri gelmesi an meselesi.
      const removed = [
        'partner_important_days_est_2',
        'partner_important_days_tip_1',
        'notif_partner_updates',
        'partner_share_phase_info',
        'partner_share_predictions',
        'home_partner_notified',
      ];

      for (final lang in languages) {
        final keys = dictionary(lang).keys;
        for (final key in removed) {
          expect(keys, isNot(contains(key)), reason: '$lang: $key duruyor');
        }
      }
    });
  });

  group('yanlış beyanlar geri gelmedi', () {
    test('tanıtım yüzeylerinde uçtan uca şifreleme iddiası yok', () {
      // Firestore aktarımda ve diskte şifreliyor ama anahtarlar
      // sağlayıcıda; bu uçtan uca şifreleme değil. Sahip olunmayan bir
      // güvenlik garantisini yazmak, kullanıcının paylaşım kararını yanlış
      // temele oturtur.
      const terms = [
        'uçtan uca',
        'end-to-end',
        'ende-zu-ende',
        'extremo a extremo',
        'bout en bout',
        'ponta a ponta',
      ];

      // Eşleşme ve paylaşım ekranları: hiç geçmemeli.
      const surfaces = [
        'partner_match_encryption_notice',
        'consent_where',
        'privacy_policy_section3_content',
      ];

      for (final lang in languages) {
        final d = dictionary(lang);
        for (final key in surfaces) {
          final text = (d[key] as String).toLowerCase();
          for (final term in terms) {
            expect(
              text,
              isNot(contains(term)),
              reason: '$lang · $key: "$term" iddiası duruyor',
            );
          }
        }
      }
    });

    test('gizlilik politikası uçtan uca olmadığını açıkça söylüyor', () {
      // Bu bölüm terimi **kullanmak** zorunda: kullanıcı "şifreli" sözünü
      // uçtan uca sanmasın diye farkın yazılı olması gerekiyor. O yüzden
      // burada aranan şey terimin yokluğu değil, olumsuzlanmış hâli.
      const denials = {
        'tr': 'uçtan uca şifreleme değildir',
        'en': 'not end-to-end encryption',
        'de': 'keine ende-zu-ende-verschlüsselung',
        'es': 'no es cifrado de extremo a extremo',
        'fr': "n'est pas un chiffrement de bout en bout",
        'pt': 'não é criptografia de ponta a ponta',
      };

      for (final lang in languages) {
        expect(
          (dictionary(lang)['privacy_policy_section4_content'] as String)
              .toLowerCase(),
          contains(denials[lang]),
          reason: '$lang: politika farkı açıklamıyor',
        );
      }
    });

    test('ana ekran kartı bağlantı durumuna bakıyor', () {
      final source = File(
        'lib/presentation/home/widgets/two_column_widgets.dart',
      ).readAsStringSync();

      expect(
        source.contains('hasPartner'),
        isTrue,
        reason: 'kart koşulsuzsa partner yokken de "bağlı" der',
      );
    });
  });

  group('paylaşım ekranı yalnızca gerçekten gideni sayıyor', () {
    test('tek anahtar var ve yakınlık durumunu anlatıyor', () {
      final ekran = File(
        'lib/presentation/partner_match/partner_share_settings_screen.dart',
      ).readAsStringSync();
      final anahtar = File(
        'lib/presentation/partner_match/widgets/privacy_control_section.dart',
      ).readAsStringSync();

      expect(ekran.contains('PrivacyControlSection'), isTrue);
      expect(anahtar.contains('partner_match_allow_sharing'), isTrue);
      for (final gone in [
        'partner_share_phase_info',
        'partner_share_symptom_details',
        'partner_share_mood',
        'partner_share_predictions',
      ]) {
        expect(ekran.contains(gone), isFalse, reason: '$gone duruyor');
        expect(anahtar.contains(gone), isFalse, reason: '$gone duruyor');
      }
    });

    test('döngü verisinin gitmediği yazılı', () {
      // Kullanıcının bilmesi gereken asıl şey bu: rıza metni de söylüyor.
      for (final lang in languages) {
        expect(
          dictionary(lang)['consent_what'],
          isNotNull,
          reason: '$lang: rıza metni eksik',
        );
      }
    });
  });
}
