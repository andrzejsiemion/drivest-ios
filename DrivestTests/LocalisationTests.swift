import XCTest

final class LocalisationTests: XCTestCase {

    private var catalog: [String: Any] = [:]
    private var strings: [String: Any] = [:]

    override func setUpWithError() throws {
        guard let url = Bundle(for: LocalisationTests.self)
            .url(forResource: "Localizable", withExtension: "xcstrings",
                 subdirectory: nil) ??
            // Fall back to main bundle path for test environment
            Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings") else {
            // Try loading from source path directly (works in test targets that copy resources)
            let sourcePath = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Fuel/Resources/Localizable.xcstrings")
            let data = try Data(contentsOf: sourcePath)
            catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            strings = catalog["strings"] as? [String: Any] ?? [:]
            return
        }
        let data = try Data(contentsOf: url)
        catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        strings = catalog["strings"] as? [String: Any] ?? [:]
    }

    // MARK: - Key Coverage

    func testAllKeysHavePolishTranslation() {
        var missingPolish: [String] = []
        for (key, value) in strings {
            guard let entry = value as? [String: Any] else { continue }
            if let shouldTranslate = entry["shouldTranslate"] as? Bool, !shouldTranslate { continue }
            let localizations = entry["localizations"] as? [String: Any] ?? [:]
            let pl = localizations["pl"] as? [String: Any]
            let hasTranslation = pl != nil && !(pl?.isEmpty ?? true)
            if !hasTranslation {
                missingPolish.append(key)
            }
        }
        XCTAssertTrue(
            missingPolish.isEmpty,
            "Keys missing Polish translation (\(missingPolish.count)): \(missingPolish.sorted().joined(separator: ", "))"
        )
    }

    // MARK: - Plural Coverage

    func testPluralKeysHaveRequiredPolishForms() {
        let requiredForms = ["one", "few", "other"]
        var issues: [String] = []

        for (key, value) in strings {
            guard let entry = value as? [String: Any] else { continue }
            let localizations = entry["localizations"] as? [String: Any] ?? [:]
            guard let pl = localizations["pl"] as? [String: Any],
                  let variations = pl["variations"] as? [String: Any],
                  let plural = variations["plural"] as? [String: Any] else { continue }

            for form in requiredForms {
                if plural[form] == nil {
                    issues.append("Key \"\(key)\" missing plural form: \(form)")
                }
            }
        }

        XCTAssertTrue(
            issues.isEmpty,
            "Plural coverage issues:\n\(issues.joined(separator: "\n"))"
        )
    }

    // MARK: - No Empty Translations

    func testNoEmptyPolishValues() {
        var emptyValues: [String] = []
        for (key, value) in strings {
            guard let entry = value as? [String: Any] else { continue }
            if let shouldTranslate = entry["shouldTranslate"] as? Bool, !shouldTranslate { continue }
            let localizations = entry["localizations"] as? [String: Any] ?? [:]
            guard let pl = localizations["pl"] as? [String: Any] else { continue }

            if let stringUnit = pl["stringUnit"] as? [String: Any],
               let translatedValue = stringUnit["value"] as? String,
               translatedValue.trimmingCharacters(in: .whitespaces).isEmpty {
                emptyValues.append(key)
            }
        }
        XCTAssertTrue(
            emptyValues.isEmpty,
            "Keys with empty Polish translation value: \(emptyValues.joined(separator: ", "))"
        )
    }
}
