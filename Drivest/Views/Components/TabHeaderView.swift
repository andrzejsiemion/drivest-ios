import SwiftUI
import SwiftData

struct TabHeaderView: View {
    let title: LocalizedStringKey
    @Binding var showSettings: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Color(.systemGroupedBackground))
    }
}

private let _groupByMonthFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "LLLL yyyy"
    return f
}()

func groupedByMonth<T>(
    _ items: [T],
    dateKeyPath: KeyPath<T, Date>
) -> [(key: String, value: [T])] {
    var seen = Set<String>()
    var keys: [String] = []
    var dict: [String: [T]] = [:]
    for item in items {
        let key = _groupByMonthFormatter.string(from: item[keyPath: dateKeyPath])
        dict[key, default: []].append(item)
        if seen.insert(key).inserted { keys.append(key) }
    }
    return keys.map { (key: $0, value: dict[$0]!) }
}
