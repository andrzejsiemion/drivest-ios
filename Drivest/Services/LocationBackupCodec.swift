import Foundation

/// Shared encode/decode helpers for the four optional GPS keys
/// (`latitude`, `longitude`, `locationAccuracy`, `locationCapturedAt`) that any
/// backup `Codable` may include.
///
/// Decoding uses `decodeIfPresent` for all four keys so older backup files
/// (which predate the GPS feature) parse cleanly with the fields defaulting to
/// `nil`.
enum LocationBackupCodec {
    struct Fields: Equatable {
        let latitude: Double?
        let longitude: Double?
        let accuracy: Double?
        let capturedAt: Date?

        static let empty = Fields(latitude: nil, longitude: nil, accuracy: nil, capturedAt: nil)
    }

    static func decode<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        latitude: K,
        longitude: K,
        accuracy: K,
        capturedAt: K
    ) throws -> Fields {
        Fields(
            latitude: try container.decodeIfPresent(Double.self, forKey: latitude),
            longitude: try container.decodeIfPresent(Double.self, forKey: longitude),
            accuracy: try container.decodeIfPresent(Double.self, forKey: accuracy),
            capturedAt: try container.decodeIfPresent(Date.self, forKey: capturedAt)
        )
    }

    static func encode<K: CodingKey>(
        _ fields: Fields,
        into container: inout KeyedEncodingContainer<K>,
        latitude: K,
        longitude: K,
        accuracy: K,
        capturedAt: K
    ) throws {
        try container.encodeIfPresent(fields.latitude, forKey: latitude)
        try container.encodeIfPresent(fields.longitude, forKey: longitude)
        try container.encodeIfPresent(fields.accuracy, forKey: accuracy)
        try container.encodeIfPresent(fields.capturedAt, forKey: capturedAt)
    }
}
