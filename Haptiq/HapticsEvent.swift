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
    
    static func fromDTO(_ dto: EventDTO) -> Self {
        let keyedParameters = Dictionary(uniqueKeysWithValues: dto.eventParameters.map { ($0.parameterID, $0.parameterValue) })
        return .init(startTime: dto.time,
                     duration: dto.eventType == .hapticContinuous ? dto.eventDuration : nil,
                     intensity: Float(keyedParameters[.hapticIntensity] ?? 0),
                     sharpness: Float(keyedParameters[.hapticSharpness] ?? 0))
    }
}
