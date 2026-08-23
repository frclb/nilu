import 'package:flutter/material.dart';
import '../../../domain/models/period_log.dart';
import '../../../domain/models/daily_log.dart';
import '../../../domain/models/cycle_info.dart';
import '../../../domain/services/period_service.dart';
import '../../../domain/services/prediction_service.dart';
import '../../../data/repositories/period_repository.dart';
import '../../../data/datasources/widget_datasource.dart';
import '../../../data/repositories/cycle_settings_repository.dart';
import '../../../domain/services/widget_snapshot.dart';

/// Takvim ekranının durumunu yöneten ve iş mantığını bağlayan ViewModel.
class CalendarViewModel extends ChangeNotifier {
  final PeriodRepository _repository = PeriodRepository();
  final PeriodService _periodService = PeriodService();
  final PredictionService _predictionService = PredictionService();
  final CycleSettingsRepository _settingsRepo = CycleSettingsRepository();
  final WidgetDatasource _widget = const WidgetDatasource();

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

  /// Hormonal doğum kontrolü açıkken doğurganlık tahmini gösterilmez.
  bool get hormonalContraception => _hormonalContraception;

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
  Future<bool> togglePeriodDay(DateTime date) async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final currentlyIsPeriod = isPeriodDay(date);

    // Gelecek bir tarihe yeni regl girişi yapılamaz (kayıt silmeye izin ver)
    if (date.isAfter(today) && !currentlyIsPeriod) {
      return false;
    }

    _periodLogs = _periodService.toggleDay(
      _periodLogs,
      date,
      ongoingLength: _userPeriodLength,
    );
    _recalculate();
    await _repository.savePeriodLogs(_periodLogs);
    notifyListeners();
    return true;
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
    final day = getCycleDayForDate(date);
    if (day == null) return CyclePhase.unknown;
    return _cycleInfo.getPhaseForDay(day);
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
    );
    _publishWidget();
  }

  /// Belirli bir günün regl olup olmadığını kontrol eder.
  /// Devam eden dönemler kullanıcının ayarladığı regl süresi kadar projekte edilir.
  bool isPeriodDay(DateTime date) {
    return _periodLogs.any(
      (log) => log.contains(date, ongoingLength: _userPeriodLength),
    );
  }
}
