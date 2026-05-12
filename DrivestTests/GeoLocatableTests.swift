import XCTest
import CoreLocation
@testable import Drivest

final class GeoLocatableTests: XCTestCase {

    // MARK: - Test double

    /// Plain class adopting `GeoLocatable` so the protocol contract can be
    /// exercised without standing up a SwiftData container.
    private final class GeoStub: GeoLocatable {
        var latitude: Double?
        var longitude: Double?
        var locationAccuracy: Double?
        var locationCapturedAt: Date?
    }

    // MARK: - Protocol extension helpers

    func testHasLocationIsFalseWhenEitherCoordinateMissing() {
        let stub = GeoStub()
        XCTAssertFalse(stub.hasLocation)

        stub.latitude = 52.0
        XCTAssertFalse(stub.hasLocation)

        stub.longitude = 21.0
        XCTAssertTrue(stub.hasLocation)

        stub.latitude = nil
        XCTAssertFalse(stub.hasLocation)
    }

    func testCoordinateIsNilUntilBothFieldsSet() {
        let stub = GeoStub()
        XCTAssertNil(stub.coordinate)

        stub.latitude = 52.2297
        XCTAssertNil(stub.coordinate)

        stub.longitude = 21.0122
        XCTAssertEqual(stub.coordinate?.latitude, 52.2297)
        XCTAssertEqual(stub.coordinate?.longitude, 21.0122)
    }

    func testApplyLocationCopiesAllFourFields() {
        let stub = GeoStub()
        let captured = Date(timeIntervalSince1970: 1_730_000_000)
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122),
            altitude: 0,
            horizontalAccuracy: 12.5,
            verticalAccuracy: -1,
            timestamp: captured
        )

        stub.applyLocation(location)

        XCTAssertEqual(stub.latitude, 52.2297)
        XCTAssertEqual(stub.longitude, 21.0122)
        XCTAssertEqual(stub.locationAccuracy, 12.5)
        XCTAssertEqual(stub.locationCapturedAt, captured)
    }

    func testClearLocationResetsAllFields() {
        let stub = GeoStub()
        stub.latitude = 1
        stub.longitude = 2
        stub.locationAccuracy = 3
        stub.locationCapturedAt = Date()

        stub.clearLocation()

        XCTAssertNil(stub.latitude)
        XCTAssertNil(stub.longitude)
        XCTAssertNil(stub.locationAccuracy)
        XCTAssertNil(stub.locationCapturedAt)
    }

    // MARK: - LocationCaptureFields

    @MainActor
    func testCaptureFieldsApplyAndWriteRoundTrip() {
        let fields = LocationCaptureFields()
        XCTAssertFalse(fields.hasLocation)

        let captured = Date(timeIntervalSince1970: 1_730_000_000)
        fields.apply(CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 50.0, longitude: 19.0),
            altitude: 0,
            horizontalAccuracy: 8,
            verticalAccuracy: -1,
            timestamp: captured
        ))

        XCTAssertTrue(fields.hasLocation)

        let target = GeoStub()
        fields.writeTo(target)

        XCTAssertEqual(target.latitude, 50.0)
        XCTAssertEqual(target.longitude, 19.0)
        XCTAssertEqual(target.locationAccuracy, 8)
        XCTAssertEqual(target.locationCapturedAt, captured)
    }

    @MainActor
    func testCaptureFieldsWriteToIsNoOpWhenEmpty() {
        let fields = LocationCaptureFields()
        let target = GeoStub()
        target.latitude = 11
        target.longitude = 22
        target.locationAccuracy = 33
        target.locationCapturedAt = Date(timeIntervalSince1970: 1_700_000_000)

        fields.writeTo(target)

        XCTAssertEqual(target.latitude, 11)
        XCTAssertEqual(target.longitude, 22)
        XCTAssertEqual(target.locationAccuracy, 33)
        XCTAssertEqual(target.locationCapturedAt, Date(timeIntervalSince1970: 1_700_000_000))
    }

    @MainActor
    func testCaptureFieldsClear() {
        let fields = LocationCaptureFields()
        fields.apply(CLLocation(latitude: 1, longitude: 2))
        XCTAssertTrue(fields.hasLocation)

        fields.clear()

        XCTAssertFalse(fields.hasLocation)
        XCTAssertNil(fields.latitude)
        XCTAssertNil(fields.longitude)
        XCTAssertNil(fields.locationAccuracy)
        XCTAssertNil(fields.locationCapturedAt)
    }

    // MARK: - LocationBackupCodec

    private struct CodecHarness: Codable, Equatable {
        let title: String
        let fields: LocationBackupCodec.Fields

        enum CodingKeys: String, CodingKey {
            case title
            case latitude
            case longitude
            case locationAccuracy
            case locationCapturedAt
        }

        init(title: String, fields: LocationBackupCodec.Fields) {
            self.title = title
            self.fields = fields
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.title = try c.decode(String.self, forKey: .title)
            self.fields = try LocationBackupCodec.decode(
                from: c,
                latitude: .latitude,
                longitude: .longitude,
                accuracy: .locationAccuracy,
                capturedAt: .locationCapturedAt
            )
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(title, forKey: .title)
            try LocationBackupCodec.encode(
                fields,
                into: &c,
                latitude: .latitude,
                longitude: .longitude,
                accuracy: .locationAccuracy,
                capturedAt: .locationCapturedAt
            )
        }
    }

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

    func testCodecDecodesOldJSONWithNoLocationKeys() throws {
        let oldJSON = #"{"title":"legacy"}"#.data(using: .utf8)!
        let decoded = try makeDecoder().decode(CodecHarness.self, from: oldJSON)
        XCTAssertEqual(decoded.title, "legacy")
        XCTAssertEqual(decoded.fields, .empty)
    }

    func testCodecRoundTripsPopulatedFields() throws {
        let captured = Date(timeIntervalSince1970: 1_730_000_000)
        let original = CodecHarness(
            title: "round-trip",
            fields: LocationBackupCodec.Fields(
                latitude: 52.2297,
                longitude: 21.0122,
                accuracy: 12.5,
                capturedAt: captured
            )
        )

        let data = try makeEncoder().encode(original)
        let decoded = try makeDecoder().decode(CodecHarness.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testCodecRoundTripsEmptyFields() throws {
        let original = CodecHarness(title: "empty", fields: .empty)
        let data = try makeEncoder().encode(original)
        let decoded = try makeDecoder().decode(CodecHarness.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testCodecDecodesPartialFields() throws {
        let partialJSON = #"{"title":"partial","latitude":52.0}"#.data(using: .utf8)!
        let decoded = try makeDecoder().decode(CodecHarness.self, from: partialJSON)

        XCTAssertEqual(decoded.fields.latitude, 52.0)
        XCTAssertNil(decoded.fields.longitude)
        XCTAssertNil(decoded.fields.accuracy)
        XCTAssertNil(decoded.fields.capturedAt)
    }
}
