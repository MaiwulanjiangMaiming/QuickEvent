import Foundation

protocol EventParsing {
    func parse(_ input: String) async throws -> ParsedEvent
}
