//
//  ContentViewModel.swift
//  Haptiq
//
//  Created by Henry on 19/07/2025.
//

import Foundation
import CoreHaptics
import UniformTypeIdentifiers
import SwiftUI

class ContentViewModel: ObservableObject {
    // Parameters
    @Published var intensity: Float = 0.5
    @Published var sharpness: Float = 0.5
    @Published var duration = 0.0

    // Recording state
    @Published var recordingStartTime: Date?
    @Published var continouslyPlayingStartTime: Date?
    @Published var recordings: [HapticsEvent] = []

    @Published var exportURL: URL?
    @Published var isImporting = false
    @Published var importError: Error?

    // MARK: - Recording Controls
    func handleRecordButton() {
        if recordingStartTime == nil {
            recordings.removeAll()
            recordingStartTime = .now
        } else {
            recordingStartTime = nil
        }
    }

    func addTapEvent() {
        if let recordingStartTime {
            recordings.append(.init(startTime: Date.now.timeIntervalSince(recordingStartTime),
                                    duration: nil,
                                    intensity: intensity,
                                    sharpness: sharpness))
        }
    }

    func startContinuousIfRecording() {
        if recordingStartTime != nil {
            continouslyPlayingStartTime = .now
        }
    }

    func stopContinuousIfRecording() {
        if let recordingStartTime, let continouslyPlayingStartTime {
            self.continouslyPlayingStartTime = nil
            recordings.append(.init(startTime: continouslyPlayingStartTime.timeIntervalSince(recordingStartTime),
                                    duration: Date.now.timeIntervalSince(continouslyPlayingStartTime),
                                    intensity: intensity,
                                    sharpness: sharpness))
        }
    }

    // MARK: - Play & Export
    func playPattern(_ manager: FeedbackManager) {
        do {
            let pattern = try CHHapticPattern(events: recordings.map { $0.toCHHapticEvent() }, parameters: [])
            manager.playPattern(pattern)
        } catch {
            print(error)
        }
    }

    func exportPattern() {
        do {
            let pattern = try CHHapticPattern(events: recordings.map { $0.toCHHapticEvent() }, parameters: [])
            let exportData = try JSONSerialization.data(withJSONObject: pattern.exportDictionary())
            let exportUrl = FileManager.default
                .temporaryDirectory
                .appendingPathComponent("pattern.ahap")
            if FileManager.default.fileExists(atPath: exportUrl.path) {
                try FileManager.default.removeItem(at: exportUrl)
            }
            try exportData.write(to: exportUrl)
#if os(macOS)
            guard let url = showSavePanel() else { return }
            try FileManager.default.moveItem(at: exportUrl, to: url)
#else
            self.exportURL = exportUrl
#endif
        } catch {
            print(error)
        }
    }

    #if os(macOS)
    func showSavePanel() -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.ahap]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save your haptic file"
        savePanel.message = "Choose a folder and a name"
        savePanel.nameFieldLabel = "AHAP file name:"
        
        let response = savePanel.runModal()
        return response == .OK ? savePanel.url : nil
    }
    #endif
    
    // MARK: - Import
    func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                do {
                    guard url.startAccessingSecurityScopedResource() else { return }
                    let data = try Data(contentsOf: url)
                    url.stopAccessingSecurityScopedResource()
                    let ahapDTO = try JSONDecoder().decode(AHAPPatternDTO.self, from: data)
                    recordings = ahapDTO.pattern.map { HapticsEvent.fromDTO($0.event) }
                } catch {
                    importError = error
                }
            }
        case .failure(let error):
            importError = error
        }
    }

    func dismissImportError() {
        importError = nil
    }
}
