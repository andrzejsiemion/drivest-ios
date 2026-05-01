import Foundation

struct VehicleExporter {

    // MARK: - Export

    static func export(vehicle: Vehicle) throws -> Data {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        let vehicleBackup = VehicleBackup(
            id: vehicle.id.uuidString,
            name: vehicle.name,
            make: vehicle.make,
            model: vehicle.model,
            descriptionText: vehicle.descriptionText,
            initialOdometer: vehicle.initialOdometer,
            distanceUnit: vehicle.distanceUnit?.rawValue,
            fuelType: vehicle.fuelType?.rawValue,
            fuelUnit: vehicle.fuelUnit?.rawValue,
            efficiencyDisplayFormat: vehicle.efficiencyDisplayFormat?.rawValue,
            secondTankFuelType: vehicle.secondTankFuelType?.rawValue,
            secondTankFuelUnit: vehicle.secondTankFuelUnit?.rawValue,
            vin: vehicle.vin,
            photoData: vehicle.photoData.map { $0.base64EncodedString() },
            lastUsedAt: vehicle.lastUsedAt,
            createdAt: vehicle.createdAt
        )

        let fillUpBackups = vehicle.fillUps.map { fillUp -> FillUpBackup in
            let photoStrings = fillUp.allPhotos.map { $0.base64EncodedString() }
            return FillUpBackup(
                id: fillUp.id.uuidString,
                date: fillUp.date,
                pricePerLiter: fillUp.pricePerLiter,
                volume: fillUp.volume,
                totalCost: fillUp.totalCost,
                odometerReading: fillUp.odometerReading,
                isFullTank: fillUp.isFullTank,
                efficiency: fillUp.efficiency,
                fuelType: fillUp.fuelType?.rawValue,
                currencyCode: fillUp.currencyCode,
                exchangeRate: fillUp.exchangeRate,
                discount: fillUp.discount,
                note: fillUp.note,
                photos: photoStrings,
                createdAt: fillUp.createdAt
            )
        }

        let costEntryBackups = vehicle.costEntries.map { entry -> CostEntryBackup in
            let allAttachments = entry.allPhotos.map { $0.base64EncodedString() }
                + entry.attachmentData.map { $0.base64EncodedString() }
            return CostEntryBackup(
                id: entry.id.uuidString,
                date: entry.date,
                title: entry.categoryName,
                amount: entry.amount,
                currencyCode: entry.currencyCode,
                exchangeRate: entry.exchangeRate,
                categoryName: entry.categoryName,
                note: entry.note,
                attachments: allAttachments,
                createdAt: entry.createdAt
            )
        }

        let snapshotBackups = vehicle.energySnapshots.map { s in
            EnergySnapshotBackup(
                id: s.id.uuidString,
                fetchedAt: s.fetchedAt,
                odometerKm: s.odometerKm,
                socPercent: s.socPercent,
                source: s.source,
                createdAt: s.createdAt
            )
        }

        let billBackups = vehicle.electricityBills.map { b in
            ElectricityBillBackup(
                id: b.id.uuidString,
                startDate: b.startDate,
                endDate: b.endDate,
                totalKwh: b.totalKwh,
                totalCost: b.totalCost,
                currencyCode: b.currencyCode,
                distanceKm: b.distanceKm,
                efficiencyKwhPer100km: b.efficiencyKwhPer100km,
                costPerKm: b.costPerKm,
                hasSnapshotData: b.hasSnapshotData,
                startSnapshotId: b.startSnapshotId?.uuidString,
                endSnapshotId: b.endSnapshotId?.uuidString,
                createdAt: b.createdAt
            )
        }

        let envelope = BackupEnvelope(
            version: 1,
            exportedAt: Date(),
            appVersion: appVersion,
            vehicle: vehicleBackup,
            fillUps: fillUpBackups,
            costEntries: costEntryBackups,
            chargingSessions: [],
            energySnapshots: snapshotBackups,
            electricityBills: billBackups
        )

        return try BackupCodable.jsonEncoder.encode(envelope)
    }

    // MARK: - Filename

    static func filename(for vehicle: Vehicle) -> String {
        let safe = vehicle.name.replacingOccurrences(of: " ", with: "_")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let date = formatter.string(from: Date())
        return "\(safe)_\(date).drivestbackup"
    }
}
