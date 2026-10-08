import 'dart:async';

import 'package:flutter/material.dart';
import '../../../domain/models/calendar_day.dart';
import '../../../domain/models/period_log.dart';
import '../../../domain/models/daily_log.dart';
import '../../../domain/models/cycle_info.dart';
import '../../../domain/models/life_stage.dart';
import '../../../domain/models/pregnancy.dart';
import '../../../domain/services/cycle_intervals.dart';
import '../../../domain/services/period_service.dart';
import '../../../domain/services/prediction_service.dart';
import '../../../data/repositories/period_repository.dart';
import '../../../data/repositories/cycle_settings_repository.dart';
import '../../../data/repositories/health_write_back.dart';
import '../../../data/repositories/pregnancy_repository.dart';

/// Takvim ekranının durumunu yöneten ve iş mantığını bağlayan ViewModel.
class CalendarViewModel extends ChangeNotifier {
  final PeriodRepository _repository = PeriodRepository();
  final PeriodService _periodService = PeriodService();
  final PredictionService _predictionService = PredictionService();
  final CycleSettingsRepository _settingsRepo = CycleSettingsRepository();
  final PregnancyRepository _pregnancyRepo = const PregnancyRepository();
  final HealthWriteBack _healthWriteBack;

  List<PeriodLog> _periodLogs = [];
  List<DailyLog> _dailyLogs = [];
  CycleInfo _cycleInfo = CycleInfo();
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = true;

  // Kullanıcı ayarları
  int _userCycleLength = 28;
  bool _cycleLengthSaved = false;
  int _userPeriodLength = 5;
  DateTime? _settingsUpdatedAt;
  bool _hormonalContraception = false;
  LifeStage _lifeStage = LifeStage.cycle;
  List<DateSpan> _cycleBreaks = const [];
  int _pregnancyRevision = -1;

  /// Hormonal doğum kontrolü açıkken doğurganlık tahmini gösterilmez.
  bool get hormonalContraception => _hormonalContraception;

  /// Ortalama döngü uzunluğu kullanıcıdan mı geliyor?
  ///
  /// Ya kendisi bir süre kaydetmiş ya da kayıtlarından en az bir döngü
  /// aralığı çıkıyor. İkisi de yoksa `cycleInfo.averageCycleLength`
  /// varsayılan 28: kurulumda gebelik yolunu seçen kullanıcı ne süre söyledi
  /// ne regl kaydı girdi. O sayıyı "senin döngün" diye sunmamak için.
  bool get cycleLengthKnown =>
      _cycleLengthSaved ||
      CycleIntervals.of(_periodLogs, breaks: _cycleBreaks).isNotEmpty;

  /// Kullanıcının bulunduğu yaşam evresi.
  LifeStage get lifeStage => _lifeStage;

  /// Süren bir gebelik var mı?
  bool get pregnant => _lifeStage == LifeStage.pregnancy;

  /// Döngü istatistiğinden dışlanan gebelik/lohusalık aralıkları.
  ///
  /// Döngü uzunluğu hesaplayan her ekran bunu buradan alıyor:
  /// `InsightsService.cycleLengths` bu parametreyi **zorunlu** tutuyor, yani
  /// yeni bir ekran onu unutamıyor.
  List<DateSpan> get cycleBreaks => _cycleBreaks;

  /// Gebelik durumundaki değişikliği uygular.
  ///
  /// `PregnancyViewModel` her değiştiğinde `main.dart`'taki
  /// `ChangeNotifierProxyProvider` bunu çağırıyor. Gebelik bittiği an takvim
  /// de biliyor; hiçbir ekranın "takvimi yenilemeyi" hatırlaması gerekmiyor.
  /// Aynı sürüm ikinci kez uygulanmıyor: yeniden çizimlerde boşuna
  /// hesaplamasın.
  void applyPregnancies(List<Pregnancy> gebelikler, {required int revision}) {
    if (revision == _pregnancyRevision) return;
    _pregnancyRevision = revision;
    _lifeStage = LifeStage.resolve(gebelikler, today: DateTime.now());
    _cycleBreaks = CycleBreaks.fromPregnancies(gebelikler);
    if (_isLoading) return;
    _recalculate();
    notifyListeners();
  }

  /// Bu evrede regl kaydı tutulur mu?
  ///
  /// Karar tek yerde: `LifeStage.bleedingMeaning`. Gebelikte kanama tehlike
  /// işareti, lohusalıkta lohia — ikisi de regl değil. Regl kaydı açılırsa
  /// `lastPeriodStart` kayar ve her şey yanlışlanır; kullanıcı fark etmez,
  /// çünkü ekranda makul bir sayı durur.
  ///
  /// Reddetme sessiz değil: çağıran `false` alıyor ve arayüz sebebini
  /// söyleyebiliyor.
  bool get _canRecordPeriods => _lifeStage.recordsPeriods;

  List<PeriodLog> get periodLogs => _periodLogs;
  List<DailyLog> get dailyLogs => _dailyLogs;
  CycleInfo get cycleInfo => _cycleInfo;
  DateTime get selectedDate => _selectedDate;
  DateTime get currentMonth => _currentMonth;
  bool get isLoading => _isLoading;

  CalendarViewModel({HealthWriteBack? healthWriteBack})
    : _healthWriteBack = healthWriteBack ?? HealthWriteBack() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _periodLogs = await _repository.getPeriodLogs();
      _dailyLogs = await _repository.getDailyLogs();

      // Kullanıcı döngü ayarlarını yükle
      _userCycleLength = await _settingsRepo.getCycleLength();
      _cycleLengthSaved = await _settingsRepo.hasCycleLength();
      _userPeriodLength = await _settingsRepo.getPeriodLength();
      _settingsUpdatedAt = await _settingsRepo.getSettingsUpdatedAt();
      _hormonalContraception = await _settingsRepo.getHormonalContraception();
      final gebelikler = await _pregnancyRepo.getAll();
      _lifeStage = LifeStage.resolve(gebelikler, today: DateTime.now());
      _cycleBreaks = CycleBreaks.fromPregnancies(gebelikler);

      _recalculate();
    } catch (e) {
      debugPrint('Error loading calendar data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Dışarıdan çağrılabilir: verilerini yeniden yükler.
  /// Onboarding sonrası veya döngü ayarları değiştirildikten sonra çağrılır.
  Future<void> refreshData() async {
    await _loadData();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void nextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    notifyListeners();
  }

  void previousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    notifyListeners();
  }

  /// Görünen ayı ve seçili günü bugüne döndürür.
  ///
  /// Kullanıcı ileri/geri oklarıyla uzaklaştığında tek dokunuşla dönebilmeli;
  /// aksi halde ok düğmesine ay sayısı kadar basmak gerekiyor.
  void goToToday() {
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = now;
    notifyListeners();
  }

  /// Görünen ay, içinde bulunduğumuz ay mı?
  bool get isViewingCurrentMonth {
    final now = DateTime.now();
    return _currentMonth.year == now.year && _currentMonth.month == now.month;
  }

  /// Seçili gün için döngü gününü hesaplar.
  int? getCycleDay() {
    return getCycleDayForDate(_selectedDate);
  }

  /// Belirli bir gün için döngü gününü hesaplar.
  ///
  /// Yalnızca son kayıttan saymak gelecek tarihlerde 30., 40. güne uzuyordu;
  /// tahmin edilen başlangıçlar da çapa sayılıyor.
  int? getCycleDayForDate(DateTime date) {
    // Gebelik ve lohusalık günlerinde döngü yok. Önceden 24 haftalık
    // gebelikte takvim başlığı "Döngü günü 5" diyordu.
    if (_inBreak(date)) return null;
    final start = _periodService.getLastPeriodStartBefore(_periodLogs, date);
    // Kesintiden sonra henüz regl yoksa gün de yok: gebelik öncesi son
    // adetten sayılsaydı düşükten bir ay sonra "Döngü günü 171" yazılırdı.
    if (start != null && _startPrecedesBreakEnd(start, date)) return null;
    return _cycleInfo.cycleDayForDate(date, loggedStart: start);
  }

  /// [date] bir gebelik ya da lohusalık aralığında mı (bkz. `CycleBreaks`)?
  bool _inBreak(DateTime date) => _cycleBreaks.any((b) => b.contains(date));

  /// [start] ile [date] arasında biten bir kesinti var mı?
  bool _startPrecedesBreakEnd(DateTime start, DateTime date) =>
      _cycleBreaks.any((b) {
        final son = b.end;
        return son != null && !date.isBefore(son) && start.isBefore(son);
      });

  /// Bir günü regl günü olarak işaretler veya kaldırır. Başarılıysa true döner.
  Future<bool> togglePeriodDay(DateTime rawDate) async {
    if (!_canRecordPeriods) return false;

    // Saat bilgisi burada temizleniyor. "Bugünü işaretle" diyen bir çağrı
    // `DateTime.now()` geçirdiğinde tarih gece yarısından sonra olduğu için
    // aşağıdaki gelecek-günü koruması devreye giriyor ve işlem sessizce
    // reddediliyordu. İşlem zaten gün hassasiyetinde; normalleştirmenin yeri
    // çağıran taraf değil burası.
    final date = DateTime(rawDate.year, rawDate.month, rawDate.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentlyIsPeriod = isPeriodDay(date);

    // Gelecek bir tarihe yeni regl girişi yapılamaz (kayıt silmeye izin ver)
    if (date.isAfter(today) && !currentlyIsPeriod) {
      return false;
    }

    _periodLogs = _periodService.toggleDay(
      _periodLogs,
      date,
      today: today,
      expectedLength: _userPeriodLength,
    );
    await _persistPeriods();
    return true;
  }

  /// Takvimin "tahmin" olarak boyadığı gün.
  ///
  /// İki kaynak var: sonraki döngünün tahmini, bir de devam eden dönemin
  /// bugünden sonraki beklenen günleri.
  /// Gebelik ve lohusalık günlerinde tahmin yok: açık kalmış bir kanama
  /// kaydının "beklenen devamı" da dahil. Kurulum ekranı "tahminler duracak"
  /// diyor; takvim bunu boyamaya devam ediyordu.
  bool isPredictedPeriodDay(DateTime date) =>
      !_inBreak(date) &&
      (_cycleInfo.isPredictedPeriod(date) || isExpectedPeriodDay(date));

  /// Ana ekrandaki düğmenin bugün için sunduğu eylem.
  PeriodAction get periodActionToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final log in _periodLogs) {
      if (!log.containsRecorded(today, today: today)) continue;
      // Dönem bugünde kapatılmışsa yapacak bir şey kalmadı; geri alma dışında.
      final end = log.endDate;
      final closedToday =
          end != null &&
          DateTime(end.year, end.month, end.day).isAtSameMomentAs(today);
      return closedToday ? PeriodAction.endedToday : PeriodAction.end;
    }
    return PeriodAction.start;
  }

  /// Bugünkü kayıt bugün mü açıldı?
  ///
  /// Geri alma düğmesi yalnızca bunun doğru olduğu gün gösteriliyor: dün
  /// başlamış bir dönemde "geri al" bugünü kayıttan çıkarırdı ve bu da
  /// geri alma değil, veriyi bozmak olurdu.
  bool get periodStartedToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _periodLogs.any((log) => log.firstDay.isAtSameMomentAs(today));
  }

  /// "Reglim başladı" — bugünden itibaren devam eden bir dönem açar.
  Future<bool> startPeriodToday() async {
    if (!_canRecordPeriods) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _periodLogs = _periodService.startPeriod(_periodLogs, today);
    await _persistPeriods();
    return true;
  }

  /// "Reglim bitti" — dönemi bugünde kapatır; bugün kayıtta kalır.
  Future<bool> endPeriodToday() async {
    if (!_canRecordPeriods) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _periodLogs = _periodService.endPeriod(_periodLogs, today);
    await _persistPeriods();
    return true;
  }

  /// "Reglim başladı"yı geri alır: bugünü kayıttan tamamen çıkarır.
  ///
  /// Yanlışlıkla basıldığında ekranda duran "Reglim bitti" bir çıkış yolu
  /// değil — o, bugünü işaretli bırakıp dönemi kapatır. Geri alma, başlatma
  /// öncesine dönmeli: yeni açılan kayıt siliniyor, yeniden açılmış bir kayıt
  /// varsa eski bitiş tarihine dönüyor.
  Future<bool> undoPeriodStart() async {
    if (!_canRecordPeriods) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!isPeriodDay(today)) return false;
    _periodLogs = _periodService.toggleDay(_periodLogs, today, today: today);
    await _persistPeriods();
    return true;
  }

  /// "Reglim bitti"yi geri alır.
  ///
  /// Dönem **bugün açıldıysa** kayıt tamamen kaldırılıyor: o durumda
  /// kullanıcı yanlışlıkla başlatıp bitirmiştir ve yalnızca yeniden açmak
  /// onu bir günlük sahte bir dönemle baş başa bırakır — üstelik o kayıt
  /// `lastPeriodStart`'ı kaydırdığı için bütün tahminler de bozuk kalır.
  ///
  /// Dönem daha eskiyse geri alma "bitirmeyi" geri alır, yani kayıt yeniden
  /// açılır; oradaki günler gerçek veri.
  Future<bool> reopenPeriodToday() async {
    if (!_canRecordPeriods) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final log in _periodLogs) {
      final end = log.endDate;
      if (end == null) continue;
      if (!DateTime(end.year, end.month, end.day).isAtSameMomentAs(today)) {
        continue;
      }

      if (log.firstDay.isAtSameMomentAs(today)) {
        _periodLogs = _periodService.toggleDay(
          _periodLogs,
          today,
          today: today,
        );
      } else {
        log.endDate = null;
      }
      break;
    }

    await _persistPeriods();
    return true;
  }

  Future<void> _persistPeriods() async {
    _recalculate();
    await _repository.savePeriodLogs(_periodLogs);
    notifyListeners();
    _mirrorToHealth();
  }

  /// Kullanıcı açtıysa regl günlerini Sağlık'a da yazar (bkz.
  /// `HealthWriteBack`). Beklenmiyor: ekran yazımı beklememeli.
  void _mirrorToHealth() {
    unawaited(
      _healthWriteBack.syncIfEnabled(
        periods: _periodLogs,
        dailyLogs: _dailyLogs,
      ),
    );
  }

  /// Günlük detayı (semptom/not) günceller.
  Future<void> updateDailyLog(DailyLog log) async {
    final index = _dailyLogs.indexWhere(
      (l) => DateUtils.isSameDay(l.date, log.date),
    );

    final oncekiAkis = index != -1 ? _dailyLogs[index].flowIntensity : null;
    if (index != -1) {
      _dailyLogs[index] = log;
    } else {
      _dailyLogs.add(log);
    }

    await _repository.saveDailyLogs(_dailyLogs);
    notifyListeners();
    // Sağlık'a yazılan günün akışı değişti.
    if (oncekiAkis != log.flowIntensity) _mirrorToHealth();
  }

  /// Bitişi girilmemiş regl kayıtlarını kapatır: planlanan regl süresinin
  /// sonunda, bugünü geçmeden.
  ///
  /// Açık kayıt bugüne kadar uzanıyor (bkz. `PeriodLog.lastRecordedDay`).
  /// Gebelik başlarken kapatılmazsa, "Reglim bitti"ye basmayı unutmuş
  /// kullanıcının takviminde bütün gebelik regl günü olarak boyanırdı.
  /// Kayıt silinmiyor; yalnızca makul bir sonla kapanıyor.
  Future<void> closeOngoingPeriods() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var degisti = false;
    for (final log in _periodLogs) {
      if (!log.isOngoing) continue;
      final planlanan = log.firstDay.plusDays(_userPeriodLength - 1);
      log.endDate = planlanan.isAfter(today) ? today : planlanan;
      degisti = true;
    }
    if (!degisti) return;
    await _repository.savePeriodLogs(_periodLogs);
    _recalculate();
    notifyListeners();
  }

  /// Belirli bir gün için DailyLog getirir (yoksa boş döner).
  DailyLog getDailyLogForDate(DateTime date) {
    try {
      return _dailyLogs.firstWhere((l) => DateUtils.isSameDay(l.date, date));
    } catch (_) {
      return DailyLog(date: date);
    }
  }

  /// Son girilen DailyLog'u döndürür (en yakın tarih).
  DailyLog? getLastDailyLog() {
    if (_dailyLogs.isEmpty) return null;
    final sorted = List<DailyLog>.from(_dailyLogs)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }

  /// Seçili günün döngü evresini döndürür.
  ///
  /// Takvimde başka bir güne dokunulduğunda içerik o güne göre değişsin diye;
  /// öncesinde her gün için bugünün evresi gösteriliyordu.
  CyclePhase phaseForDate(DateTime date) {
    return _cycleInfo.phaseForDate(
      date,
      loggedStart: _periodService.getLastPeriodStartBefore(_periodLogs, date),
    );
  }

  void _recalculate() {
    _cycleInfo = _predictionService.getCycleInfo(
      _periodLogs,
      userCycleLength: _userCycleLength,
      userPeriodLength: _userPeriodLength,
      settingsUpdatedAt: _settingsUpdatedAt,
      hormonalContraception: _hormonalContraception,
      // Tek üretim çağıranı burası; varsayılan `const []` olduğu için
      // unutulursa lohusa anneye eski SAT'tan tahmin yapılır. Bunu
      // `calendar_breaks_wiring_test` koruyor.
      breaks: _cycleBreaks,
    );
  }

  /// Belirli bir günün regl olup olmadığını kontrol eder.
  /// Devam eden dönemler kullanıcının ayarladığı regl süresi kadar projekte edilir.
  bool isPeriodDay(DateTime date) {
    return _periodLogs.any((log) => log.containsRecorded(date));
  }

  /// Devam eden dönemin bugünden sonraki beklenen günü mü?
  ///
  /// Takvim bunu tahmin olarak boyuyor. Kayıtlı günlerle aynı koyulukta
  /// gösterseydik kullanıcının yaşamadığı bir kanamayı yaşanmış gibi
  /// gösterirdik.
  bool isExpectedPeriodDay(DateTime date) {
    return _periodLogs.any(
      (log) =>
          log.isExpectedContinuation(date, expectedLength: _userPeriodLength),
    );
  }
}

/// Ana ekrandaki düğmenin gösterdiği eylem.
enum PeriodAction {
  /// Bugün kanama kaydı yok.
  start,

  /// Dönem devam ediyor; bitirilebilir.
  end,

  /// Dönem bugün kapatıldı. Geriye yalnızca geri almak kalıyor.
  endedToday,
}
