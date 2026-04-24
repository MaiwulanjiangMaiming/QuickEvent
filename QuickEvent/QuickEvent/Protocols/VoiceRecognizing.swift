import Foundation
import Speech

@MainActor
protocol VoiceRecognizing: AnyObject {
    var transcript: String { get }
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus { get }
    var isRecording: Bool { get }

    func startRecording()
    func stopRecording()
    func requestAuthorization()
}
