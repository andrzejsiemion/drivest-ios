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
