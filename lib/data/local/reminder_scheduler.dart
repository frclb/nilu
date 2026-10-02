import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/services/reminder_planner.dart';

/// [ReminderPlanner] tarafından üretilen planı cihaza yazar.
///
/// Ayarlar ekranları eskiden yalnızca tercihi kaydediyordu; hiçbir bildirim
/// planlanmıyordu. Kullanıcı "Adet Döngüsü Yaklaşıyor" hatırlatıcısını açıyor
/// ama hiçbir zaman bildirim almıyordu.
class ReminderScheduler {
  static const String _channelId = 'cycle_reminders';
  static const String _channelName = 'Cycle Reminders';

  final FlutterLocalNotificationsPlugin _plugin;

  ReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Eklentiyi ve saat dilimi veritabanını hazırlar. Tekrar çağrılabilir.
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        // İzin açılışta değil, kullanıcı hatırlatıcıyı açtığında istenir.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Bildirim iznini ister. Kullanıcı reddederse false döner.
  Future<bool> requestPermission() async {
    await init();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    return false;
  }

  /// Planı uygular: önce mevcut hatırlatıcıları temizler, sonra yenilerini yazar.
  ///
  /// [localize] anahtarı kullanıcının diline çevirir — bildirim metni cihazda
  /// üretildiği için burada çözülmelidir.
  Future<void> apply(
    List<ScheduledReminder> reminders, {
    required String Function(String key) localize,
  }) async {
    await init();
    await cancelAll();

    for (final reminder in reminders) {
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.literalTitle ?? localize(reminder.titleKey),
          body: localize(reminder.bodyKey),
          scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: reminder.type == ReminderType.dailyLog
              ? DateTimeComponents
                    .time // Günlük kayıt her gün tekrarlar
              : null,
        );
      } catch (e) {
        // Tek bir hatırlatıcının planlanamaması diğerlerini engellememeli.
        debugPrint('Reminder ${reminder.id} could not be scheduled: $e');
      }
    }
  }

  /// Bekleyen bütün hatırlatıcıları iptal eder. Hata fırlatmaz.
  ///
  /// Temizlik "elinden geleni yap" türünde bir işlem: başarısız olması
  /// çağıranı durdurmamalı. Önceden `init()` hata yakalamanın dışındaydı;
  /// senkronizasyon boş planda da temizlik yapmaya başlayınca eklentinin
  /// başlatılamadığı her durumda yakalanmamış bir hata fırlıyordu.
  Future<void> cancelAll() async {
    try {
      await init();
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Could not cancel reminders: $e');
    }
  }

  /// Bekleyen hatırlatıcılar — hata ayıklama ve test için.
  Future<List<PendingNotificationRequest>> pending() async {
    await init();
    return _plugin.pendingNotificationRequests();
  }
}
