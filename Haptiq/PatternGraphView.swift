import SwiftUI
import Charts

extension Color {
    static func red(_ value: Double) -> Color {
        Color(red: value, green: 0, blue: 1 - value)
    }
}

struct PatternGraphView: View {
    @Binding var pattern: [HapticsEvent]
    @State var selectedEvent: HapticsEvent?
    
    @State var translation: CGSize?
    @State var durationTranslation: CGFloat?
    
    var body: some View {
        VStack {
            if pattern.isEmpty {
                Text("No pattern data available.")
            } else {
                Chart {
                    ForEach(pattern) { event in
                        let color = Color.red(Double(event.sharpness))
                        let startTime = event.startTime + (event.id == selectedEvent?.id ? (translation?.width ?? 0) : 0)
                        let intensity = event.intensity + Float(event.id == selectedEvent?.id ? (translation?.height ?? 0) : 0)
                        
                        if let duration = event.duration {
                            let endTime = startTime + (selectedEvent?.id == event.id ? (duration * (durationTranslation ?? 1)) : duration)
                            
                            RectangleMark(
                                xStart: .value("Start", startTime),
                                xEnd: .value("End", endTime),
                                yStart: .value("Zero", 0),
                                yEnd: .value("Intensity", intensity)
                            )
                            .zIndex(selectedEvent?.id == event.id ? 2 : 0)
                            .foregroundStyle(color)
                            .opacity(selectedEvent?.id == event.id || selectedEvent == nil ? 0.75 : 0.5)
                        } else {
                            PointMark(
                                x: .value("Time", startTime),
                                y: .value("Intensity", intensity)
                            )
                            .zIndex(selectedEvent?.id == event.id ? 2 : 1)
                            .foregroundStyle(color)
                            .opacity(selectedEvent?.id == event.id || selectedEvent == nil ? 1 : 0.5)
                        }
                    }
                }
                .chartYScale(domain: 0...1)
                .chartXScale(domain: 0...(pattern.compactMap(\.endTime).max() ?? 10) + 5)
                .chartYAxisLabel("Intensity")
                .chartXAxisLabel("Time (s)")
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    // get plot area coordiate from gesture location
                                    guard let selectedEvent else { return }
                                    translation = clampTranslation(value.translation, to: selectedEvent)
                                }
                                .onEnded { value in
                                    if let selectedEvent, value.translation.diagonal > 0 {
                                        if let translation {
                                            guard let eventIx = pattern.firstIndex(where: { $0.id == selectedEvent.id }) else { return }
                                            pattern[eventIx].startTime += translation.width
                                            pattern[eventIx].intensity += Float(translation.height)
                                            
                                            pattern[eventIx].startTime = max(0, pattern[eventIx].startTime)
                                            pattern[eventIx].intensity = max(0, min(1, pattern[eventIx].intensity))
                                            self.translation = nil
                                            self.selectedEvent = pattern[eventIx]
                                        } else {
                                            self.selectedEvent = nil
                                        }
                                    } else {
                                        guard let (time, intensity) = getChartCorrdinates(inGeometry: geometry, chartProxy: proxy, value: value) else { return }
                                        selectedEvent = getEventForCorrdinates(time: time, intensity: intensity)
                                    }
                                }
                            ).simultaneousGesture(MagnifyGesture().onChanged { value in
                                durationTranslation = value.magnification
                            }.onEnded { value in
                                guard let selectedEvent,
                                      let eventIx = pattern.firstIndex(where: { $0.id == selectedEvent.id }),
                                      let duration = selectedEvent.duration else { return }
                                let targetDuration = max(0.05, duration * value.magnification)
                                pattern[eventIx].duration = targetDuration
                                self.selectedEvent?.duration = targetDuration
                                durationTranslation = nil
                            })
                    }
                }
                .focusable()
                .onKeyPress(action: { press in
                    guard selectedEvent != nil else { return .ignored }
                    let delta = press.modifiers.contains(.shift) ? 0.1 : 0.01
                    switch press.key {
                    case .upArrow: Task { editEventKeyPress(intensity: delta) }
                    case .downArrow: Task { editEventKeyPress(intensity: -delta) }
                    case .leftArrow: Task { editEventKeyPress(startTime: -delta) }
                    case .rightArrow: Task { editEventKeyPress(startTime: delta) }
                    default: return .ignored
                    }
                    
                    return .handled
                })
                .frame(height: 240)
                .padding()
                
                VStack(spacing: 8) {
                    Text("Sharpness")
                        .font(.subheadline)
                    HStack {
                        Text("0")
                            .font(.caption)
                        
                        LinearGradient(
                            gradient: Gradient(colors: [.red(0), .red(1)]),
                            startPoint: .leading, endPoint: .trailing
                        )
                        .frame(height: 50)
                        .overlay {
                            GeometryReader { geometry in
                                Rectangle().fill(.clear).contentShape(Rectangle())
                                    .gesture(DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            // get plot area coordiate from gesture location
                                            guard let selectedEvent,
                                                  let eventIx = pattern.firstIndex(where: { $0.id == selectedEvent.id }) else { return }
                                            let sharpness = Float(value.location.x / geometry.size.width)
                                            pattern[eventIx].sharpness = sharpness
                                            self.selectedEvent?.sharpness = sharpness
                                        }
                                    )
                            }
                        }
                        .cornerRadius(5)
                        
                        Text("1")
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 16)
            }
            
            if let selectedEvent {
                Text("Start time: \(selectedEvent.startTime + (translation?.width ?? 0))")
                Text("Intensity: \(CGFloat(selectedEvent.intensity) + (translation?.height ?? 0))")
                Text("Sharpness: \(selectedEvent.sharpness)")
                if let duration = selectedEvent.duration {
                    Text("Duration: \(duration * (durationTranslation ?? 1))")
                }
                #if DEBUG
                Text("Debug: \(translation.debugDescription)")
                #endif
                
                Button("Remove selected event", role: .destructive) {
                    guard let eventIx = pattern.firstIndex(where: { $0.id == selectedEvent.id }) else { return }
                    pattern.remove(at: eventIx)
                    self.selectedEvent = nil
                }
                .padding(.top)
                .keyboardShortcut(.delete, modifiers: [])
            }
            Spacer()
        }
        .navigationTitle("Pattern Graph")
    }
    
    func editEventKeyPress(startTime: CGFloat = 0, intensity: CGFloat = 0) {
        guard let selectedEvent,
              let eventIx = pattern.firstIndex(where: { $0.id == selectedEvent.id }) else {
            return
        }

        pattern[eventIx].startTime = max(0, selectedEvent.startTime + startTime)
        pattern[eventIx].intensity = max(0, min(1, selectedEvent.intensity + Float(intensity)))
        self.selectedEvent = pattern[eventIx]
    }
    
    func clampTranslation(_ translation: CGSize, to event: HapticsEvent) -> CGSize {
        let maxHeight = 1 - CGFloat(event.intensity)
        let minHeight = -CGFloat(event.intensity)
        let minWidth = -event.startTime
        let maxWidth: CGFloat = 5
        return CGSize(
            width: min(max(translation.width * 0.1, minWidth), maxWidth),
            // negative height as y = 0 is top edge but bottom in chart
            height: min(max(-translation.height * 0.01, minHeight), maxHeight)
        )
    }
    
    func getChartCorrdinates(inGeometry geometry: GeometryProxy, chartProxy: ChartProxy, value: DragGesture.Value) -> (TimeInterval, Float)? {
        guard let plotFrame = chartProxy.plotFrame else { return nil }
        let origin = geometry[plotFrame].origin
        let location = CGPoint(
            x: value.location.x - origin.x,
            y: value.location.y - origin.y)
        print(location)
        // update state
        return chartProxy.value(at: location, as: ((TimeInterval, Float).self))
    }
    
    func getEventForCorrdinates(time: TimeInterval, intensity: Float) -> HapticsEvent? {
        pattern.filter { $0.targetTimeRange ~= time }
            .min { lhs, rhs in
                if (lhs.duration == nil) != (rhs.duration == nil) {
                    lhs.duration == nil
                } else {
                    abs(lhs.intensity - intensity) < abs(rhs.intensity - intensity)
                }
            }
    }
}

extension CGSize {
    var diagonal: CGFloat {
        return sqrt(width * width + height * height)
    }
}
