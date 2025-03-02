//
// Copyright © 2024 THALES. All rights reserved.
//

import SwiftUI
import TSHPaySDK

@main
struct TSHPaySampleApp: App {
    
    // Due to the requirements of app delegate in current swift ui version for stuff like notificaiton etc
    // we will use it as main environment object for everything,
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
            
    var body: some Scene {
        WindowGroup {
            ZStack {
                AppView()
            }
        }
    }
}
