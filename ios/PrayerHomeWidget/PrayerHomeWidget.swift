import SwiftUI
import WidgetKit

private let prayerWidgetAppGroup = "group.com.example.islamicApp"

struct PrayerWidgetSnapshot {
    let prayerName: String
    let prayerKey: String
    let timeText: String
    let remainingText: String
    let locationLabel: String
    let backgroundFilePath: String
    let nextPrayerAtMillis: Int64
    let followingPrayerName: String
    let followingPrayerTime: String
    let hasData: Bool

    static func read() -> PrayerWidgetSnapshot {
        let defaults = UserDefaults(suiteName: prayerWidgetAppGroup)
        return PrayerWidgetSnapshot(
            prayerName: defaults?.string(forKey: "prayerName") ?? "الصلاة",
            prayerKey: defaults?.string(forKey: "prayerKey") ?? "maghrib",
            timeText: defaults?.string(forKey: "timeText") ?? "--:--",
            remainingText: defaults?.string(forKey: "remainingText") ?? "--:--:--",
            locationLabel: defaults?.string(forKey: "locationLabel") ?? "موقعك",
            backgroundFilePath: defaults?.string(forKey: "backgroundFilePath") ?? "",
            nextPrayerAtMillis: Int64(defaults?.integer(forKey: "nextPrayerAtMillis") ?? 0),
            followingPrayerName: defaults?.string(forKey: "followingPrayerName") ?? "—",
            followingPrayerTime: defaults?.string(forKey: "followingPrayerTime") ?? "—",
            hasData: defaults?.bool(forKey: "hasData") ?? false
        )
    }
}

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: PrayerWidgetSnapshot
}

struct PrayerWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerWidgetEntry {
        PrayerWidgetEntry(date: Date(), snapshot: PrayerWidgetSnapshot.read())
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        completion(PrayerWidgetEntry(date: Date(), snapshot: PrayerWidgetSnapshot.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void) {
        let snapshot = PrayerWidgetSnapshot.read()
        let entry = PrayerWidgetEntry(date: Date(), snapshot: snapshot)
        let nextRefresh = refreshDate(for: snapshot)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func refreshDate(for snapshot: PrayerWidgetSnapshot) -> Date {
        let now = Date()
        let midnight = Calendar.current.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)

        if snapshot.nextPrayerAtMillis > 0 {
            let nextPrayer = Date(timeIntervalSince1970: TimeInterval(snapshot.nextPrayerAtMillis) / 1000)
                .addingTimeInterval(60)
            if nextPrayer > now {
                return min(nextPrayer, midnight)
            }
        }

        return now.addingTimeInterval(60 * 60)
    }
}

struct PrayerHomeWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PrayerWidgetEntry

    var body: some View {
        ZStack {
            background
            LinearGradient(
                colors: [
                    Color.black.opacity(0.18),
                    Color(red: 0.03, green: 0.09, blue: 0.14).opacity(0.86)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            VStack(alignment: .trailing, spacing: family == .systemSmall ? 5 : 8) {
                HStack {
                    locationChip
                    Spacer(minLength: 6)
                    Text("الصلاة القادمة")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.86))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Text(entry.snapshot.hasData ? entry.snapshot.prayerName : "حدّث المواقيت")
                    .font(.system(size: family == .systemSmall ? 26 : 32, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(entry.snapshot.timeText)
                    .font(.system(size: family == .systemSmall ? 22 : 26, weight: .bold))
                    .foregroundStyle(.white)
                    .environment(\.layoutDirection, .leftToRight)

                Text(entry.snapshot.hasData ? "متبقي \(entry.snapshot.remainingText)" : "افتح التطبيق للتحديث")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)

                if family != .systemSmall {
                    Text("الصلاة التالية: \(entry.snapshot.followingPrayerName) \(entry.snapshot.followingPrayerTime)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.14), in: Capsule())
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
            .padding(14)
        }
        .widgetURL(URL(string: "islamicapp://prayer"))
    }

    private var background: some View {
        Group {
            if let image = widgetBackgroundImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.44, blue: 0.32),
                        Color(red: 0.07, green: 0.23, blue: 0.16),
                        Color(red: 0.02, green: 0.09, blue: 0.15)
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            }
        }
    }

    private var locationChip: some View {
        Text(entry.snapshot.locationLabel)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(0.14), in: Capsule())
    }

    private func widgetBackgroundImage() -> UIImage? {
        if let bundledImage = UIImage(named: "PrayerWidgetBackground") {
            return bundledImage
        }

        let path = entry.snapshot.backgroundFilePath
        guard !path.isEmpty else { return nil }
        return UIImage(contentsOfFile: path)
    }
}

@main
struct PrayerHomeWidget: Widget {
    let kind = "PrayerHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerWidgetProvider()) { entry in
            PrayerHomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("الصلاة القادمة")
        .description("يعرض الصلاة القادمة والوقت المتبقي.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
