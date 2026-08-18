import 'package:flutter/material.dart';
import '../domain/models/cycle_info.dart';
import 'app_tokens.dart';

/// Döngü fazının rengi ve doğurganlık göstergesi.
///
/// Ana ekranda bu eşleme sabit renklerle yapılıyordu — yumurtlama açık mavi,
/// foliküler yeşil, luteal turuncu, doğurganlık noktası ise `Colors.red` /
/// `Colors.orange`. Dört ayrı renk ailesi paletin dışındaydı ve halka ekranın
/// ortasında yabancı duruyordu. Üstelik takvimdeki açıklama satırı (regl gül,
/// yumurtlama mor) ile de çelişiyordu.
extension CyclePhaseColors on CyclePhase {
  /// Fazın rengi. Menstrüasyon ve yumurtlama, takvimdekiyle **aynı** renkleri
  /// kullanır; kullanıcı iki ekranda aynı şeyi aynı renkte görsün.
  Color color(AppTokens t) => switch (this) {
    CyclePhase.menstruation => t.flow,
    CyclePhase.follicular => t.phaseFollicular,
    CyclePhase.ovulation => t.ovulation,
    CyclePhase.luteal => t.phaseLuteal,
    CyclePhase.unknown => t.textFaint,
  };

  /// Doğurganlık göstergesinin rengi.
  ///
  /// Kırmızı–turuncu–yeşil trafik ışığı değil: kırmızı "tehlike", yeşil
  /// "güvenli" çağrıştırıyordu, oysa yüksek doğurganlık kullanıcının
  /// hedefine göre istenen ya da istenmeyen olabilir. Değer yargısı
  /// taşımayan bir yoğunluk ölçeği kullanılıyor.
  Color fertilityColor(AppTokens t) => switch (this) {
    CyclePhase.ovulation => t.ovulation,
    CyclePhase.follicular => t.ovulation.withAlpha(140),
    CyclePhase.luteal => t.textFaint,
    CyclePhase.menstruation => t.textFaint,
    CyclePhase.unknown => t.textFaint,
  };
}
