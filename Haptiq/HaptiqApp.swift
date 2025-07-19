//
//  HaptiqApp.swift
//  Haptiq
//
//  Created by Henry on 19/07/2025.
//

import SwiftUI

@main
struct HaptiqApp: App {
    @StateObject var uiFeedbackManager = FeedbackManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(uiFeedbackManager)
        }
    }
}
