//
//  ShareSheet.swift
//  Haptiq
//
//  Created by Henry on 18/07/2025.
//


import SwiftUI
#if os(macOS)
import AppKit
#endif

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    var items: [URL]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#if os(macOS)
struct ShareSheet: NSViewRepresentable {
    var items: [URL]

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: "Share", target: context.coordinator, action: #selector(Coordinator.share))
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(items: items)
    }

    class Coordinator: NSObject {
        let items: [URL]
        init(items: [URL]) { self.items = items }
        @objc func share(_ sender: NSButton) {
            let picker = NSSharingServicePicker(items: items)
            picker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }
}
#endif

extension URL: @retroactive Identifiable {
    public var id: Self { self }
}

extension View {
    func shareSheet(item: Binding<URL?>) -> some View {
        sheet(item: item) {
            ShareSheet(items: [$0])
                .ignoresSafeArea()
                .presentationDetents([.medium, .large])
        }
    }
}
