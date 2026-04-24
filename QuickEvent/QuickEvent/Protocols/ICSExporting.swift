import Foundation

protocol ICSExporting {
    func generateICS(for event: ParsedEvent) throws -> String
    func exportEvent(_ event: ParsedEvent) throws -> URL
    func saveICS(_ content: String, to url: URL) throws
}
