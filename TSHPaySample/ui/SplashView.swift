//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import SwiftUI

/**
 Splash screen shown on application startup.
 */
struct SplashView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @EnvironmentObject var sdkStateViewModel: SdkStateViewModel
    
    var body: some View {
        VStack {
            LoadingView(title: LocalizedStringKey("progress_title_splash")).onChange(of: self.sdkStateViewModel.isApplicationInitialized) { isApplicationInitialized in
                if isApplicationInitialized {
                    self.viewRouter.currentPage = .cardList
                }
            }.onAppear {
                self.sdkStateViewModel.checkSdkInitialization()
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
