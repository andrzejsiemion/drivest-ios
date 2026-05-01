import Foundation

/// Extracts numeric values from OCR text strings.
struct ReceiptNumberExtractor {

    func extractNumbers(from text: String) -> [Double] {
        guard let regex = try? NSRegularExpression(pattern: Self.pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let r = Range(match.range, in: text) else { return nil }
            return normalize(String(text[r]))
        }
    }

    func extractNumbersWithPositions(from text: String) -> [ReceiptNumber] {
        guard let regex = try? NSRegularExpression(pattern: Self.pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let textLength = max(text.count, 1)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let r = Range(match.range, in: text) else { return nil }
            guard let value = normalize(String(text[r])) else { return nil }
            let relativeX = Double(match.range.location) / Double(textLength)
            return ReceiptNumber(value: value, relativeX: relativeX)
        }
    }

    func normalize(_ str: String) -> Double? {
        let lastComma = str.lastIndex(of: ",")
        let lastDot   = str.lastIndex(of: ".")
        var s = str
        if let lc = lastComma, let ld = lastDot {
            if lc > ld {
                s = s.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            } else {
                s = s.replacingOccurrences(of: ",", with: "")
            }
        } else if lastComma != nil {
            s = s.replacingOccurrences(of: ",", with: ".")
        }
        return Double(s)
    }

    private static let pattern = #"(\d{1,3}(?:[.,]\d{3})*[.,]\d+|\d+[.,]\d+|\d+)"#
}
