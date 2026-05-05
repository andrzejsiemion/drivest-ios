import Foundation
import Observation

enum DeepLinkDestination: Equatable {
    case costDetail(costEntryId: UUID)
}

@Observable
final class DeepLinkRouter {
    var pending: DeepLinkDestination?

    func handle(userInfo: [AnyHashable: Any]) {
        if let costIdString = userInfo["costEntryId"] as? String,
           let costId = UUID(uuidString: costIdString) {
            pending = .costDetail(costEntryId: costId)
        }
    }
}
