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
            HStack {
                if let recordingStartTime {
                    Circle().fill(.red)
                        .frame(width: 8, height: 8)
                    Text(recordingStartTime, style: .timer)
                }
            }
            
            ScrollView {
                Text(recordings.map(\.shortDescription).joined(separator: "\n"))
            }
            
            VStack(spacing: 16) {
                Group {
                    Text("Intensity: \(intensity)")
                    Slider(value: $intensity, in: 0...1)
                }
                
                Group {
                    Text("Sharpness: \(sharpness)")
                    Slider(value: $sharpness, in: 0...1)
                }
                
                Divider()
                
                Text("BZZZZZZZZZZZZ!!")
                    .bold()
                    .foregroundStyle(.tint)
                    .padding()
                    .background(.gray.opacity(0.2), in: .capsule)
                    .opacity(isContinuouslyPlaying ? 0.5 : 1)
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
                
                
                
                Button("BZZ!!") {
                    maneger.playInstamty(intensity: intensity, sharpness: sharpness)
                    if let recordingStartTime {
                        recordings.append(.init(startTime: Date.now.timeIntervalSince(recordingStartTime),
                                                duration: nil,
                                                intensity: intensity,
                                                sharpness: sharpness))
                    }
                }
                .padding()
                .buttonStyle(.bordered)
                .bold()
                
                HStack {
                    if !recordings.isEmpty, recordingStartTime == nil {
                        Button("Play recorded pattern") {
                            do {
                                let pattern = try CHHapticPattern(events: recordings.map { $0.toCHHapticEvent() },
                                                                  parameters: [])
                                maneger.playPattern(pattern)
                            } catch {
                                print(error)
                            }
                        }
                    }
                    
                    Button(recordingStartTime == nil ? "Start recorcding" : "Stop recording") {
                        if recordingStartTime == nil {
                            recordings.removeAll()
                            recordingStartTime = .now
                        } else {
                            recordingStartTime = nil
                        }
                    }
                    .padding()
                    .buttonStyle(.bordered)
                    .bold()
                }
            }
            .padding()
            .shareSheet(item: $exportURL)
            .toolbar {
                if !recordings.isEmpty {
                    ToolbarItem {
                        Button("Export", systemImage: "square.and.arrow.up") {
                            do {
                                let pattern = try CHHapticPattern(events: recordings.map { $0.toCHHapticEvent() },
                                                                  parameters: [])
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
                        }
                    }
                }
            }
            .navigationTitle("AHAP Testing")
        }
    }
}

#Preview {
    ContentView()
}
