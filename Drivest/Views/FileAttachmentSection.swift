import SwiftUI

private let maxFileSizeBytes = 5 * 1024 * 1024 // 5 MB

struct FileAttachmentSection: View {
    @Binding var attachmentData: [Data]
    @Binding var attachmentNames: [String]

    @State private var showPicker = false
    @State private var showSizeLimitAlert = false
    @State private var oversizedFileName = ""

    var body: some View {
        Section("Documents") {
            ForEach(attachmentNames.indices, id: \.self) { index in
                HStack {
                    Image(systemName: attachmentNames[index].attachmentIconName)
                        .foregroundStyle(.secondary)
                    Text(attachmentNames[index])
                        .lineLimit(1)
                    Spacer()
                    ShareLink(
                        item: attachmentData[index],
                        preview: SharePreview(attachmentNames[index])
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.secondary)
                    }
                    Button(role: .destructive) {
                        attachmentData.remove(at: index)
                        attachmentNames.remove(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                showPicker = true
            } label: {
                Label("Add Document", systemImage: "doc.badge.plus")
            }
            .background(
                DocumentPickerLauncher(isPresented: $showPicker) { data, name in
                    if data.count > maxFileSizeBytes {
                        oversizedFileName = name
                        showSizeLimitAlert = true
                    } else {
                        attachmentData.append(data)
                        attachmentNames.append(name)
                    }
                }
            )
        }
        .alert("File Too Large", isPresented: $showSizeLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\"\(oversizedFileName)\" exceeds the 5 MB limit. Please attach a smaller file.")
        }
    }

}
