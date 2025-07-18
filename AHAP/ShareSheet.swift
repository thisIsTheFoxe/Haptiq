//
//  ShareSheet.swift
//  Haptiq
//
//  Created by Henry on 18/07/2025.
//


import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    var items: [URL]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

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
