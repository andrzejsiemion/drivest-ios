import Foundation

struct CurrencyDefinition: Identifiable, Hashable {
    let code: String
    let symbol: String
    let name: String

    var id: String { code }

    static let allCurrencies: [CurrencyDefinition] = [
        CurrencyDefinition(code: "EUR", symbol: "€", name: "Euro"),
        CurrencyDefinition(code: "USD", symbol: "$", name: "US Dollar"),
        CurrencyDefinition(code: "GBP", symbol: "£", name: "British Pound"),
        CurrencyDefinition(code: "PLN", symbol: "zł", name: "Polish Złoty"),
        CurrencyDefinition(code: "CZK", symbol: "Kč", name: "Czech Koruna"),
        CurrencyDefinition(code: "CHF", symbol: "Fr", name: "Swiss Franc"),
        CurrencyDefinition(code: "SEK", symbol: "kr", name: "Swedish Krona"),
        CurrencyDefinition(code: "NOK", symbol: "kr", name: "Norwegian Krone"),
        CurrencyDefinition(code: "DKK", symbol: "kr", name: "Danish Krone"),
        CurrencyDefinition(code: "HUF", symbol: "Ft", name: "Hungarian Forint"),
        CurrencyDefinition(code: "RON", symbol: "lei", name: "Romanian Leu"),
        CurrencyDefinition(code: "BGN", symbol: "лв", name: "Bulgarian Lev"),
        CurrencyDefinition(code: "TRY", symbol: "₺", name: "Turkish Lira"),
        CurrencyDefinition(code: "UAH", symbol: "₴", name: "Ukrainian Hryvnia"),
        CurrencyDefinition(code: "JPY", symbol: "¥", name: "Japanese Yen"),
        CurrencyDefinition(code: "CAD", symbol: "C$", name: "Canadian Dollar"),
        CurrencyDefinition(code: "AUD", symbol: "A$", name: "Australian Dollar"),
    ]

    static func currency(for code: String) -> CurrencyDefinition? {
        allCurrencies.first { $0.code == code }
    }

    static func symbol(for code: String) -> String? {
        currency(for: code)?.symbol
    }
}
