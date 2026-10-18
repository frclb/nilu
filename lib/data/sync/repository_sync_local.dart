import '../../domain/models/sync_snapshot.dart';
import '../../domain/services/sync_engine.dart';
import '../repositories/care_repository.dart';
import '../repositories/conception_repository.dart';
import '../repositories/cycle_settings_repository.dart';
import '../repositories/period_repository.dart';
import '../repositories/pregnancy_repository.dart';
import '../repositories/profile_repository.dart';

/// Cihazdaki veriyi depolardan okuyup yazan eşitleme kaynağı.
///
/// Eşitlenen: regl ve günlük kayıtlar, gebelikler ve bakım kalemleri,
/// gebelik planlama niyeti, döngü ayarları, profil. Eşitlenmeyen: cihaza
/// özgü tercihler (bildirim saatleri, tema, uygulama kilidi, simge) ve
/// partnerle paylaşılan yakınlık durumu (o zaten kendi yolundan gidiyor).
class RepositorySyncLocal implements SyncLocal {
  const RepositorySyncLocal({
    PeriodRepository periods = const PeriodRepository(),
    PregnancyRepository pregnancies = const PregnancyRepository(),
    CareRepository care = const CareRepository(),
    ConceptionRepository conception = const ConceptionRepository(),
    CycleSettingsRepository settings = const CycleSettingsRepository(),
    ProfileRepository profile = const ProfileRepository(),
  }) : _periods = periods,
       _pregnancies = pregnancies,
       _care = care,
       _conception = conception,
       _settings = settings,
       _profile = profile;

  final PeriodRepository _periods;
  final PregnancyRepository _pregnancies;
  final CareRepository _care;
  final ConceptionRepository _conception;
  final CycleSettingsRepository _settings;
  final ProfileRepository _profile;

  @override
  Future<SyncSnapshot> read() async => SyncSnapshot(
    periodLogs: await _periods.getPeriodLogs(),
    dailyLogs: await _periods.getDailyLogs(),
    pregnancies: await _pregnancies.getAll(),
    careEvents: await _care.getAll(),
    conception: await _conception.get(),
    cycleSettings: SyncCycleSettings(
      cycleLength: await _settings.hasCycleLength()
          ? await _settings.getCycleLength()
          : null,
      periodLength: await _settings.hasPeriodLength()
          ? await _settings.getPeriodLength()
          : null,
      updatedAt: await _settings.getSettingsUpdatedAt(),
      hormonalContraception: await _settings.getHormonalContraception(),
    ),
    profile: SyncProfile(
      name: await _profile.getName(),
      email: await _profile.getEmail(),
      birthDate: await _profile.getBirthDate(),
    ),
  );

  @override
  Future<void> write(SyncSnapshot s) async {
    await _periods.savePeriodLogs(s.periodLogs);
    await _periods.saveDailyLogs(s.dailyLogs);
    await _pregnancies.saveAll(s.pregnancies);
    await _care.saveAll(s.careEvents);
    await _conception.set(s.conception);
    await _settings.restore(
      cycleLength: s.cycleSettings.cycleLength,
      periodLength: s.cycleSettings.periodLength,
      updatedAt: s.cycleSettings.updatedAt,
      hormonalContraception: s.cycleSettings.hormonalContraception,
    );
    await _profile.replace(
      name: s.profile.name,
      email: s.profile.email,
      birthDate: s.profile.birthDate,
    );
  }
}
