import WidgetKit
import SwiftUI

/// Uygulamanın paylaşılan depoya yazdığı özet.
///
/// Widget ayrı bir süreçte çalışır ve uygulamanın belleğine erişemez; yalnızca
/// App Group üzerinden paylaşılan bu küçük özeti okur. Ham sağlık kaydı
/// buraya yazılmaz — widget'ın döngü gününden fazlasına ihtiyacı yok ve
/// paylaşılan depo uygulamanın şifreli deposu kadar korumalı değil.
struct CycleSnapshot {
    let cycleDay: Int?
    let daysUntilPeriod: Int?
    let phaseKey: String
    let hasData: Bool

    static let appGroup = "group.com.furkan.rcperiodtracker"

    /// `home_widget`'in `saveWidgetData` çağrısı anahtarı olduğu gibi yazıyor —
    /// `shared_preferences`'ın aksine `flutter.` öneki eklemiyor. Anahtar adları
    /// Dart tarafındaki `WidgetSnapshot.toMap()` ile birebir aynı olmalı.
    static func load() -> CycleSnapshot {
        let defaults = UserDefaults(suiteName: appGroup)

        func int(_ key: String) -> Int? {
            guard let value = defaults?.object(forKey: key) else {
                return nil
            }
            return (value as? NSNumber)?.intValue
        }

        return CycleSnapshot(
            cycleDay: int("cycleDay"),
            daysUntilPeriod: int("daysUntilPeriod"),
            phaseKey: defaults?.string(forKey: "phaseKey") ?? "unknown",
            hasData: defaults?.bool(forKey: "hasData") ?? false
        )
    }

    /// Faz adı. Widget uzantısının kendi Localizable dosyası olmadığı için
    /// metinler burada; uygulamanın sözlüğüne erişemiyor.
    var phaseName: String {
        switch phaseKey {
        case "menstruation": return NSLocalizedString("Regl", comment: "")
        case "follicular":   return NSLocalizedString("Foliküler", comment: "")
        case "ovulation":    return NSLocalizedString("Yumurtlama", comment: "")
        case "luteal":       return NSLocalizedString("Luteal", comment: "")
        default:             return ""
        }
    }

    /// Faz rengi — uygulamanın paletiyle aynı.
    var phaseColor: Color {
        switch phaseKey {
        case "menstruation": return Color(red: 0.698, green: 0.290, blue: 0.400) // rose600
        case "follicular":   return Color(red: 0.243, green: 0.557, blue: 0.494) // success
        case "ovulation":    return Color(red: 0.482, green: 0.369, blue: 0.655) // iris500
        case "luteal":       return Color(red: 0.722, green: 0.349, blue: 0.212) // clay600
        default:             return Color(red: 0.420, green: 0.184, blue: 0.333) // plum700
        }
    }

    /// Döngünün ne kadarının geçtiği (0...1).
    ///
    /// Toplam uzunluk elde veri olmadan bilinemiyor; geçen gün ile kalan günün
    /// toplamı tam olarak bu döngünün tahmini uzunluğu. Sabit bir oran çizmek
    /// kullanıcıya yanlış bilgi verirdi.
    var progress: Double? {
        guard let day = cycleDay, let remaining = daysUntilPeriod else { return nil }
        let total = day + remaining
        guard total > 0 else { return nil }
        return min(1, max(0, Double(day) / Double(total)))
    }
}

struct CycleEntry: TimelineEntry {
    let date: Date
    let snapshot: CycleSnapshot
}

struct CycleProvider: TimelineProvider {
    func placeholder(in context: Context) -> CycleEntry {
        CycleEntry(
            date: Date(),
            snapshot: CycleSnapshot(
                cycleDay: 14, daysUntilPeriod: 14,
                phaseKey: "ovulation", hasData: true
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CycleEntry) -> Void) {
        completion(CycleEntry(date: Date(), snapshot: CycleSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CycleEntry>) -> Void) {
        let entry = CycleEntry(date: Date(), snapshot: CycleSnapshot.load())

        // Gün sayacı gece yarısı değişiyor; bir sonraki güne kadar bekle.
        // Sabit aralıkla yenilemek hem gereksiz hem gün ortasında yanlış
        // sayı gösterme riski taşıyor.
        let midnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)

        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

struct CycleWidgetEntryView: View {
    var entry: CycleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if !entry.snapshot.hasData {
            VStack(spacing: 6) {
                Image(systemName: "calendar.badge.plus")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Kayıt ekle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            switch family {
            case .systemMedium: mediumBody
            default: smallBody
            }
        }
    }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DÖNGÜ GÜNÜ")
                .font(.system(size: 10, weight: .semibold))
                .kerning(1)
                .foregroundStyle(entry.snapshot.phaseColor)

            Text("\(entry.snapshot.cycleDay ?? 0)")
                .font(.system(size: 40, weight: .bold, design: .serif))

            Spacer(minLength: 0)

            if !entry.snapshot.phaseName.isEmpty {
                Text(entry.snapshot.phaseName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let days = entry.snapshot.daysUntilPeriod {
                Text(days == 0 ? "Bugün başlıyor" : "Regle \(days) gün kaldı")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mediumBody: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(entry.snapshot.phaseColor.opacity(0.2), lineWidth: 8)
                if let progress = entry.snapshot.progress {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            entry.snapshot.phaseColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                Text("\(entry.snapshot.cycleDay ?? 0)")
                    .font(.system(size: 26, weight: .bold, design: .serif))
            }
            .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 4) {
                Text("DÖNGÜ GÜNÜ")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1)
                    .foregroundStyle(entry.snapshot.phaseColor)
                if !entry.snapshot.phaseName.isEmpty {
                    Text(entry.snapshot.phaseName).font(.headline)
                }
                if let days = entry.snapshot.daysUntilPeriod {
                    Text(days == 0 ? "Reglin bugün başlıyor" : "Regle \(days) gün kaldı")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct CycleWidget: Widget {
    let kind = "CycleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CycleProvider()) { entry in
            CycleWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { Color(.systemBackground) }
        }
        .configurationDisplayName("Döngü")
        .description("Döngü gününü ve regle kalan süreyi gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct CycleWidgetBundle: WidgetBundle {
    var body: some Widget {
        CycleWidget()
    }
}
