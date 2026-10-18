import '../models/sync_snapshot.dart';

/// Buluttaki kopyanın üst bilgisi.
class SyncMeta {
  /// Her yüklemede değişen kimlik. "Benim gördüğümden beri başka bir cihaz
  /// yükledi mi?" sorusunun cevabı.
  final String? version;

  /// Yüklenen metnin SHA-256 özeti (bkz. [SyncSnapshot.hash]).
  final String? hash;

  /// Kopyanın kaç parçaya bölündüğü (Firestore belge sınırı 1 MB).
  final int chunkCount;

  /// Kullanıcı başka bir cihazda eşitlemeyi kapattı (rızasını geri çekti).
  /// Bu cihaz da yüklemeyi bırakmalı.
  final bool disabled;

  const SyncMeta({
    this.version,
    this.hash,
    this.chunkCount = 0,
    this.disabled = false,
  });
}

/// Bulut tarafı. Ağ hatasında [SyncException] fırlatır.
abstract class SyncRemote {
  bool get isAvailable;

  /// Kopya hiç yoksa `null`.
  Future<SyncMeta?> fetchMeta(String uid);

  /// Kopyanın metni. Özet tutmazsa [SyncException] (yarım ya da bozuk
  /// kopya cihazdakinin üstüne yazılmasın).
  Future<String> download(String uid, SyncMeta meta);

  /// Kopyayı yazar; yeni üst bilgiyi döner.
  Future<SyncMeta> upload(String uid, String payload, String hash);

  /// Kopyayı siler. [keepDisabledMarker] ise "eşitleme kapatıldı" işareti
  /// kalır ki öbür cihazlar da yüklemeyi bıraksın.
  Future<void> delete(String uid, {bool keepDisabledMarker = false});
}

/// Bu cihazdaki veri.
abstract class SyncLocal {
  Future<SyncSnapshot> read();

  /// Cihazdaki veriyi [snapshot] ile **değiştirir**.
  Future<void> write(SyncSnapshot snapshot);
}

/// Son eşitlemenin izi (hesaba göre).
class SyncState {
  final String? lastHash;
  final String? lastRemoteVersion;
  final DateTime? lastSyncAt;

  const SyncState({this.lastHash, this.lastRemoteVersion, this.lastSyncAt});
}

abstract class SyncStateStore {
  Future<SyncState> load(String uid);
  Future<void> save(String uid, SyncState state);
  Future<void> clear(String uid);
}

class SyncException implements Exception {
  final String message;
  const SyncException(this.message);

  @override
  String toString() => 'SyncException: $message';
}

enum SyncOutcome {
  /// Bulut ile cihaz zaten aynı.
  upToDate,

  /// Cihazdaki değişiklik buluta yazıldı.
  uploaded,

  /// Başka cihazdaki değişiklik bu cihaza indi.
  downloaded,

  /// İki taraf da değişmişti; birleşim iki tarafa yazıldı.
  merged,

  /// Eşitlenecek bir şey yok (bulut boş, cihaz boş).
  nothing,

  /// Eşitleme başka bir cihazda kapatılmış; bu cihaz da durmalı.
  disabledRemotely,
}

/// Bir hesabın cihaz ile bulut kopyasını eşitler.
///
/// Karar, son eşitlemede görülen özet ve sürüme göre:
///
/// | bulut değişti mi | cihaz değişti mi | ne yapılıyor              |
/// |------------------|------------------|---------------------------|
/// | hayır            | —                | cihaz yükleniyor          |
/// | evet             | hayır            | bulut indiriliyor         |
/// | evet             | evet             | birleşim iki tarafa       |
///
/// İlk eşitleme (bu cihaz bulutu hiç görmedi) "ikisi de değişti" sayılıyor:
/// yeni telefonda boşsa bulut iniyor, doluysa iki taraf birleşiyor. Hiçbir
/// durumda boş bir cihaz buluttakinin üstüne yazılmıyor.
class SyncEngine {
  SyncEngine({
    required this.remote,
    required this.local,
    required this.state,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SyncRemote remote;
  final SyncLocal local;
  final SyncStateStore state;
  final DateTime Function() _clock;

  /// [resume]: kullanıcı bu cihazda eşitlemeyi (yeniden) açtı. Başka bir
  /// cihazın bıraktığı "kapatıldı" işareti o zaman aşılıyor; yoksa bu cihaz
  /// da durmalı.
  Future<SyncOutcome> sync(String uid, {bool resume = false}) async {
    final yerel = await local.read();
    final yerelOzet = yerel.hash;
    final iz = await state.load(uid);
    final meta = await remote.fetchMeta(uid);

    if (meta != null && meta.disabled) {
      if (!resume) return SyncOutcome.disabledRemotely;
      // Boş bile olsa yükleniyor: işaret ancak yeni bir kopyayla kalkar.
      await _upload(uid, yerel);
      return SyncOutcome.uploaded;
    }

    if (meta == null || meta.version == null) {
      if (yerel.isEmpty) return SyncOutcome.nothing;
      await _upload(uid, yerel);
      return SyncOutcome.uploaded;
    }

    if (meta.hash == yerelOzet) {
      await _remember(uid, yerelOzet, meta.version);
      return SyncOutcome.upToDate;
    }

    final bulutDegisti = iz.lastRemoteVersion != meta.version;
    final cihazDegisti = iz.lastHash != yerelOzet;

    if (!bulutDegisti) {
      await _upload(uid, yerel);
      return SyncOutcome.uploaded;
    }

    final bulut = await _download(uid, meta);

    if (!cihazDegisti || yerel.isEmpty) {
      await local.write(bulut);
      await _remember(uid, (await local.read()).hash, meta.version);
      return SyncOutcome.downloaded;
    }

    final birlesim = SyncSnapshot.merge(local: yerel, remote: bulut);
    await local.write(birlesim);
    final yazilan = await local.read();
    if (yazilan.hash == meta.hash) {
      // Birleşim buluttakiyle aynı çıktı: bu cihazın eklediği bir şey yok.
      await _remember(uid, yazilan.hash, meta.version);
      return SyncOutcome.downloaded;
    }
    await _upload(uid, yazilan);
    return SyncOutcome.merged;
  }

  /// Son eşitlemeden beri bu cihazda bir şey değişti mi? Ağa çıkmıyor:
  /// ekranın her bildirimi (seçili gün değişti, sayfa açıldı) bir sunucu
  /// okumasına dönüşmesin.
  Future<bool> hasLocalChanges(String uid) async =>
      (await local.read()).hash != (await state.load(uid)).lastHash;

  Future<void> _upload(String uid, SyncSnapshot snapshot) async {
    final yeni = await remote.upload(uid, snapshot.encode(), snapshot.hash);
    await _remember(uid, snapshot.hash, yeni.version);
  }

  Future<SyncSnapshot> _download(String uid, SyncMeta meta) async {
    final metin = await remote.download(uid, meta);
    try {
      return SyncSnapshot.decode(metin);
    } on FormatException catch (e) {
      throw SyncException('Unreadable cloud copy: ${e.message}');
    }
  }

  Future<void> _remember(String uid, String hash, String? version) =>
      state.save(
        uid,
        SyncState(
          lastHash: hash,
          lastRemoteVersion: version,
          lastSyncAt: _clock(),
        ),
      );
}
