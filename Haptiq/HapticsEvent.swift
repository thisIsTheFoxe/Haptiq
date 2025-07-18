//
//  HapticsEvent.swift
//  Haptiq
//
//  Created by Henry on 18/07/2025.
//
import Foundation
import CoreHaptics

struct HapticsEvent: Identifiable {
    let id: UUID = UUID()
    let startTime: TimeInterval
    let duration: TimeInterval?
    let intensity: Float
    let sharpness: Float
    
    var shortDescription: String {
        ">\(String(format: "%.2f", startTime))s"
        + "\(duration.flatMap { " - \(String(format: "%.2f", $0))s" } ?? "")"
        + " <> Integrity: \(intensity), Sharpness: \(sharpness)"
    }
    
    func toCHHapticEvent() -> CHHapticEvent {
        CHHapticEvent(eventType: duration == nil ? .hapticTransient : .hapticContinuous,
                      parameters: [.init(parameterID: .hapticIntensity, value: intensity),
                                   .init(parameterID: .hapticSharpness, value: sharpness)],
                      relativeTime: startTime,
                      duration: duration ?? 0)
    }
    
    static func parseAHAPDictionary(_ dict: [String: Any]) throws -> [HapticsEvent] {
        guard let eventsArray = dict["Pattern"] as? [String: Any],
              let events = eventsArray["Events"] as? [[String: Any]] else {
            // Some AHAP files might have "Events" at top level dictionary
            if let events = dict["Events"] as? [[String: Any]] {
                return try events.map { try HapticsEvent.parseEvent($0) }
            }
            throw NSError(domain: "AHAPImport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to find events in AHAP file"])
        }
        
        return try events.map { try HapticsEvent.parseEvent($0) }
    }
    
    static func parseEvent(_ eventDict: [String: Any]) throws -> HapticsEvent {
        guard let time = eventDict["Time"] as? Double,
              let eventType = eventDict["EventType"] as? String,
              let parameters = eventDict["EventParameters"] as? [[String: Any]] else {
            throw NSError(domain: "AHAPImport", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid event format"])
        }
        
        var intensity: Float = 0.5
        var sharpness: Float = 0.5
        var duration: TimeInterval? = nil
        
        for param in parameters {
            guard let paramID = param["ParameterID"] as? String,
                  let value = param["ParameterValue"] else { continue }
            if paramID == "HapticIntensity" || paramID == "hapticIntensity" {
                if let v = value as? NSNumber {
                    intensity = v.floatValue
                } else if let v = value as? Float {
                    intensity = v
                }
            } else if paramID == "HapticSharpness" || paramID == "hapticSharpness" {
                if let v = value as? NSNumber {
                    sharpness = v.floatValue
                } else if let v = value as? Float {
                    sharpness = v
                }
            } else if paramID == "Duration" || paramID == "duration" {
                if let v = value as? NSNumber {
                    duration = v.doubleValue
                } else if let v = value as? Double {
                    duration = v
                }
            }
        }
        
        // Duration is nil for transient events, use duration parameter for continuous
        if eventType == "HapticTransient" {
            duration = nil
        }
        
        return HapticsEvent(startTime: time, duration: duration, intensity: intensity, sharpness: sharpness)
    }
}
