//
//  Copyright © 2024 SquareOne. All rights reserved.
//

import SwiftUI

@main
struct AHAPApp: App {
    @StateObject var uiFeedbackManager = UIFeedbackManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(uiFeedbackManager)
        }
    }
}
