import '../models/period_log.dart';

/// Regl günlerini yöneten ve logları blok (başlangıç/bitiş) olarak tutan servis.
class PeriodService {
  /// Yeni bir regl dönemi başlatır.
  /// Eğer zaten devam eden bir dönem varsa, onu bugünden bir önceki gün olarak kapatır.
  List<PeriodLog> startPeriod(List<PeriodLog> logs, DateTime startDate) {
    final cleanStart = DateTime(startDate.year, startDate.month, startDate.day);
    final newList = List<PeriodLog>.from(logs);

    // Devam eden bir döngü var mı kontrol et ve kapat
    for (var log in newList) {
      if (log.isOngoing) {
        // Eğer aynı gün başlatılmaya çalışılıyorsa hiçbir şey yapma
        if (DateTime(
          log.startDate.year,
          log.startDate.month,
          log.startDate.day,
        ).isAtSameMomentAs(cleanStart)) {
          return newList;
        }
        // Devam eden döngüyü, yeni başlayanın bir gün öncesinden kapat
        log.endDate = cleanStart.subtract(const Duration(days: 1));
      }
    }

    // Yeni log oluştur
    final newLog = PeriodLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startDate: cleanStart,
      endDate: null, // Devam ediyor
    );
    newList.add(newLog);

    newList.sort((a, b) => a.startDate.compareTo(b.startDate));
    return newList;
  }

  /// Devam eden veya belirli bir regl dönemini sonlandırır.
  List<PeriodLog> endPeriod(List<PeriodLog> logs, String id, DateTime endDate) {
    final cleanEnd = DateTime(endDate.year, endDate.month, endDate.day);
    final newList = List<PeriodLog>.from(logs);

    final index = newList.indexWhere((log) => log.id == id);
    if (index != -1) {
      // Bitiş tarihi, başlangıç tarihinden önce olamaz
      final logStart = newList[index].startDate;
      final cleanStart = DateTime(logStart.year, logStart.month, logStart.day);

      if (cleanEnd.isBefore(cleanStart)) {
        newList[index].endDate = cleanStart;
      } else {
        newList[index].endDate = cleanEnd;
      }
    }

    return newList;
  }

  /// Belirli bir regl kaydını tamamen siler.
  List<PeriodLog> deletePeriod(List<PeriodLog> logs, String id) {
    final newList = List<PeriodLog>.from(logs);
    newList.removeWhere((log) => log.id == id);
    return newList;
  }

  /// Bir günü regl günü olarak işaretler veya kaldırır.
  ///
  /// [ongoingLength]: devam eden bir dönemin kaç gün olarak varsayılacağı —
  /// kullanıcının ayarladığı regl süresi geçilmelidir.
  List<PeriodLog> toggleDay(
    List<PeriodLog> logs,
    DateTime date, {
    int ongoingLength = PeriodLog.defaultOngoingLength,
  }) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final newList = List<PeriodLog>.from(logs);

    // Check if the day is already in any period
    int foundIndex = -1;
    for (int i = 0; i < newList.length; i++) {
      if (newList[i].contains(cleanDate, ongoingLength: ongoingLength)) {
        foundIndex = i;
        break;
      }
    }

    if (foundIndex != -1) {
      // It is already a period day. We need to remove it.
      // 1. If it's a 1-day period, just delete the period
      final log = newList[foundIndex];
      final logStart = DateTime(
        log.startDate.year,
        log.startDate.month,
        log.startDate.day,
      );
      final logEnd = log.endDate != null
          ? DateTime(log.endDate!.year, log.endDate!.month, log.endDate!.day)
          : null;

      if (logStart.isAtSameMomentAs(cleanDate) &&
          (logEnd == null || logEnd.isAtSameMomentAs(cleanDate))) {
        newList.removeAt(foundIndex);
      } else if (logStart.isAtSameMomentAs(cleanDate)) {
        // Remove from the beginning
        newList[foundIndex].startDate = cleanDate.add(const Duration(days: 1));
      } else if (logEnd != null && logEnd.isAtSameMomentAs(cleanDate)) {
        // Remove from the end
        newList[foundIndex].endDate = cleanDate.subtract(
          const Duration(days: 1),
        );
      } else {
        // Split the period into two
        final newPeriodFirstPart = PeriodLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          startDate: log.startDate,
          endDate: cleanDate.subtract(const Duration(days: 1)),
        );
        final newPeriodSecondPart = PeriodLog(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          startDate: cleanDate.add(const Duration(days: 1)),
          endDate: log.endDate,
        );
        newList.removeAt(foundIndex);
        newList.add(newPeriodFirstPart);
        newList.add(newPeriodSecondPart);
      }
    } else {
      // It is not a period day. We need to add it.
      // Find if there are adjacent periods
      final nextDay = cleanDate.add(const Duration(days: 1));
      final prevDay = cleanDate.subtract(const Duration(days: 1));

      PeriodLog? prevPeriod;
      PeriodLog? nextPeriod;

      for (var log in newList) {
        if (log.endDate != null &&
            DateTime(
              log.endDate!.year,
              log.endDate!.month,
              log.endDate!.day,
            ).isAtSameMomentAs(prevDay)) {
          prevPeriod = log;
        }
        if (DateTime(
          log.startDate.year,
          log.startDate.month,
          log.startDate.day,
        ).isAtSameMomentAs(nextDay)) {
          nextPeriod = log;
        }
      }

      if (prevPeriod != null && nextPeriod != null) {
        // Merge two periods
        prevPeriod.endDate = nextPeriod.endDate;
        newList.remove(nextPeriod);
      } else if (prevPeriod != null) {
        // Merge to prev period
        prevPeriod.endDate = cleanDate;
      } else if (nextPeriod != null) {
        // Merge to next period
        nextPeriod.startDate = cleanDate;
      } else {
        // Standalone 1-day period
        newList.add(
          PeriodLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            startDate: cleanDate,
            endDate: cleanDate,
          ),
        );
      }
    }

    // Clean up and sort
    newList.sort((a, b) => a.startDate.compareTo(b.startDate));
    return newList;
  }

  /// Belirli bir tarihten önceki en son regl başlangıcını bulur.
  DateTime? getLastPeriodStartBefore(List<PeriodLog> logs, DateTime date) {
    if (logs.isEmpty) return null;
    final cleanDate = DateTime(date.year, date.month, date.day);
    final previousLogs = logs.where((l) {
      final logStart = DateTime(
        l.startDate.year,
        l.startDate.month,
        l.startDate.day,
      );
      return logStart.isBefore(cleanDate) ||
          logStart.isAtSameMomentAs(cleanDate);
    }).toList();

    if (previousLogs.isEmpty) return null;
    previousLogs.sort(
      (a, b) => b.startDate.compareTo(a.startDate),
    ); // En yakın geçmişten uzağa
    return previousLogs.first.startDate;
  }
}
