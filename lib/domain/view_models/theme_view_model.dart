import 'package:flutter/foundation.dart';
import '../../data/repositories/theme_repository.dart';
import '../../design_system/app_flavor.dart';

/// Seçili tema çeşidi.
///
/// Abonelik durumu dışarıdan bildirilir: tema deposu premium bilgisine
/// erişmez, aksi hâlde tasarım katmanı satın alma katmanına bağlanırdı.
class ThemeViewModel extends ChangeNotifier {
  final ThemeRepository _repository;

  ThemeViewModel({ThemeRepository repository = const ThemeRepository()})
    : _repository = repository {
    _load();
  }

  AppFlavor _flavor = AppFlavor.free;
  AppFlavor get flavor => _flavor;

  bool _isPremium = false;

  Future<void> _load() async {
    _flavor = await _repository.resolveFor(isPremium: _isPremium);
    notifyListeners();
  }

  /// Abonelik durumu değişince çağrılır.
  ///
  /// Abonelik biterse seçili premium tema ücretsiz temaya düşer — kayıt
  /// silinmez, kullanıcı yeniden abone olunca eski seçimi geri gelir.
  Future<void> setPremium(bool value) async {
    if (_isPremium == value) return;
    _isPremium = value;
    final resolved = await _repository.resolveFor(isPremium: value);
    if (resolved != _flavor) {
      _flavor = resolved;
      notifyListeners();
    }
  }

  /// Temayı değiştirir. Premium gerektiren bir tema abonesiz seçilirse
  /// `false` döner ve değişiklik yapılmaz.
  Future<bool> select(AppFlavor flavor) async {
    if (flavor.requiresPremium && !_isPremium) return false;

    await _repository.setFlavor(flavor);
    _flavor = flavor;
    notifyListeners();
    return true;
  }

  bool canUse(AppFlavor flavor) => !flavor.requiresPremium || _isPremium;
}
