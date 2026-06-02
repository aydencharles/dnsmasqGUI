import SwiftUI
import ServiceManagement

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

struct SettingsView: View {
    @AppStorage("menuBarOnlyMode") private var menuBarOnly = false
    @AppStorage("launchAtStartup") private var launchAtStartup = false
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @State private var showingRestartAlert = false
    
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Configure Handed preferences".localized)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)

                // Startup Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle(isOn: $launchAtStartup) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Launch at Startup".localized)
                                    .fontWeight(.medium)
                                Text("Automatically start Handed when you log in".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: launchAtStartup) { newValue in
                            updateLaunchAtStartup(enabled: newValue)
                        }

                        Divider()

                        Toggle(isOn: $menuBarOnly) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Menu Bar Only".localized)
                                    .fontWeight(.medium)
                                Text("Hide the Dock icon and run only in the menu bar".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: menuBarOnly) { newValue in
                            updateActivationPolicy(menuBarOnly: newValue)
                            showingRestartAlert = true
                        }
                    }
                    .padding(4)
                } label: {
                    Label("Startup".localized, systemImage: "power")
                }

                // Appearance Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theme".localized)
                            .fontWeight(.medium)

                        Picker("Appearance".localized, selection: $appearanceMode) {
                            ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                                Label(mode.rawValue.localized, systemImage: mode.icon)
                                    .tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: appearanceMode) { newValue in
                            updateAppearance(mode: AppearanceMode(rawValue: newValue) ?? .system)
                        }

                        Text("Choose how Handed appears. Select System to automatically match your Mac's appearance.".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(4)
                } label: {
                    Label("Appearance".localized, systemImage: "paintbrush.fill")
                }

                // Language Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Language".localized)
                            .fontWeight(.medium)

                        Picker("Language".localized, selection: $languageManager.selectedLanguage) {
                            ForEach(LanguageManager.Language.allCases) { lang in
                                Text(lang.nativeName)
                                    .tag(lang.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text("Choose the application language.".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(4)
                } label: {
                    Label("Language".localized, systemImage: "globe")
                }

                // Menu Bar Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "menubar.rectangle")
                                .font(.title2)
                                .foregroundColor(.accentColor)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Menu Bar Access".localized)
                                    .fontWeight(.medium)
                                Text("Handed always shows in the menu bar for quick access to start/stop dnsmasq, flush DNS cache, and check status.".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack(spacing: 16) {
                            StatusIndicator(color: .green, label: "Running".localized)
                            StatusIndicator(color: .gray, label: "Stopped".localized)
                            StatusIndicator(color: .red, label: "Error".localized)
                            StatusIndicator(color: .orange, label: "Unknown".localized)
                        }
                        .padding(.top, 4)
                    }
                    .padding(4)
                } label: {
                    Label("Menu Bar".localized, systemImage: "hand.raised.fill")
                }

                // About Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)

                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Handed")
                                    .font(.headline)
                                Text(String(format: "Version %@".localized, AppInfo.version))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("A native macOS GUI for dnsmasq".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }

                        Divider()

                        HStack(spacing: 16) {
                            Link(destination: URL(string: "https://github.com/thejustinjames/handed")!) {
                                Label("GitHub".localized, systemImage: "link")
                            }

                            Link(destination: URL(string: "https://github.com/thejustinjames/handed/issues")!) {
                                Label("Report Issue".localized, systemImage: "exclamationmark.bubble")
                            }
                        }
                        .font(.caption)
                    }
                    .padding(4)
                } label: {
                    Label("About".localized, systemImage: "info.circle")
                }

                Spacer()
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .alert("Restart Required".localized, isPresented: $showingRestartAlert) {
            Button("OK".localized) { }
        } message: {
            Text("The Dock icon change will take full effect after restarting Handed.".localized)
        }
    }

    private func updateLaunchAtStartup(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at startup: \(error)")
        }
    }

    private func updateActivationPolicy(menuBarOnly: Bool) {
        if menuBarOnly {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }
    }

    private func updateAppearance(mode: AppearanceMode) {
        switch mode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

struct StatusIndicator: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(LanguageManager.shared)
}

