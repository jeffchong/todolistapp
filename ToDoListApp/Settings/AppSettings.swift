import AppKit
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("selectedFontFamily") var selectedFontFamily = "SF Mono" {
        willSet {
            objectWillChange.send()
        }
    }
    @AppStorage("backgroundImagePath") var backgroundImagePath = "" {
        willSet {
            objectWillChange.send()
        }
    }
    @AppStorage("showMainWindowBackground") var showMainWindowBackground = false {
        willSet {
            objectWillChange.send()
        }
    }
    @AppStorage("showMenuBarBackground") var showMenuBarBackground = false {
        willSet {
            objectWillChange.send()
        }
    }
    @AppStorage("showCompletedTasksInMainWindow") var showCompletedTasksInMainWindow = false {
        willSet {
            objectWillChange.send()
        }
    }
    @AppStorage("backgroundImageOpacity") var backgroundImageOpacity = 0.28 {
        willSet {
            objectWillChange.send()
        }
    }
    @AppStorage("backgroundImageBlur") var backgroundImageBlur = 3.0 {
        willSet {
            objectWillChange.send()
        }
    }

    var fontFamilies: [String] {
        let installedFamilies = NSFontManager.shared.availableFontFamilies
        let preferredFamilies = ["SF Mono", "System", "Helvetica Neue", "Avenir Next", "Menlo"]
        let combined = preferredFamilies + installedFamilies
        return Array(Set(combined)).sorted { lhs, rhs in
            if lhs == selectedFontFamily { return true }
            if rhs == selectedFontFamily { return false }
            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
    }

    func appFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if selectedFontFamily == "System" {
            return .system(size: size, weight: weight)
        }

        return .custom(selectedFontFamily, size: size).weight(weight)
    }

    var backgroundImageURL: URL? {
        guard !backgroundImagePath.isEmpty else { return nil }
        return URL(fileURLWithPath: backgroundImagePath)
    }

    var hasBackgroundImage: Bool {
        guard let url = backgroundImageURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    func copyBackgroundImage(from sourceURL: URL) throws {
        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let directoryURL = try supportDirectoryURL()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let fileExtension = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension
        let destinationURL = directoryURL.appendingPathComponent("background-image.\(fileExtension)")
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        backgroundImagePath = destinationURL.path
        showMainWindowBackground = true
        showMenuBarBackground = true
    }

    func clearBackgroundImage() {
        if let backgroundImageURL, FileManager.default.fileExists(atPath: backgroundImageURL.path) {
            try? FileManager.default.removeItem(at: backgroundImageURL)
        }
        backgroundImagePath = ""
        showMainWindowBackground = false
        showMenuBarBackground = false
    }

    private func supportDirectoryURL() throws -> URL {
        try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ToDoListApp", isDirectory: true)
    }
}
