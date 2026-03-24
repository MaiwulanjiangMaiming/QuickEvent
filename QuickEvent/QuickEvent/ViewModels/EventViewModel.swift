//
//  EventViewModel.swift
//  QuickEvent
//
//  Created by Maiwulanjiang Maiming
//  GitHub: https://github.com/MaiwulanjiangMaiming/Calendar_ics_generation_helper
//

import Foundation
import SwiftUI
import Combine
import EventKit

@MainActor
class EventViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var parsedEvent: ParsedEvent?
    @Published var showPreview: Bool = false
    @Published var parseError: String?
    @Published var isProcessing: Bool = false
    @Published var hasCalendarAccess: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    @Published var isVoiceRecording: Bool = false
    @Published var selectedCalendar: EKCalendar?
    
    private let parser = NaturalLanguageParser()
    private let eventKitManager = EventKitManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        hasCalendarAccess = eventKitManager.hasAccess
        selectedCalendar = eventKitManager.selectedCalendar
        setupNotifications()
        setupBindings()
    }
    
    private func setupNotifications() {
        NotificationCenter.default
            .publisher(for: .toggleVoiceInput)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.toggleVoiceInput()
            }
            .store(in: &cancellables)
    }
    
    private func setupBindings() {
        eventKitManager.$hasAccess
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasCalendarAccess)
        
        eventKitManager.$selectedCalendar
            .receive(on: DispatchQueue.main)
            .assign(to: &$selectedCalendar)
    }
    
    func toggleVoiceInput() {
        isVoiceRecording.toggle()
    }
    
    func parseInput() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            parseError = "Please enter event details"
            showPreview = true
            parsedEvent = nil
            return
        }
        
        isProcessing = true
        parseError = nil
        
        Task {
            do {
                let event = try await parser.parse(inputText)
                
                await MainActor.run {
                    parsedEvent = event
                    showPreview = true
                    parseError = nil
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    parseError = error.localizedDescription
                    showPreview = true
                    parsedEvent = nil
                    isProcessing = false
                }
            }
        }
    }
    
    func exportICS() {
        guard let event = parsedEvent else { return }
        
        do {
            let url = try ICSGenerator.shared.exportEvent(event)
            
            let panel = NSSavePanel()
            panel.title = "Save ICS File"
            panel.nameFieldStringValue = url.lastPathComponent
            panel.allowedContentTypes = [.init(filenameExtension: "ics")!]
            panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            
            if panel.runModal() == .OK, let destination = panel.url {
                try FileManager.default.copyItem(at: url, to: destination)
                showSuccess("ICS file saved to \(destination.path)")
            }
        } catch {
            parseError = "Failed to export: \(error.localizedDescription)"
        }
    }
    
    func addToCalendar() {
        guard let event = parsedEvent else { return }
        
        Task {
            do {
                try eventKitManager.addEvent(event, to: selectedCalendar)
                showSuccess("Event added to calendar")
                eventKitManager.openCalendarApp()
            } catch {
                parseError = error.localizedDescription
            }
        }
    }
    
    func clearAll() {
        inputText = ""
        parsedEvent = nil
        showPreview = false
        parseError = nil
    }
    
    private func showSuccess(_ message: String) {
        successMessage = message
        showSuccessMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showSuccessMessage = false
        }
    }
}
