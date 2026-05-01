import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// Presents UIDocumentPickerViewController directly via UIKit to avoid SwiftUI sheet conflicts.
struct DocumentPickerLauncher: UIViewRepresentable {
    @Binding var isPresented: Bool
    let onPick: (Data, String) -> Void

    func makeUIView(context: Context) -> UIView { UIView() }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard isPresented, !context.coordinator.isPresenting else { return }
        context.coordinator.isPresenting = true
        DispatchQueue.main.async {
            let types: [UTType] = [.pdf, .spreadsheet, .presentation, .text, .image, .data, .content]
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
            picker.delegate = context.coordinator
            picker.allowsMultipleSelection = false
            if let vc = uiView.parentViewController {
                vc.present(picker, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(isPresented: $isPresented, onPick: onPick) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        @Binding var isPresented: Bool
        let onPick: (Data, String) -> Void
        var isPresenting = false

        init(isPresented: Binding<Bool>, onPick: @escaping (Data, String) -> Void) {
            _isPresented = isPresented
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            defer { done() }
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else { return }
            onPick(data, url.lastPathComponent)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { done() }

        private func done() {
            isPresenting = false
            isPresented = false
        }
    }
}

private extension UIView {
    var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
    }
}
