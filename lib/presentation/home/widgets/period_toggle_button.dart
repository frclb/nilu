import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/app_snack.dart';
import '../../../design_system/app_theme.dart';
import '../../../localization/date_names.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../../calendar/view_models/calendar_view_model.dart';

/// Reglin başlangıcını ve bitişini kaydeden düğme.
///
/// Bu eylem eskiden yalnızca takvimde gizliydi: ana ekrandan takvime git, güne
/// dokun, sayfayı kaydır, "Regl işaretle"ye bas. Uygulamanın en sık yapılan
/// işi dört dokunuş uzaktaydı.
///
/// Alan tek bir şey gösteriyor: sıradaki eylem. Eylem kalmadığında — regl
/// bugün kapatıldığında — yerini sessiz bir durum satırı alıyor.
///
/// Geri alma önce yalnızca eylemin ardından çıkan geçici bildirimdeydi.
/// Bildirim geçince ana ekranda dönüş yolu kalmıyordu: yanlışlıkla
/// "Reglim başladı"ya basan kullanıcıyı karşılayan "Reglim bitti" bir
/// çıkış değil — bir günlük sahte bir dönem yaratıyor ve `lastPeriodStart`
/// kaydığı için bütün tahminleri de bozuyor. Tek çare takvimi bulup günü
/// elle kaldırmaktı.
///
/// Artık düğmenin altında kalıcı bir "Geri al" var. Eski itiraz — "geri
/// alınacak bir şey kalmadığında da orada duruyordu" — kuralı
/// daraltarak karşılandı: yalnızca bugün açılmış ya da bugün kapatılmış
/// bir kayıt varken görünüyor. Dün başlamış bir dönemde geri alma bugünü
/// kayıttan çıkarırdı, ki bu geri alma değil veri bozmaktır.
class PeriodToggleButton extends StatefulWidget {
  const PeriodToggleButton({super.key});

  @override
  State<PeriodToggleButton> createState() => _PeriodToggleButtonState();
}

class _PeriodToggleButtonState extends State<PeriodToggleButton> {
  bool _busy = false;

  /// Bu oturumda düğmeye basıldı mı?
  ///
  /// Kaydın kendisinden okunamayan durumlar var: dün biten bir dönem
  /// bugün işaretlenince yeni kayıt açılmıyor, eski kayıt yeniden
  /// açılıyor (aynı kanamayı iki döngü göstermemek için). O kaydın ilk
  /// günü dün değil, günler öncesi — yani "bugün bir şey yapıldı"
  /// bilgisi veride kalmıyor. Kazayla basan kullanıcının çıkışı da tam
  /// o durumda gerekiyor.
  bool _actedThisSession = false;

  /// Eylemi çalıştırır.
  ///
  /// Başarıda bildirim **göstermiyor**. Eskiden gösteriyordu ve bildirim
  /// "Geri al" düğmesinin üstüne biniyordu: 390×844 bir ekranda düğme
  /// 706–726, bildirim 708–772 arasındaydı. Bildirim dört saniye durduğu
  /// için kullanıcı yanlış dokunduğunu fark edip geri almak istediği tam
  /// aralıkta düğme dokunuşu yutuluyordu — hiçbir geri bildirim de
  /// olmadığından uygulama bozuk görünüyordu.
  ///
  /// Onay zaten ekranda: başlık değişiyor ("8 gün sürdü"), düğmenin yerini
  /// onay simgeli durum satırı alıyor ve altında geri alma beliriyor. Geçici
  /// bir şerit bunu tekrarlayıp üstünü örtmekten başka bir şey yapmıyordu.
  /// Hata durumunda bildirim duruyor: orada ekranda değişen bir şey yok.
  Future<void> _run(Future<bool> Function() action) async {
    final failed = context.tr('home_period_toggle_failed');

    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!ok) {
      AppSnack.error(context, failed);
      return;
    }
    setState(() => _actedThisSession = true);
  }

  /// Geri alma eylemi.
  ///
  /// `_run`'dan ayrı: o, yaptığı işin ardından yine "Geri al" sunuyor.
  /// Geri almanın geri alması kullanıcıyı nerede olduğundan emin olamadığı
  /// bir döngüye sokardı.
  Future<void> _undo(Future<bool> Function() action) async {
    final failed = context.tr('home_period_toggle_failed');

    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      // Geri alındıktan sonra geri alınacak bir şey kalmıyor. Geri almanın
      // geri alması kullanıcıyı nerede olduğunu bilemediği bir döngüye
      // sokardı.
      if (ok) _actedThisSession = false;
    });

    if (!ok) AppSnack.error(context, failed);
  }

  /// Tahmin edilen tarihten çok önce regl başlatılıyorsa onay ister.
  ///
  /// Kazara dokunuş döngüyü sessizce yeniden yazıyordu: "17 gün var" bir
  /// anda "1. gün" oluyor, `lastPeriodStart` kayıyor ve bütün tahminler
  /// bununla birlikte kayıyor. Geri alma yolu var ama geçici; kazayı baştan
  /// durdurmak daha iyi.
  ///
  /// Gecikmede **sormuyoruz**: regl gecikmesi olağan ve kullanıcı zaten
  /// bekliyor olur. Yalnızca beklenenden bir haftadan fazla erkenken
  /// soruluyor — o kadar erken bir başlangıç ya gerçekten olağandışı ya da
  /// yanlış dokunuş.
  static const int _earlyStartThresholdDays = 7;

  Future<bool> _confirmEarlyStart(CalendarViewModel viewModel) async {
    final info = viewModel.cycleInfo;
    final daysLeft = info.daysUntilNextPeriod;
    final predicted = info.predictedNextPeriod;

    if (daysLeft == null ||
        predicted == null ||
        daysLeft <= _earlyStartThresholdDays) {
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('home_period_early_title')),
        content: Text(
          ctx.tr(
            'home_period_early_body',
            params: {
              'n': '$daysLeft',
              'date': '${predicted.day} ${ctx.monthName(predicted.month)}',
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            style: AppTheme.dialogAction(),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('home_period_early_confirm')),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final viewModel = context.watch<CalendarViewModel>();
    final action = viewModel.periodActionToday;

    // Geri alma iki kaynaktan geliyor.
    //
    // Kayıttan: dönem bugün kapatıldıysa yeniden açılabilir, bugün
    // açıldıysa tamamen kaldırılabilir. Bu bilgi uygulama kapanıp
    // açılsa da duruyor.
    //
    // Oturumdan: dün biten bir dönemi bugün işaretlemek eski kaydı
    // yeniden açıyor, yani "bugün bir şey yapıldı" veride iz bırakmıyor.
    // Kazayla basan kullanıcının çıkışı tam orada gerekiyor.
    //
    // Süren ve bugüne ait işlemi olmayan bir dönemde geri alma
    // gösterilmiyor: orada "geri al" bugünü kayıttan çıkarırdı ve bu geri
    // alma değil, gerçek veriyi silmek olurdu.
    final undoable =
        action == PeriodAction.endedToday ||
        viewModel.periodStartedToday ||
        _actedThisSession;

    final undo = !undoable
        ? null
        : switch (action) {
            PeriodAction.endedToday => viewModel.reopenPeriodToday,
            PeriodAction.end => viewModel.undoPeriodStart,
            PeriodAction.start => null,
          };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 52,
            child: switch (action) {
              PeriodAction.start => FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        if (!await _confirmEarlyStart(viewModel)) return;
                        if (!mounted) return;
                        await _run(viewModel.startPeriodToday);
                      },
                icon: const Icon(Icons.water_drop_outlined, size: 20),
                label: Text(context.tr('home_period_start')),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              // Bitirme yıkıcı bir eylem değil ama geri alınabilir olduğu belli
              // olsun diye daha sakin duruyor.
              PeriodAction.end => OutlinedButton.icon(
                onPressed: _busy ? null : () => _run(viewModel.endPeriodToday),
                icon: const Icon(Icons.stop_circle_outlined, size: 20),
                label: Text(context.tr('home_period_end')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: t.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              // Basılacak bir şey kalmadı. Düğme bırakmak, basınca hiçbir şey
              // olmayacağı için uygulamayı bozuk gösterirdi.
              PeriodAction.endedToday => const _EndedToday(),
            },
          ),

          // Geri alma altta ve sade: birincil eylemle yan yana koymak dar
          // telefonlarda ikisini de sıkıştırıyordu — Almanca "Meine Periode
          // ist vorbei" tek başına satırın çoğunu alıyor.
          if (undo != null)
            TextButton.icon(
              onPressed: _busy ? null : () => _undo(undo),
              icon: const Icon(Icons.undo, size: 18),
              label: Text(context.tr('home_period_undo')),
              style: TextButton.styleFrom(foregroundColor: t.textMuted),
            ),
        ],
      ),
    );
  }
}

class _EndedToday extends StatelessWidget {
  const _EndedToday();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: t.success),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              context.tr('home_period_ended_today'),
              style: theme.textTheme.bodyMedium?.copyWith(color: t.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
