import Foundation
import CoreGraphics

/// Parses OCR text blocks into structured receipt fields.
struct ReceiptParser {

    typealias Item = (text: String, rect: CGRect)

    private let extractor = ReceiptNumberExtractor()

    func parse(items: [Item]) -> ScannedReceiptData {
        var result = ScannedReceiptData()

        // Pass 1: fuel product line — "45,56L * 5,77 262,88 A"
        for item in items {
            if let hit = parseFuelProductLine(item.text) {
                result.volume       = ReceiptField(value: hit.volume, rect: item.rect)
                result.pricePerUnit = ReceiptField(value: hit.price,  rect: item.rect)
                result.totalCost    = ReceiptField(value: hit.total,  rect: item.rect)
                return result
            }
        }

        // Pass 2: keyword matching
        for item in items {
            let lower = item.text.lowercased()
            let numbers = extractor.extractNumbers(from: item.text)
            guard !numbers.isEmpty else { continue }

            if result.totalCost == nil, matchesTotal(lower) {
                if let max = numbers.max() {
                    result.totalCost = ReceiptField(value: max, rect: item.rect)
                }
            } else if result.pricePerUnit == nil, matchesPricePerUnit(lower) {
                if let n = numbers.first {
                    result.pricePerUnit = ReceiptField(value: n, rect: item.rect)
                }
            } else if result.volume == nil, matchesVolume(lower) {
                if let n = numbers.first {
                    result.volume = ReceiptField(value: n, rect: item.rect)
                }
            }
        }

        // Pass 3: keyword label on its own line, value on the next
        if result.totalCost == nil {
            result.totalCost = findValueAfterKeywordItem(items: items, matches: matchesTotal)
        }

        // Pass 4: mathematical inference — no visual location
        inferMissing(from: items, result: &result)
        return result
    }

    // MARK: - Fuel product line ("45,56L * 5,77 262,88 A")

    private func parseFuelProductLine(_ line: String) -> (volume: Double, price: Double, total: Double)? {
        let pattern = #"(\d+[.,]\d+)\s*[Ll]\s*[*×x]\s*(\d+[.,]\d+)\s+(\d+[.,]\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = line as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: line, range: range), match.numberOfRanges == 4 else { return nil }

        let r1 = match.range(at: 1), r2 = match.range(at: 2), r3 = match.range(at: 3)
        guard r1.location != NSNotFound, r2.location != NSNotFound, r3.location != NSNotFound,
              let vol   = extractor.normalize(ns.substring(with: r1)),
              let price = extractor.normalize(ns.substring(with: r2)),
              let total = extractor.normalize(ns.substring(with: r3)),
              isPlausibleVolume(vol), isPlausiblePrice(price), isPlausibleTotal(total) else { return nil }

        guard abs(price * vol - total) <= total * 0.05 + 0.5 else { return nil }
        return (volume: vol, price: price, total: total)
    }

    // MARK: - Keyword helpers

    private func matchesTotal(_ lower: String) -> Bool {
        ["total", "suma pln", "suma brutto", "razem", "wartość", "należność",
         "do zapłaty", "zapłata", "amount due", "sale total",
         "wpłacono razem"].contains { lower.contains($0) }
    }

    private func matchesPricePerUnit(_ lower: String) -> Bool {
        ["/l", "/gal", "cena/", "price/", "za litr", "unit price",
         "pln/l", "eur/l", "usd/l", "zł/l", "price per"].contains { lower.contains($0) }
    }

    private func matchesVolume(_ lower: String) -> Bool {
        ["ilość", "quantity", "volume", "vol:", "litry", "litrów",
         "liters", "litres"].contains { lower.contains($0) }
    }

    private func findValueAfterKeywordItem(items: [Item], matches predicate: (String) -> Bool) -> ReceiptField? {
        for (i, item) in items.enumerated() {
            guard predicate(item.text.lowercased()) else { continue }
            let numbers = extractor.extractNumbers(from: item.text)
            if let max = numbers.max() { return ReceiptField(value: max, rect: item.rect) }
            if let next = items.dropFirst(i + 1).first(where: { !$0.text.isEmpty }),
               let n = extractor.extractNumbers(from: next.text).max() {
                return ReceiptField(value: n, rect: next.rect)
            }
        }
        return nil
    }

    // MARK: - Mathematical inference

    private func inferMissing(from items: [Item], result: inout ScannedReceiptData) {
        guard result.pricePerUnit == nil || result.volume == nil || result.totalCost == nil else { return }
        let allNumbers = Array(
            Set(items.flatMap { extractor.extractNumbers(from: $0.text) }.filter { $0 > 0 })
        ).sorted()

        for i in 0..<allNumbers.count {
            for j in (i + 1)..<allNumbers.count {
                for k in (j + 1)..<allNumbers.count {
                    if assignIfPlausible(allNumbers[i], allNumbers[j], allNumbers[k], result: &result) { return }
                }
            }
        }
    }

    @discardableResult
    private func assignIfPlausible(_ a: Double, _ b: Double, _ c: Double, result: inout ScannedReceiptData) -> Bool {
        for (price, vol, total) in [(a,b,c),(a,c,b),(b,a,c),(b,c,a),(c,a,b),(c,b,a)] {
            guard isPlausiblePrice(price), isPlausibleVolume(vol), isPlausibleTotal(total) else { continue }
            if abs(price * vol - total) <= total * 0.05 + 0.5 {
                if result.pricePerUnit == nil { result.pricePerUnit = ReceiptField(value: price, rect: nil) }
                if result.volume       == nil { result.volume       = ReceiptField(value: vol,   rect: nil) }
                if result.totalCost    == nil { result.totalCost    = ReceiptField(value: total, rect: nil) }
                return true
            }
        }
        return false
    }

    private func isPlausiblePrice(_ v: Double) -> Bool { v >= 0.3 && v <= 15 }
    private func isPlausibleVolume(_ v: Double) -> Bool { v >= 1 && v <= 300 }
    private func isPlausibleTotal(_ v: Double) -> Bool { v >= 1 && v <= 3000 }
}
