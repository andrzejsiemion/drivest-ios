import UniformTypeIdentifiers

extension UTType {
    /// Custom type for .drivestbackup export files.
    static let drivestBackup: UTType = {
        guard let type = UTType("app.drivest.backup") else {
            preconditionFailure("UTType app.drivest.backup not registered in Info.plist")
        }
        return type
    }()
}
