import Foundation

// MARK: - Backup Envelope

struct BackupEnvelope: Codable {
    let version: Int
    let exportedAt: Date
    let appVersion: String
    let vehicle: VehicleBackup
    let fillUps: [FillUpBackup]
    let costEntries: [CostEntryBackup]
    let chargingSessions: [ChargingSessionBackup]  // always [] for now
    var energySnapshots: [EnergySnapshotBackup]
    var electricityBills: [ElectricityBillBackup]
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
