import Foundation
import AppKit
import UniformTypeIdentifiers

class ICSExportService: ICSExporting {
    private let generator: ICSExporting

    init(generator: ICSExporting = ICSGenerator.shared) {
        self.generator = generator
    }

    func generateICS(for event: ParsedEvent) throws -> String {
        try generator.generateICS(for: event)
    }

    func exportEvent(_ event: ParsedEvent) throws -> URL {
        try generator.exportEvent(event)
    }

    func saveICS(_ content: String, to url: URL) throws {
        try generator.saveICS(content, to: url)
    }

    func exportWithSavePanel(_ event: ParsedEvent) -> String? {
        do {
            let url = try generator.exportEvent(event)

            let panel = NSSavePanel()
            panel.title = "Save ICS File"
            panel.nameFieldStringValue = url.lastPathComponent
            panel.allowedContentTypes = [UTType(filenameExtension: "ics")!]
            panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first

            if panel.runModal() == .OK, let destination = panel.url {
                try FileManager.default.copyItem(at: url, to: destination)
                return "ICS file saved to \(destination.path)"
            }
            return nil
        } catch {
            return "Failed to export: \(error.localizedDescription)"
        }
    }
}
