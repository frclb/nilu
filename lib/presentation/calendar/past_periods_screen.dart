import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_snack.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/calendar_day.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';
import 'view_models/calendar_view_model.dart';

/// Hatırlanan geçmiş regl başlangıçlarını toplu ekleme.
///
/// Yeni kullanıcının elinde kurulumda girdiği tek başlangıç oluyordu: döngü
/// ortalaması, tahmin aralığı ve trend ancak aylar sonra çıkıyordu. Takvimde
/// gün gün işaretlemek mümkündü ama her dönem için ayrı ay, ayrı gün sayfası
/// demekti. Burada son bir yılın ayları alt alta; her başlangıç tek dokunuş.
///
/// Kayıtlı günler, gelecek ve gebelik/lohusalık aralıkları seçilemiyor
/// (kurallar `PeriodService.addStarts`'ta da var; ekran yalnızca baştan
/// gösteriyor).
///
/// Seçilen her başlangıcın ardından eklenecek dönem önizleniyor (açık gül
/// bant): giriş metni "her biri n günlük bir dönem olarak eklenir" diyor,
/// takvim de bunu gösteriyor. Kayıtlı dönemler gri bant.
class PastPeriodsScreen extends StatefulWidget {
  const PastPeriodsScreen({super.key});

  /// Kaç ay geriye gidilebilir.
  static const int monthsBack = 12;

  @override
  State<PastPeriodsScreen> createState() => _PastPeriodsScreenState();
}

class _PastPeriodsScreenState extends State<PastPeriodsScreen> {
  final Set<DateTime> _secilen = {};
  bool _kaydediliyor = false;
  final DateTime _bugun = DateTime.now().plusDays(0);

  Future<void> _kaydet() async {
    if (_secilen.isEmpty || _kaydediliyor) return;
    setState(() => _kaydediliyor = true);
    final eklenen = await context.read<CalendarViewModel>().addPastPeriodStarts(
      _secilen,
    );
    if (!mounted) return;
    AppSnack.show(
      context,
      context.tr('past_periods_added', params: {'n': '$eklenen'}),
    );
    context.pop();
  }

  void _degistir(DateTime gun) => setState(
    () => _secilen.contains(gun) ? _secilen.remove(gun) : _secilen.add(gun),
  );

  /// Seçilen başlangıçların ardından eklenecek günler.
  ///
  /// `PeriodService.addStarts` ile aynı sınırlar: dönem en fazla [uzunluk]
  /// gün, bugünü geçmiyor ve bir sonraki kayıtlı dönemin başladığı günden
  /// önce bitiyor.
  Set<DateTime> _onizleme(int uzunluk, bool Function(DateTime) kayitli) {
    final gunler = <DateTime>{};
    for (final bas in _secilen) {
      for (var i = 1; i < uzunluk; i++) {
        final gun = bas.plusDays(i);
        if (gun.isAfter(_bugun) || kayitli(gun)) break;
        gunler.add(gun);
      }
    }
    return gunler;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final takvim = context.watch<CalendarViewModel>();
    final primary = theme.colorScheme.primary;

    final aylar = [
      for (var i = 0; i < PastPeriodsScreen.monthsBack; i++)
        DateTime(_bugun.year, _bugun.month - i),
    ];
    final onizleme = _onizleme(takvim.periodLength, takvim.isPeriodDay);
    final etkin = _secilen.isNotEmpty && !_kaydediliyor;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          context.tr('past_periods_title'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
            color: t.text,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        color: t.background,
        child: SafeArea(
          top: false,
          child: AppContentWidth(
            // Degrade, düğmenin altında: seçim yokken düğme temanın sönük
            // hâline dönüyor.
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: etkin ? AppGradients.primary(context) : null,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: etkin ? AppShadows.floating(context) : null,
              ),
              child: FilledButton(
                key: const Key('past_periods_save'),
                onPressed: etkin ? _kaydet : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: t.surfaceAlt,
                  disabledForegroundColor: t.textFaint,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        context.tr(
                          'past_periods_add',
                          params: {'n': '${_secilen.length}'},
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: AppContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // Giriş: ne olacağını anlatan gül tülü kart.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.brandTint,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIconTile(
                    icon: Icons.calendar_month,
                    circle: true,
                    background: t.secondaryTint,
                    color: primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('past_periods_entry_body'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: t.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr(
                            'past_periods_intro',
                            params: {'n': '${takvim.periodLength}'},
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: t.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final ay in aylar)
              _Ay(
                ay: ay,
                bugun: _bugun,
                secilen: _secilen,
                onizleme: onizleme,
                kayitli: takvim.isPeriodDay,
                kesinti: takvim.isInPregnancyBreak,
                onTap: _degistir,
              ),
          ],
        ),
      ),
    );
  }
}

/// Bir günün bant türü.
enum _Bant { yok, kayitli, yeni }

/// Bir ayın ızgarası. Hafta pazartesi başlıyor (kurulumdaki takvimle aynı).
class _Ay extends StatelessWidget {
  const _Ay({
    required this.ay,
    required this.bugun,
    required this.secilen,
    required this.onizleme,
    required this.kayitli,
    required this.kesinti,
    required this.onTap,
  });

  final DateTime ay;
  final DateTime bugun;
  final Set<DateTime> secilen;

  /// Seçilen başlangıçların ardından eklenecek günler.
  final Set<DateTime> onizleme;
  final bool Function(DateTime) kayitli;
  final bool Function(DateTime) kesinti;
  final ValueChanged<DateTime> onTap;

  static const List<String> _gunAnahtarlari = [
    'calendar_day_mon',
    'calendar_day_tue',
    'calendar_day_wed',
    'calendar_day_thu',
    'calendar_day_fri',
    'calendar_day_sat',
    'calendar_day_sun',
  ];

  /// Satır yüksekliği içinde bandın dikey payı.
  static const double _bantPayi = 4;

  _Bant _bant(DateTime gun) {
    if (kayitli(gun)) return _Bant.kayitli;
    if (secilen.contains(gun) || onizleme.contains(gun)) return _Bant.yeni;
    return _Bant.yok;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final gunSayisi = DateTime(ay.year, ay.month + 1, 0).day;
    final bosluk = DateTime(ay.year, ay.month).weekday - 1;
    final hucreler = <DateTime?>[
      for (var i = 0; i < bosluk; i++) null,
      for (var d = 1; d <= gunSayisi; d++) DateTime(ay.year, ay.month, d),
    ];
    while (hucreler.length % 7 != 0) {
      hucreler.add(null);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: AppCard.decoration(t),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 10),
            child: Semantics(
              header: true,
              child: Text(
                '${context.monthName(ay.month)} ${ay.year}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          ExcludeSemantics(
            child: Row(
              children: [
                for (final k in _gunAnahtarlari)
                  Expanded(
                    child: Center(
                      child: Text(
                        context.tr(k),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: t.textFaint,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (var r = 0; r < hucreler.length ~/ 7; r++)
            _satir(context, hucreler.sublist(r * 7, r * 7 + 7)),
        ],
      ),
    );
  }

  /// Bir hafta: önce bantlar (ardışık günler tek parça), üstünde hücreler.
  ///
  /// Bant hücre hücre değil satır satır çiziliyor: yan yana iki ayrı kap
  /// kenar yumuşatmadan ötürü aralarında ince bir zemin çizgisi bırakıyor
  /// (bkz. takvimdeki `_seamOverlap`).
  Widget _satir(BuildContext context, List<DateTime?> gunler) {
    final t = context.tokens;

    // Satırdaki bant parçaları: (ilk sütun, son sütun, tür).
    final parcalar = <(int, int, _Bant)>[];
    for (var c = 0; c < 7; c++) {
      final gun = gunler[c];
      final tur = gun == null ? _Bant.yok : _bant(gun);
      if (tur == _Bant.yok) continue;
      if (parcalar.isNotEmpty &&
          parcalar.last.$2 == c - 1 &&
          parcalar.last.$3 == tur) {
        parcalar.last = (parcalar.last.$1, c, tur);
      } else {
        parcalar.add((c, c, tur));
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final hucre = constraints.maxWidth / 7;
        return Stack(
          children: [
            for (final (ilk, son, tur) in parcalar)
              Positioned(
                left: ilk * hucre,
                width: (son - ilk + 1) * hucre,
                top: _bantPayi,
                bottom: _bantPayi,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tur == _Bant.kayitli ? t.border : t.secondaryTint,
                    // Dönem önceki/sonraki haftadan sürüyorsa o uç düz:
                    // "burada bitiyor" değil "devam ediyor".
                    borderRadius: BorderRadius.horizontal(
                      left: _surer(gunler[ilk]!, -1, tur)
                          ? Radius.zero
                          : const Radius.circular(AppRadius.pill),
                      right: _surer(gunler[son]!, 1, tur)
                          ? Radius.zero
                          : const Radius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                for (final gun in gunler) Expanded(child: _hucre(context, gun)),
              ],
            ),
          ],
        );
      },
    );
  }

  /// [gun]ün [yon] yanındaki gün (ayın içinde) aynı bantta mı?
  bool _surer(DateTime gun, int yon, _Bant tur) {
    final komsu = gun.plusDays(yon);
    if (komsu.month != ay.month) return false;
    return _bant(komsu) == tur;
  }

  Widget _hucre(BuildContext context, DateTime? gun) {
    if (gun == null) return const AspectRatio(aspectRatio: 1);
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final gelecek = gun.isAfter(bugun);
    final kayit = kayitli(gun);
    final kapali = gelecek || kayit || kesinti(gun);
    final secili = secilen.contains(gun);
    final yeni = onizleme.contains(gun);

    final Color yazi = secili
        ? scheme.onPrimary
        : kayit
        ? t.textMuted
        : yeni
        ? t.secondary
        : kapali
        ? t.textFaint.withAlpha(150)
        : t.text;

    final etiket = [
      '${gun.day} ${context.monthName(gun.month)} ${gun.year}',
      if (kayit) context.tr('past_periods_day_recorded'),
    ].join(', ');

    return AspectRatio(
      aspectRatio: 1,
      child: Semantics(
        button: !kapali,
        enabled: !kapali,
        selected: secili,
        label: etiket,
        excludeSemantics: true,
        child: InkWell(
          key: Key('past_periods_day_${gun.year}_${gun.month}_${gun.day}'),
          customBorder: const CircleBorder(),
          onTap: kapali ? null : () => onTap(gun),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: secili ? scheme.primary : null,
                shape: BoxShape.circle,
                boxShadow: secili ? AppShadows.soft(context) : null,
              ),
              child: Center(
                child: Text(
                  '${gun.day}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: (secili || yeni)
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: yazi,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
