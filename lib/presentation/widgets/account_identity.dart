import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../domain/view_models/account_view_model.dart';

/// Hesabın kimliği (hesap, ad, e-posta); değiştiğinde ad ve e-posta
/// profilden yeniden okunmalı.
///
/// Ad ve e-posta giriş yönteminden geliyor ve girişte, çıkışta, hesap
/// silinince profile yazılıyor (`AccountViewModel._applyIdentity`). Adı
/// gösteren sekmeler (`StatefulShellRoute`) açık kalıyor ve adı yalnızca
/// ilk açılışta okuyordu: çıkıştan sonra önceki kişinin adı görünmeye devam
/// ediyordu. `build` içinde çağrılıyor; sağlayıcı yoksa (tek başına çizilen
/// bileşen testleri) `null`.
Object? watchAccountIdentity(BuildContext context) {
  try {
    return context.select<AccountViewModel, Object?>((vm) {
      final a = vm.account;
      return (a?.uid, a?.displayName, a?.email);
    });
  } on ProviderNotFoundException {
    return null;
  }
}
