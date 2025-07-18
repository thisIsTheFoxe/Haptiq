import SwiftUI
import Charts

struct PatternGraphView: View {
    let pattern: [HapticsEvent]
    var body: some View {
        VStack {
            Text("Pattern Graph")
                .font(.title)
                .padding()
            if pattern.isEmpty {
                Text("No pattern data available.")
            } else {
                Chart {
                    ForEach(pattern) { event in
                        let color = Color.blue.mix(with: .red, by: Double(event.sharpness))
                        if let duration = event.duration {
                            RectangleMark(
                                xStart: .value("Start", event.startTime),
                                xEnd: .value("End", event.startTime + duration),
                                yStart: .value("Zero", 0),
                                yEnd: .value("Intensity", event.intensity)
                            )
                            .foregroundStyle(color)
                            .opacity(0.75)
                        } else {
                            PointMark(
                                x: .value("Time", event.startTime),
                                y: .value("Intensity", event.intensity)
                            )
                            .zIndex(1)
                            .foregroundStyle(color)
                        }
                    }
                }
                .chartYAxisLabel("Intensity")
                .chartXAxisLabel("Time (s)")
                .frame(height: 240)
                .padding()
                HStack(spacing: 0) {
                    Text("Sharpness: 0")
                        .font(.caption)
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple, .red]),
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: 60, height: 10)
                    .cornerRadius(5)
                    Text("1")
                        .font(.caption)
                }
            }
            Spacer()
        }
        .navigationTitle("Pattern Graph")
    }
}
