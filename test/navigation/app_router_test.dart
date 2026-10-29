import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/core/navigation/app_router.dart';

/// Yönlendirme kararının tamamı burada doğrulanır.
///
/// Karar mantığı bilinçli olarak saf bir fonksiyona ([resolveRedirect])
/// ayrılmıştır: widget ağacı kurmadan tüm durum bileşimlerini hızlı ve
/// kararlı biçimde denemeyi sağlar.
void main() {
  group('durum henüz yüklenmediyse', () {
    test('splash dışındaki her yol splash\'e yönlendirilir', () {
      for (final location in [
        '/home',
        '/onboarding',
        '/calendar',
        '/premium',
      ]) {
        expect(
          resolveRedirect(
            isLoaded: false,
            onboardingComplete: false,
            location: location,
          ),
          splashPath,
          reason: '$location için beklenen splash',
        );
      }
    });

    test('splash\'te bekletilir', () {
      expect(
        resolveRedirect(
          isLoaded: false,
          onboardingComplete: true,
          location: splashPath,
        ),
        isNull,
      );
    });
  });

  group('kök adres', () {
    // Android'de Health Connect'in politika bağlantısı uygulamayı yeni bir
    // pencerede "/" ile açıyor; rota olmadığı için "sayfa bulunamadı"
    // çıkıyordu.
    test('splash gibi: yüklenince ana ekrana ya da onboarding\'e', () {
      expect(
        resolveRedirect(
          isLoaded: false,
          onboardingComplete: true,
          location: '/',
        ),
        splashPath,
      );
      expect(
        resolveRedirect(
          isLoaded: true,
          onboardingComplete: true,
          location: '/',
        ),
        homePath,
      );
      expect(
        resolveRedirect(
          isLoaded: true,
          onboardingComplete: false,
          location: '/',
        ),
        onboardingPath,
      );
    });
  });

  group('splash\'ten çıkış', () {
    test('onboarding tamamlanmışsa ana ekrana geçer', () {
      // Regresyon: initialLocation asenkron okumadan önce hesaplandığı için
      // dönen kullanıcı da onboarding'e düşüyordu.
      expect(
        resolveRedirect(
          isLoaded: true,
          onboardingComplete: true,
          location: splashPath,
        ),
        homePath,
      );
    });

    test('onboarding tamamlanmamışsa onboarding\'e geçer', () {
      expect(
        resolveRedirect(
          isLoaded: true,
          onboardingComplete: false,
          location: splashPath,
        ),
        onboardingPath,
      );
    });
  });

  group('onboarding tamamlanmadan', () {
    test('korumalı ekranlar onboarding\'e yönlendirilir', () {
      for (final location in [
        '/home',
        '/calendar',
        '/insights',
        '/profile',
        '/premium',
        '/log-entry',
        '/health-library',
        '/cycle_settings',
      ]) {
        expect(
          resolveRedirect(
            isLoaded: true,
            onboardingComplete: false,
            location: location,
          ),
          onboardingPath,
          reason: '$location onboarding tamamlanmadan açılmamalı',
        );
      }
    });

    test('onboarding akışındaki adımlar serbesttir', () {
      for (final location in [
        '/onboarding',
        '/onboarding_goal',
        '/onboarding_pregnancy',
        '/onboarding_last_period',
        '/onboarding_cycle_length',
        '/onboarding_success',
      ]) {
        expect(
          resolveRedirect(
            isLoaded: true,
            onboardingComplete: false,
            location: location,
          ),
          isNull,
          reason: '$location onboarding akışının parçası',
        );
      }
    });

    test('partner QR tarama serbesttir', () {
      // Partner, karşılama ekranından QR okutarak giriş yapar.
      expect(
        resolveRedirect(
          isLoaded: true,
          onboardingComplete: false,
          location: '/partner_scan',
        ),
        isNull,
      );
    });

    test('yasal metinler serbesttir', () {
      for (final location in ['/privacy_policy', '/terms_of_service']) {
        expect(
          resolveRedirect(
            isLoaded: true,
            onboardingComplete: false,
            location: location,
          ),
          isNull,
          reason: '$location her zaman okunabilmeli',
        );
      }
    });
  });

  group('onboarding tamamlandıktan sonra', () {
    test('karşılama ekranında takılıp kalınmaz', () {
      // Regresyon: uygulama her zaman splash'ten başlamıyor. Web'de URL
      // hash'i, mobilde derin bağlantı doğrudan /onboarding'e düşürebiliyor;
      // dönen kullanıcı karşılama ekranında kilitleniyordu.
      expect(
        resolveRedirect(
          isLoaded: true,
          onboardingComplete: true,
          location: onboardingPath,
        ),
        homePath,
      );
    });

    test('akışın ara adımları zorla yönlendirilmez', () {
      // Başarı ekranı onboarding'i tamamlar tamamlamaz kendisi /home'a gider;
      // redirect araya girip ekranı yarıda kesmemeli.
      for (final location in [
        '/onboarding_last_period',
        '/onboarding_cycle_length',
        '/onboarding_success',
      ]) {
        expect(
          resolveRedirect(
            isLoaded: true,
            onboardingComplete: true,
            location: location,
          ),
          isNull,
          reason: location,
        );
      }
    });

    test('tüm ekranlar serbesttir', () {
      for (final location in [
        '/home',
        '/calendar',
        '/insights',
        '/profile',
        '/premium',
        '/partner',
      ]) {
        expect(
          resolveRedirect(
            isLoaded: true,
            onboardingComplete: true,
            location: location,
          ),
          isNull,
          reason: '$location serbest olmalı',
        );
      }
    });
  });

  group('çıkış davranışı', () {
    test('çıkış sonrası korumalı ekran kapanır', () {
      // Veriler silinince onboardingComplete false olur; aynı konum artık
      // onboarding'e yönlendirilmelidir.
      const location = '/home';

      expect(
        resolveRedirect(
          isLoaded: true,
          onboardingComplete: true,
          location: location,
        ),
        isNull,
        reason: 'çıkıştan önce serbest',
      );

      expect(
        resolveRedirect(
          isLoaded: true,
          onboardingComplete: false,
          location: location,
        ),
        onboardingPath,
        reason: 'çıkıştan sonra kapalı',
      );
    });

    test('çıkış sonrası onboarding\'de sabit kalınır (sonsuz döngü yok)', () {
      // Regresyon: router yeniden kurulduğunda kullanıcı ana ekrana geri
      // sıçrıyordu. Onboarding konumu kendine yönlendirme üretmemeli.
      expect(
        resolveRedirect(
          isLoaded: true,
          onboardingComplete: false,
          location: onboardingPath,
        ),
        isNull,
      );
    });
  });

  // Uygulama Apple ya da Google hesabıyla kullanılıyor (TestFlight: "normal
  // kullanıcı giriş yapmadan girebiliyor").
  group('oturum yokken', () {
    /// GoRouter gibi: yönlendirme bitene kadar uygular, son konumu döndürür.
    String son(
      String location, {
      required bool onboardingComplete,
      required bool needsSignIn,
    }) {
      var konum = location;
      for (var i = 0; i < 5; i++) {
        final sonraki = resolveRedirect(
          isLoaded: true,
          onboardingComplete: onboardingComplete,
          location: konum,
          needsSignIn: needsSignIn,
        );
        if (sonraki == null) return konum;
        konum = sonraki;
      }
      fail('$location: yönlendirme döngüye girdi');
    }

    test('kurulum girişten sonra başlıyor', () {
      for (final adim in [
        '/onboarding_goal',
        '/onboarding_last_period',
        '/onboarding_success',
      ]) {
        expect(
          son(adim, onboardingComplete: false, needsSignIn: true),
          signInPath,
          reason: adim,
        );
      }
    });

    test('kurulumu bitmemiş kullanıcı önce karşılamayı görüyor', () {
      expect(
        son(homePath, onboardingComplete: false, needsSignIn: true),
        onboardingPath,
      );
    });

    test('karşılama ekranı ve giriş ekranı açık; döngü yok', () {
      expect(
        son(onboardingPath, onboardingComplete: false, needsSignIn: true),
        onboardingPath,
      );
      // Giriş ekranı kurulum yollarında da olmalı: yoksa kurulumu bitmemiş
      // kullanıcı karşılamaya geri atılır ve girişe hiç ulaşamaz.
      expect(
        son(signInPath, onboardingComplete: false, needsSignIn: true),
        signInPath,
      );
    });

    test('kurulmuş uygulamada her ekran giriş istiyor', () {
      for (final yol in [splashPath, '/', homePath, '/calendar', '/account']) {
        expect(
          son(yol, onboardingComplete: true, needsSignIn: true),
          signInPath,
          reason: yol,
        );
      }
    });

    test('kendi girişini gösteren ekranlar ve yasal metinler açık', () {
      for (final yol in [
        '/partner_scan',
        '/account_restore',
        '/privacy_policy',
        '/terms_of_service',
      ]) {
        expect(
          son(yol, onboardingComplete: false, needsSignIn: true),
          yol,
          reason: yol,
        );
      }
    });

    test('hesap hizmeti yokken (yerel mod) giriş istenmiyor', () {
      expect(
        son('/onboarding_goal', onboardingComplete: false, needsSignIn: false),
        '/onboarding_goal',
      );
      expect(
        son(homePath, onboardingComplete: true, needsSignIn: false),
        homePath,
      );
    });
  });

  // E-postayla açılan hesap adres doğrulanana kadar kullanılmıyor.
  group('e-posta doğrulanmamışken', () {
    String son(String location, {required bool onboardingComplete}) {
      var konum = location;
      for (var i = 0; i < 5; i++) {
        final sonraki = resolveRedirect(
          isLoaded: true,
          onboardingComplete: onboardingComplete,
          location: konum,
          needsEmailVerification: true,
        );
        if (sonraki == null) return konum;
        konum = sonraki;
      }
      fail('$location: yönlendirme döngüye girdi');
    }

    test('kurulum ve uygulama doğrulama ekranına çıkıyor; döngü yok', () {
      for (final (yol, kuruldu) in [
        ('/onboarding_goal', false),
        ('/onboarding_last_period', false),
        (onboardingPath, false),
        (homePath, true),
        ('/calendar', true),
        ('/account', true),
        ('/partner_scan', true),
        (signInPath, true),
      ]) {
        expect(
          son(yol, onboardingComplete: kuruldu),
          verifyEmailPath,
          reason: yol,
        );
      }
      expect(son(verifyEmailPath, onboardingComplete: false), verifyEmailPath);
    });

    test('şifre yenileme ve yasal metinler açık', () {
      for (final yol in [
        resetPasswordPath,
        '/privacy_policy',
        '/terms_of_service',
      ]) {
        expect(son(yol, onboardingComplete: false), yol, reason: yol);
      }
    });

    test('şifre yenileme oturum yokken de açılıyor', () {
      expect(
        resolveRedirect(
          isLoaded: true,
          onboardingComplete: true,
          location: resetPasswordPath,
          needsSignIn: true,
        ),
        isNull,
      );
    });
  });

  test(
    'izin verilen yollar listesi splash ve onboarding adımlarını içerir',
    () {
      expect(preOnboardingPaths, contains(splashPath));
      expect(preOnboardingPaths, contains(onboardingPath));
    },
  );
}
