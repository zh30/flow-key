import SwiftUI

struct DictationControl: View {
    @Binding var text: String
    let localeIdentifier: String

    @State private var service = DictationService()
    @State private var prefix = ""

    var body: some View {
        HStack(spacing: 6) {
            if let message = service.state.message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
                    .help(message)
            }

            if case .permissionDenied(let permission) = service.state {
                Button("Open Settings") {
                    service.openPrivacySettings(for: permission)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }

            Button {
                if service.state.isRecording {
                    service.stop()
                } else {
                    prefix = text
                    Task {
                        await service.start(localeIdentifier: localeIdentifier)
                    }
                }
            } label: {
                Image(systemName: service.state.isRecording ? "stop.circle.fill" : "mic")
                    .symbolEffect(.pulse, isActive: service.state.isRecording)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(service.state.isRecording ? .red : .secondary)
            .help(
                service.state.isRecording
                    ? L10n.string("Stop dictation")
                    : L10n.string("Dictate text")
            )
            .accessibilityLabel(
                service.state.isRecording
                    ? L10n.string("Stop dictation")
                    : L10n.string("Start dictation")
            )
            .disabled(service.state == .requestingPermission)
        }
        .onChange(of: service.transcript) { _, transcript in
            text = DictationTextMerger.merge(prefix: prefix, transcript: transcript)
        }
        .onDisappear {
            service.stop()
        }
    }

    private var statusColor: Color {
        switch service.state {
        case .permissionDenied, .unavailable, .failed:
            return .orange
        case .recording:
            return .red
        case .idle, .requestingPermission:
            return .secondary
        }
    }
}
