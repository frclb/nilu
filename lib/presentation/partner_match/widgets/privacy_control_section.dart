import 'package:flutter/material.dart';
import '../../../data/repositories/share_settings_repository.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../../../domain/models/share_settings.dart';
import '../../../../localization/app_localizations.dart';

/// Eşleşme ekranındaki gizlilik kontrolü.
///
/// Buradaki iki anahtar yalnızca `setState` ile çalışıyordu: hiçbir yere
/// yazılmıyor, hiçbir şeyi etkilemiyorlardı. "Veri Paylaşımına İzin Ver"i
/// kapatan kullanıcı paylaşımı durdurduğunu sanıyor ama hiçbir şeye
/// dokunmuyordu — kontrol etmeyen bir gizlilik denetimi, olmayandan kötü.
///
/// Ana anahtar artık gerçek ayara bağlı. "Detaylı semptomları gizle"
/// kaldırıldı: partnere semptom hiç gitmiyor, gizlenecek bir şey yok.
class PrivacyControlSection extends StatefulWidget {
  const PrivacyControlSection({super.key});

  @override
  State<PrivacyControlSection> createState() => _PrivacyControlSectionState();
}

class _PrivacyControlSectionState extends State<PrivacyControlSection> {
  static const _repository = ShareSettingsRepository();

  ShareSettings _settings = const ShareSettings();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loaded = true;
    });
  }

  Future<void> _update(bool value) async {
    final next = _settings.copyWith(intimacyStatus: value);
    setState(() => _settings = next);
    await _repository.save(next);
  }

  @override
  Widget build(BuildContext context) {

    final headerColor = context.tokens.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('partner_match_privacy'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: headerColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppCard.decoration(context.tokens),
          child: Column(
            children: [
              // Master Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('partner_match_allow_sharing'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.tokens.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('partner_match_allow_sharing_desc'),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: _settings.intimacyStatus,
                    onChanged: _loaded ? _update : null,
                  ),
                ],
              ),

            ],
          ),
        ),

        const SizedBox(height: 16),

        // Güvenlik notu.
        //
        // Metin `Flexible` içinde: satır esnek değilken uzun bir açıklama
        // ekranın sağından taşıyordu. Kısa bir cümleyle çalışıyor gibi
        // görünen bu düzen, metin uzadığı anda kırılıyor — ve çeviriler
        // her dilde farklı uzunlukta.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.lock,
                size: 14,
                color: context.tokens.textFaint,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.tr('partner_match_encryption_notice'),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: context.tokens.textFaint,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
