import SwiftUI

struct EmptyStateView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let actionLabel: LocalizedStringKey
    var systemImage: String = "fuelpump"
    let action: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            Button(action: action) {
                Text(actionLabel)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
