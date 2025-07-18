//
//  Copyright © 2024 SquareOne. All rights reserved.
//

import SwiftUI

@main
struct HaptiqApp: App {
    @StateObject var uiFeedbackManager = UIFeedbackManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(uiFeedbackManager)
        }
    }
}
