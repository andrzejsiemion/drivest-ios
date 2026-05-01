import Foundation

/// Groups a date-keyed collection by "LLLL yyyy" (nominative month name), preserving insertion order.
enum MonthGrouper {
    static func group<T>(
        _ items: [T],
        dateKeyPath: KeyPath<T, Date>
    ) -> [(key: String, values: [T])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        var seen = Set<String>()
        var keys: [String] = []
        var dict: [String: [T]] = [:]
        for item in items {
            let key = formatter.string(from: item[keyPath: dateKeyPath])
            dict[key, default: []].append(item)
            if seen.insert(key).inserted { keys.append(key) }
        }
        return keys.map { (key: $0, values: dict[$0]!) }
    }
}
