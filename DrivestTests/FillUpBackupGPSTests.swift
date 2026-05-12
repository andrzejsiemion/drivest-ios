import XCTest
@testable import Drivest

/// Backward-compatibility guarantees around the four GPS keys
/// (`latitude`, `longitude`, `locationAccuracy`, `locationCapturedAt`)
/// on `FillUpBackup`. Existing fields are exercised only enough to make sure
/// the custom `init(from:)` / `encode(to:)` did not regress them.
final class FillUpBackupGPSTests: XCTestCase {

    private func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }

    private func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private func legacyFillUpJSON() -> Data {
        // Verbatim shape of a pre-GPS backup entry. No `latitude` / `longitude`
        // / `locationAccuracy` / `locationCapturedAt` keys. ISO-8601 dates match
        // the encoder strategy.
        let json = """
        {
            "createdAt": "2024-01-15T08:30:00Z",
            "date": "2024-01-15T08:30:00Z",
            "discount": null,
            "efficiency": 7.2,
            "fuelType": "diesel",
            "id": "11111111-1111-1111-1111-111111111111",
            "isFullTank": true,
            "note": null,
            "odometerReading": 50000,
            "photos": [],
            "pricePerLiter": 6.5,
            "totalCost": 325,
            "volume": 50
        }
        """
        return json.data(using: .utf8)!
    }

    // MARK: - Old format

    func testDecodesLegacyBackupWithNoGPSKeys() throws {
        let decoded = try makeDecoder().decode(FillUpBackup.self, from: legacyFillUpJSON())

        XCTAssertEqual(decoded.id, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(decoded.odometerReading, 50000)
        XCTAssertEqual(decoded.fuelType, "diesel")
        XCTAssertEqual(decoded.efficiency, 7.2)

        XCTAssertNil(decoded.latitude)
        XCTAssertNil(decoded.longitude)
        XCTAssertNil(decoded.locationAccuracy)
        XCTAssertNil(decoded.locationCapturedAt)
    }

    func testDecodesLegacyBackupInsideEnvelope() throws {
        // Verify the envelope-level decode tolerates pre-GPS fill-ups too.
        let envelopeJSON = """
        {
            "appVersion": "1.0",
            "exportedAt": "2024-01-15T09:00:00Z",
            "version": 1,
            "vehicle": {
                "id": "22222222-2222-2222-2222-222222222222",
                "name": "Old Car",
                "initialOdometer": 10000,
                "lastUsedAt": "2024-01-15T09:00:00Z",
                "createdAt": "2023-01-01T00:00:00Z"
            },
            "fillUps": [
                \(String(data: legacyFillUpJSON(), encoding: .utf8)!)
            ],
            "costEntries": []
        }
        """.data(using: .utf8)!

        let envelope = try makeDecoder().decode(BackupEnvelope.self, from: envelopeJSON)
        XCTAssertEqual(envelope.fillUps.count, 1)
        XCTAssertNil(envelope.fillUps[0].latitude)
        XCTAssertNil(envelope.fillUps[0].longitude)
    }

    // MARK: - New format

    func testEncodesAndDecodesPopulatedGPSFields() throws {
        let captured = Date(timeIntervalSince1970: 1_730_000_000)
        let original = FillUpBackup(
            id: "33333333-3333-3333-3333-333333333333",
            date: Date(timeIntervalSince1970: 1_730_000_000),
            pricePerLiter: 6.5,
            volume: 50,
            totalCost: 325,
            odometerReading: 50000,
            isFullTank: true,
            efficiency: 7.2,
            fuelType: "diesel",
            currencyCode: "PLN",
            exchangeRate: nil,
            discount: nil,
            note: "Tank near A2",
            photos: [],
            createdAt: Date(timeIntervalSince1970: 1_730_000_000),
            latitude: 52.2297,
            longitude: 21.0122,
            locationAccuracy: 12.5,
            locationCapturedAt: captured
        )

        let data = try makeEncoder().encode(original)
        let decoded = try makeDecoder().decode(FillUpBackup.self, from: data)

        XCTAssertEqual(decoded.latitude, 52.2297)
        XCTAssertEqual(decoded.longitude, 21.0122)
        XCTAssertEqual(decoded.locationAccuracy, 12.5)
        XCTAssertEqual(decoded.locationCapturedAt, captured)

        // Non-GPS fields untouched by the custom Codable.
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.pricePerLiter, original.pricePerLiter)
        XCTAssertEqual(decoded.note, original.note)
    }

    func testEncodedJSONOmitsNilGPSKeys() throws {
        let withoutGPS = FillUpBackup(
            id: "44444444-4444-4444-4444-444444444444",
            date: Date(timeIntervalSince1970: 1_730_000_000),
            pricePerLiter: 6.5,
            volume: 50,
            totalCost: 325,
            odometerReading: 50000,
            isFullTank: true,
            efficiency: nil,
            fuelType: nil,
            currencyCode: nil,
            exchangeRate: nil,
            discount: nil,
            note: nil,
            photos: [],
            createdAt: Date(timeIntervalSince1970: 1_730_000_000)
        )

        let data = try makeEncoder().encode(withoutGPS)
        let asString = String(data: data, encoding: .utf8) ?? ""

        // `encodeIfPresent` skips nil values, so older app versions reading this
        // JSON will simply not see the GPS keys at all.
        XCTAssertFalse(asString.contains("\"latitude\""))
        XCTAssertFalse(asString.contains("\"longitude\""))
        XCTAssertFalse(asString.contains("\"locationAccuracy\""))
        XCTAssertFalse(asString.contains("\"locationCapturedAt\""))
    }

    func testMixedCollectionPreservesPerEntryGPSState() throws {
        let captured = Date(timeIntervalSince1970: 1_730_000_000)
        let withGPS = FillUpBackup(
            id: "55555555-5555-5555-5555-555555555555",
            date: captured,
            pricePerLiter: 7,
            volume: 40,
            totalCost: 280,
            odometerReading: 60000,
            isFullTank: true,
            efficiency: nil,
            fuelType: nil,
            currencyCode: nil,
            exchangeRate: nil,
            discount: nil,
            note: nil,
            photos: [],
            createdAt: captured,
            latitude: 50.06,
            longitude: 19.94,
            locationAccuracy: 8,
            locationCapturedAt: captured
        )
        let withoutGPS = FillUpBackup(
            id: "66666666-6666-6666-6666-666666666666",
            date: captured,
            pricePerLiter: 7.1,
            volume: 41,
            totalCost: 291.1,
            odometerReading: 60500,
            isFullTank: true,
            efficiency: nil,
            fuelType: nil,
            currencyCode: nil,
            exchangeRate: nil,
            discount: nil,
            note: nil,
            photos: [],
            createdAt: captured
        )

        let data = try makeEncoder().encode([withGPS, withoutGPS])
        let decoded = try makeDecoder().decode([FillUpBackup].self, from: data)

        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].latitude, 50.06)
        XCTAssertEqual(decoded[0].longitude, 19.94)
        XCTAssertNil(decoded[1].latitude)
        XCTAssertNil(decoded[1].longitude)
    }
}
