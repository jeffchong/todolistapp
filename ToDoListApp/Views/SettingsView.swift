import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: TaskStore

    @AppStorage("collapsedMenuBarGroupIDs") private var collapsedMenuBarGroupIDs = ""

    @State private var showingBackgroundImporter = false
    @State private var backgroundError: String?
    @State private var launchAtLoginEnabled = false
    @State private var launchAtLoginError: String?
    @State private var showingResetFirstPrompt = false
    @State private var showingResetFinalPrompt = false

    var body: some View {
        Form {
            Section("General") {
                Toggle(
                    "Start To-Do List on login",
                    isOn: Binding(
                        get: { launchAtLoginEnabled },
                        set: { setLaunchAtLogin($0) }
                    )
                )

                if launchAtLoginStatusText != nil || launchAtLoginError != nil {
                    LabeledContent("Login item") {
                        Text(launchAtLoginError ?? launchAtLoginStatusText ?? "")
                            .foregroundStyle(launchAtLoginError == nil ? Color.secondary : Color.red)
                    }
                }
            }

            Section("Appearance") {
                Picker("Font", selection: $settings.selectedFontFamily) {
                    ForEach(settings.fontFamilies, id: \.self) { family in
                        Text(family).tag(family)
                    }
                }
                Text("Default: SF Mono")
                    .foregroundStyle(.secondary)
            }

            Section("Background") {
                HStack {
                    Label(backgroundLabel, systemImage: settings.hasBackgroundImage ? "photo" : "photo.badge.plus")
                    Spacer()
                    Button("Choose") {
                        showingBackgroundImporter = true
                    }
                    if settings.hasBackgroundImage {
                        Button("Clear", role: .destructive) {
                            settings.clearBackgroundImage()
                        }
                    }
                }

                Toggle("Main window", isOn: $settings.showMainWindowBackground)
                    .disabled(!settings.hasBackgroundImage)

                Toggle("Menu bar", isOn: $settings.showMenuBarBackground)
                    .disabled(!settings.hasBackgroundImage)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Fade")
                        Spacer()
                        Text("\(Int(settings.backgroundImageOpacity * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $settings.backgroundImageOpacity, in: 0.12...0.48)
                        .disabled(!settings.hasBackgroundImage)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Blur")
                        Spacer()
                        Text("\(settings.backgroundImageBlur, specifier: "%.1f")")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $settings.backgroundImageBlur, in: 0...8)
                        .disabled(!settings.hasBackgroundImage)
                }

                if let backgroundError {
                    Label(backgroundError, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            Section("Data") {
                LabeledContent("Groups", value: "\(store.groups.count)")
                LabeledContent("Tasks", value: "\(store.tasks.count)")
                LabeledContent("Open", value: "\(store.openTasks.count)")

                Button("Reset Task Data...", role: .destructive) {
                    showingResetFirstPrompt = true
                }
            }

            Section("Sync") {
                HStack {
                    Label("iCloud", systemImage: "icloud")
                    Spacer()
                    Text("Ready for CloudKit setup")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("OneDrive", systemImage: "cloud")
                    Spacer()
                    Text("Needs Microsoft sign-in")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding(.vertical)
        .font(settings.appFont(size: 13))
        .onAppear {
            refreshLaunchAtLoginStatus()
        }
        .alert("Reset all task data?", isPresented: $showingResetFirstPrompt) {
            Button("Cancel", role: .cancel) {}
            Button("Continue", role: .destructive) {
                showingResetFinalPrompt = true
            }
        } message: {
            Text("This will remove every task and custom group. Your app settings will stay the same.")
        }
        .alert("Are you absolutely sure?", isPresented: $showingResetFinalPrompt) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Data", role: .destructive) {
                resetTaskData()
            }
        } message: {
            Text("This cannot be undone. The app will return to an empty General group.")
        }
        .fileImporter(
            isPresented: $showingBackgroundImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                guard let url = urls.first else { return }
                do {
                    try settings.copyBackgroundImage(from: url)
                    backgroundError = nil
                } catch {
                    backgroundError = error.localizedDescription
                }
            case let .failure(error):
                backgroundError = error.localizedDescription
            }
        }
    }

    private var backgroundLabel: String {
        settings.hasBackgroundImage ? "Background image selected" : "No background image"
    }

    private var launchAtLoginStatusText: String? {
        switch SMAppService.mainApp.status {
        case .requiresApproval:
            "Needs approval in macOS Login Items"
        case .notFound:
            "Login item unavailable for this build"
        default:
            nil
        }
    }

    private func refreshLaunchAtLoginStatus() {
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
        }
        refreshLaunchAtLoginStatus()
    }

    private func resetTaskData() {
        store.resetData()
        collapsedMenuBarGroupIDs = ""
    }
}
