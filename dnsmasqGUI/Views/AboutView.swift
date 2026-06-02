import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Logo
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)

            // App Name & Version
            VStack(spacing: 4) {
                Text("Handed")
                    .font(.title)
                    .fontWeight(.bold)

                Text(String(format: "Version %@ (%@)".localized, AppInfo.version, AppInfo.build))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Description
            Text("A native macOS GUI for managing dnsmasq and DNS resolvers".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .padding(.horizontal, 40)

            // Credits
            VStack(spacing: 8) {
                Text("Created by Justin James".localized)
                    .font(.callout)

                Link("GitHub Repository".localized, destination: URL(string: "https://github.com/thejustinjames/handed")!)
                    .font(.callout)
            }

            Spacer()

            // Copyright
            Text("© 2026 Justin James. MIT License.".localized)
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Close".localized) {
                dismiss()
            }
            .keyboardShortcut(.escape)
            .padding(.bottom)
        }
        .padding()
        .frame(width: 350, height: 400)
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Handed Help".localized)
                    .font(.headline)
                Spacer()
                Button("Close".localized) { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HelpSection(
                        title: "Getting Started".localized,
                        icon: "play.circle",
                        content: "Help_GettingStarted_Content".localized
                    )

                    HelpSection(
                        title: "DNS Configuration".localized,
                        icon: "network",
                        content: "Help_DNSConfig_Content".localized
                    )

                    HelpSection(
                        title: "DHCP Configuration".localized,
                        icon: "server.rack",
                        content: "Help_DHCPConfig_Content".localized
                    )

                    HelpSection(
                        title: "Resolver Files".localized,
                        icon: "folder.badge.gearshape",
                        content: "Help_ResolverFiles_Content".localized
                    )

                    HelpSection(
                        title: "Quick Setup Guide".localized,
                        icon: "list.number",
                        content: "Help_QuickSetup_Content".localized
                    )

                    HelpSection(
                        title: "Service Control".localized,
                        icon: "gearshape.2",
                        content: "Help_ServiceControl_Content".localized
                    )

                    HelpSection(
                        title: "Log Viewer".localized,
                        icon: "doc.text.magnifyingglass",
                        content: "Help_LogViewer_Content".localized
                    )

                    HelpSection(
                        title: "Keyboard Shortcuts".localized,
                        icon: "keyboard",
                        content: "Help_KeyboardShortcuts_Content".localized
                    )

                    HelpSection(
                        title: "Troubleshooting".localized,
                        icon: "wrench.and.screwdriver",
                        content: "Help_Troubleshooting_Content".localized
                    )
                }
                .padding()
            }
        }
        .frame(width: 500, height: 600)
    }
}

struct HelpSection: View {
    let title: String
    let icon: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
            }

            Text(content)
                .font(.callout)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// App version info
struct AppInfo {
    static let version = "2.1.0"
    static let build = "1"
    static let name = "Handed"
    static let author = "Justin James"
}


#Preview {
    AboutView()
}

#Preview("Help") {
    HelpView()
}
