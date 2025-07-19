//
//  Copyright © 2024 SquareOne. All rights reserved.
//

import SwiftUI
import CoreHaptics
import UniformTypeIdentifiers
import Charts

struct ContentView: View {
    @EnvironmentObject var manager: FeedbackManager
    
    @StateObject private var viewModel = ContentViewModel()
    
    @GestureState private var isContinuouslyPlaying = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Status & Record Controls
                    HStack(alignment: .center, spacing: 12) {
                        if let recordingStartTime = viewModel.recordingStartTime {
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
                                .padding(6)
                                .background(.gray.opacity(0.08), in: .capsule)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.handleRecordButton()
                        } label: {
                            Label(viewModel.recordingStartTime == nil ? "Start Recording" : "Stop Recording",
                                  systemImage: viewModel.recordingStartTime == nil ? "dot.circle" : "stop.circle")
                            .font(.body.bold())
                            .padding(6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(viewModel.recordingStartTime == nil ? .accentColor : .red)
                    }
                    .animation(.easeInOut, value: viewModel.recordingStartTime)
                    .padding(.bottom, 6)
                    
                    // Parameter Sliders (vertical)
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Parameters")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Intensity")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $viewModel.intensity, in: 0...1)
                            Text(String(format: "%.2f", viewModel.intensity))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Sharpness")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $viewModel.sharpness, in: 0...1)
                            Text(String(format: "%.2f", viewModel.sharpness))
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
                                manager.playInstamty(intensity: viewModel.intensity, sharpness: viewModel.sharpness)
                                viewModel.addTapEvent()
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
                                .onChange(of: isContinuouslyPlaying) {
                                    if isContinuouslyPlaying {
                                        manager.startPlayingContinously(intensity: viewModel.intensity, sharpness: viewModel.sharpness)
                                        viewModel.startContinuousIfRecording()
                                    } else {
                                        manager.stopPlayingContinously()
                                        viewModel.stopContinuousIfRecording()
                                    }
                                }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    // Recordings List - adaptive height
                    if !viewModel.recordings.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recorded Events")
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(viewModel.recordings) { rec in
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
                        if !viewModel.recordings.isEmpty, viewModel.recordingStartTime == nil {
                            Button {
                                viewModel.playPattern(manager)
                            } label: {
                                Label("Play Pattern", systemImage: "play.circle")
                                    .font(.body.bold())
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if !viewModel.recordings.isEmpty && viewModel.recordingStartTime == nil {
                            Button {
                                viewModel.exportPattern()
                            } label: {
                                Label("Export", systemImage: "square.and.arrow.up")
                                    .font(.body.bold())
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if !viewModel.recordings.isEmpty && viewModel.recordingStartTime == nil {
                            NavigationLink(destination: PatternGraphView(pattern: viewModel.recordings)) {
                                Label("Show Pattern Graph", systemImage: "waveform.path.ecg")
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
            .shareSheet(item: $viewModel.exportURL)
            .navigationTitle("Haptiq")
            // File importer to import AHAP files
            .fileImporter(
                isPresented: $viewModel.isImporting,
                allowedContentTypes: [UTType(filenameExtension: "ahap")!],
                allowsMultipleSelection: false) { result in
                    viewModel.handleImportResult(result)
                }
                .alert("Import Error", isPresented: Binding<Bool>(
                    get: { viewModel.importError != nil },
                    set: { if !$0 { viewModel.importError = nil } }
                ), presenting: viewModel.importError) { error in
                    Button("OK", role: .cancel) {}
                } message: { error in
                    Text(error.localizedDescription)
                }
            // Toolbar with import button
                .toolbar {
                    ToolbarItem(placement: .secondaryAction) {
                        Button {
                            viewModel.isImporting = true
                        } label: {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FeedbackManager())
}
