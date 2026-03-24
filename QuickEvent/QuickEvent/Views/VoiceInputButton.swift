//
//  VoiceInputButton.swift
//  QuickEvent
//
//  Created by Maiwulanjiang Maiming
//  GitHub: https://github.com/MaiwulanjiangMaiming/Calendar_ics_generation_helper
//

import SwiftUI
import Speech
import AVFoundation

struct VoiceInputButton: View {
    @Binding var isRecording: Bool
    let onResult: (String) -> Void
    
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var showPermissionAlert = false
    
    var body: some View {
        ZStack {
            if isRecording {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 40, height: 40)
            }
            
            Button(action: toggleRecording) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title)
                    .foregroundStyle(isRecording ? .red : .blue)
                    .padding(4)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .frame(width: 42, height: 42)
        .help(isRecording ? "Stop recording (⌘⇧V)" : "Start voice input (⌘⇧V)")
        .onReceive(speechRecognizer.$transcript) { newValue in
            if !newValue.isEmpty {
                onResult(newValue)
                isRecording = false
            }
        }
        .onReceive(speechRecognizer.$authorizationStatus) { status in
            if status == .denied {
                showPermissionAlert = true
            }
        }
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please grant microphone access in System Settings to use voice input.")
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            speechRecognizer.stopRecording()
            isRecording = false
        } else {
            if speechRecognizer.authorizationStatus == .authorized {
                speechRecognizer.startRecording()
                isRecording = true
            } else {
                speechRecognizer.requestAuthorization()
            }
        }
    }
}

class SpeechRecognizer: NSObject, ObservableObject {
    @Published var transcript: String = ""
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var silenceTimer: Timer?
    private var lastTranscriptLength: Int = 0
    private var currentLocale: Locale
    private var isStopping: Bool = false
    
    override init() {
        currentLocale = Locale(identifier: "zh-CN")
        speechRecognizer = SFSpeechRecognizer(locale: currentLocale)
        super.init()
        speechRecognizer?.delegate = self
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
        
        if authorizationStatus == .notDetermined {
            requestAuthorization()
        }
    }
    
    func setLocale(_ locale: Locale) {
        guard locale != currentLocale else { return }
        stopRecording()
        currentLocale = locale
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        speechRecognizer?.delegate = self
        transcript = ""
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
            }
        }
    }
    
    func startRecording() {
        guard authorizationStatus == .authorized else {
            requestAuthorization()
            return
        }
        
        isStopping = false
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        transcript = ""
        lastTranscriptLength = 0
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true
        
        if #available(macOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self, !self.isStopping else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    let newTranscript = result.bestTranscription.formattedString
                    self.transcript = newTranscript
                    
                    if newTranscript.count > self.lastTranscriptLength {
                        self.lastTranscriptLength = newTranscript.count
                        self.resetSilenceTimer()
                    }
                    
                    if result.isFinal {
                        self.stopRecording()
                    }
                }
            }
            
            if let error = error as? NSError {
                let noSpeechErrorCode = 216
                let speechTimeoutCode = 216
                
                if error.code != noSpeechErrorCode && error.code != speechTimeoutCode {
                    print("Speech recognition error: \(error.localizedDescription) (code: \(error.code))")
                }
                
                DispatchQueue.main.async {
                    if self.transcript.isEmpty {
                        self.stopRecording()
                    }
                }
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self, !self.isStopping else { return }
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start failed: \(error)")
            cleanup()
        }
        
        startSilenceDetection()
    }
    
    func stopRecording() {
        guard !isStopping else { return }
        isStopping = true
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.silenceTimer?.invalidate()
            self.silenceTimer = nil
            self.cleanup()
        }
    }
    
    private func cleanup() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    private func startSilenceDetection() {
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isStopping else { return }
            
            if !self.transcript.isEmpty && self.transcript.count == self.lastTranscriptLength {
                self.stopRecording()
            }
        }
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        startSilenceDetection()
    }
}

extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            print("Speech recognizer unavailable")
        }
    }
}
