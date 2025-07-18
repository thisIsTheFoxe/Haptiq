//
//  Copyright © 2024 SquareOne. All rights reserved.
//

import SwiftUI
import CoreHaptics

struct HapticsEvent: Identifiable {
    let id: UUID = UUID()
    let startTime: TimeInterval
    let duration: TimeInterval?
    let intensity: Float
    let sharpness: Float
    
    var shortDescription: String {
        ">\(String(format: "%.2f", startTime))s"
        + " \(duration.flatMap { " - \(String(format: "%.2f", $0))s" } ?? "")"
        + " <> Integrity: \(intensity), Sharpness: \(sharpness)"
    }
    
    func toCHHapticEvent() -> CHHapticEvent {
        CHHapticEvent(eventType: duration == nil ? .hapticTransient : .hapticContinuous,
                      parameters: [.init(parameterID: .hapticIntensity, value: intensity),
                                   .init(parameterID: .hapticSharpness, value: sharpness)],
                      relativeTime: startTime,
                      duration: duration ?? 0)
    }
}

struct ContentView: View {
    @State var intensity: Float = 0.5
    @State var sharpness: Float = 0.5
    @State var duration = 0.0
    
    @State var recordingStartTime: Date?
    @State var continouslyPlayingStartTime: Date?
    @State var recordings: [HapticsEvent] = []
    
    @State var exportURL: URL?
    
    @GestureState private var isContinuouslyPlaying = false
    
    let maneger = UIFeedbackManager()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Status & Record Controls
                    HStack(alignment: .center, spacing: 12) {
                        if let recordingStartTime {
                            Label {
                                Text(recordingStartTime, style: .timer)
                                    .font(.system(.body, design: .monospaced))
                            } icon: {
                                Circle().fill(.red).frame(width: 12, height: 12)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(.red.opacity(0.1), in: .capsule)
                        } else {
                            Text("Ready to record")
                                .foregroundStyle(.gray)
                                .padding(.vertical, 6)
                                .background(.gray.opacity(0.08), in: .capsule)
                        }
                        Button {
                            if recordingStartTime == nil {
                                recordings.removeAll()
                                recordingStartTime = .now
                            } else {
                                recordingStartTime = nil
                            }
                        } label: {
                            Label(recordingStartTime == nil ? "Start Recording" : "Stop Recording", systemImage: recordingStartTime == nil ? "dot.circle" : "stop.circle")
                                .font(.body.bold())
                                .padding(6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(recordingStartTime == nil ? .accentColor : .red)
                        Spacer()
                    }
                    .animation(.easeInOut, value: recordingStartTime)
                    .padding(.bottom, 6)
                    
                    // Parameter Sliders (vertical)
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Parameters")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Intensity")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $intensity, in: 0...1)
                            Text(String(format: "%.2f", intensity))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Sharpness")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $sharpness, in: 0...1)
                            Text(String(format: "%.2f", sharpness))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    // Haptic Triggers
                    VStack(spacing: 12) {
                        Text("Play Haptic")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 16) {
                            Button {
                                maneger.playInstamty(intensity: intensity, sharpness: sharpness)
                                if let recordingStartTime {
                                    recordings.append(.init(startTime: Date.now.timeIntervalSince(recordingStartTime),
                                                            duration: nil,
                                                            intensity: intensity,
                                                            sharpness: sharpness))
                                }
                            } label: {
                                Label("Tap", systemImage: "sparkle")
                                    .font(.body.bold())
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Text("or Hold")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("Hold")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(isContinuouslyPlaying ? .gray.opacity(0.4) : .gray.opacity(0.2))
                                }
                                .opacity(isContinuouslyPlaying ? 0.7 : 1)
                                .gesture(DragGesture(minimumDistance: 0)
                                    .updating($isContinuouslyPlaying) { (_, isTapped, _) in
                                        isTapped = true
                                    })
                                .onChange(of: isContinuouslyPlaying) { newValue in
                                    if newValue {
                                        maneger.startPlayingContinously(intensity: intensity, sharpness: sharpness)
                                        if recordingStartTime != nil {
                                            continouslyPlayingStartTime = .now
                                        }
                                    } else {
                                        maneger.stopPlayingContinously()
                                        if let recordingStartTime, let continouslyPlayingStartTime {
                                            self.continouslyPlayingStartTime = nil
                                            recordings.append(.init(startTime: continouslyPlayingStartTime.timeIntervalSince(recordingStartTime),
                                                                    duration: Date.now.timeIntervalSince(continouslyPlayingStartTime),
                                                                    intensity: intensity,
                                                                    sharpness: sharpness))
                                        }
                                    }
                                }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    // Recordings List - adaptive height
                    if !recordings.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recorded Events")
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(recordings) { rec in
                                    Text(rec.shortDescription)
                                        .font(.system(.footnote, design: .monospaced))
                                        .padding(4)
                                        .background(.tertiary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    
                    // Play & Export Controls
                    HStack(spacing: 14) {
                        if !recordings.isEmpty, recordingStartTime == nil {
                            Button {
                                do {
                                    let pattern = try CHHapticPattern(events: recordings.map { $0.toCHHapticEvent() }, parameters: [])
                                    maneger.playPattern(pattern)
                                } catch {
                                    print(error)
                                }
                            } label: {
                                Label("Play Pattern", systemImage: "play.circle")
                                    .font(.body.bold())
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if !recordings.isEmpty && recordingStartTime == nil {
                            Button {
                                do {
                                    let pattern = try CHHapticPattern(events: recordings.map { $0.toCHHapticEvent() },parameters: [])
                                    let exportData = try JSONSerialization.data(withJSONObject: pattern.exportDictionary())
                                    let exportUrl = FileManager.default
                                        .temporaryDirectory
                                        .appendingPathComponent("pattern.ahap")
                                    if FileManager.default.fileExists(atPath: exportUrl.path) {
                                        try FileManager.default.removeItem(at: exportUrl)
                                    }
                                    try exportData.write(to: exportUrl)
                                    self.exportURL = exportUrl
                                } catch {
                                    print(error)
                                }
                            } label: {
                                Label("Export", systemImage: "square.and.arrow.up")
                                    .font(.body.bold())
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 6)
                    
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal)
            .shareSheet(item: $exportURL)
            .navigationTitle("AHAP Tester")
        }
    }
}

#Preview {
    ContentView()
}
