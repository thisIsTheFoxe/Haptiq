import SwiftUI
import Charts

extension Color {
    static func red(_ value: Double) -> Color {
        Color(red: value, green: 0, blue: 1 - value)
    }
}

struct PatternGraphView: View {
    let pattern: [HapticsEvent]
    var body: some View {
        VStack {
            if pattern.isEmpty {
                Text("No pattern data available.")
            } else {
                Chart {
                    ForEach(pattern) { event in
                        let color = Color.red(Double(event.sharpness))
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
                HStack(spacing: 8) {
                    Text("Sharpness: 0")
                        .font(.caption)
                    LinearGradient(
                        gradient: Gradient(colors: [.red(0), .red(1)]),
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(height: 10)
                    .cornerRadius(5)
                    Text("1")
                        .font(.caption)
                }
                .padding(.horizontal, 32)
            }
            Spacer()
        }
        .navigationTitle("Pattern Graph")
    }
}
