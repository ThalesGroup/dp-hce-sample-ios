//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import SwiftUI

/**
 Root view of the application.
 */
struct RootView: View {
    @EnvironmentObject var viewRouter: ViewRouter

    var body: some View {
        switch self.viewRouter.currentPage {
        case .splash:
            SplashView()
        case .cardList:
            CardHorizontalListView()
        case .payment:
            PaymentView()
        case .enrollment:
            CardEnrollmentView()
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
