import Foundation

// MARK: - Backup Envelope

struct BackupEnvelope: Codable {
    let version: Int
    let exportedAt: Date
    let appVersion: String
    let vehicle: VehicleBackup
    let fillUps: [FillUpBackup]
    let costEntries: [CostEntryBackup]
    var chargingSessions: [ChargingSessionBackup]
    var energySnapshots: [EnergySnapshotBackup]
    var electricityBills: [ElectricityBillBackup]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        appVersion = try container.decode(String.self, forKey: .appVersion)
        vehicle = try container.decode(VehicleBackup.self, forKey: .vehicle)
        fillUps = try container.decode([FillUpBackup].self, forKey: .fillUps)
        costEntries = try container.decode([CostEntryBackup].self, forKey: .costEntries)
        chargingSessions = (try? container.decode([ChargingSessionBackup].self, forKey: .chargingSessions)) ?? []
        energySnapshots = (try? container.decode([EnergySnapshotBackup].self, forKey: .energySnapshots)) ?? []
        electricityBills = (try? container.decode([ElectricityBillBackup].self, forKey: .electricityBills)) ?? []
    }

    init(version: Int, exportedAt: Date, appVersion: String, vehicle: VehicleBackup, fillUps: [FillUpBackup], costEntries: [CostEntryBackup], chargingSessions: [ChargingSessionBackup], energySnapshots: [EnergySnapshotBackup], electricityBills: [ElectricityBillBackup]) {
        self.version = version
        self.exportedAt = exportedAt
        self.appVersion = appVersion
        self.vehicle = vehicle
        self.fillUps = fillUps
        self.costEntries = costEntries
        self.chargingSessions = chargingSessions
        self.energySnapshots = energySnapshots
        self.electricityBills = electricityBills
    }
}

// MARK: - Vehicle

struct VehicleBackup: Codable {
    let id: String
    let name: String
    let make: String?
    let model: String?
    let descriptionText: String?
    let initialOdometer: Double
    let distanceUnit: String?
    let fuelType: String?
    let fuelUnit: String?
    let efficiencyDisplayFormat: String?
    let secondTankFuelType: String?
    let secondTankFuelUnit: String?
    let vin: String?
    let photoData: String?   // base64
    let lastUsedAt: Date
    let createdAt: Date
}

// MARK: - FillUp

struct FillUpBackup: Codable {
    let id: String
    let date: Date
    let pricePerLiter: Double
    let volume: Double
    let totalCost: Double
    let odometerReading: Double
    let isFullTank: Bool
    let efficiency: Double?
    let fuelType: String?
    let currencyCode: String?
    let exchangeRate: Double?
    let discount: Double?
    let note: String?
    let photos: [String]   // base64 array
    let createdAt: Date

    // GPS — all optional. Older backup files (which predate the GPS feature)
    // are decoded via `decodeIfPresent` and arrive here as `nil`.
    let latitude: Double?
    let longitude: Double?
    let locationAccuracy: Double?
    let locationCapturedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, date, pricePerLiter, volume, totalCost, odometerReading
        case isFullTank, efficiency, fuelType, currencyCode, exchangeRate
        case discount, note, photos, createdAt
        case latitude, longitude, locationAccuracy, locationCapturedAt
    }

    init(
        id: String,
        date: Date,
        pricePerLiter: Double,
        volume: Double,
        totalCost: Double,
        odometerReading: Double,
        isFullTank: Bool,
        efficiency: Double?,
        fuelType: String?,
        currencyCode: String?,
        exchangeRate: Double?,
        discount: Double?,
        note: String?,
        photos: [String],
        createdAt: Date,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationAccuracy: Double? = nil,
        locationCapturedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.pricePerLiter = pricePerLiter
        self.volume = volume
        self.totalCost = totalCost
        self.odometerReading = odometerReading
        self.isFullTank = isFullTank
        self.efficiency = efficiency
        self.fuelType = fuelType
        self.currencyCode = currencyCode
        self.exchangeRate = exchangeRate
        self.discount = discount
        self.note = note
        self.photos = photos
        self.createdAt = createdAt
        self.latitude = latitude
        self.longitude = longitude
        self.locationAccuracy = locationAccuracy
        self.locationCapturedAt = locationCapturedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.date = try c.decode(Date.self, forKey: .date)
        self.pricePerLiter = try c.decode(Double.self, forKey: .pricePerLiter)
        self.volume = try c.decode(Double.self, forKey: .volume)
        self.totalCost = try c.decode(Double.self, forKey: .totalCost)
        self.odometerReading = try c.decode(Double.self, forKey: .odometerReading)
        self.isFullTank = try c.decode(Bool.self, forKey: .isFullTank)
        self.efficiency = try c.decodeIfPresent(Double.self, forKey: .efficiency)
        self.fuelType = try c.decodeIfPresent(String.self, forKey: .fuelType)
        self.currencyCode = try c.decodeIfPresent(String.self, forKey: .currencyCode)
        self.exchangeRate = try c.decodeIfPresent(Double.self, forKey: .exchangeRate)
        self.discount = try c.decodeIfPresent(Double.self, forKey: .discount)
        self.note = try c.decodeIfPresent(String.self, forKey: .note)
        self.photos = try c.decode([String].self, forKey: .photos)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt)

        let gps = try LocationBackupCodec.decode(
            from: c,
            latitude: .latitude,
            longitude: .longitude,
            accuracy: .locationAccuracy,
            capturedAt: .locationCapturedAt
        )
        self.latitude = gps.latitude
        self.longitude = gps.longitude
        self.locationAccuracy = gps.accuracy
        self.locationCapturedAt = gps.capturedAt
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encode(pricePerLiter, forKey: .pricePerLiter)
        try c.encode(volume, forKey: .volume)
        try c.encode(totalCost, forKey: .totalCost)
        try c.encode(odometerReading, forKey: .odometerReading)
        try c.encode(isFullTank, forKey: .isFullTank)
        try c.encodeIfPresent(efficiency, forKey: .efficiency)
        try c.encodeIfPresent(fuelType, forKey: .fuelType)
        try c.encodeIfPresent(currencyCode, forKey: .currencyCode)
        try c.encodeIfPresent(exchangeRate, forKey: .exchangeRate)
        try c.encodeIfPresent(discount, forKey: .discount)
        try c.encodeIfPresent(note, forKey: .note)
        try c.encode(photos, forKey: .photos)
        try c.encode(createdAt, forKey: .createdAt)

        try LocationBackupCodec.encode(
            LocationBackupCodec.Fields(
                latitude: latitude,
                longitude: longitude,
                accuracy: locationAccuracy,
                capturedAt: locationCapturedAt
            ),
            into: &c,
            latitude: .latitude,
            longitude: .longitude,
            accuracy: .locationAccuracy,
            capturedAt: .locationCapturedAt
        )
    }
}

// MARK: - CostEntry

struct CostEntryBackup: Codable {
    let id: String
    let date: Date
    let title: String
    let amount: Double
    let currencyCode: String?
    let exchangeRate: Double?
    let categoryName: String?
    let note: String?
    let attachments: [String]   // base64 array
    let createdAt: Date
}

// MARK: - ChargingSession (placeholder)

struct ChargingSessionBackup: Codable {
    // empty placeholder for future use
    let id: String
}

// MARK: - EnergySnapshot

struct EnergySnapshotBackup: Codable {
    let id: String
    let fetchedAt: Date
    let odometerKm: Double
    let socPercent: Int?
    let source: String
    let createdAt: Date
}

// MARK: - ElectricityBill

struct ElectricityBillBackup: Codable {
    let id: String
    let startDate: Date?
    let endDate: Date
    let totalKwh: Double
    let totalCost: Double
    let currencyCode: String?
    let distanceKm: Double?
    let efficiencyKwhPer100km: Double?
    let costPerKm: Double?
    let hasSnapshotData: Bool
    let startSnapshotId: String?
    let endSnapshotId: String?
    let createdAt: Date
}

// MARK: - Encoder / Decoder

enum BackupCodable {
    static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
