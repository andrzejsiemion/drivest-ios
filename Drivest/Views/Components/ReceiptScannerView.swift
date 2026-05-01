import SwiftUI
import PhotosUI

// MARK: - Main button

struct ReceiptScanButton: View {
    let onApply: (_ price: String?, _ volume: String?, _ total: String?, _ image: UIImage?) -> Void

    @State private var showSourcePicker = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var showResults = false
    @State private var scannedImage: UIImage?
    @State private var scannedData = ScannedReceiptData()
    @State private var resultPrice = ""
    @State private var resultVolume = ""
    @State private var resultTotal = ""

    private let service = ReceiptScannerService()
    private var cameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var body: some View {
        Button {
            showSourcePicker = true
        } label: {
            if isProcessing {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.8)
                    Text("Scanning…")
                }
            } else {
                Label("Scan Receipt", systemImage: "camera.viewfinder")
            }
        }
        .disabled(isProcessing)
        .confirmationDialog("Scan Receipt", isPresented: $showSourcePicker) {
            if cameraAvailable {
                Button("Take Photo") { showCamera = true }
            }
            Button("Choose from Library") { showPhotoPicker = true }
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView(isPresented: $showCamera) { image in
                guard let image else { return }
                processImage(image)
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    processImage(image)
                }
                selectedItem = nil
            }
        }
        .sheet(isPresented: $showResults) {
            ScanResultsSheet(
                image: scannedImage,
                data: scannedData,
                price: $resultPrice,
                volume: $resultVolume,
                total: $resultTotal,
                onApply: { p, v, t in onApply(p, v, t, scannedImage); showResults = false },
                onCancel: { showResults = false }
            )
        }
    }

    private func processImage(_ image: UIImage) {
        isProcessing = true
        scannedImage = image
        Task {
            let data = await service.scan(image: image)
            await MainActor.run {
                scannedData  = data
                resultPrice  = data.pricePerUnit.map { String(format: "%.3f", $0.value) } ?? ""
                resultVolume = data.volume.map      { String(format: "%.2f",  $0.value) } ?? ""
                resultTotal  = data.totalCost.map   { String(format: "%.2f",  $0.value) } ?? ""
                isProcessing = false
                showResults  = true
            }
        }
    }
}

// MARK: - Results sheet

private struct ScanResultsSheet: View {
    let image: UIImage?
    let data: ScannedReceiptData
    @Binding var price: String
    @Binding var volume: String
    @Binding var total: String
    let onApply: (String?, String?, String?) -> Void
    let onCancel: () -> Void

    private var hasAnyValue: Bool { !price.isEmpty || !volume.isEmpty || !total.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                if let image {
                    Section {
                        ReceiptImageOverlay(
                            image: image,
                            data: data,
                            priceText: $price,
                            volumeText: $volume,
                            totalText: $total
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section {
                    if !hasAnyValue {
                        Text("No values could be detected. Try a clearer photo of the receipt.")
                            .foregroundStyle(.secondary)
                    } else {
                        if !price.isEmpty  { valueRow(.blue,  "Price per Unit", $price) }
                        if !volume.isEmpty { valueRow(.green, "Volume",         $volume) }
                        if !total.isEmpty  { valueRow(.red,   "Total Cost",     $total) }
                    }
                } header: {
                    Text("Detected Values")
                } footer: {
                    Text("Drag a pin on the receipt image to point its tip at the correct value. Only non-empty fields will be updated.")
                }
            }
            .navigationTitle("Scan Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(
                            price.isEmpty  ? nil : price,
                            volume.isEmpty ? nil : volume,
                            total.isEmpty  ? nil : total
                        )
                    }
                    .disabled(!hasAnyValue)
                }
            }
        }
    }

    @ViewBuilder
    private func valueRow(_ color: Color, _ label: String, _ text: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).foregroundStyle(.secondary)
            Spacer()
            TextField("—", text: text)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
        }
    }
}

// MARK: - Interactive image with draggable frames

private struct ReceiptImageOverlay: View {
    let image: UIImage
    let observations: [ReceiptObservation]
    @Binding var priceText: String
    @Binding var volumeText: String
    @Binding var totalText: String

    @State private var priceCenter: CGPoint
    @State private var volumeCenter: CGPoint
    @State private var totalCenter: CGPoint

    init(image: UIImage, data: ScannedReceiptData,
         priceText: Binding<String>, volumeText: Binding<String>, totalText: Binding<String>) {
        self.image = image
        self.observations = data.allObservations
        _priceText  = priceText
        _volumeText = volumeText
        _totalText  = totalText

        let pc = data.pricePerUnit?.rect.map { CGPoint(x: $0.midX, y: $0.midY) } ?? CGPoint(x: 0.5, y: 0.35)
        var vc = data.volume?.rect.map       { CGPoint(x: $0.midX, y: $0.midY) } ?? CGPoint(x: 0.5, y: 0.45)
        var tc = data.totalCost?.rect.map    { CGPoint(x: $0.midX, y: $0.midY) } ?? CGPoint(x: 0.5, y: 0.55)

        // If frames overlap (e.g. all three from the same observation), spread them horizontally
        // so each is visible. No Y offset — receipt lines are only ~2-3% of image height apart
        // so even a small vertical shift would land on the wrong line.
        let tooClose: (CGPoint, CGPoint) -> Bool = { abs($0.x - $1.x) < 0.03 && abs($0.y - $1.y) < 0.03 }
        // Receipt line order is always: volume × price total (left → right)
        // So when all three come from the same observation, spread: volume LEFT, price CENTER, total RIGHT
        if tooClose(pc, vc) || tooClose(vc, tc) || tooClose(pc, tc) {
            vc = CGPoint(x: (vc.x - 0.14).clamped(0.08...0.92), y: vc.y)
            // pc stays at center
            tc = CGPoint(x: (tc.x + 0.14).clamped(0.08...0.92), y: tc.y)
        }

        _priceCenter  = State(initialValue: pc)
        _volumeCenter = State(initialValue: vc)
        _totalCenter  = State(initialValue: tc)
    }

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                GeometryReader { geo in
                    if !priceText.isEmpty {
                        DraggableFrame(
                            color: .blue, label: "Price/unit",
                            center: $priceCenter, containerSize: geo.size
                        ) { newCenter in
                            pick(&priceText, at: newCenter, format: "%.3f")
                        }
                    }
                    if !volumeText.isEmpty {
                        DraggableFrame(
                            color: .green, label: "Volume",
                            center: $volumeCenter, containerSize: geo.size
                        ) { newCenter in
                            pick(&volumeText, at: newCenter, format: "%.2f")
                        }
                    }
                    if !totalText.isEmpty {
                        DraggableFrame(
                            color: .red, label: "Total",
                            center: $totalCenter, containerSize: geo.size
                        ) { newCenter in
                            pick(&totalText, at: newCenter, format: "%.2f")
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
    }

    /// Finds the observation at `point`, then picks the number whose estimated x-position
    /// within the text block is closest to the drop x. This correctly distinguishes e.g.
    /// 45.56 / 5.77 / 262.88 when they all live on the same receipt line.
    private func pick(_ text: inout String, at point: CGPoint, format: String) {
        let candidates = observations.filter { !$0.numberedPositions.isEmpty }
        guard let obs = candidates.first(where: { $0.rect.contains(point) })
            ?? candidates.min(by: {
                hypot($0.rect.midX - point.x, $0.rect.midY - point.y) <
                hypot($1.rect.midX - point.x, $1.rect.midY - point.y)
            })
        else { return }

        let obsLeft  = obs.rect.minX
        let obsWidth = max(obs.rect.width, 0.01)
        guard let best = obs.numberedPositions.min(by: { a, b in
            let ax = obsLeft + a.relativeX * obsWidth
            let bx = obsLeft + b.relativeX * obsWidth
            return abs(ax - point.x) < abs(bx - point.x)
        }) else { return }

        text = String(format: format, best.value)
    }
}

// MARK: - Map-pin marker (draggable)
//
// The pin TIP points at the target value on the receipt.
// The circle head is above; the user grabs the head and drags.
// `center` stores the normalized TIP position (0-1 relative to image).

private struct DraggableFrame: View {
    let color: Color
    let label: String
    @Binding var center: CGPoint        // normalized tip position [0, 1]
    let containerSize: CGSize
    let onDropped: (CGPoint) -> Void

    @GestureState private var dragOffset: CGSize = .zero

    private let headDiameter: CGFloat = 36
    private let tailHeight: CGFloat   = 18
    private var totalHeight: CGFloat  { headDiameter + tailHeight }

    // Screen position of the TIP (what the pin points at)
    private var tipX: CGFloat { center.x * containerSize.width  + dragOffset.width  }
    private var tipY: CGFloat { center.y * containerSize.height + dragOffset.height }

    var body: some View {
        VStack(spacing: 0) {
            // Circle head
            ZStack {
                Circle().fill(color)
                Circle().fill(.white).padding(7)
            }
            .frame(width: headDiameter, height: headDiameter)

            // Pointed tail — tip is at the BOTTOM of this VStack
            PinTail()
                .fill(color)
                .frame(width: 14, height: tailHeight)
        }
        .shadow(color: color.opacity(0.55), radius: 4, y: 2)
        // Place VStack center so its bottom tip lands at (tipX, tipY)
        .position(x: tipX, y: tipY - totalHeight / 2)
        .gesture(
            DragGesture(minimumDistance: 2)
                .updating($dragOffset) { v, state, _ in state = v.translation }
                .onEnded { v in
                    let nx = (center.x + v.translation.width  / containerSize.width ).clamped(0...1)
                    let ny = (center.y + v.translation.height / containerSize.height).clamped(0...1)
                    center = CGPoint(x: nx, y: ny)
                    onDropped(center)
                }
        )
    }
}

private struct PinTail: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: rect.width, y: 0))
            p.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
            p.closeSubpath()
        }
    }
}

private extension CGFloat {
    func clamped(_ range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
