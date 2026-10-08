import WidgetKit
import SwiftUI

/// Uygulamanın paylaşılan depoya yazdığı bir günlük içerik.
///
/// Widget ayrı bir süreçte çalışır ve uygulamanın belleğine de sözlüğüne de
/// erişemez. Uygulama önümüzdeki günlerin her biri için metinleri kendi
/// dilinde hazırlayıp yazıyor (bkz. `HomeWidgetPlan`); widget yalnızca o
/// günün girdisini çiziyor. Anahtar adları Dart tarafındaki
/// `HomeWidgetEntry.toJson()` ile birebir aynı olmalı.
///
/// Önceki sürüm döngü gününü alıp metni kendisi Türkçe kuruyordu: gebelikte
/// "Kayıt ekle" diyor, gecikmede "bugün başlıyor" yazıyor, uygulama
/// açılmadıkça gece yarısından sonra da dünün sayısını gösteriyordu.
struct WidgetDay: Decodable {
    let date: String
    let hasData: Bool
    let label: String
    let value: String
    let caption: String
    let detail: String
    let spoken: String?
    let progress: Double?
    let colorKey: String

    /// "yyyy-MM-dd" → o günün başlangıcı, cihazın takviminde.
    func start(in calendar: Calendar) -> Date? {
        let parts = date.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(
            from: DateComponents(year: parts[0], month: parts[1], day: parts[2])
        )
    }
}

struct WidgetStore {
    let days: [WidgetDay]
    let staleText: String?

    static let appGroup = "group.com.furkan.rcperiodtracker"

    /// `home_widget` anahtarı olduğu gibi yazıyor (`flutter.` öneki yok).
    static func load() -> WidgetStore {
        let defaults = UserDefaults(suiteName: appGroup)
        var days: [WidgetDay] = []
        if let json = defaults?.string(forKey: "entries"),
           let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([WidgetDay].self, from: data) {
            days = decoded
        }
        return WidgetStore(days: days, staleText: defaults?.string(forKey: "staleText"))
    }
}

/// Uygulama hiç veri yazmadan önce gereken birkaç metin. Uzantının kendi
/// sözlüğü yok; cihaz diline göre seçiliyor, bilinmeyen dilde İngilizce.
enum WidgetText {
    private static var language: String {
        let code = Locale.preferredLanguages.first ?? "en"
        return String(code.prefix(2))
    }

    static var description: String {
        switch language {
        case "tr": return "Döngü gününü, gebelik haftanı ya da lohusalık gününü gösterir."
        case "de": return "Zeigt deinen Zyklustag, deine Schwangerschaftswoche oder deinen Tag im Wochenbett."
        case "es": return "Muestra tu día del ciclo, tu semana de embarazo o tu día de posparto."
        case "fr": return "Affiche ton jour du cycle, ta semaine de grossesse ou ton jour de post-partum."
        case "pt": return "Mostra seu dia do ciclo, sua semana de gravidez ou seu dia de pós-parto."
        default: return "Shows your cycle day, pregnancy week or postnatal day."
        }
    }

    static var openApp: String {
        switch language {
        case "tr": return "Başlamak için Nilu'yu aç"
        case "de": return "Öffne Nilu, um zu beginnen"
        case "es": return "Abre Nilu para empezar"
        case "fr": return "Ouvre Nilu pour commencer"
        case "pt": return "Abra o Nilu para começar"
        default: return "Open Nilu to get started"
        }
    }
}

struct NiluEntry: TimelineEntry {
    let date: Date
    /// `nil`: gösterilecek gün yok — [message] yazılıyor.
    let day: WidgetDay?
    let message: String
}

struct NiluProvider: TimelineProvider {
    func placeholder(in context: Context) -> NiluEntry {
        // Yer tutucu gri kutular olarak çiziliyor; içerik görünmüyor.
        NiluEntry(
            date: Date(),
            day: WidgetDay(
                date: "", hasData: true, label: "••••• ••••", value: "14",
                caption: "•••••••", detail: "•••••••••••", spoken: nil,
                progress: 0.5, colorKey: "unknown"
            ),
            message: ""
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NiluEntry) -> Void) {
        completion(Self.entries(now: Date(), calendar: .current).current)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NiluEntry>) -> Void) {
        let plan = Self.entries(now: Date(), calendar: .current)
        // Her gün kendi gece yarısında başlıyor; günler bitince "uygulamayı
        // aç" girdisi kalıyor. Uygulama yeni içerik yazınca zaman çizelgesini
        // kendisi yeniliyor, ondan önce yeniden sormaya gerek yok.
        completion(Timeline(entries: plan.timeline, policy: .never))
    }

    /// Bugünden itibaren girdiler. Bugünün girdisi yoksa (uygulama hiç
    /// açılmadı ya da yazılan günler geride kaldı) başta mesaj var.
    static func entries(
        now: Date,
        calendar: Calendar
    ) -> (current: NiluEntry, timeline: [NiluEntry]) {
        let store = WidgetStore.load()
        let today = calendar.startOfDay(for: now)
        let stale = store.days.isEmpty ? WidgetText.openApp : (store.staleText ?? WidgetText.openApp)

        let upcoming = store.days
            .compactMap { day -> (Date, WidgetDay)? in
                guard let start = day.start(in: calendar), start >= today else { return nil }
                return (start, day)
            }
            .sorted { $0.0 < $1.0 }

        var timeline: [NiluEntry] = []
        if upcoming.first?.0 != today {
            timeline.append(NiluEntry(date: now, day: nil, message: stale))
        }
        for (start, day) in upcoming {
            timeline.append(NiluEntry(date: start, day: day, message: ""))
        }
        if let last = upcoming.last?.0,
           let after = calendar.date(byAdding: .day, value: 1, to: last) {
            timeline.append(NiluEntry(date: after, day: nil, message: stale))
        }
        return (timeline[0], timeline)
    }
}

/// Uygulamanın paletiyle aynı renkler; koyu temada açık tonlar.
func niluColor(_ key: String, dark: Bool) -> Color {
    func rgb(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
    switch key {
    case "menstruation": return rgb(dark ? 0xD07E93 : 0xB24A66)   // flow
    case "follicular":   return rgb(dark ? 0x5FB3A1 : 0x3E8E7E)   // phaseFollicular
    case "ovulation":    return rgb(dark ? 0x9E85C6 : 0x7B5EA7)   // ovulation
    case "luteal":       return rgb(dark ? 0xE08A5F : 0xB85936)   // phaseLuteal
    case "suppressed":   return rgb(dark ? 0xA0788F : 0xC79BB4)   // phaseSuppressed
    case "pregnancy", "postpartum":
                         return rgb(dark ? 0xE08A5F : 0xB85936)   // accent
    default:             return rgb(dark ? 0xC79BB4 : 0x6B2F55)   // marka
    }
}

struct CycleWidgetEntryView: View {
    var entry: NiluEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Group {
            if let day = entry.day, day.hasData {
                switch family {
                case .systemMedium: medium(day)
                default: small(day)
                }
            } else {
                empty(entry.day?.detail ?? entry.message)
            }
        }
        // Bekleme modunda ve kilitli ekranda içerik gizleniyor.
        .privacySensitive()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenText)
    }

    private var spokenText: String {
        guard let day = entry.day else { return entry.message }
        if let spoken = day.spoken, !spoken.isEmpty { return spoken }
        return [day.label, day.value, day.caption, day.detail]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private func color(_ day: WidgetDay) -> Color {
        niluColor(day.colorKey, dark: colorScheme == .dark)
    }

    private func empty(_ text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar.badge.plus")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.8)
        }
    }

    private func label(_ day: WidgetDay) -> some View {
        Text(day.label)
            .font(.system(size: 10, weight: .semibold))
            .kerning(1)
            .foregroundStyle(color(day))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private func small(_ day: WidgetDay) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            label(day)
            Text(day.value)
                .font(.system(size: 40, weight: .bold, design: .serif))
                .lineLimit(1)
                .minimumScaleFactor(0.45)
            Spacer(minLength: 0)
            if !day.caption.isEmpty {
                Text(day.caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            if !day.detail.isEmpty {
                Text(day.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func medium(_ day: WidgetDay) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(color(day).opacity(0.2), lineWidth: 8)
                if let progress = day.progress {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(color(day), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                Text(day.value)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.4)
                    .padding(10)
            }
            .frame(width: 84, height: 84)

            VStack(alignment: .leading, spacing: 4) {
                label(day)
                if !day.caption.isEmpty {
                    Text(day.caption)
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                if !day.detail.isEmpty {
                    Text(day.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct CycleWidget: Widget {
    /// Dart tarafındaki `WidgetDatasource.iOSWidgetName` ile aynı.
    let kind = "CycleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NiluProvider()) { entry in
            CycleWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { Color(.systemBackground) }
        }
        .configurationDisplayName("Nilu")
        .description(WidgetText.description)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct CycleWidgetBundle: WidgetBundle {
    var body: some Widget {
        CycleWidget()
    }
}
