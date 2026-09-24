import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// UMP çağrılarının arkasındaki ince kapı.
///
/// Rızanın **kuralları** burada değil [AdConsent] içinde: hangi sırayla
/// çağrıldığı, formun ne zaman gösterildiği, hata hâlinde ne olduğu. Kırılan
/// yer orası olduğu için orası test edilebilir kalmalı; bu arayüz de onu
/// platform kanalından ayırmak için var.
abstract class ConsentPort {
  /// Rıza durumunu Google'dan tazeler. Başarılıysa true.
  Future<bool> requestUpdate();

  /// Reklam isteği yapılabilir mi? (AB dışında rıza alınmadan da true olur.)
  Future<bool> canRequestAds();

  /// Kullanıcıya sonradan rızasını değiştirme yolu sunulmak zorunda mı?
  Future<bool> privacyOptionsRequired();

  /// Gerekiyorsa rıza formunu yükler ve gösterir. Gerekmiyorsa hiçbir şey olmaz.
  Future<void> showFormIfRequired();

  /// Rıza tercihleri formunu açar (kullanıcı kendi isteğiyle).
  Future<void> showPrivacyOptions();
}

/// Gerçek UMP kurulumu.
///
/// Her çağrı `catch (e)` ile sarılı — `on Exception` ile değil. UMP
/// sarmalayıcısı `(await invokeMethod<int>(...))!` yazıyor: platform kanalı
/// yanıt vermediğinde dönen null'a `!` uygulanıyor ve çıkan `TypeError` bir
/// `Exception` değil `Error`. Dar yakalama onu kaçırır ve reklam bandı
/// açıklanamayan bir çökmeye dönüşürdü.
///
/// Hata hâlinde hep "rıza yok" yönüne düşülüyor: eksik bilgiyle reklam
/// istemektense reklamsız kalmak.
class UmpConsentPort implements ConsentPort {
  const UmpConsentPort();

  /// Askıda kalmamak için üst sınır.
  static const Duration _limit = Duration(seconds: 8);

  @override
  Future<bool> requestUpdate() async {
    // Önce eklentinin orada olduğu yoklanıyor.
    //
    // `requestConsentInfoUpdate` geri çağrı tabanlı ve sarmalayıcısı yalnızca
    // `PlatformException` yakalıyor. Eklenti kayıtlı değilse gelen
    // `MissingPluginException` ne yakalanıyor ne de geri çağrılardan birine
    // dönüşüyor: çağrı sessizce yutuluyor, bekleyen taraf **sonsuza kadar**
    // askıda kalıyor. Gizlilik ekranı bu yüzden dönen çarkta donuyordu.
    //
    // `getConsentStatus` aynı kanalı kullanıyor ama hatasını Future üzerinden
    // veriyor, yani yakalanabiliyor.
    try {
      await ConsentInformation.instance.getConsentStatus();
    } catch (e) {
      debugPrint('Consent unavailable: $e');
      return false;
    }

    // UMP geri çağrı veriyor, çağıran taraf ise `await` bekliyor.
    final done = Completer<bool>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!done.isCompleted) done.complete(true);
        },
        (error) {
          // Ağ yoksa ya da Google erişilemezse: önbellekteki durum geçerli
          // kalır. Durum hâlâ bilinmiyorsa reklam istenmez — açıkta kalmaktansa
          // reklamsız kalmak yeğ.
          debugPrint('Consent update failed: ${error.message}');
          if (!done.isCompleted) done.complete(false);
        },
      );
    } catch (e) {
      debugPrint('Consent update threw: $e');
      if (!done.isCompleted) done.complete(false);
    }
    return done.future.timeout(_limit, onTimeout: () => false);
  }

  @override
  Future<bool> canRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('canRequestAds failed: $e');
      return false;
    }
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('privacyOptionsRequirementStatus failed: $e');
      return false;
    }
  }

  @override
  Future<void> showFormIfRequired() async {
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) debugPrint('Consent form: ${error.message}');
      });
    } catch (e) {
      debugPrint('Consent form failed: $e');
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) debugPrint('Privacy options: ${error.message}');
      });
    } catch (e) {
      debugPrint('Privacy options failed: $e');
    }
  }
}

/// Reklam rızası.
///
/// Google, Ocak 2024'ten beri AEA ve Birleşik Krallık trafiğinde sertifikalı
/// bir rıza platformu şart koşuyor ve bu **kişiselleştirilmemiş reklamlar için
/// de** geçerli: reklam hedeflenmese bile cihazda okuma/yazma yapılıyor ve
/// ePrivacy bunu rızaya bağlıyor. Formsuz o trafikte reklam servis edilmiyor.
/// Uygulama de/es/fr/pt ile yayınlanıyor, yani altı pazarın dördü AEA.
///
/// Form **tembel** gösteriliyor: reklamın olduğu ilk ekran açılırken. Açılışta
/// gösterilseydi Alman bir kullanıcı uygulamayı görmeden önce onboarding'in
/// ortasında bir Google rıza sayfasıyla karşılaşırdı. Premium kullanıcıya ve
/// reklam görmeyen kullanıcıya hiç sorulmuyor — sormanın karşılığı yok.
class AdConsent {
  const AdConsent._();

  /// Platform kapısı. Testler kendi sahtesini koyar.
  @visibleForTesting
  static ConsentPort port = const UmpConsentPort();

  static bool _updated = false;
  static Future<bool>? _inFlight;

  /// Durumu uygulama ömründe bir kez tazeler.
  ///
  /// Google her açılışta tazelenmesini istiyor; bir kez yeterli. Başarısız
  /// olursa **önbelleğe alınmıyor**: çevrimdışı açılan bir oturum, ağ gelince
  /// yeniden denesin.
  static Future<void> refresh() async {
    if (_updated) return;
    _inFlight ??= _runUpdate();
    await _inFlight;
  }

  static Future<bool> _runUpdate() async {
    try {
      final ok = await port.requestUpdate();
      if (ok) _updated = true;
      return ok;
    } finally {
      _inFlight = null;
    }
  }

  /// Reklam istenebilir mi?
  ///
  /// [mayShowForm] false ise yalnızca bakılır; true ise gerekiyorsa form
  /// gösterilir ve kullanıcının kararından sonra tekrar bakılır.
  static Future<bool> resolve({required bool mayShowForm}) async {
    await refresh();
    if (await port.canRequestAds()) return true;
    if (!mayShowForm) return false;
    await port.showFormIfRequired();
    return port.canRequestAds();
  }

  /// Ayarlarda "Reklam tercihleri" girişi gösterilmeli mi?
  ///
  /// AEA'da rızasını veren kullanıcının sonradan **geri alabilmesi** gerekiyor;
  /// girişi olmayan bir kurulum eksik sayılıyor.
  ///
  /// Durumu tazelemiyor, önbellekten okuyor. UMP rıza durumunu oturumlar arası
  /// saklıyor ve tazeleme zaten reklamın çıktığı yerde yapılıyor. Ayrıca
  /// anlamı da doğru oluyor: geri alınacak bir rıza ancak bir kez verilmişse
  /// vardır, o da reklam görmüş kullanıcıda. Ayarlar ekranı bunun için ağa
  /// çıkmak zorunda değil.
  static Future<bool> privacyOptionsRequired() => port.privacyOptionsRequired();

  static Future<void> showPrivacyOptions() => port.showPrivacyOptions();

  @visibleForTesting
  static void resetForTest([ConsentPort? replacement]) {
    _updated = false;
    _inFlight = null;
    port = replacement ?? const UmpConsentPort();
  }
}
