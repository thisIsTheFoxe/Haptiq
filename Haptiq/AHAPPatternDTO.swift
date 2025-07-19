//
//  AHAPPatternDTO.swift
//  Haptiq
//
//  Created by Henry on 19/07/2025.
//

struct AHAPPatternDTO: Codable {
    let pattern: [PatternDTO]

    enum CodingKeys: String, CodingKey {
        case pattern = "Pattern"
    }
}

// MARK: - Pattern
struct PatternDTO: Codable {
    let event: EventDTO

    enum CodingKeys: String, CodingKey {
        case event = "Event"
    }
}

// MARK: - Event
struct EventDTO: Codable {
    let eventParameters: [EventParameterDTO]
    let eventType: EventType
    let time, eventDuration: Double

    enum CodingKeys: String, CodingKey {
        case eventParameters = "EventParameters"
        case eventType = "EventType"
        case time = "Time"
        case eventDuration = "EventDuration"
    }
}

// MARK: - EventParameter
struct EventParameterDTO: Codable {
    let parameterID: ParameterID
    let parameterValue: Double

    enum CodingKeys: String, CodingKey {
        case parameterID = "ParameterID"
        case parameterValue = "ParameterValue"
    }
}

enum ParameterID: String, Codable {
    case hapticIntensity = "HapticIntensity"
    case hapticSharpness = "HapticSharpness"
}

enum EventType: String, Codable {
    case hapticContinuous = "HapticContinuous"
    case hapticTransient = "HapticTransient"
}
