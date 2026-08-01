import SwiftUI

struct TerminologySettingsView: View {
    let store: TerminologyStore

    @State private var term = ""
    @State private var guidance = ""
    @State private var pendingDeletion: TerminologyEntry?

    var body: some View {
        Form {
            Section("Add Terminology") {
                TextField("Term", text: $term, prompt: Text("FlowKey"))
                TextField(
                    "Guidance",
                    text: $guidance,
                    prompt: Text("Keep this product name unchanged")
                )

                HStack {
                    Text("Used only by on-device rewrite actions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Add") {
                        if store.add(term: term, guidance: guidance) {
                            term = ""
                            guidance = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let errorMessage = store.lastErrorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Terms") {
                if store.entries.isEmpty {
                    ContentUnavailableView(
                        "No Terminology Yet",
                        systemImage: "text.book.closed",
                        description: Text("Add only names or phrases that regularly need special handling.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    ForEach(store.entries) { entry in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.term)
                                    .font(.body.weight(.medium))
                                if entry.guidance.isEmpty == false {
                                    Text(entry.guidance)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                pendingDeletion = entry
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                            .help(L10n.format("Delete %@", entry.term))
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .alert(
            "Delete this term?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if $0 == false { pendingDeletion = nil } }
            ),
            presenting: pendingDeletion
        ) { entry in
            Button("Delete", role: .destructive) {
                _ = store.remove(entry)
                pendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeletion = nil
            }
        } message: { entry in
            Text(
                L10n.format(
                    "“%@” will be removed from local rewrite context.",
                    entry.term
                )
            )
        }
    }
}
