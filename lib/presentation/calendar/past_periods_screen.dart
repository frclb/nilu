import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final takvim = context.watch<CalendarViewModel>();
    final primary = Theme.of(context).colorScheme.primary;

    final aylar = [
      for (var i = 0; i < PastPeriodsScreen.monthsBack; i++)
        DateTime(_bugun.year, _bugun.month - i),
    ];

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          context.tr('past_periods_title'),
          style: TextStyle(
            color: t.text,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border(top: BorderSide(color: t.border)),
        ),
        child: SafeArea(
          top: false,
          child: AppContentWidth(
            child: FilledButton(
              key: const Key('past_periods_save'),
              onPressed: _secilen.isEmpty || _kaydediliyor ? null : _kaydet,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                context.tr(
                  'past_periods_add',
                  params: {'n': '${_secilen.length}'},
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
      body: AppContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              context.tr(
                'past_periods_intro',
                params: {'n': '${takvim.periodLength}'},
              ),
              style: TextStyle(fontSize: 14, height: 1.5, color: t.textMuted),
            ),
            const SizedBox(height: 16),
            for (final ay in aylar)
              _Ay(
                ay: ay,
                bugun: _bugun,
                secilen: _secilen,
                kayitli: takvim.isPeriodDay,
                kesinti: takvim.isInPregnancyBreak,
                onTap: _degistir,
                primary: primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Bir ayın ızgarası. Hafta pazartesi başlıyor (kurulumdaki takvimle aynı).
class _Ay extends StatelessWidget {
  const _Ay({
    required this.ay,
    required this.bugun,
    required this.secilen,
    required this.kayitli,
    required this.kesinti,
    required this.onTap,
    required this.primary,
  });

  final DateTime ay;
  final DateTime bugun;
  final Set<DateTime> secilen;
  final bool Function(DateTime) kayitli;
  final bool Function(DateTime) kesinti;
  final ValueChanged<DateTime> onTap;
  final Color primary;

  static const List<String> _gunAnahtarlari = [
    'calendar_day_mon',
    'calendar_day_tue',
    'calendar_day_wed',
    'calendar_day_thu',
    'calendar_day_fri',
    'calendar_day_sat',
    'calendar_day_sun',
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
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
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Semantics(
              header: true,
              child: Text(
                '${context.monthName(ay.month)} ${ay.year}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.text,
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
                        style: TextStyle(fontSize: 12, color: t.textMuted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          for (var r = 0; r < hucreler.length ~/ 7; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(child: _hucre(context, hucreler[r * 7 + c])),
              ],
            ),
        ],
      ),
    );
  }

  Widget _hucre(BuildContext context, DateTime? gun) {
    if (gun == null) return const AspectRatio(aspectRatio: 1);
    final t = context.tokens;
    final gelecek = gun.isAfter(bugun);
    final kayit = kayitli(gun);
    final kapali = gelecek || kayit || kesinti(gun);
    final secili = secilen.contains(gun);

    final Color? zemin = secili
        ? primary
        : kayit
        ? t.brandTint
        : null;
    final Color yazi = secili
        ? Theme.of(context).colorScheme.onPrimary
        : kapali
        ? t.textFaint
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
              decoration: BoxDecoration(color: zemin, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '${gun.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
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
