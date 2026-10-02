import '../../data/repositories/care_repository.dart';
import '../../data/repositories/conception_repository.dart';
import '../../data/repositories/pregnancy_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/services/reminder_planner.dart';

/// Bakım hatırlatıcılarının girdisini depolardan yükler.
///
/// Planı yazan iki yer de (açılış senkronizasyonu ve bildirim ayarları)
/// bunu kullanıyor. Her biri kendi yükleseydi ikisi zamanla ayrışırdı ve
/// birinin yazdığı plan ötekinin hatırlatıcılarını silerdi.
Future<CarePlanInput> loadCarePlanInput({
  PregnancyRepository pregnancies = const PregnancyRepository(),
  CareRepository care = const CareRepository(),
  ConceptionRepository conception = const ConceptionRepository(),
  ProfileRepository profile = const ProfileRepository(),
  DateTime? today,
}) async {
  final gun = today ?? DateTime.now();
  final hepsi = await pregnancies.getAll();
  final ilgili = LifeStage.relevantPregnancy(hepsi, today: gun);

  return CarePlanInput(
    stage: LifeStage.resolve(hepsi, today: gun),
    pregnancy: ilgili,
    events: ilgili == null ? const [] : await care.forPregnancy(ilgili.id),
    conception: await conception.get(),
    birthDate: await profile.getBirthDate(),
  );
}
