//
//  UIFeedbackManager.swift
//  Haptiq
//
//  Created by Henry on 19/07/2025.
//

import Foundation
import CoreHaptics

protocol FeedbackManagerProtocol: ObservableObject {
    func stop(completionHandler: ((Error?) -> Void)?)
    func start() throws
    func startPlayingContinously(intensity: Float, sharpness: Float)
    func stopPlayingContinously()
    func playInstamty(intensity: Float, sharpness: Float)
    func playPattern(_ pattern: CHHapticPattern)
}

@available(macOS, unavailable)
class UIFeedbackManager: FeedbackManagerProtocol {
    
    private let hapticEngine: CHHapticEngine?
    var needsToRestart = false
    
    var playingPlayer: CHHapticPatternPlayer?
    
    init() {
        hapticEngine = try? CHHapticEngine()
        hapticEngine?.resetHandler = resetHandler
        hapticEngine?.stoppedHandler = restartHandler
        hapticEngine?.playsHapticsOnly = true
        
        try? start()
    }
    
    public func stop(completionHandler: CHHapticEngine.CompletionHandler? = nil) {
        hapticEngine?.stop(completionHandler: completionHandler)
    }

    /// Starts the internal CHHapticEngine. Should be called when your app enters the foreground.
    public func start() throws {
        try hapticEngine?.start()
        needsToRestart = false
    }

    private func resetHandler() {
        do {
            try start()
        } catch {
            needsToRestart = true
        }
    }

    private func restartHandler(_ reasonForStopping: CHHapticEngine.StoppedReason? = nil) {
        resetHandler()
    }
    
    func startPlayingContinously(intensity: Float, sharpness: Float) {
        do {
            try playingPlayer?.cancel()
            
            let pattern = try CHHapticPattern(events: [
                .init(eventType: .hapticContinuous,
                      parameters: [.init(parameterID: .hapticSharpness, value: sharpness), .init(parameterID: .hapticIntensity, value: intensity)],
                      relativeTime: 0,
                      duration: .infinity)
            ], parameters: [])
            
            playingPlayer = try hapticEngine?.makePlayer(with: pattern)
            if needsToRestart {
                try? start()
            }
            try playingPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print(error)
        }
    }
    
    func stopPlayingContinously() {
        do {
            try playingPlayer?.cancel()
        } catch {
            print(error)
        }
    }
    
    func playInstamty(intensity: Float, sharpness: Float) {
        do {
            try playingPlayer?.cancel()
            
            let pattern = try CHHapticPattern(events: [
                .init(eventType: .hapticTransient,
                      parameters: [.init(parameterID: .hapticSharpness, value: sharpness), .init(parameterID: .hapticIntensity, value: intensity)],
                      relativeTime: 0,
                      duration: 0)
            ], parameters: [])
            
            playingPlayer = try hapticEngine?.makePlayer(with: pattern)
            if needsToRestart {
                try? start()
            }
            try playingPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print(error)
        }
    }
    
    func loadPatternFromURL(_ url: URL) throws -> CHHapticPattern {
        // Read JSON data from the URL.
        let patternJSONData = try Data(contentsOf: url, options: [])
        
        // Create a dictionary from the JSON data.
        let dict = try JSONSerialization.jsonObject(with: patternJSONData, options: [])
        
        if let patternDict = dict as? [CHHapticPattern.Key: Any] {
            // Create a pattern from the dictionary.
            return try CHHapticPattern(dictionary: patternDict)
        }
        
        throw CHHapticError(.fileNotFound, userInfo: [:])
    }
    
    func playFromURL(url: URL) {
        do {
            let pattern = try loadPatternFromURL(url)
            playPattern(pattern)
        } catch {
            print("Error starting haptic player: \(error)")
        }
    }
    
    func playPattern(_ pattern: CHHapticPattern) {
        do {
            let player = try hapticEngine?.makePlayer(with: pattern)
            if needsToRestart {
                try? start()
            }
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Error starting haptic player: \(error)")
        }
    }
}

#if os(macOS)
import Foundation
class DummyFeedbackManager: FeedbackManagerProtocol {
    func stop(completionHandler: ((Error?) -> Void)?) {}
    func start() throws {}
    func startPlayingContinously(intensity: Float, sharpness: Float) {}
    func stopPlayingContinously() {}
    func playInstamty(intensity: Float, sharpness: Float) {}
    func playPattern(_ pattern: CHHapticPattern) {}
}
#endif

#if os(macOS)
typealias FeedbackManager = DummyFeedbackManager
#else
typealias FeedbackManager = UIFeedbackManager
#endif
