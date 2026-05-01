import Foundation
import SwiftData

struct VehicleImporter {

    // MARK: - Types

    enum ConflictStrategy { case replace, merge, createNew }

    enum ImportError: LocalizedError {
        case unsupportedVersion(Int)
        case invalidData(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedVersion(let v):
                return "This backup was created with a newer version of the app (version \(v))."
            case .invalidData(let msg):
                return "File is not a valid Fuel backup. \(msg)"
            }
        }
    }

    struct ImportPreview {
        let vehicleName: String
        let fillUpCount: Int
        let costEntryCount: Int
        let exportedAt: Date
        let conflictingVehicle: Vehicle?
    }

    // MARK: - Preview

    static func preview(from data: Data, existingVehicles: [Vehicle]) throws -> ImportPreview {
        let envelope: BackupEnvelope
        do {
            envelope = try BackupCodable.jsonDecoder.decode(BackupEnvelope.self, from: data)
        } catch {
            throw ImportError.invalidData(error.localizedDescription)
        }
        guard envelope.version == 1 else {
            throw ImportError.unsupportedVersion(envelope.version)
        }
        let conflict = existingVehicles.first { $0.name == envelope.vehicle.name }
        return ImportPreview(
            vehicleName: envelope.vehicle.name,
            fillUpCount: envelope.fillUps.count,
            costEntryCount: envelope.costEntries.count,
            exportedAt: envelope.exportedAt,
            conflictingVehicle: conflict
        )
    }

    // MARK: - Import

    static func `import`(
        from data: Data,
        into modelContext: ModelContext,
        existingVehicles: [Vehicle],
        strategy: ConflictStrategy
    ) throws -> Vehicle {
        let envelope: BackupEnvelope
        do {
            envelope = try BackupCodable.jsonDecoder.decode(BackupEnvelope.self, from: data)
        } catch {
            throw ImportError.invalidData(error.localizedDescription)
        }
        guard envelope.version == 1 else {
            throw ImportError.unsupportedVersion(envelope.version)
        }

        // Replace strategy: delete existing records and reuse vehicle
        if strategy == .replace,
           let existing = existingVehicles.first(where: { $0.name == envelope.vehicle.name }) {
            for f in existing.fillUps { modelContext.delete(f) }
            for c in existing.costEntries { modelContext.delete(c) }
            for s in existing.energySnapshots { modelContext.delete(s) }
            for b in existing.electricityBills { modelContext.delete(b) }
            applyVehicleBackup(envelope.vehicle, to: existing)
            insertRecords(envelope, into: modelContext, vehicle: existing, strategy: strategy)
            Persistence.save(modelContext)
            return existing
        }

        // Merge strategy: find existing vehicle and add only new records
        if strategy == .merge,
           let existing = existingVehicles.first(where: { $0.name == envelope.vehicle.name }) {
            insertRecords(envelope, into: modelContext, vehicle: existing, strategy: strategy)
            Persistence.save(modelContext)
            return existing
        }

        // createNew (or merge/replace when no existing match): create fresh vehicle
        let vehicleName: String
        if strategy == .createNew,
           existingVehicles.contains(where: { $0.name == envelope.vehicle.name }) {
            vehicleName = envelope.vehicle.name + " (imported)"
        } else {
            vehicleName = envelope.vehicle.name
        }

        let vehicle = Vehicle(name: vehicleName, initialOdometer: envelope.vehicle.initialOdometer)
        applyVehicleBackup(envelope.vehicle, to: vehicle)
        vehicle.name = vehicleName  // re-apply in case applyVehicleBackup overwrote it
        modelContext.insert(vehicle)
        insertRecords(envelope, into: modelContext, vehicle: vehicle, strategy: strategy)
        Persistence.save(modelContext)
        return vehicle
    }

    // MARK: - Private helpers

    private static func applyVehicleBackup(_ backup: VehicleBackup, to vehicle: Vehicle) {
        vehicle.make = backup.make
        vehicle.model = backup.model
        vehicle.descriptionText = backup.descriptionText
        vehicle.initialOdometer = backup.initialOdometer
        vehicle.distanceUnit = backup.distanceUnit.flatMap { DistanceUnit(rawValue: $0) }
        vehicle.fuelType = backup.fuelType.flatMap { FuelType(rawValue: $0) }
        vehicle.fuelUnit = backup.fuelUnit.flatMap { FuelUnit(rawValue: $0) }
        vehicle.efficiencyDisplayFormat = backup.efficiencyDisplayFormat.flatMap { EfficiencyDisplayFormat(rawValue: $0) }
        vehicle.secondTankFuelType = backup.secondTankFuelType.flatMap { FuelType(rawValue: $0) }
        vehicle.secondTankFuelUnit = backup.secondTankFuelUnit.flatMap { FuelUnit(rawValue: $0) }
        vehicle.vin = backup.vin
        vehicle.photoData = backup.photoData.flatMap { Data(base64Encoded: $0) }
        vehicle.lastUsedAt = backup.lastUsedAt
        vehicle.createdAt = backup.createdAt
    }

    private static func insertRecords(
        _ envelope: BackupEnvelope,
        into modelContext: ModelContext,
        vehicle: Vehicle,
        strategy: ConflictStrategy
    ) {
        for sb in envelope.energySnapshots {
            if strategy == .merge {
                let exists = vehicle.energySnapshots.contains {
                    abs($0.fetchedAt.timeIntervalSince(sb.fetchedAt)) < 60
                }
                if exists { continue }
            }
            let snapshot = EnergySnapshot(
                fetchedAt: sb.fetchedAt,
                odometerKm: sb.odometerKm,
                socPercent: sb.socPercent,
                source: sb.source,
                vehicle: vehicle
            )
            modelContext.insert(snapshot)
        }

        for bb in envelope.electricityBills {
            if strategy == .merge {
                let exists = vehicle.electricityBills.contains {
                    abs($0.endDate.timeIntervalSince(bb.endDate)) < 60
                }
                if exists { continue }
            }
            let bill = ElectricityBill(
                startDate: bb.startDate,
                endDate: bb.endDate,
                totalKwh: bb.totalKwh,
                totalCost: bb.totalCost,
                currencyCode: bb.currencyCode,
                vehicle: vehicle
            )
            bill.distanceKm              = bb.distanceKm
            bill.efficiencyKwhPer100km   = bb.efficiencyKwhPer100km
            bill.costPerKm               = bb.costPerKm
            bill.hasSnapshotData         = bb.hasSnapshotData
            bill.startSnapshotId         = bb.startSnapshotId.flatMap { UUID(uuidString: $0) }
            bill.endSnapshotId           = bb.endSnapshotId.flatMap { UUID(uuidString: $0) }
            modelContext.insert(bill)
        }

        for fb in envelope.fillUps {
            if strategy == .merge {
                let exists = vehicle.fillUps.contains {
                    abs($0.odometerReading - fb.odometerReading) < 0.1
                    && abs($0.date.timeIntervalSince1970 - fb.date.timeIntervalSince1970) < 60
                }
                if exists { continue }
            }

            let f = FillUp(
                date: fb.date,
                pricePerLiter: fb.pricePerLiter,
                volume: fb.volume,
                totalCost: fb.totalCost,
                odometerReading: fb.odometerReading,
                isFullTank: fb.isFullTank,
                vehicle: vehicle,
                note: fb.note,
                fuelType: fb.fuelType.flatMap { FuelType(rawValue: $0) }
            )
            f.efficiency = fb.efficiency
            f.currencyCode = fb.currencyCode
            f.exchangeRate = fb.exchangeRate
            f.discount = fb.discount
            f.photos = fb.photos.compactMap { Data(base64Encoded: $0) }
            modelContext.insert(f)
        }

        for cb in envelope.costEntries {
            if strategy == .merge {
                let exists = vehicle.costEntries.contains {
                    abs($0.amount - cb.amount) < 0.01
                    && abs($0.date.timeIntervalSince1970 - cb.date.timeIntervalSince1970) < 60
                }
                if exists { continue }
            }

            let categoryName = cb.categoryName ?? cb.title
            // Look up existing category icon, fall back to generic tag
            let categoryIcon = lookupCategoryIcon(name: categoryName, in: modelContext)

            let entry = CostEntry(
                date: cb.date,
                categoryName: categoryName,
                categoryIcon: categoryIcon,
                amount: cb.amount,
                note: cb.note
            )
            entry.currencyCode = cb.currencyCode
            entry.exchangeRate = cb.exchangeRate
            entry.vehicle = vehicle
            // Photos come from the attachments array
            entry.photos = cb.attachments.compactMap { Data(base64Encoded: $0) }
            modelContext.insert(entry)
        }
    }

    private static func lookupCategoryIcon(name: String, in modelContext: ModelContext) -> String {
        let descriptor = FetchDescriptor<CostCategory>(
            predicate: #Predicate { $0.name == name }
        )
        if let found = try? modelContext.fetch(descriptor), let category = found.first {
            return category.iconName
        }
        return "tag.fill"
    }
}
