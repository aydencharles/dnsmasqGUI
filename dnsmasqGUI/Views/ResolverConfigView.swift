import SwiftUI

struct ResolverConfigView: View {
    @StateObject private var resolverManager = ResolverManager()
    @State private var selectedFile: ResolverFile?
    @State private var isAddingFile = false
    @State private var isEditingFile = false
    @State private var fileToEdit: ResolverFile?
    @State private var fileToDelete: ResolverFile?
    @State private var showDeleteConfirmation = false
    @State private var showCreateDirectoryAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Resolver Files".localized)
                    .font(.headline)

                Text("/etc/resolver/")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)

                Spacer()

                Button(action: { isAddingFile = true }) {
                    Label("Add Resolver".localized, systemImage: "plus")
                }

                Button(action: {
                    if let file = selectedFile {
                        fileToEdit = file
                        isEditingFile = true
                    }
                }) {
                    Label("Edit".localized, systemImage: "pencil")
                }
                .disabled(selectedFile == nil)

                Button(action: {
                    if let file = selectedFile {
                        fileToDelete = file
                        showDeleteConfirmation = true
                    }
                }) {
                    Label("Delete".localized, systemImage: "trash")
                }
                .disabled(selectedFile == nil)

                Divider()
                    .frame(height: 20)

                Button(action: {
                    Task {
                        await resolverManager.loadResolverFiles()
                    }
                }) {
                    Label("Reload".localized, systemImage: "arrow.clockwise")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Content
            if resolverManager.isLoading {
                Spacer()
                ProgressView("Loading resolver files...".localized)
                Spacer()
            } else if let error = resolverManager.error {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry".localized) {
                        Task {
                            await resolverManager.loadResolverFiles()
                        }
                    }
                }
                .padding()
                Spacer()
            } else if resolverManager.resolverFiles.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Resolver Files Found".localized)
                        .font(.headline)

                    Text("Resolver files in /etc/resolver/ route DNS queries for specific domains to custom DNS servers.".localized)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Common use cases:".localized)
                            .font(.caption)
                            .fontWeight(.medium)

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("Route .local domains to your local dnsmasq".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("Route .test or .dev domains to localhost".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("Route corporate domains to internal DNS".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )

                    Button("Create Your First Resolver".localized) {
                        isAddingFile = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                Spacer()
            } else {
                List(selection: $selectedFile) {
                    ForEach(resolverManager.resolverFiles) { file in
                        ResolverFileRow(file: file, onEdit: {
                            fileToEdit = file
                            isEditingFile = true
                        })
                        .tag(file)
                        .contextMenu {
                            Button("Edit".localized) {
                                fileToEdit = file
                                isEditingFile = true
                            }
                            Button("View File Content".localized) {
                                // Could show a preview
                            }
                            Divider()
                            Button("Delete".localized, role: .destructive) {
                                fileToDelete = file
                                showDeleteConfirmation = true
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }

            // Info bar
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("Resolver files route DNS queries for specific TLDs to custom nameservers".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .task {
            await resolverManager.loadResolverFiles()
        }
        .sheet(isPresented: $isAddingFile) {
            ResolverFileEditor(mode: .add) { file in
                Task {
                    await resolverManager.saveResolverFile(file)
                }
            }
        }
        .sheet(isPresented: $isEditingFile) {
            if let file = fileToEdit {
                ResolverFileEditor(mode: .edit(file)) { updatedFile in
                    Task {
                        await resolverManager.saveResolverFile(updatedFile)
                    }
                }
            }
        }
        .alert("Delete Resolver File".localized, isPresented: $showDeleteConfirmation, presenting: fileToDelete) { file in
            Button("Cancel".localized, role: .cancel) { }
            Button("Delete".localized, role: .destructive) {
                Task {
                    _ = await resolverManager.deleteResolverFile(file)
                    selectedFile = nil
                }
            }
        } message: { file in
            Text(String(format: "Are you sure you want to delete the resolver file for '%@'?\n\nThis will remove /etc/resolver/%@".localized, file.domain, file.domain))
        }
    }
}

struct ResolverFileRow: View {
    let file: ResolverFile
    let onEdit: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(".\(file.domain)")
                        .font(.body)
                        .fontWeight(.medium)

                    Text(file.filePath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(4)
                }

                HStack {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    ForEach(file.nameservers, id: \.self) { ns in
                        Text(ns)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(3)
                    }
                }

                if let comment = file.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil.circle")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("Edit resolver file".localized)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onEdit()
        }
    }
}

struct ResolverFileEditor: View {
    enum Mode {
        case add
        case edit(ResolverFile)
    }

    let mode: Mode
    let onSave: (ResolverFile) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var domain: String = ""
    @State private var nameserversText: String = "127.0.0.1"
    @State private var comment: String = ""

    init(mode: Mode, onSave: @escaping (ResolverFile) -> Void) {
        self.mode = mode
        self.onSave = onSave

        if case .edit(let file) = mode {
            _domain = State(initialValue: file.domain)
            _nameserversText = State(initialValue: file.nameservers.joined(separator: "\n"))
            _comment = State(initialValue: file.comment ?? "")
        }
    }

    private var isValid: Bool {
        !domain.isEmpty && !nameserversText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var nameservers: [String] {
        nameserversText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(mode.isEditing ? "Edit Resolver File".localized : "Add Resolver File".localized)
                    .font(.headline)
                Spacer()
                Button("Cancel".localized) {
                    dismiss()
                }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Domain field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Domain / TLD".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack {
                            Text("/etc/resolver/")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)

                            TextField("local", text: $domain)
                                .textFieldStyle(.roundedBorder)
                                .disabled(mode.isEditing)
                        }

                        Text("The filename determines which domains are routed (e.g., 'local' routes all *.local queries)".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Nameservers field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nameservers".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextEditor(text: $nameserversText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 80)
                            .border(Color(NSColor.separatorColor), width: 1)

                        Text(String(format: "One IP address per line. These DNS servers will handle queries for *.%@".localized, domain.isEmpty ? "domain" : domain))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Comment field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Comment (optional)".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Description or notes".localized, text: $comment)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    // Preview
                    VStack(alignment: .leading, spacing: 4) {
                        Text("File Preview".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(previewContent)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.textBackgroundColor))
                            )
                    }

                    // Usage example
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How it works".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top) {
                                Text("1.")
                                    .foregroundColor(.secondary)
                                Text("macOS checks /etc/resolver/ when resolving domains".localized)
                                    .font(.caption)
                            }
                            HStack(alignment: .top) {
                                Text("2.")
                                    .foregroundColor(.secondary)
                                Text("If a file matches the TLD, those nameservers are used".localized)
                                    .font(.caption)
                            }
                            HStack(alignment: .top) {
                                Text("3.")
                                    .foregroundColor(.secondary)
                                Text("Example: /etc/resolver/local routes *.local to 127.0.0.1".localized)
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Spacer()

                Button("Cancel".localized) {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button(mode.isEditing ? "Save".localized : "Create".localized) {
                    let id: UUID
                    if case .edit(let file) = mode {
                        id = file.id
                    } else {
                        id = UUID()
                    }

                    let file = ResolverFile(
                        id: id,
                        domain: domain,
                        nameservers: nameservers,
                        comment: comment.isEmpty ? nil : comment
                    )
                    onSave(file)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }

    private var previewContent: String {
        if domain.isEmpty {
            return "# Enter a domain to see preview".localized
        }

        var lines: [String] = []

        if !comment.isEmpty {
            lines.append("# \(comment)")
        }

        for ns in nameservers {
            lines.append("nameserver \(ns)")
        }

        if lines.isEmpty {
            lines.append("nameserver 127.0.0.1")
        }

        return lines.joined(separator: "\n")
    }
}

extension ResolverFileEditor.Mode {
    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }
}

#Preview {
    ResolverConfigView()
}
