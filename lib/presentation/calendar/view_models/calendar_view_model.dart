import 'package:flutter/material.dart';
import '../../../domain/models/period_log.dart';
import '../../../domain/models/daily_log.dart';
import '../../../domain/models/cycle_info.dart';
import '../../../domain/models/life_stage.dart';
import '../../../domain/services/cycle_intervals.dart';
import '../../../domain/services/period_service.dart';
import '../../../domain/services/prediction_service.dart';
import '../../../data/repositories/period_repository.dart';
import '../../../data/datasources/widget_datasource.dart';
import '../../../data/repositories/cycle_settings_repository.dart';
import '../../../data/repositories/pregnancy_repository.dart';
import '../../../domain/services/widget_snapshot.dart';

/// Takvim ekranının durumunu yöneten ve iş mantığını bağlayan ViewModel.
class CalendarViewModel extends ChangeNotifier {
  final PeriodRepository _repository = PeriodRepository();
  final PeriodService _periodService = PeriodService();
  final PredictionService _predictionService = PredictionService();
  final CycleSettingsRepository _settingsRepo = CycleSettingsRepository();
  final WidgetDatasource _widget = const WidgetDatasource();
  final PregnancyRepository _pregnancyRepo = const PregnancyRepository();

  List<PeriodLog> _periodLogs = [];
  List<DailyLog> _dailyLogs = [];
  CycleInfo _cycleInfo = CycleInfo();
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = true;

  // Kullanıcı ayarları
  int _userCycleLength = 28;
  int _userPeriodLength = 5;
  DateTime? _settingsUpdatedAt;
  bool _hormonalContraception = false;
  LifeStage _lifeStage = LifeStage.cycle;
  List<DateSpan> _cycleBreaks = const [];

  /// Hormonal doğum kontrolü açıkken doğurganlık tahmini gösterilmez.
  bool get hormonalContraception => _hormonalContraception;

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

  CalendarViewModel() {
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
    return _cycleInfo.cycleDayForDate(
      date,
      loggedStart: _periodService.getLastPeriodStartBefore(_periodLogs, date),
    );
  }

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
  bool isPredictedPeriodDay(DateTime date) =>
      _cycleInfo.isPredictedPeriod(date) || isExpectedPeriodDay(date);

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
  }

  /// Günlük detayı (semptom/not) günceller.
  Future<void> updateDailyLog(DailyLog log) async {
    final index = _dailyLogs.indexWhere(
      (l) => DateUtils.isSameDay(l.date, log.date),
    );

    if (index != -1) {
      _dailyLogs[index] = log;
    } else {
      _dailyLogs.add(log);
    }

    await _repository.saveDailyLogs(_dailyLogs);
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

  /// Ana ekran widget'ını günceller.
  ///
  /// Hesap her değiştiğinde çağrılır; kullanıcı uygulamayı açmadan da doğru
  /// sayıyı görmeli.
  void _publishWidget() {
    _widget.publish(WidgetSnapshot.from(_cycleInfo));
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
    _publishWidget();
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
